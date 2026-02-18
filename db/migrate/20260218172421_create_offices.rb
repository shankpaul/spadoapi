class CreateOffices < ActiveRecord::Migration[8.0]
  def change
    create_table :offices do |t|
      t.string :name, null: false
      t.decimal :latitude, precision: 10, scale: 7, null: false
      t.decimal :longitude, precision: 10, scale: 7, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :offices, :name
    add_index :offices, :active
  end
end
