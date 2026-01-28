class UpdatePackagesForUnitPriceAndFeatures < ActiveRecord::Migration[8.0]
  def change
    rename_column :packages, :base_price, :unit_price
    add_column :packages, :features, :text, array: true, default: []
    add_column :packages, :duration_minutes, :integer, comment: 'Estimated time to complete the service in minutes'
  end
end
