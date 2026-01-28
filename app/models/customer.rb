class Customer < ApplicationRecord
  acts_as_paranoid

  # Validations
  validates :name, presence: true
  validates :email, format: { with: URI::MailTo::EMAIL_REGEXP, allow_blank: true }
  validates :phone, presence: true
  validates :area, presence: true
  validates :latitude, numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90, allow_nil: true }
  validates :longitude, numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180, allow_nil: true }

  # Scopes
  scope :with_whatsapp, -> { where(has_whatsapp: true) }
  scope :by_city, ->(city) { where(city: city) }
  scope :by_state, ->(state) { where(state: state) }
  scope :recently_booked, -> { where('last_booked_at > ?', 30.days.ago).order(last_booked_at: :desc) }

  # Methods
  def full_address
    [address_line1, address_line2, area, city, district, state].compact.reject(&:blank?).join(', ')
  end

  def coordinates
    return nil unless latitude.present? && longitude.present?
    { latitude: latitude, longitude: longitude }
  end

  def send_whatsapp_message_tracking
    update(last_whatsapp_message_sent_at: Time.current)
  end
end
