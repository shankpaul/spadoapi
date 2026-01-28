class CreateOrderStatusLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :order_status_logs do |t|
      t.references :order, null: false, foreign_key: true
      t.string :from_status, null: false
      t.string :to_status, null: false
      t.references :changed_by, foreign_key: { to_table: :users }
      t.datetime :changed_at, null: false

      t.timestamps
    end

    add_index :order_status_logs, [:order_id, :changed_at]
  end
end
