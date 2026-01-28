# Order Management System - Implementation Summary

## Overview
Successfully implemented a comprehensive car wash order booking system with polymorphic associations, AASM state machine, service layer pattern, booking conflict detection with buffer time, configurable GST, and race-condition-safe order numbering.

## What Was Built

### 1. Core Models

#### Settings Model
- Key-value configuration storage
- Cached settings for performance (1-hour expiry)
- Default values:
  - `gst_percentage`: 18.0%
  - `booking_buffer_minutes`: 30 minutes
- Helper methods: `Setting.gst_percentage`, `Setting.booking_buffer_minutes`

#### Package Model
- Fields: name, description, base_price, vehicle_type (enum), active status
- Vehicle types: hatchback, sedan, suv, luxury
- Soft delete with acts_as_paranoid
- Associations: has_many order_packages

#### Addon Model
- Fields: name, description, price, active status
- Soft delete with acts_as_paranoid
- Associations: has_many order_addons

#### Order Model (Main)
- **Order Number**: Format SPYYMMDDNN (e.g., SP26012401)
  - SP prefix + 2-digit year + 2-digit month + 2-digit day + 2-digit sequence
  - Race-condition safe with database locking and 3-attempt retry
  - Unique constraint on order_number

- **Associations**:
  - Polymorphic `bookable` (User who created: sales_executive/admin/customer)
  - belongs_to customer
  - belongs_to assigned_to (agent User)
  - belongs_to cancelled_by (User)
  - has_many order_packages, order_addons
  - has_many order_status_logs, assignment_histories

- **Address Fields** (copied from customer):
  - contact_phone, address_line1 (required), address_line2
  - area (required), city, state
  - latitude, longitude, map_link

- **Booking Fields**:
  - booking_date, booking_time_from, booking_time_to
  - actual_start_time, actual_end_time

- **Financial Fields**:
  - total_amount, gst_amount, gst_percentage (copied from Settings)
  - payment_status enum: pending, paid, failed
  - payment_method enum: cod, upi

- **Status Management (AASM)**:
  - States: draft, tentative, booked, in_progress, completed, cancelled
  - Role-based transitions with guards
  - Auto-logging of status changes

- **Validations**:
  - Booking time conflicts with buffer time
  - booking_time_from < booking_time_to
  - No past booking dates
  - Cancel reason required when cancelling
  - Feedback only on completed orders
  - Rating 1-5 stars

#### OrderPackage & OrderAddon (Join Tables)
- Quantity, price, discount, total_price
- OrderPackage includes vehicle_type
- Auto-calculation of total_price via callback
- Values rounded to 2 decimals

#### OrderStatusLog (Audit Trail)
- Tracks all status transitions
- from_status, to_status, changed_by, changed_at
- Auto-created via AASM after_transition callback

#### AssignmentHistory (Agent Tracking)
- assigned_to, assigned_by, assigned_at, status, notes
- Auto-populated when assigned_to changes
- Auto-notes when booking_date changes

### 2. Service Layer (app/services/orders/)

#### CalculationService
- Calculates subtotal from order_packages + order_addons
- Applies GST based on order.gst_percentage
- Rounds all amounts to 2 decimals
- Updates order.gst_amount and order.total_amount

#### CreationService
- Handles order creation with 3-attempt retry for race conditions
- Copies address from customer (with override support)
- Creates order_packages and order_addons
- Auto-calculates totals
- Transaction-wrapped for atomic creation

#### StatusUpdateService
- Validates role permissions for transitions
- Requires cancel_reason for cancellations
- Sets actual_start_time and actual_end_time
- Wraps AASM transitions in transactions
- Rolls back on failure

#### AssignmentService
- Validates agent exists and has agent role
- Checks for booking conflicts with buffer time
- Creates assignment history
- Transaction-wrapped for atomic assignment

### 3. API Controllers

#### OrdersController (api/v1/orders)
**Endpoints**:
- `GET /api/v1/orders` - List orders with filters (status, assigned_to, customer, date range)
- `GET /api/v1/orders/:id` - Show order with full details
- `POST /api/v1/orders` - Create order (calls CreationService)
- `PATCH /api/v1/orders/:id` - Update order (role-based params)
- `DELETE /api/v1/orders/:id` - Soft delete order
- `POST /api/v1/orders/:id/assign` - Assign to agent
- `POST /api/v1/orders/:id/update_status` - Change status
- `POST /api/v1/orders/:id/cancel` - Cancel order (requires reason)
- `POST /api/v1/orders/:id/add_feedback` - Add customer feedback
- `GET /api/v1/orders/calendar` - Calendar view (date range filter)

**Features**:
- Pagination with Kaminari (25 per page)
- Eager loading with .with_associations
- Role-based strong params
- Service object integration

#### PackagesController (api/v1/packages)
- Full CRUD operations
- Active filter
- Vehicle type filter
- Pagination

#### AddonsController (api/v1/addons)
- Full CRUD operations
- Active filter
- Pagination

### 4. Authorization (CanCanCan)

**Admin**:
- Manage everything

**Sales Executive**:
- Manage all orders, packages, addons, customers
- Add feedback to orders
- Change order status (all transitions)

**Agent**:
- Read assigned orders only
- Update status (in_progress, completed)
- Update actual times and notes
- Read packages and addons

**Accountant**:
- Read-only access to orders, packages, addons, customers

### 5. Jbuilder Views

#### Orders
- `_order.json.jbuilder` - Partial with all fields + computed values
- `index.json.jbuilder` - List with pagination
- `show.json.jbuilder` - Full details with nested:
  - packages (with package details)
  - addons (with addon details)
  - status_logs
  - assignment_history

#### Packages & Addons
- Standard CRUD views with pagination

### 6. Database Schema

**Key Indexes for Performance**:
- orders(order_number) - unique
- orders(assigned_to_id, booking_date, status) - compound for calendar queries
- orders(bookable_type, bookable_id) - polymorphic
- orders(status, booking_date, created_at) - individual
- order_packages(order_id, package_id)
- order_addons(order_id, addon_id)
- order_status_logs(order_id, changed_at)
- assignment_histories(order_id, assigned_at)

### 7. Key Features Implemented

✅ **Order Number Generation**: SPYYMMDDNN format with race-condition handling
✅ **AASM State Machine**: Role-based transitions with guards
✅ **Booking Conflict Detection**: Checks agent availability with buffer time
✅ **Polymorphic Bookable**: Supports User (sales_executive) or Customer booking
✅ **Address Copying**: Separate order address from customer
✅ **GST Calculation**: Configurable via Settings, copied to order
✅ **Audit Trails**: Status logs and assignment history
✅ **Service Layer**: Clean separation of business logic
✅ **Transaction Safety**: Rollback on failures
✅ **Comprehensive Validations**: Booking times, ratings, cancel reasons
✅ **Authorization**: Role-based permissions with CanCanCan
✅ **Performance Indexes**: Optimized for common queries

## Database Migrations Created

1. `20260124000001_create_settings.rb` - Settings table with seed data
2. `20260124000002_add_address_line1_to_customers.rb` - Customer address fields
3. `20260124000003_create_packages.rb` - Packages table
4. `20260124000004_create_addons.rb` - Addons table
5. `20260124000005_create_orders.rb` - Orders table with all indexes
6. `20260124000006_create_order_packages.rb` - Join table with pricing
7. `20260124000007_create_order_addons.rb` - Join table with pricing
8. `20260124000008_create_order_status_logs.rb` - Audit log
9. `20260124000009_create_assignment_histories.rb` - Assignment tracking

## API Usage Examples

### Create Order
```bash
POST /api/v1/orders
{
  "order": {
    "customer_id": 1,
    "booking_date": "2026-01-25",
    "booking_time_from": "10:00",
    "booking_time_to": "12:00",
    "assigned_to_id": 5,
    "payment_method": "cod",
    "notes": "Customer prefers morning slot",
    "packages": [
      {
        "package_id": 1,
        "quantity": 1,
        "price": 500,
        "vehicle_type": "sedan",
        "discount": 50
      }
    ],
    "addons": [
      {
        "addon_id": 2,
        "quantity": 1,
        "price": 100,
        "discount": 0
      }
    ]
  }
}
```

### Assign Order to Agent
```bash
POST /api/v1/orders/1/assign
{
  "agent_id": 5,
  "notes": "Assigned to nearest available agent"
}
```

### Update Order Status
```bash
POST /api/v1/orders/1/update_status
{
  "status": "in_progress",
  "actual_start_time": "2026-01-25T10:05:00Z"
}
```

### Cancel Order
```bash
POST /api/v1/orders/1/cancel
{
  "cancel_reason": "Customer requested cancellation"
}
```

### Add Feedback
```bash
POST /api/v1/orders/1/add_feedback
{
  "order": {
    "rating": 5,
    "comments": "Excellent service, very satisfied!"
  }
}
```

### Get Calendar View
```bash
GET /api/v1/orders/calendar?start_date=2026-01-25&end_date=2026-01-31&assigned_to_id=5
```

## Configuration

### Settings Management
```ruby
# Get setting
Setting.gst_percentage          # => 18.0
Setting.booking_buffer_minutes  # => 30

# Update setting
Setting.set('gst_percentage', '20.0', value_type: 'decimal')
```

### AASM State Transitions

```ruby
order = Order.find(1)

# Check if transition is allowed
order.may_mark_tentative?  # => true/false

# Perform transition
order.mark_tentative!      # draft -> tentative
order.confirm_booking!     # tentative -> booked
order.start_service!       # booked -> in_progress
order.complete_service!    # in_progress -> completed
order.cancel_order!        # any -> cancelled
```

## Notes

1. **Spring Compatibility**: Spring has compatibility issues with Rails 8. Use `DISABLE_SPRING=1` when running rails commands or remove Spring from Gemfile.

2. **Current User**: The Order model uses `Current.user` for tracking who makes changes. This is set in the Authenticable concern during authentication.

3. **Race Condition Handling**: Order number generation retries up to 3 times if uniqueness constraint fails. If all attempts fail, user gets an error asking to retry.

4. **Booking Buffer Time**: Applied after booking_time_to to prevent double-booking agents. Configurable via Settings.

5. **GST Copy**: GST percentage is copied from Settings to order at creation time for historical accuracy if tax rates change.

6. **Feedback Timing**: Feedback can only be added to completed orders by sales executives (who call customers post-service).

7. **Notes Field**: Can be updated anytime by authorized users without audit trail.

8. **Soft Delete**: All main models use acts_as_paranoid for soft deletion.

## Testing Recommendations

1. Test order creation with concurrent requests (race condition)
2. Test booking conflict detection with overlapping times
3. Test AASM transitions with different user roles
4. Test GST calculation with various package/addon combinations
5. Test order number sequence across date boundaries
6. Test feedback submission restrictions
7. Test cancel reason validation

## Future Enhancements

1. Real-time scheduling system with conflict detection
2. Payment gateway integration (Razorpay, Stripe)
3. WhatsApp notifications for status changes
4. Customer self-booking portal
5. Agent mobile app for order updates
6. Advanced calendar with drag-drop rescheduling
7. Reporting and analytics dashboard
8. Automated assignment based on proximity/availability
