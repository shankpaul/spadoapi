json.orders do
  json.array! @orders do |order|
    json.partial! 'api/v1/orders/order_basic', order: order
    
    # Include package and addon counts in list view
    json.packages_count order.order_packages.size
    json.addons_count order.order_addons.size
  end
end

json.pagination do
  json.current_page @orders.current_page
  json.next_page @orders.next_page
  json.prev_page @orders.prev_page
  json.total_pages @orders.total_pages
  json.total_count @orders.total_count
  json.per_page @orders.limit_value
end
