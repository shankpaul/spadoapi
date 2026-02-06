# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_02_05_000001) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "addons", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "price", precision: 10, scale: 2, default: "0.0", null: false
    t.boolean "active", default: true
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["active"], name: "index_addons_on_active"
    t.index ["deleted_at"], name: "index_addons_on_deleted_at"
  end

  create_table "assignment_histories", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "assigned_to_id", null: false
    t.bigint "assigned_by_id"
    t.datetime "assigned_at", null: false
    t.string "status"
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["assigned_by_id"], name: "index_assignment_histories_on_assigned_by_id"
    t.index ["assigned_to_id"], name: "index_assignment_histories_on_assigned_to_id"
    t.index ["order_id", "assigned_at"], name: "index_assignment_histories_on_order_id_and_assigned_at"
    t.index ["order_id"], name: "index_assignment_histories_on_order_id"
  end

  create_table "customers", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone"
    t.string "email"
    t.boolean "has_whatsapp", default: false
    t.datetime "last_booked_at"
    t.string "area"
    t.string "city"
    t.string "district"
    t.string "state"
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.string "map_link"
    t.datetime "last_whatsapp_message_sent_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.string "address_line1"
    t.string "address_line2"
    t.index ["city"], name: "index_customers_on_city"
    t.index ["deleted_at"], name: "index_customers_on_deleted_at"
    t.index ["email"], name: "index_customers_on_email"
    t.index ["phone"], name: "index_customers_on_phone"
  end

  create_table "jwt_denylist", force: :cascade do |t|
    t.string "jti", null: false
    t.datetime "exp", null: false
    t.index ["jti"], name: "index_jwt_denylist_on_jti"
  end

  create_table "order_addons", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "addon_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.decimal "discount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "discount_type"
    t.index ["addon_id"], name: "index_order_addons_on_addon_id"
    t.index ["order_id", "addon_id"], name: "index_order_addons_on_order_id_and_addon_id"
    t.index ["order_id"], name: "index_order_addons_on_order_id"
  end

  create_table "order_packages", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "package_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.integer "vehicle_type", null: false
    t.decimal "discount", precision: 10, scale: 2, default: "0.0"
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "discount_type"
    t.index ["order_id", "package_id"], name: "index_order_packages_on_order_id_and_package_id"
    t.index ["order_id"], name: "index_order_packages_on_order_id"
    t.index ["package_id"], name: "index_order_packages_on_package_id"
  end

  create_table "order_status_logs", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.string "from_status", null: false
    t.string "to_status", null: false
    t.bigint "changed_by_id"
    t.datetime "changed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["changed_by_id"], name: "index_order_status_logs_on_changed_by_id"
    t.index ["order_id", "changed_at"], name: "index_order_status_logs_on_order_id_and_changed_at"
    t.index ["order_id"], name: "index_order_status_logs_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "order_number", null: false
    t.bigint "customer_id", null: false
    t.string "bookable_type", null: false
    t.bigint "bookable_id", null: false
    t.string "contact_phone"
    t.string "address_line1"
    t.string "address_line2"
    t.string "area"
    t.string "city"
    t.string "state"
    t.decimal "latitude", precision: 10, scale: 8
    t.decimal "longitude", precision: 11, scale: 8
    t.string "map_link"
    t.date "booking_date"
    t.datetime "booking_time_from"
    t.datetime "booking_time_to"
    t.datetime "actual_start_time"
    t.datetime "actual_end_time"
    t.bigint "assigned_to_id"
    t.decimal "total_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "gst_amount", precision: 10, scale: 2, default: "0.0"
    t.decimal "gst_percentage", precision: 5, scale: 2, default: "18.0"
    t.string "status", default: "draft", null: false
    t.string "payment_status", default: "pending"
    t.string "payment_method", default: "cod"
    t.text "notes"
    t.bigint "cancelled_by_id"
    t.datetime "cancelled_at"
    t.text "cancel_reason"
    t.integer "rating"
    t.text "comments"
    t.datetime "feedback_submitted_at"
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "subscription_id"
    t.index ["assigned_to_id", "booking_date", "status"], name: "index_orders_on_agent_calendar"
    t.index ["assigned_to_id"], name: "index_orders_on_assigned_to_id"
    t.index ["bookable_type", "bookable_id"], name: "index_orders_on_bookable"
    t.index ["booking_date"], name: "index_orders_on_booking_date"
    t.index ["cancelled_by_id"], name: "index_orders_on_cancelled_by_id"
    t.index ["created_at"], name: "index_orders_on_created_at"
    t.index ["customer_id"], name: "index_orders_on_customer_id"
    t.index ["deleted_at"], name: "index_orders_on_deleted_at"
    t.index ["order_number"], name: "index_orders_on_order_number", unique: true
    t.index ["status"], name: "index_orders_on_status"
    t.index ["subscription_id"], name: "index_orders_on_subscription_id"
  end

  create_table "packages", force: :cascade do |t|
    t.string "name", null: false
    t.text "description"
    t.decimal "unit_price", precision: 10, scale: 2, default: "0.0", null: false
    t.integer "vehicle_type", default: 0
    t.boolean "active", default: true
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "features", default: [], array: true
    t.integer "duration_minutes", comment: "Estimated time to complete the service in minutes"
    t.boolean "subscription_enabled", default: false, null: false
    t.decimal "subscription_price", precision: 10, scale: 2
    t.integer "max_washes_per_month"
    t.integer "min_subscription_months", default: 1
    t.index ["active"], name: "index_packages_on_active"
    t.index ["deleted_at"], name: "index_packages_on_deleted_at"
    t.index ["vehicle_type"], name: "index_packages_on_vehicle_type"
  end

  create_table "settings", force: :cascade do |t|
    t.string "key", null: false
    t.text "value"
    t.string "value_type", default: "string"
    t.text "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["key"], name: "index_settings_on_key", unique: true
  end

  create_table "subscription_addons", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.bigint "addon_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "discount", precision: 10, scale: 2
    t.string "discount_type"
    t.decimal "discount_value", precision: 10, scale: 2
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.text "applicable_wash_numbers", default: "[]", comment: "JSON array of integers representing the specific wash numbers where this addon should be applied. \n          Example: [1, 2, 3, 12] means addon applies to 1st, 2nd, 3rd, and 12th wash.\n          Empty array means addon is not applied to any wash."
    t.index ["addon_id"], name: "index_subscription_addons_on_addon_id"
    t.index ["subscription_id", "addon_id"], name: "index_subscription_addons_on_subscription_id_and_addon_id"
    t.index ["subscription_id"], name: "index_subscription_addons_on_subscription_id"
  end

  create_table "subscription_orders", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.bigint "order_id"
    t.date "scheduled_date", null: false
    t.datetime "generated_at"
    t.string "status", default: "pending_generation"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.time "time_from"
    t.time "time_to"
    t.index ["order_id"], name: "index_subscription_orders_on_order_id"
    t.index ["status"], name: "index_subscription_orders_on_status"
    t.index ["subscription_id", "scheduled_date"], name: "idx_on_subscription_id_scheduled_date_bdda95b267", unique: true
    t.index ["subscription_id"], name: "index_subscription_orders_on_subscription_id"
  end

  create_table "subscription_packages", force: :cascade do |t|
    t.bigint "subscription_id", null: false
    t.bigint "package_id", null: false
    t.integer "quantity", default: 1, null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.string "vehicle_type", null: false
    t.decimal "discount", precision: 10, scale: 2
    t.string "discount_type"
    t.decimal "discount_value", precision: 10, scale: 2
    t.decimal "total_price", precision: 10, scale: 2, null: false
    t.text "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["package_id"], name: "index_subscription_packages_on_package_id"
    t.index ["subscription_id", "package_id"], name: "index_subscription_packages_on_subscription_id_and_package_id"
    t.index ["subscription_id"], name: "index_subscription_packages_on_subscription_id"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.bigint "customer_id", null: false
    t.string "vehicle_type", null: false
    t.string "status", default: "active", null: false
    t.date "start_date", null: false
    t.date "end_date", null: false
    t.integer "months_duration", null: false
    t.decimal "subscription_amount", precision: 10, scale: 2, null: false
    t.decimal "payment_amount", precision: 10, scale: 2, default: "0.0"
    t.date "payment_date"
    t.string "payment_status", default: "pending"
    t.string "payment_method"
    t.text "notes"
    t.bigint "created_by_id", null: false
    t.datetime "deleted_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.jsonb "washing_schedules", default: []
    t.string "map_url"
    t.string "area"
    t.integer "number_of_orders", default: 0, null: false
    t.integer "completed_no_orders", default: 0, null: false
    t.index ["created_by_id"], name: "index_subscriptions_on_created_by_id"
    t.index ["customer_id"], name: "index_subscriptions_on_customer_id"
    t.index ["deleted_at"], name: "index_subscriptions_on_deleted_at"
    t.index ["status"], name: "index_subscriptions_on_status"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer "sign_in_count", default: 0, null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string "current_sign_in_ip"
    t.string "last_sign_in_ip"
    t.integer "failed_attempts", default: 0, null: false
    t.string "unlock_token"
    t.datetime "locked_at"
    t.datetime "last_activity_at"
    t.string "name", null: false
    t.integer "role", default: 0, null: false
    t.datetime "expires_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.datetime "deleted_at"
    t.index ["deleted_at"], name: "index_users_on_deleted_at"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
    t.index ["unlock_token"], name: "index_users_on_unlock_token", unique: true
  end

  add_foreign_key "assignment_histories", "orders"
  add_foreign_key "assignment_histories", "users", column: "assigned_by_id"
  add_foreign_key "assignment_histories", "users", column: "assigned_to_id"
  add_foreign_key "order_addons", "addons"
  add_foreign_key "order_addons", "orders"
  add_foreign_key "order_packages", "orders"
  add_foreign_key "order_packages", "packages"
  add_foreign_key "order_status_logs", "orders"
  add_foreign_key "order_status_logs", "users", column: "changed_by_id"
  add_foreign_key "orders", "customers"
  add_foreign_key "orders", "subscriptions"
  add_foreign_key "orders", "users", column: "assigned_to_id"
  add_foreign_key "orders", "users", column: "cancelled_by_id"
  add_foreign_key "subscription_addons", "addons"
  add_foreign_key "subscription_addons", "subscriptions"
  add_foreign_key "subscription_orders", "orders"
  add_foreign_key "subscription_orders", "subscriptions"
  add_foreign_key "subscription_packages", "packages"
  add_foreign_key "subscription_packages", "subscriptions"
  add_foreign_key "subscriptions", "customers"
  add_foreign_key "subscriptions", "users", column: "created_by_id"
end
