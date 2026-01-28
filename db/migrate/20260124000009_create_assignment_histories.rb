class CreateAssignmentHistories < ActiveRecord::Migration[8.0]
  def change
    create_table :assignment_histories do |t|
      t.references :order, null: false, foreign_key: true
      t.references :assigned_to, null: false, foreign_key: { to_table: :users }
      t.references :assigned_by, foreign_key: { to_table: :users }
      t.datetime :assigned_at, null: false
      t.string :status
      t.text :notes

      t.timestamps
    end

    add_index :assignment_histories, [:order_id, :assigned_at]
  end
end
