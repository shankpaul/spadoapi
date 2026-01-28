class CreateOrders < ActiveRecord::Migration[8.0]
  def change
    create_table :orders do |t|
      t.string :order_number, null: false
      t.references :customer, null: false, foreign_key: true
      
      # Polymorphic bookable (User who books: sales_executive/admin/customer)
      t.references :bookable, polymorphic: true, null: false
      
      # Address fields (copied from customer at creation)
      t.string :contact_phone
      t.string :address_line1
      t.string :address_line2
      t.string :area
      t.string :city
      t.string :state
      t.decimal :latitude, precision: 10, scale: 8
      t.decimal :longitude, precision: 11, scale: 8
      t.string :map_link
      
      # Booking details
      t.date :booking_date
      t.datetime :booking_time_from
      t.datetime :booking_time_to
      t.datetime :actual_start_time
      t.datetime :actual_end_time
      
      # Assignment
      t.references :assigned_to, foreign_key: { to_table: :users }
      
      # Financial
      t.decimal :total_amount, precision: 10, scale: 2, default: 0
      t.decimal :gst_amount, precision: 10, scale: 2, default: 0
      t.decimal :gst_percentage, precision: 5, scale: 2, default: 18.0
      
      # Status (managed by AASM)
      t.string :status, default: 'draft', null: false
      t.string :payment_status, default: 'pending'
      t.string :payment_method, default: 'cod'
      
      # Notes
      t.text :notes
      
      # Cancellation
      t.references :cancelled_by, foreign_key: { to_table: :users }
      t.datetime :cancelled_at
      t.text :cancel_reason
      
      # Customer feedback
      t.integer :rating
      t.text :comments
      t.datetime :feedback_submitted_at
      
      # Soft delete
      t.datetime :deleted_at

      t.timestamps
    end

    # Indexes for performance
    add_index :orders, :order_number, unique: true
    add_index :orders, [:assigned_to_id, :booking_date, :status], name: 'index_orders_on_agent_calendar'
    # Note: index on [:bookable_type, :bookable_id] is automatically created by polymorphic reference
    add_index :orders, :status
    add_index :orders, :booking_date
    add_index :orders, :created_at
    add_index :orders, :deleted_at
  end
end
