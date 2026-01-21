# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rails db:seed command (or created alongside the database with db:setup).

# Clear existing users
puts "Clearing existing users..."
User.destroy_all

agent2 = User.create!(
  name: 'Jane Agent',
  email: 'agent2@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :agent
)
puts "✓ Agent created: #{agent2.email}"

# Create Sales Executive Users
puts "\nCreating Sales Executive users..."
sales_exec1 = User.create!(
  name: 'Mike Sales',
  email: 'sales1@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :sales_executive
)
puts "✓ Sales Executive created: #{sales_exec1.email}"

sales_exec2 = User.create!(
  name: 'Sarah Sales',
  email: 'sales2@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :sales_executive
)
puts "✓ Sales Executive created: #{sales_exec2.email}"

# Create Accountant Users
puts "\nCreating Accountant users..."
accountant1 = User.create!(
  name: 'David Accountant',
  email: 'accountant1@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :accountant
)
puts "✓ Accountant created: #{accountant1.email}"

accountant2 = User.create!(
  name: 'Emma Accountant',
  email: 'accountant2@spado.com',
  password: 'password123',
  password_confirmation: 'password123',
  role: :accountant
)
puts "✓ Accountant created: #{accountant2.email}"

puts "\n" + "="*50
puts "Seed completed successfully!"
puts "="*50
puts "\nCreated users:"
puts "Admin: admin@spado.com (password: password123)"
puts "Agents: agent1@spado.com, agent2@spado.com (password: password123)"
puts "Sales Executives: sales1@spado.com, sales2@spado.com (password: password123)"
puts "Accountants: accountant1@spado.com, accountant2@spado.com (password: password123)"
puts "="*50
