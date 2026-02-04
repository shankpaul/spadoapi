# Monthly Subscription Feature - Implementation Guide

## Overview

The monthly subscription feature allows customers to subscribe to car wash packages for a specified duration with pre-selected washing dates and preferred time slots. Orders are automatically generated 7 days before each washing date using the customer's preferred time.

## Key Features

✅ **Time Slot Selection**: Each washing schedule includes date, time_from, and time_to in 24-hour format  
✅ **Flexible Scheduling**: Customers choose preferred time slots for each wash  
✅ **Auto-Generated Orders**: System creates orders with exact time slots 7 days in advance  
✅ **Payment Flexibility**: Upfront, partial, or post-first-wash payment tracking  
✅ **Subscription Management**: Pause, resume, cancel subscriptions  
✅ **Smart Validations**: Date/time validation, capacity limits, no duplicates  
✅ **AASM State Machine**: Automated status transitions (scheduled → active → completed/expired/cancelled)  
✅ **Order Tracking**: Tracks completed orders and auto-completes subscription when all orders are done

## Database Schema

### New Tables

1. **subscriptions**
   - Stores subscription information with customer, package, payment details, and washing schedules
   - Status: active, paused, cancelled, expired
   - Payment tracking: subscription_amount, payment_amount, payment_date, payment_status
   - Location: area, map_url (for service location)
   - **washing_schedules** (JSONB): Array of schedules, each with:
     - `date`: Washing date (YYYY-MM-DD)
     - `time_from`: Start time in 24-hour format (HH:MM)
     - `time_to`: End time in 24-hour format (HH:MM)

2. **subscription_orders**
   - Join table linking subscriptions to generated orders
   - Tracks which washing schedules have generated orders
   - Status: pending_generation, generated, cancelled
   - Fields: scheduled_date, time_from, time_to, generated_at

3. **Package Enhancements**
   - `subscription_enabled`: Boolean to mark packages available for subscription
   - `subscription_price`: Monthly subscription price
   - `max_washes_per_month`: Maximum washes allowed per month
   - `min_subscription_months`: Minimum subscription duration

4. **Order Enhancement**
   - `subscription_id`: Optional reference to link subscription-generated orders

## API Endpoints

### Packages

**Enable subscription on a package (Sales Executive/Admin)**
```bash
POST /api/v1/packages
{
  "package": {
    "name": "Premium Wash",
    "unit_price": 500,
    "vehicle_type": "sedan",
    "subscription_enabled": true,
    "subscription_price": 2000,
    "max_washes_per_month": 4,
    "min_subscription_months": 1,
    "duration_minutes": 60,
    "features": ["Exterior wash", "Interior cleaning"]
  }
}
```

**Filter subscription packages**
```bash
GET /api/v1/packages?subscription_enabled=true
```

### Subscriptions

**Create subscription**
```bash
POST /api/v1/subscriptions
{
  "customer_id": 1,
  "vehicle_type": "sedan",
  "start_date": "2026-02-01",
  "months_duration": 3,
  "area": "Koramangala",
  "map_url": "https://maps.google.com/?q=12.9352,77.6245",
  "packages": [
    {
      "package_id": 2,
      "quantity": 1,
      "unit_price": 500,
      "price": 500,
      "vehicle_type": "sedan",
      "discount": 10,
      "discount_type": "percentage",
      "discount_value": 50,
      "notes": "Premium wash package"
    }
  ],
  "addons": [
    {
      "addon_id": 1,
      "quantity": 1,
      "unit_price": 100,
      "price": 100,
      "discount": 0,
      "discount_type": null,
      "discount_value": 0
    }
  ],
  "washing_schedules": [
    {"date": "2026-02-05", "time_from": "10:00", "time_to": "11:00"},
    {"date": "2026-02-12", "time_from": "14:00", "time_to": "15:00"},
    {"date": "2026-02-19", "time_from": "10:00", "time_to": "11:00"},
    {"date": "2026-02-26", "time_from": "09:00", "time_to": "10:00"},
    {"date": "2026-03-05", "time_from": "10:00", "time_to": "11:00"},
    {"date": "2026-03-12", "time_from": "14:00", "time_to": "15:00"},
    {"date": "2026-03-19", "time_from": "10:00", "time_to": "11:00"},
    {"date": "2026-03-26", "time_from": "09:00", "time_to": "10:00"},
    {"date": "2026-04-05", "time_from": "10:00", "time_to": "11:00"},
    {"date": "2026-04-12", "time_from": "14:00", "time_to": "15:00"},
    {"date": "2026-04-19", "time_from": "10:00", "time_to": "11:00"},
    {"date": "2026-04-26", "time_from": "09:00", "time_to": "10:00"}
  ],
  "payment_amount": 2000,
  "payment_date": "2026-02-01",
  "payment_method": "upi",
  "notes": "Customer prefers morning slots"
}
```

**Note:** 
- Times are in 24-hour format (HH:MM). The system will use these exact time slots when generating orders.
- Packages array is required with at least one package
- Addons array is optional
- Each package/addon supports quantity and discount (percentage or fixed)

**cURL Example:**
```bash
curl -X POST http://localhost:3000/api/v1/subscriptions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "customer_id": 1,
    "vehicle_type": "sedan",
    "start_date": "2026-02-01",
    "months_duration": 1,
    "area": "Koramangala",
    "map_url": "https://maps.google.com/?q=12.9352,77.6245",
    "packages": [
      {
        "package_id": 2,
        "quantity": 1,
        "unit_price": 500,
        "vehicle_type": "sedan",
        "discount_value": 50
      }
    ],
    "addons": [
      {
        "addon_id": 1,
        "quantity": 1,
        "unit_price": 100
      }
    ],
    "washing_schedules": [
      {"date": "2026-02-05", "time_from": "10:00", "time_to": "11:00"},
      {"date": "2026-02-12", "time_from": "14:00", "time_to": "15:00"},
      {"date": "2026-02-19", "time_from": "10:00", "time_to": "11:00"},
      {"date": "2026-02-26", "time_from": "09:00", "time_to": "10:00"}
    ],
    "payment_amount": 2000,
    "payment_date": "2026-02-01",
    "payment_method": "upi",
    "notes": "Customer prefers morning slots"
  }'
```

**List subscriptions**
```bash
GET /api/v1/subscriptions
GET /api/v1/subscriptions?customer_id=1
GET /api/v1/subscriptions?status=active
GET /api/v1/subscriptions?search=John
```

**Get subscription details**
```bash
GET /api/v1/subscriptions/:id
```

**Update subscription payment**
```bash
POST /api/v1/subscriptions/:id/update_payment
{
  "payment_amount": 1000,
  "payment_date": "2026-02-15",
  "payment_method": "cash"
}
```

**Pause subscription**
```bash
POST /api/v1/subscriptions/:id/pause
```

**Resume subscription**
```bash
POST /api/v1/subscriptions/:id/resume
```

**Cancel subscription**
```bash
POST /api/v1/subscriptions/:id/cancel
```

**Get subscription orders**
```bash
GET /api/v1/subscriptions/:id/orders
```

## Automated Order Generation

### Rake Tasks

**Generate upcoming orders (run daily via cron)**
```bash
rake subscriptions:generate_orders
```
- Generates orders for washing schedules within 7 days
- Creates orders with customer's preferred time slots from washing_schedules
- Orders created with status 'tentative' and no agent assignment
- Sales executives can reassign and modify as needed

**Expire old subscriptions**
```bash
rake subscriptions:expire_subscriptions
```
- Marks subscriptions as expired if end_date has passed

**Payment reminders**
```bash
rake subscriptions:payment_reminders
```
- Lists subscriptions with pending/partial payments
- Ready for SMS/Email integration

**Run all maintenance tasks**
```bash
rake subscriptions:maintenance
```

### Cron Setup

Add to crontab for daily execution:
```bash
# Run at 6 AM daily
0 6 * * * cd /path/to/spado-api && RAILS_ENV=production bundle exec rake subscriptions:maintenance
```

## Workflow

### 1. Package Setup (Sales Executive)
- Create or update package with subscription fields
- Set subscription_price, max_washes_per_month, min_subscription_months
- Mark subscription_enabled as true

### 2. Subscription Creation (Sales Executive)
- Select customer and subscription-enabled package
- Choose vehicle type and subscription duration
- Select specific washing dates with preferred time slots (24-hour format)
- Each washing schedule includes: date, time_from, time_to
- Validated against max_washes_per_month
- Record payment details (optional, can be updated later)
- System validates dates within subscription period
- Creates subscription_order placeholders for each schedule with time information
- Subscription starts in `scheduled` status
- System sets `number_of_orders` based on washing schedules count

### 3. Automatic Order Generation (System)
- Rake task runs daily at 6 AM
- Finds washing schedules 7 days ahead with pending_generation status
- Creates orders with:
  - Customer details from subscription
  - Packages and addons from subscription
  - Booking date = scheduled washing date
  - Booking time = time_from and time_to from washing schedule
  - Status: tentative
  - No agent assignment
- Links order to subscription
- Marks subscription_order as generated
- **First order generation activates the subscription** (scheduled → active)

### 4. Order Management (Sales Executive)
- Review auto-generated orders
- Assign agents based on availability
- Adjust booking times if needed
- Confirm orders when ready

### 5. Service Completion (Agent)
- Agent completes service as usual
- Order status updates: in_progress → completed
- **System automatically increments `completed_no_orders` counter**
- **When all orders completed, subscription auto-transitions to `completed` status**

### 6. Payment Tracking (Sales Executive/Accountant)
- Update payment amounts as customer pays
- System calculates payment_status: pending/partial/paid
- View balance due in subscription details

### 7. Subscription Lifecycle
- **scheduled**: Initial state, waiting for first order generation
- **active**: At least one order generated, service in progress
- **paused**: Temporarily suspended, can be resumed
- **completed**: All orders completed (`completed_no_orders` = `number_of_orders`)
- **cancelled**: Manually cancelled by staff
- **expired**: End date passed

## Features

### Smart Validations
- Packages array must contain at least one package
- Package must be subscription-enabled
- Washing schedules must be within subscription period
- Each schedule must have valid date, time_from, and time_to
- Respects max_washes_per_month limit
- Enforces min_subscription_months
- No duplicate orders for same date
- Time format validation (24-hour format)

### Payment Flexibility
- Upfront payment (full or partial)
- Post-first-wash payment
- Multiple payment tracking
- AASM payment status: pending (initial), paid, cancelled, failed
- Total calculated from all packages and addons: sum of (package/addon total_price) × months_duration

### Subscription Management
- Pause/Resume subscriptions
- Cancel subscriptions (cancels pending orders)
- Automatic expiration
- Search by customer/status
- Multiple packages with quantity and discounts per subscription
- Optional addons with quantity and discounts
- Flexible discount types (percentage or fixed amount)

### Order Tracking
- Link orders to subscription
- View all subscription orders
- Track completion rate
- Separate subscription orders in reports

## Authorization

- **Admin**: Full access to all subscription features
- **Sales Executive**: Create, manage, and view all subscriptions
- **Agent**: Read-only access to subscriptions
- **Accountant**: Read-only access to subscriptions

## Best Practices

1. **Schedule washing dates strategically**
   - Include preferred time slots for each wash (24-hour format)
   - Avoid consecutive days for same vehicle
   - Consider customer availability and preferences
   - Leave buffer for agent scheduling flexibility

2. **Payment tracking**
   - Record initial payment at subscription creation
   - Update payments as received
   - Monitor pending/partial payments

3. **Order generation timing**
   - 7-day advance generation allows time for agent assignment
   - Orders use customer's preferred time slots from subscription
   - Sales executives should review generated orders daily
   - Can adjust agent assignments before service date

4. **Customer communication**
   - Inform customers about auto-generated orders
   - Send reminders 1-2 days before wash
   - Follow up on pending payments

5. **Cron maintenance**
   - Monitor rake task execution logs
   - Handle any generation errors promptly
   - Review expired subscriptions weekly

## Testing

To test the subscription flow:

1. Create a subscription-enabled package
2. Create a subscription with:
   - Multiple packages (with quantity and optional discounts)
   - Optional addons (with quantity and optional discounts)
   - Washing schedules including dates and time slots (24-hour format)
   - Location information (area, map_url)
3. Run `rake subscriptions:generate_orders`
4. Verify orders are created with:
   - All packages from subscription_packages
   - All addons from subscription_addons
   - Correct dates and time slots
   - Customer location (area, map_url)
5. Assign agents and confirm orders
6. Complete service as usual
7. Verify pricing calculations:
   - Each package/addon total_price = (quantity × unit_price) - discount_value
   - Subscription total = sum of all packages and addons total_price × months_duration

## Future Enhancements

Potential features for future versions:
- SMS/Email notifications for upcoming washes
- Auto-renewal option for expired subscriptions
- Customer portal for date management
- Multi-vehicle subscriptions
- Bulk discount rules based on quantity or duration
- Package/addon editing after subscription creation
- Proration for mid-term cancellations
- Usage analytics and reporting
- Subscription discount tiers
- Referral rewards for subscriptions
