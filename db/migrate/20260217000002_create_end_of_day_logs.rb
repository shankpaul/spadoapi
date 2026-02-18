class CreateEndOfDayLogs < ActiveRecord::Migration[8.0]
  def change
    create_table :end_of_day_logs do |t|
      t.references :agent, null: false, foreign_key: { to_table: :users }
      t.date :date, null: false
      t.datetime :check_out_time, null: false
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.decimal :cash_in_hand, precision: 10, scale: 2, default: 0.0
      t.decimal :distance_travelled, precision: 10, scale: 2, default: 0.0
      t.text :notes

      t.timestamps
    end

    add_index :end_of_day_logs, [:agent_id, :date], unique: true
    add_index :end_of_day_logs, :date
  end
end
