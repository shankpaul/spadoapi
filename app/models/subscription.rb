class Subscription < ApplicationRecord
  include AASM
  acts_as_paranoid

  # Constants
  VEHICLE_TYPES = %w[hatchback sedan suv luxury].freeze

  # AASM State Machines
  aasm :status, column: :status do
    state :scheduled, initial: true
    state :active
    state :paused
    state :completed
    state :cancelled
    state :expired

    event :activate do
      transitions from: :scheduled, to: :active
    end

    event :pause do
      transitions from: :active, to: :paused
    end

    event :resume do
      transitions from: :paused, to: :active
    end

    event :complete do
      transitions from: [:active, :paused], to: :completed, guard: :all_orders_completed?
    end

    event :cancel do
      transitions from: [:scheduled, :active, :paused], to: :cancelled, after: :cancel_pending_orders
    end

    event :expire do
      transitions from: [:scheduled, :active, :paused], to: :expired
    end
  end

  aasm :payment, column: :payment_status do
    state :pending, initial: true
    state :paid
    state :payment_cancelled
    state :failed

    event :mark_paid do
      transitions from: [:pending, :failed], to: :paid
    end

    event :mark_cancelled do
      transitions from: [:pending, :paid, :failed], to: :payment_cancelled
    end

    event :mark_failed do
      transitions from: :pending, to: :failed
    end
  end

  # Associations
  belongs_to :customer
  belongs_to :created_by, class_name: 'User'
  has_many :subscription_orders, dependent: :destroy
  has_many :orders, through: :subscription_orders
  has_many :subscription_packages, dependent: :destroy
  has_many :packages, through: :subscription_packages
  has_many :subscription_addons, dependent: :destroy
  has_many :addons, through: :subscription_addons

  # Validations
  validates :customer_id, presence: true
  validates :vehicle_type, presence: true, inclusion: { in: VEHICLE_TYPES, message: "%{value} is not a valid vehicle type" }
  validates :start_date, presence: true
  validates :end_date, presence: true
  validates :months_duration, presence: true, numericality: { greater_than: 0 }
  validates :subscription_amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :payment_amount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :washing_schedules, presence: true
  validates :number_of_orders, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :completed_no_orders, numericality: { greater_than_or_equal_to: 0 }
  validate :validate_end_date_after_start_date
  validate :validate_washing_schedules_format
  validate :validate_washing_schedules_within_period

  # Scopes
  scope :by_customer, ->(customer_id) { where(customer_id: customer_id) }
  scope :by_status, ->(status) { where(status: status) }
  scope :expiring_soon, ->(days = 7) { where(status: :active).where('end_date <= ?', Date.current + days.days) }

  # Callbacks
  before_validation :calculate_end_date, if: :should_calculate_end_date?
  before_validation :normalize_vehicle_type

  # Methods
  def increment_completed_orders!
    increment!(:completed_no_orders)
    complete!(:status) if may_complete?(:status)
  end

  def all_orders_completed?
    completed_no_orders >= number_of_orders
  end

  def cancel_pending_orders
    subscription_orders.pending_generation.each(&:cancel!)
  end

  private

  def validate_end_date_after_start_date
    return unless start_date.present? && end_date.present?
    errors.add(:end_date, "must be after start date") if end_date <= start_date
  end

  def validate_washing_schedules_format
    return unless washing_schedules.present?
    
    unless washing_schedules.is_a?(Array)
      errors.add(:washing_schedules, "must be an array")
      return
    end
    
    washing_schedules.each_with_index do |schedule, index|
      unless schedule.is_a?(Hash) && schedule['date'].present? && schedule['time_from'].present? && schedule['time_to'].present?
        errors.add(:washing_schedules, "invalid format at index #{index}. Each schedule must have date, time_from, and time_to")
      end
    end
  end

  def validate_washing_schedules_within_period
    return unless washing_schedules.present? && start_date.present? && end_date.present?
    
    washing_schedules.each do |schedule|
      date = Date.parse(schedule['date'].to_s) rescue nil
      next unless date
      
      unless date.between?(start_date, end_date)
        errors.add(:washing_schedules, "date #{date} must be within subscription period (#{start_date} to #{end_date})")
        break
      end
    end
  end

  def should_calculate_end_date?
    start_date.present? && months_duration.present? && (end_date.blank? || start_date_changed? || months_duration_changed?)
  end

  def calculate_end_date
    self.end_date = start_date + months_duration.months - 1.day
  end

  def normalize_vehicle_type
    self.vehicle_type = vehicle_type.to_s.downcase if vehicle_type.present?
  end
end
