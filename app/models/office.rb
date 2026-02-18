class Office < ApplicationRecord
  # Associations
  has_many :users, foreign_key: :office_id, dependent: :nullify

  # Validations
  validates :name, presence: true, uniqueness: true
  validates :latitude, presence: true,
            numericality: { greater_than_or_equal_to: -90, less_than_or_equal_to: 90 }
  validates :longitude, presence: true,
            numericality: { greater_than_or_equal_to: -180, less_than_or_equal_to: 180 }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :inactive, -> { where(active: false) }
  scope :ordered, -> { order(:name) }

  # Methods
  def coordinates
    { latitude: latitude, longitude: longitude }
  end

  def user_count
    users.count
  end

  def deactivate!
    update(active: false)
  end

  def activate!
    update(active: true)
  end
end
