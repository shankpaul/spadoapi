class CreateSubscriptions < ActiveRecord::Migration[8.0]
  def change
    create_table :subscriptions do |t|
      t.references :customer, null: false, foreign_key: true
      t.references :package, null: false, foreign_key: true
      t.integer :vehicle_type, null: false
      t.string :status, null: false, default: 'active'
      t.date :start_date, null: false
      t.date :end_date, null: false
      t.integer :months_duration, null: false
      t.date :washing_dates, array: true, default: []
      t.decimal :subscription_amount, precision: 10, scale: 2, null: false
      t.decimal :payment_amount, precision: 10, scale: 2, default: 0.0
      t.date :payment_date
      t.string :payment_status, default: 'pending'
      t.string :payment_method
      t.text :notes
      t.references :created_by, null: false, foreign_key: { to_table: :users }
      t.datetime :deleted_at

      t.timestamps
    end
    
    add_index :subscriptions, :status
    add_index :subscriptions, :deleted_at
  end
end
