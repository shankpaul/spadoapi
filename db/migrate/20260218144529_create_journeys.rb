class CreateJourneys < ActiveRecord::Migration[8.0]
  def change
    create_table :journeys do |t|
      t.references :order, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.decimal :from_latitude, precision: 10, scale: 7, null: false
      t.decimal :from_longitude, precision: 10, scale: 7, null: false
      t.decimal :to_latitude, precision: 10, scale: 7, null: false
      t.decimal :to_longitude, precision: 10, scale: 7, null: false
      t.decimal :distance_km, precision: 10, scale: 2, null: false
      t.decimal :amount, precision: 10, scale: 2
      t.string :trip_type, null: false, default: 'to_customer'
      t.datetime :traveled_at, null: false

      t.timestamps
    end

    add_index :journeys, [:order_id, :trip_type], unique: true
  end
end
