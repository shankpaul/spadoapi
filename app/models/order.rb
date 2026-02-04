class Order < ApplicationRecord
  include AASM

  acts_as_paranoid

  # Constants
  VEHICLE_TYPES = %w[hatchback sedan suv luxury].freeze

  # Associations
  belongs_to :customer
  belongs_to :bookable, polymorphic: true
  belongs_to :assigned_to, class_name: 'User', optional: true
  belongs_to :cancelled_by, class_name: 'User', optional: true
  belongs_to :subscription, optional: true
  
  has_many :order_packages, dependent: :destroy
  has_many :packages, through: :order_packages
  has_many :order_addons, dependent: :destroy
  has_many :addons, through: :order_addons
  has_many :order_status_logs, dependent: :destroy
  has_many :assignment_histories, dependent: :destroy
  has_many :subscription_orders, dependent: :destroy

  # Validations
  validates :order_number, presence: true, uniqueness: true
  validates :customer_id, presence: true
  validates :contact_phone, presence: true
  validates :area, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true }
  validates :rating, numericality: { only_integer: true, greater_than_or_equal_to: 1, less_than_or_equal_to: 5, allow_nil: true }
  validates :cancel_reason, presence: true, if: :cancelled?
  
  validate :validate_booking_times
  validate :validate_booking_availability, if: :should_validate_availability?
  validate :validate_feedback_on_completed_only

  # Callbacks
  before_validation :generate_order_number, on: :create
  before_validation :copy_gst_percentage_from_settings, on: :create
  after_create :update_customer_last_booked_at
  after_update :track_assignment_change, if: :saved_change_to_assigned_to_id?
  after_update :update_customer_last_booked_at, if: :saved_change_to_booking_date?
  after_update :increment_subscription_completed_count, if: :saved_change_to_status_and_completed?

  # Scopes
  scope :by_status, ->(status) { where(status: status) }
  scope :assigned_to, ->(user_id) { where(assigned_to_id: user_id) }
  scope :by_date_range, ->(from, to) { where(booking_date: from..to) }
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :with_associations, -> { includes(:customer, :assigned_to, :packages, :addons, :order_packages, :order_addons) }

  # AASM State Machine
  aasm column: :status do
    state :draft, initial: true
    state :tentative
    state :confirmed
    state :in_progress
    state :completed
    state :cancelled

    # draft -> tentative (sales_executive/admin)
    event :mark_tentative do
      transitions from: [:draft, :confirmed], to: :tentative
    end

    # draft/tentative -> confirmed (sales_executive/admin)
    event :confirm_booking do
      transitions from: [:draft, :tentative], to: :confirmed
      after do
        log_status_change(aasm.from_state, :confirmed)
      end
    end

    # confirmed -> in_progress (agent/sales_executive/admin)
    event :start_service do
      transitions from: :confirmed, to: :in_progress
      after do
        update_column(:actual_start_time, Time.current) if actual_start_time.blank?
        log_status_change(:confirmed, :in_progress)
      end
    end

    # in_progress -> completed (agent/sales_executive/admin)
    event :complete_service do
      transitions from: :in_progress, to: :completed
      after do
        update_column(:actual_end_time, Time.current) if actual_end_time.blank?
        log_status_change(:in_progress, :completed)
      end
    end

    # any -> cancelled (admin/sales_executive)
    event :cancel_order do
      transitions from: [:draft, :tentative, :confirmed, :in_progress], to: :cancelled
      after do
        update_columns(cancelled_at: Time.current)
        log_status_change(aasm.from_state, :cancelled)
      end
    end
  end

  # Methods

  def full_address
    [address_line1, address_line2, area, city, state].compact.reject(&:blank?).join(', ')
  end

  def coordinates
    return nil unless latitude.present? && longitude.present?
    { latitude: latitude, longitude: longitude }
  end

  def duration_in_minutes
    return nil unless actual_start_time && actual_end_time
    ((actual_end_time - actual_start_time) / 60).to_i
  end

  def can_add_feedback?
    completed? && feedback_submitted_at.blank?
  end

  def can_update_notes?
    !cancelled?
  end

  private

  def generate_order_number
    return if order_number.present?
    date = Time.current
    prefix = "SP#{date.strftime('%y%m%d')}"
    
    # Get the last order number for today with lock
    last_order = Order.where("order_number LIKE ?", "#{prefix}%")
                      .order(order_number: :desc)
                      .lock
                      .first
    
    sequence = if last_order
                 last_order.order_number[-2..-1].to_i + 1
               else
                 1
               end
    
    self.order_number = "#{prefix}#{sequence.to_s.rjust(2, '0')}"
  end

  def copy_gst_percentage_from_settings
    self.gst_percentage ||= Setting.gst_percentage || 0
  end

  def validate_booking_times
    return unless booking_time_from && booking_time_to
    
    if booking_time_from >= booking_time_to
      errors.add(:booking_time_to, "must be after booking start time")
    end

    if booking_date && booking_date < Date.current
      errors.add(:booking_date, "cannot be in the past")
    end
  end

  def should_validate_availability?
    assigned_to_id.present? && booking_date.present? && booking_time_from.present? && booking_time_to.present?
  end

  def validate_booking_availability
    return unless assigned_to_id_changed? || booking_date_changed? || booking_time_from_changed? || booking_time_to_changed?
    
    buffer_minutes = Setting.booking_buffer_minutes.to_i
    
    # Check for overlapping bookings for the same agent on the same day
    overlapping = Order.where(assigned_to_id: assigned_to_id, booking_date: booking_date)
                       .where.not(id: id)
                       .where.not(status: [:cancelled, :completed])
                       .where("booking_time_from < ? AND booking_time_to > ?", 
                              booking_time_to + buffer_minutes.minutes,
                              booking_time_from - buffer_minutes.minutes)
    
    if overlapping.exists?
      conflicting_order = overlapping.first
      errors.add(:base, "Agent is not available during this time. Conflicts with Order ##{conflicting_order.order_number}")
    end
  end

  def validate_feedback_on_completed_only
    if (rating.present? || comments.present? || feedback_submitted_at.present?) && !completed?
      errors.add(:base, "Feedback can only be added to completed orders")
    end
  end

  def log_status_change(from_status, to_status)
    order_status_logs.create!(
      from_status: from_status.to_s,
      to_status: to_status.to_s,
      changed_by: Current.user, # Assuming you have Current.user set in controller
      changed_at: Time.current
    )
  end

  def track_assignment_change
    return unless assigned_to_id.present?
    
    notes_text = if saved_change_to_booking_date?
                   "Reassignment due to booking date change from #{saved_change_to_booking_date[0]} to #{saved_change_to_booking_date[1]}"
                 else
                   nil
                 end
    
    assignment_histories.create!(
      assigned_to_id: assigned_to_id,
      assigned_by: Current.user,
      assigned_at: Time.current,
      status: status,
      notes: notes_text
    )
  end

  def update_customer_last_booked_at
    customer.update_column(:last_booked_at, Time.current) if customer.present?
  end

  def saved_change_to_status_and_completed?
    saved_change_to_status? && completed?
  end

  def increment_subscription_completed_count
    return unless subscription.present?
    subscription.increment_completed_orders!
  end
end
