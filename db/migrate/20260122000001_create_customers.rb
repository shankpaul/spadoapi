class CreateCustomers < ActiveRecord::Migration[8.0]
  def change
    create_table :customers do |t|
      t.string :name, null: false
      t.string :phone
      t.string :email
      t.boolean :has_whatsapp, default: false
      t.datetime :last_booked_at
      t.string :area
      t.string :city
      t.string :district
      t.string :state
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.string :map_link
      t.datetime :last_whatsapp_message_sent_at

      t.timestamps
    end

    add_index :customers, :email
    add_index :customers, :phone
    add_index :customers, :city
  end
end
