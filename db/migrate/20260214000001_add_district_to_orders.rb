class AddDistrictToOrders < ActiveRecord::Migration[8.0]
  def change
    add_column :orders, :district, :string
  end
end
