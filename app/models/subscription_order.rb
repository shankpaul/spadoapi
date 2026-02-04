class SubscriptionOrder < ApplicationRecord
  include AASM

  # AASM State Machine
  aasm column: :status do
    state :pending_generation, initial: true
    state :generated
    state :cancelled

    event :mark_generated do
      transitions from: :pending_generation, to: :generated
    end

    event :cancel do
      transitions from: [:pending_generation, :generated], to: :cancelled
    end
  end

  # Associations
  belongs_to :subscription
  belongs_to :order, optional: true

  # Validations
  validates :scheduled_date, presence: true
  validates :scheduled_date, uniqueness: { scope: :subscription_id }

  # Scopes
  scope :pending_generation, -> { where(status: :pending_generation) }
  scope :generated, -> { where(status: :generated) }
  scope :upcoming, ->(days = 7) { 
    where(status: :pending_generation)
      .where('scheduled_date <= ?', Date.current + days.days)
      .where('scheduled_date >= ?', Date.current)
  }
end
