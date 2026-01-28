class OrderStatusLog < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :changed_by, class_name: 'User', optional: true

  # Validations
  validates :from_status, presence: true
  validates :to_status, presence: true
  validates :changed_at, presence: true

  # Scopes
  scope :recent, -> { order(changed_at: :desc) }
  scope :for_order, ->(order_id) { where(order_id: order_id) }
end
