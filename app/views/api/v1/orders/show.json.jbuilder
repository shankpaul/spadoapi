json.message @message if @message

json.order do
  json.partial! 'order', order: @order
  
  # Include packages with details
  json.packages @order.order_packages do |order_package|
    json.extract! order_package, :id, :quantity, :price, :vehicle_type, :discount, :discount_type, :total_price, :notes
    json.package do
      json.extract! order_package.package, :id, :name, :description, :unit_price, :features
    end
  end
  
  # Include addons with details
  json.addons @order.order_addons do |order_addon|
    json.extract! order_addon, :id, :quantity, :price, :discount, :discount_type, :total_price
    json.addon do
      json.extract! order_addon.addon, :id, :name, :description, :price
    end
  end
  
  # Include status change history
  json.status_logs @order.order_status_logs.recent do |log|
    json.extract! log, :id, :from_status, :to_status, :changed_at
    if log.changed_by
      json.changed_by do
        json.extract! log.changed_by, :id, :name, :email
      end
    end
  end
  
  # Include assignment history
  json.assignment_history @order.assignment_histories.recent do |history|
    json.extract! history, :id, :assigned_at, :status, :notes
    json.assigned_to do
      json.extract! history.assigned_to, :id, :name, :email
    end
    if history.assigned_by
      json.assigned_by do
        json.extract! history.assigned_by, :id, :name, :email
      end
    end
  end
end
