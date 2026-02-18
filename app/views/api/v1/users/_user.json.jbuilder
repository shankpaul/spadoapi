json.extract! user, :id, :name, :email, :last_activity_at, :created_at, :updated_at
json.role user.role
json.locked user.locked?
json.expired user.expired?
json.sign_in_count user.sign_in_count
json.current_sign_in_at user.current_sign_in_at
json.last_sign_in_at user.last_sign_in_at
json.phone user.phone
json.address user.address
json.employee_number user.employee_number
json.home_latitude user.home_latitude
json.home_longitude user.home_longitude
json.home_coordinates user.home_coordinates
json.office_id user.office_id
if user.avatar.attached?
  json.avatar_url rails_blob_url(user.avatar)
else
  json.avatar_url nil
end
if user.office
  json.office do
    json.id user.office.id
    json.name user.office.name
    json.latitude user.office.latitude
    json.longitude user.office.longitude
    json.active user.office.active
  end
end
