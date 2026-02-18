class AddDetailsToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :phone, :string
    add_column :users, :address, :text
    add_column :users, :employee_number, :string
  end
end
