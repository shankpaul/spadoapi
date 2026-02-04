# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

# Clear existing users
puts "Clearing existing users..."
# User.destroy_all

agent2 = User.create!(
  name: 'Jane Agent',
  email: 'agent2x@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :agent
)
puts "✓ Agent created: #{agent2.email}"

# Create Sales Executive Users
puts "\nCreating Sales Executive users..."
sales_exec1 = User.create!(
  name: 'Mike Sales',
  email: 'sales1x@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :sales_executive
)
puts "✓ Sales Executive created: #{sales_exec1.email}"

sales_exec2 = User.create!(
  name: 'Sarah Sales',
  email: 'sales2x@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :sales_executive
)
puts "✓ Sales Executive created: #{sales_exec2.email}"

# Create Accountant Users
puts "\nCreating Accountant users..."
accountant1 = User.create!(
  name: 'David Accountant',
  email: 'accountant1x@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :accountant
)
puts "✓ Accountant created: #{accountant1.email}"

accountant2 = User.create!(
  name: 'Emma Accountant',
  email: 'accountant2x@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :accountant
)
puts "✓ Accountant created: #{accountant2.email}"

# Create Subscription-Enabled Packages
puts "\nCreating subscription packages..."

# Hatchback - 3 Washes per Month
Package.create!([
  {
    name: 'Hatchback Basic - 3 Washes/Month',
    description: 'Basic monthly subscription for hatchback - 3 washes',
    unit_price: 300,
    vehicle_type: :hatchback,
    duration_minutes: 45,
    features: ['Exterior wash', 'Tire cleaning', 'Basic interior vacuum'],
    subscription_enabled: true,
    subscription_price: 800,
    max_washes_per_month: 3,
    min_subscription_months: 1
  },
  # Hatchback - 6 Washes per Month
  {
    name: 'Hatchback Standard - 6 Washes/Month',
    description: 'Standard monthly subscription for hatchback - 6 washes',
    unit_price: 300,
    vehicle_type: :hatchback,
    duration_minutes: 45,
    features: ['Exterior wash', 'Tire cleaning', 'Interior vacuum', 'Dashboard cleaning'],
    subscription_enabled: true,
    subscription_price: 1500,
    max_washes_per_month: 6,
    min_subscription_months: 1
  },
  # Hatchback - 10 Washes per Month
  {
    name: 'Hatchback Premium - 10 Washes/Month',
    description: 'Premium monthly subscription for hatchback - 10 washes',
    unit_price: 300,
    vehicle_type: :hatchback,
    duration_minutes: 45,
    features: ['Exterior wash', 'Tire cleaning', 'Full interior cleaning', 'Dashboard polish', 'Air freshener'],
    subscription_enabled: true,
    subscription_price: 2300,
    max_washes_per_month: 10,
    min_subscription_months: 1
  },
  # Sedan - 3 Washes per Month
  {
    name: 'Sedan Basic - 3 Washes/Month',
    description: 'Basic monthly subscription for sedan - 3 washes',
    unit_price: 400,
    vehicle_type: :sedan,
    duration_minutes: 60,
    features: ['Exterior wash', 'Tire cleaning', 'Basic interior vacuum'],
    subscription_enabled: true,
    subscription_price: 1000,
    max_washes_per_month: 3,
    min_subscription_months: 1
  },
  # Sedan - 6 Washes per Month
  {
    name: 'Sedan Standard - 6 Washes/Month',
    description: 'Standard monthly subscription for sedan - 6 washes',
    unit_price: 400,
    vehicle_type: :sedan,
    duration_minutes: 60,
    features: ['Exterior wash', 'Tire cleaning', 'Interior vacuum', 'Dashboard cleaning', 'Window cleaning'],
    subscription_enabled: true,
    subscription_price: 1900,
    max_washes_per_month: 6,
    min_subscription_months: 1
  },
  # Sedan - 10 Washes per Month
  {
    name: 'Sedan Premium - 10 Washes/Month',
    description: 'Premium monthly subscription for sedan - 10 washes',
    unit_price: 400,
    vehicle_type: :sedan,
    duration_minutes: 60,
    features: ['Exterior wash', 'Tire cleaning', 'Full interior cleaning', 'Dashboard polish', 'Window cleaning', 'Air freshener'],
    subscription_enabled: true,
    subscription_price: 3000,
    max_washes_per_month: 10,
    min_subscription_months: 1
  },
  # SUV - 3 Washes per Month
  {
    name: 'SUV Basic - 3 Washes/Month',
    description: 'Basic monthly subscription for SUV - 3 washes',
    unit_price: 600,
    vehicle_type: :suv,
    duration_minutes: 75,
    features: ['Exterior wash', 'Tire cleaning', 'Basic interior vacuum'],
    subscription_enabled: true,
    subscription_price: 1500,
    max_washes_per_month: 3,
    min_subscription_months: 1
  },
  # SUV - 6 Washes per Month
  {
    name: 'SUV Standard - 6 Washes/Month',
    description: 'Standard monthly subscription for SUV - 6 washes',
    unit_price: 600,
    vehicle_type: :suv,
    duration_minutes: 75,
    features: ['Exterior wash', 'Tire cleaning', 'Interior vacuum', 'Dashboard cleaning', 'Window cleaning'],
    subscription_enabled: true,
    subscription_price: 2800,
    max_washes_per_month: 6,
    min_subscription_months: 1
  },
  # SUV - 10 Washes per Month
  {
    name: 'SUV Premium - 10 Washes/Month',
    description: 'Premium monthly subscription for SUV - 10 washes',
    unit_price: 600,
    vehicle_type: :suv,
    duration_minutes: 75,
    features: ['Exterior wash', 'Tire cleaning', 'Full interior cleaning', 'Dashboard polish', 'Window cleaning', 'Air freshener', 'Engine bay cleaning'],
    subscription_enabled: true,
    subscription_price: 4500,
    max_washes_per_month: 10,
    min_subscription_months: 1
  }
])

puts "✓ Created 9 subscription packages (3 vehicle types × 3 wash tiers)"
puts "  - Hatchback: ₹800 (3), ₹1500 (6), ₹2300 (10)"
puts "  - Sedan: ₹1000 (3), ₹1900 (6), ₹3000 (10)"
puts "  - SUV: ₹1500 (3), ₹2800 (6), ₹4500 (10)"

puts "\n" + "="*50
puts "Seed completed successfully!"
puts "="*50
puts "\nCreated users:"
puts "Admin: admin@spado.com (password: password123)"
puts "Agents: agent1@spado.com, agent2@spado.com (password: password123)"
puts "Sales Executives: sales1@spado.com, sales2@spado.com (password: password123)"
puts "Accountants: accountant1@spado.com, accountant2@spado.com (password: password123)"
puts "\nCreated subscription packages:"
puts "9 packages covering Hatchback, Sedan, SUV with 3, 6, and 10 washes per month"
puts "="*50
