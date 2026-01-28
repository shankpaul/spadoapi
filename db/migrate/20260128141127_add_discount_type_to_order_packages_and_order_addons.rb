class AddDiscountTypeToOrderPackagesAndOrderAddons < ActiveRecord::Migration[8.0]
  def change
    add_column :order_packages, :discount_type, :string
    add_column :order_addons, :discount_type, :string
  end
end
