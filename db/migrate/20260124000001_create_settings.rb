class CreateSettings < ActiveRecord::Migration[8.0]
  def change
    create_table :settings do |t|
      t.string :key, null: false
      t.text :value
      t.string :value_type, default: 'string'
      t.text :description

      t.timestamps
    end

    add_index :settings, :key, unique: true

    # Seed default values
    reversible do |dir|
      dir.up do
        Setting.create!(key: 'gst_percentage', value: '18.0', value_type: 'decimal', description: 'GST percentage for order calculations')
        Setting.create!(key: 'booking_buffer_minutes', value: '30', value_type: 'integer', description: 'Buffer time in minutes between bookings for same agent')
      end
    end
  end
end
