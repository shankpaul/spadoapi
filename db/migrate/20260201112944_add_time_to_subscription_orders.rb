class AddTimeToSubscriptionOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :subscription_orders, :time_from, :time
    add_column :subscription_orders, :time_to, :time
  end
end
