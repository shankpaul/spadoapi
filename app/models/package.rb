class Package < ApplicationRecord
  acts_as_paranoid

  # Enums
  VEHICLE_TYPES = %w[hatchback sedan suv luxury].freeze
  enum :vehicle_type, VEHICLE_TYPES.each_with_index.to_h

  # Associations
  has_many :order_packages, dependent: :destroy
  has_many :orders, through: :order_packages

  # Validations
  validates :name, presence: true
  validates :unit_price, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :vehicle_type, presence: true

  # Scopes
  scope :active, -> { where(active: true) }
  scope :by_vehicle_type, ->(type) { where(vehicle_type: type) }

  def display_name
    "#{name} (#{vehicle_type&.humanize})"
  end
end
