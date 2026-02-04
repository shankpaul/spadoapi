class CreateSubscriptionOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :subscription_orders do |t|
      t.references :subscription, null: false, foreign_key: true
      t.references :order, null: false, foreign_key: true
      t.date :scheduled_date, null: false
      t.datetime :generated_at
      t.string :status, default: 'pending_generation'

      t.timestamps
    end
    
    add_index :subscription_orders, [:subscription_id, :scheduled_date], unique: true
    add_index :subscription_orders, :status
  end
end
