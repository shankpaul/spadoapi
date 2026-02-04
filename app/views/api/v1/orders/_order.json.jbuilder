json.extract! order,
              :id,
              :order_number,
              :customer_id,
              :bookable_type,
              :bookable_id,
              :contact_phone,
              :address_line1,
              :address_line2,
              :area,
              :city,
              :state,
              :latitude,
              :longitude,
              :map_link,
              :booking_date,
              :booking_time_from,
              :booking_time_to,
              :actual_start_time,
              :actual_end_time,
              :assigned_to_id,
              :total_amount,
              :gst_amount,
              :gst_percentage,
              :status,
              :payment_status,
              :payment_method,
              :notes,
              :cancelled_by_id,
              :cancelled_at,
              :cancel_reason,
              :rating,
              :comments,
              :feedback_submitted_at,
              :created_at,
              :updated_at
              :subscription_id

json.full_address order.full_address
json.coordinates order.coordinates
json.duration_in_minutes order.duration_in_minutes

# Customer details
if order.customer
  json.customer do
    json.extract! order.customer, :id, :name, :phone, :email
  end
end

# Bookable details (User who booked)
if order.bookable
  json.bookable do
    json.extract! order.bookable, :id, :name, :email
    json.type order.bookable_type
    json.role order.bookable.role if order.bookable.respond_to?(:role)
  end
end

# Assigned agent details
if order.assigned_to
  json.assigned_to do
    json.extract! order.assigned_to, :id, :name
  end
end

# Cancelled by details
if order.cancelled_by
  json.cancelled_by do
    json.extract! order.cancelled_by, :id, :name, :email
  end
end
