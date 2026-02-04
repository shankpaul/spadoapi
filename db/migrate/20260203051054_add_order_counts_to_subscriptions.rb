class AddOrderCountsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :number_of_orders, :integer, default: 0, null: false
    add_column :subscriptions, :completed_no_orders, :integer, default: 0, null: false
  end
end
