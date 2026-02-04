class ChangeVehicleTypeToStringInSubscriptionPackages < ActiveRecord::Migration[8.0]
  def up
    # Change vehicle_type from integer to string
    change_column :subscription_packages, :vehicle_type, :string
    
    # Update existing records to convert integer enum values to strings
    execute <<-SQL
      UPDATE subscription_packages 
      SET vehicle_type = CASE vehicle_type
        WHEN '0' THEN 'hatchback'
        WHEN '1' THEN 'sedan'
        WHEN '2' THEN 'suv'
        WHEN '3' THEN 'luxury'
        ELSE vehicle_type
      END
    SQL
  end

  def down
    # Convert strings back to integers (reverse mapping)
    execute <<-SQL
      UPDATE subscription_packages 
      SET vehicle_type = CASE vehicle_type
        WHEN 'hatchback' THEN '0'
        WHEN 'sedan' THEN '1'
        WHEN 'suv' THEN '2'
        WHEN 'luxury' THEN '3'
        ELSE vehicle_type
      END
    SQL
    
    change_column :subscription_packages, :vehicle_type, :integer, using: 'vehicle_type::integer'
  end
end
