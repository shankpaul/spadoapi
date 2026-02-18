class AddImageAndTipFieldsToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :received_amount, :decimal, precision: 10, scale: 2
    add_column :orders, :tip, :decimal, precision: 10, scale: 2, default: 0
  end
end
