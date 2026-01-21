json.extract! user, :id, :name, :email, :last_activity_at, :created_at, :updated_at
json.role user.role
json.locked user.locked?
json.expired user.expired?
json.sign_in_count user.sign_in_count
json.current_sign_in_at user.current_sign_in_at
json.last_sign_in_at user.last_sign_in_at
