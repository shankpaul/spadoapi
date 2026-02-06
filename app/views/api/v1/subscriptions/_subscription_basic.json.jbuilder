
  json.id subscription.id
  json.status subscription.status
  json.start_date subscription.start_date
  json.end_date subscription.end_date
  json.months_duration subscription.months_duration
  
  json.customer do
    json.name subscription.customer.name
    json.phone subscription.customer.phone
  end
  
  json.vehicle_type subscription.vehicle_type
  json.washing_schedules subscription.washing_schedules
  json.map_url subscription.map_url
  json.area subscription.area
  
  json.subscription_amount subscription.subscription_amount
  json.payment_amount subscription.payment_amount
  json.payment_date subscription.payment_date
  json.payment_status subscription.payment_status
  json.payment_method subscription.payment_method
  json.balance_due subscription.subscription_amount - subscription.payment_amount
  
  json.selected_packages do
    json.array! subscription.subscription_packages do |sub_pkg|
     json.name sub_pkg.package.name
    end
  end
  json.notes subscription.notes
  
  json.created_by do
    json.id subscription.created_by.id
    json.name subscription.created_by.name
    json.email subscription.created_by.email
  end
  
  json.created_at subscription.created_at
  json.updated_at subscription.updated_at
