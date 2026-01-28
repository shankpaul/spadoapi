class CreateOrderPackages < ActiveRecord::Migration[8.0]
  def change
    create_table :order_packages do |t|
      t.references :order, null: false, foreign_key: true
      t.references :package, null: false, foreign_key: true
      t.integer :quantity, default: 1, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.integer :vehicle_type, null: false
      t.decimal :discount, precision: 10, scale: 2, default: 0
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.text :notes

      t.timestamps
    end

    add_index :order_packages, [:order_id, :package_id]
  end
end
