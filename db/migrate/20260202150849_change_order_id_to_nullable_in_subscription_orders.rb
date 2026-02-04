class ChangeOrderIdToNullableInSubscriptionOrders < ActiveRecord::Migration[8.0]
  def change
    change_column_null :subscription_orders, :order_id, true
  end
end
