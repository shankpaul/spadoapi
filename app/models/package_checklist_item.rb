class PackageChecklistItem < ApplicationRecord
  belongs_to :package
  belongs_to :checklist_item
  
  validates :package_id, uniqueness: { scope: :checklist_item_id }
end
