class SubscriptionAddon < ApplicationRecord
  # Associations
  belongs_to :subscription
  belongs_to :addon

  # Serialization
  serialize :applicable_wash_numbers, coder: JSON

  # Validations
  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :total_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validate :validate_applicable_wash_numbers

  # Callbacks
  before_validation :normalize_applicable_wash_numbers
  before_validation :calculate_total_price, if: :should_calculate_price?

  # Check if addon should be applied to a specific wash number
  def applies_to_wash?(wash_number)
    return false if applicable_wash_numbers.blank?
    applicable_wash_numbers.include?(wash_number)
  end

  private

  def normalize_applicable_wash_numbers
    # Convert to array if it's a string or nil
    if applicable_wash_numbers.is_a?(String)
      begin
        self.applicable_wash_numbers = JSON.parse(applicable_wash_numbers)
      rescue JSON::ParserError
        self.applicable_wash_numbers = []
      end
    elsif applicable_wash_numbers.nil?
      self.applicable_wash_numbers = []
    end

    # Ensure it's an array and contains only integers
    self.applicable_wash_numbers = Array(applicable_wash_numbers).map(&:to_i).uniq.sort
  end

  def validate_applicable_wash_numbers
    return if applicable_wash_numbers.blank?

    unless applicable_wash_numbers.is_a?(Array)
      errors.add(:applicable_wash_numbers, "must be an array")
      return
    end

    # Check if all values are positive integers
    unless applicable_wash_numbers.all? { |n| n.is_a?(Integer) && n > 0 }
      errors.add(:applicable_wash_numbers, "must contain only positive integers")
      return
    end

    # Validate against subscription's total washes (if subscription is present)
    if subscription.present?
      total_washes = calculate_total_washes
      invalid_numbers = applicable_wash_numbers.select { |n| n > total_washes }
      
      if invalid_numbers.any?
        errors.add(:applicable_wash_numbers, 
          "contains invalid wash numbers #{invalid_numbers.join(', ')}. " \
          "Valid range is 1 to #{total_washes}")
      end
    end
  end

  def calculate_total_washes
    # Calculate total washes from subscription packages
    return 0 unless subscription.present?
    
    subscription.subscription_packages.sum do |sub_pkg|
      (sub_pkg.package&.max_washes_per_month || 0) * subscription.months_duration
    end
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
