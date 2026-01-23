class AddDeletedAtToCustomers < ActiveRecord::Migration[8.0]
  def change
    add_column :customers, :deleted_at, :datetime
    add_index :customers, :deleted_at
  end
end
