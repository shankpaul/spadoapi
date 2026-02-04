class AddSubscriptionFieldsToPackages < ActiveRecord::Migration[8.0]
  def change
    add_column :packages, :subscription_enabled, :boolean, default: false, null: false
    add_column :packages, :subscription_price, :decimal, precision: 10, scale: 2
    add_column :packages, :max_washes_per_month, :integer
    add_column :packages, :min_subscription_months, :integer, default: 1
  end
end
