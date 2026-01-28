json.addons do
  json.array! @addons do |addon|
    json.partial! 'addon', addon: addon
  end
end

json.pagination do
  json.current_page @addons.current_page
  json.next_page @addons.next_page
  json.prev_page @addons.prev_page
  json.total_pages @addons.total_pages
  json.total_count @addons.total_count
  json.per_page @addons.limit_value
end
