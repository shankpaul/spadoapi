class Journey < ApplicationRecord
  belongs_to :order
  belongs_to :user

  # Validations
  validates :from_latitude, :from_longitude, :to_latitude, :to_longitude, 
            :distance_km, :amount, :traveled_at, presence: true
  validates :from_latitude, :to_latitude, 
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :from_longitude, :to_longitude, 
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }
  validates :distance_km, numericality: { greater_than: 0 }
  validates :amount, numericality: { greater_than_or_equal_to: 0 }
  validates :trip_type, presence: true, 
            inclusion: { in: %w[to_customer to_home], 
                        message: "%{value} is not a valid trip type" }
  
  # Ensure order doesn't have more than 2 journeys (one to customer, one to home)
  validate :order_journey_limit
  
  # Ensure unique trip_type per order (can't have two 'to_customer' or two 'to_home' journeys)
  validates :trip_type, uniqueness: { scope: :order_id, 
                                      message: "journey already exists for this order" }

  # Scopes
  scope :to_customer, -> { where(trip_type: 'to_customer') }
  scope :to_home, -> { where(trip_type: 'to_home') }
  scope :recent, -> { order(traveled_at: :desc) }

  # Helper methods
  def to_customer?
    trip_type == 'to_customer'
  end

  def to_home?
    trip_type == 'to_home'
  end

  private

  def order_journey_limit
    if order.present?
      journey_count = order.journeys.count
      journey_count -= 1 if persisted? # Exclude current record if updating
      
      if journey_count >= 2
        errors.add(:base, "Order can have maximum 2 journeys (one to customer and one to home)")
      end
    end
  end
end
