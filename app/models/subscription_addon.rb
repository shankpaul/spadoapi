class SubscriptionAddon < ApplicationRecord
  # Associations
  belongs_to :subscription
  belongs_to :addon

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :calculate_total_price, if: :should_calculate_price?

  private

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
