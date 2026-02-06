class AddApplicableWashNumbersToSubscriptionAddons < ActiveRecord::Migration[7.0]
  def change
    add_column :subscription_addons, :applicable_wash_numbers, :text, default: '[]'
    
    # Add a comment to explain the field
    reversible do |dir|
      dir.up do
        execute <<-SQL
          COMMENT ON COLUMN subscription_addons.applicable_wash_numbers IS 
          'JSON array of integers representing the specific wash numbers where this addon should be applied. 
          Example: [1, 2, 3, 12] means addon applies to 1st, 2nd, 3rd, and 12th wash.
          Empty array means addon is not applied to any wash.';
        SQL
      end
    end
  end
end
