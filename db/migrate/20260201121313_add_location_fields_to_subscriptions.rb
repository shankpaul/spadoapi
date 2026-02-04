class AddLocationFieldsToSubscriptions < ActiveRecord::Migration[8.0]
  def change
    add_column :subscriptions, :map_url, :string
    add_column :subscriptions, :area, :string
  end
end
