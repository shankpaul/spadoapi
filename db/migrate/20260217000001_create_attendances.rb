class CreateAttendances < ActiveRecord::Migration[8.0]
  def change
    create_table :attendances do |t|
      t.references :agent, null: false, foreign_key: { to_table: :users }
      t.date :date, null: false
      t.datetime :check_in_time, null: false
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.boolean :is_late, default: false
      t.string :sync_status, default: 'synced'

      t.timestamps
    end

    add_index :attendances, [:agent_id, :date], unique: true
    add_index :attendances, :date
  end
end
