class CreateChecklistItems < ActiveRecord::Migration[8.0]
  def change
    create_table :checklist_items do |t|
      t.string :name, null: false
      t.string :when, null: false # 'pre' or 'post'
      t.boolean :active, default: true, null: false
      t.integer :position, default: 0 # For ordering items
      
      t.timestamps
    end

    add_index :checklist_items, :when
    add_index :checklist_items, :active
    
    # Join table for many-to-many relationship
    create_table :package_checklist_items do |t|
      t.references :package, null: false, foreign_key: true
      t.references :checklist_item, null: false, foreign_key: true
      
      t.timestamps
    end
    
    add_index :package_checklist_items, [:package_id, :checklist_item_id], unique: true, name: 'index_package_checklist_items_unique'
  end
end
