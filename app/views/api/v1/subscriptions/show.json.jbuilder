json.subscription do
  json.partial! 'subscription_basic', subscription: @subscription
  
  # Packages details
  json.subscription_packages do
    json.array! @subscription.subscription_packages do |sub_pkg|
      json.id sub_pkg.id
      json.package do
        json.id sub_pkg.package.id
        json.name sub_pkg.package.name
      end
      json.quantity sub_pkg.quantity
      json.unit_price sub_pkg.unit_price
      json.price sub_pkg.price
      json.vehicle_type sub_pkg.vehicle_type
      json.discount sub_pkg.discount
      json.discount_type sub_pkg.discount_type
      json.discount_value sub_pkg.discount_value
      json.total_price sub_pkg.total_price
      json.notes sub_pkg.notes
    end
  end
  
  # Addons details
  json.subscription_addons do
    json.array! @subscription.subscription_addons do |sub_addon|
      json.id sub_addon.id
      json.addon do
        json.id sub_addon.addon.id
        json.name sub_addon.addon.name
      end
      json.quantity sub_addon.quantity
      json.unit_price sub_addon.unit_price
      json.price sub_addon.price
      json.discount sub_addon.discount
      json.discount_type sub_addon.discount_type
      json.discount_value sub_addon.discount_value
      json.total_price sub_addon.total_price
    end
  end
  
  # Additional details for show view
  json.subscription_orders do
    json.array! @subscription.subscription_orders.order(scheduled_date: :asc) do |sub_order|
      json.id sub_order.id
      json.scheduled_date sub_order.scheduled_date
      json.time_from sub_order.time_from
      json.time_to sub_order.time_to
      json.status sub_order.status
      json.generated_at sub_order.generated_at
      
      if sub_order.order.present?
        json.order do
          json.id sub_order.order.id
          json.order_number sub_order.order.order_number
          json.status sub_order.order.status
          json.booking_date sub_order.order.booking_date
          json.assigned_to_name sub_order.order.assigned_to&.name
        end
      end
    end
  end
  
  json.orders_summary do
    json.total_orders @subscription.orders.count
    json.completed_orders @subscription.orders.where(status: :completed).count
    json.pending_orders @subscription.orders.where(status: [:draft, :tentative, :confirmed]).count
    json.in_progress_orders @subscription.orders.where(status: :in_progress).count
  end
end

json.message @message if @message.present?
