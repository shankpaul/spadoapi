class CreateSubscriptionPackages < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_packages do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :package, null: false, foreign_key: true
      t.integer :quantity, default: 1, null: false
      t.decimal :price, precision: 10, scale: 2, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.integer :vehicle_type, null: false
      t.decimal :discount, precision: 10, scale: 2
      t.string :discount_type
      t.decimal :discount_value, precision: 10, scale: 2
      t.decimal :total_price, precision: 10, scale: 2, null: false
      t.text :notes

      t.timestamps
    end
    
    add_index :subscription_packages, [:subscription_id, :package_id]
  end
end
