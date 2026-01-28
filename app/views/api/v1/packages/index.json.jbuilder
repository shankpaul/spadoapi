json.packages do
  json.array! @packages do |package|
    json.partial! 'package', package: package
  end
end

json.pagination do
  json.current_page @packages.current_page
  json.next_page @packages.next_page
  json.prev_page @packages.prev_page
  json.total_pages @packages.total_pages
  json.total_count @packages.total_count
  json.per_page @packages.limit_value
end
