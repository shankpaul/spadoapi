json.extract! package, :id, :name, :description, :unit_price, :vehicle_type, :active, :features, :duration_minutes, :created_at, :updated_at
json.display_name package.display_name

# Subscription fields
json.subscription_enabled package.subscription_enabled
if package.subscription_enabled?
  json.subscription_price package.subscription_price
  json.max_washes_per_month package.max_washes_per_month
  json.min_subscription_months package.min_subscription_months
end
