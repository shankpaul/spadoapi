class AddHomeLocationToUsers < ActiveRecord::Migration[8.0]
  def change
    add_column :users, :home_latitude, :decimal, precision: 10, scale: 7
    add_column :users, :home_longitude, :decimal, precision: 10, scale: 7
  end
end
