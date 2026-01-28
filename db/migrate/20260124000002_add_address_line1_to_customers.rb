class AddAddressLine1ToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :address_line1, :string
    add_column :customers, :address_line2, :string
  end
end
