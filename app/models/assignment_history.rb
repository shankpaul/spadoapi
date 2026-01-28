class AssignmentHistory < ApplicationRecord
  # Associations
  belongs_to :order
  belongs_to :assigned_to, class_name: 'User'
  belongs_to :assigned_by, class_name: 'User', optional: true

  # Validations
  validates :assigned_at, presence: true

  # Scopes
  scope :recent, -> { order(assigned_at: :desc) }
  scope :for_order, ->(order_id) { where(order_id: order_id) }
  scope :for_agent, ->(user_id) { where(assigned_to_id: user_id) }
end
