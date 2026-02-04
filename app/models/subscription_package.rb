class SubscriptionPackage < ApplicationRecord
  # Constants
  VEHICLE_TYPES = %w[hatchback sedan suv luxury].freeze

  # Associations
  belongs_to :subscription
  belongs_to :package

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :vehicle_type, presence: true, inclusion: { in: VEHICLE_TYPES }

  # Callbacks
  before_validation :normalize_vehicle_type
  before_validation :calculate_total_price, if: :should_calculate_price?

  private

  def normalize_vehicle_type
    self.vehicle_type = vehicle_type.to_s.downcase if vehicle_type.present?
  end

  def should_calculate_price?
    price.present? && quantity.present?
  end

  def calculate_total_price
    base_amount = price * quantity
    
    if discount_value.present? && discount_value > 0
      self.total_price = base_amount - discount_value
    else
      self.total_price = base_amount
    end
  end
end
