class Addon < ApplicationRecord
  acts_as_paranoid

  # Associations
  has_many :order_addons, dependent: :destroy
  has_many :orders, through: :order_addons

  # Validations
  validates :name, presence: true
  validates :price, presence: true, numericality: { greater_than_or_equal_to: 0 }

  # Scopes
  scope :active, -> { where(active: true) }
end
