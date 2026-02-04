json.subscriptions do
  json.array! @subscriptions do |subscription|
    json.partial! 'subscription_basic', subscription: subscription
  end
end

json.meta do
  json.current_page @subscriptions.current_page
  json.total_pages @subscriptions.total_pages
  json.total_count @subscriptions.total_count
  json.per_page @subscriptions.limit_value
end

json.message @message if @message.present?
