class CreateAddons < ActiveRecord::Migration[8.0]
  def change
    create_table :addons do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :price, precision: 10, scale: 2, null: false, default: 0
      t.boolean :active, default: true
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :addons, :deleted_at
    add_index :addons, :active
  end
end
