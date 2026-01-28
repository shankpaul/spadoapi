class OrderAddon < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :addon

  # Validations
  validates :quantity, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :discount, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Callbacks
  before_validation :calculate_total_price, if: :price_or_quantity_changed?

  private

  def price_or_quantity_changed?
    price_changed? || quantity_changed? || discount_changed?
  end

  def calculate_total_price
    return unless price && quantity
    
    subtotal = price * quantity
    discount_amount = discount || 0
    self.total_price = (subtotal - discount_amount).round(2)
  end
end
