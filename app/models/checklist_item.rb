class ChecklistItem < ApplicationRecord
  # Associations
  has_many :package_checklist_items, dependent: :destroy
  has_many :packages, through: :package_checklist_items

  # Validations
  validates :name, presence: true
  validates :when, presence: true, inclusion: { in: %w[pre post] }
  validates :active, inclusion: { in: [true, false] }

  # Scopes
  scope :active, -> { where(active: true) }
  scope :pre, -> { where(when: 'pre') }
  scope :post, -> { where(when: 'post') }
  scope :ordered, -> { order(position: :asc, id: :asc) }

  # Default scope
  default_scope { ordered }
  
  def pre?
    self.when == 'pre'
  end
  
  def post?
    self.when == 'post'
  end
end
