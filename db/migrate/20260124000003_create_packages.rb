class CreatePackages < ActiveRecord::Migration[8.0]
  def change
    create_table :packages do |t|
      t.string :name, null: false
      t.text :description
      t.decimal :base_price, precision: 10, scale: 2, null: false, default: 0
      t.integer :vehicle_type, default: 0
      t.boolean :active, default: true
      t.datetime :deleted_at

      t.timestamps
    end

    add_index :packages, :deleted_at
    add_index :packages, :active
    add_index :packages, :vehicle_type
  end
end
