json.extract! order,
              :id,
              :order_number,
              :area,
              :city,
              :latitude,
              :longitude,
              :map_link,
              :booking_date,
              :booking_time_from,
              :booking_time_to,
              :total_amount,
              :status,
              :payment_status,
              :payment_method,
              :notes,
              :cancelled_at,
              :cancel_reason,
              :rating

json.full_address order.full_address
json.duration_in_minutes order.duration_in_minutes
json.customer_name order.customer&.name
json.assigned_agent_name order.assigned_to&.name
