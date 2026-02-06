# Subscription Addon - Applicable Wash Numbers Feature

## Overview
This feature allows you to specify which wash numbers (1st wash, 2nd wash, etc.) a subscription addon should be applied to when orders are auto-generated from subscriptions.

## Database Changes

### Migration
- **File**: `db/migrate/20260205000001_add_applicable_wash_numbers_to_subscription_addons.rb`
- **Field**: `applicable_wash_numbers` (text field storing JSON array)
- **Default**: `[]` (empty array)

### Schema
```ruby
create_table "subscription_addons" do |t|
  # ... other fields ...
  t.text "applicable_wash_numbers", default: "[]"
end
```

## API Documentation

### Field: `applicable_wash_numbers`
- **Type**: Array of integers
- **Description**: Contains the specific wash numbers where this addon should be applied
- **Default**: `[]` (empty array - addon won't be applied to any wash)

### Calculation Logic

#### Total Washes Calculation
```
total_washes = sum of (package.max_washes_per_month × months_duration) for all packages
```

#### Wash Numbers Range
Wash numbers range from `1` to `total_washes`
- Example: If total_washes = 24, valid wash numbers are [1, 2, 3, ..., 24]

### User Selection Options

#### 1. All Washes
```json
{
  "applicable_wash_numbers": [1, 2, 3, ..., total_washes]
}
```
Addon will be applied to every single wash.

#### 2. Specific Washes
```json
{
  "applicable_wash_numbers": [1, 5, 10, 15]
}
```
Addon will only be applied to the 1st, 5th, 10th, and 15th wash.

#### 3. No Washes (Default)
```json
{
  "applicable_wash_numbers": []
}
```
Addon won't be applied to any wash.

### Examples

#### Example 1: Single Package
**Scenario**: 
- Package: 4 washes/month × 3 months = 12 total washes

**Options**:
- All washes: `[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]`
- First month only: `[1, 2, 3, 4]`
- Every 3rd wash: `[3, 6, 9, 12]`

#### Example 2: Multiple Packages
**Scenario**:
- Package A: 4 washes/month
- Package B: 8 washes/month
- Total: 12 washes/month × 2 months = 24 total washes

**Options**:
- All washes: `[1, 2, 3, ..., 24]`
- First wash of each month: `[1, 13]`
- Last wash of each month: `[12, 24]`

### Pricing

The price calculation follows this formula:
```
price = unit_price × applicable_wash_numbers.length - discount_value
```

**Important Notes**:
- `quantity`: Always 1 (not used in price calculation)
- `price`: The price sent in the API payload should already be calculated based on the selected wash count
- The backend stores the price as provided by the frontend

## API Request Format

### POST /api/v1/subscriptions

```json
{
  "customer_id": 1,
  "vehicle_type": "sedan",
  "start_date": "2026-02-10",
  "months_duration": 3,
  "packages": [
    {
      "package_id": 1,
      "quantity": 1,
      "unit_price": 500,
      "price": 500
    }
  ],
  "addons": [
    {
      "addon_id": 1,
      "quantity": 1,
      "unit_price": 100,
      "price": 400,
      "discount_value": 0,
      "applicable_wash_numbers": [1, 2, 3, 4]
    },
    {
      "addon_id": 2,
      "quantity": 1,
      "unit_price": 50,
      "price": 600,
      "discount_value": 0,
      "applicable_wash_numbers": [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]
    }
  ],
  "washing_schedules": [
    {"date": "2026-02-15", "time_from": "09:00", "time_to": "10:00"},
    {"date": "2026-02-22", "time_from": "09:00", "time_to": "10:00"}
    // ... more schedules
  ],
  "payment_amount": 5000,
  "payment_method": "cash"
}
```

## API Response Format

### GET /api/v1/subscriptions/:id

```json
{
  "subscription": {
    "id": 1,
    "subscription_addons": [
      {
        "id": 1,
        "addon": {
          "id": 1,
          "name": "Wax Polish"
        },
        "quantity": 1,
        "unit_price": 100.0,
        "price": 100.0,
        "discount": null,
        "discount_type": null,
        "discount_value": 0.0,
        "total_price": 400.0,
        "applicable_wash_numbers": [1, 2, 3, 4]
      }
    ]
  }
}
```

## Backend Implementation

### Model: `SubscriptionAddon`
**File**: [app/models/subscription_addon.rb](app/models/subscription_addon.rb)

#### New Features:
1. **JSON Serialization**: Automatically converts the field to/from JSON
2. **Normalization**: Ensures the field is always an array of unique, sorted integers
3. **Validation**: 
   - Validates all values are positive integers
   - Validates all wash numbers are within the valid range (1 to total_washes)
4. **Helper Method**: `applies_to_wash?(wash_number)` - checks if addon applies to a specific wash

```ruby
# Check if addon applies to wash number 5
if subscription_addon.applies_to_wash?(5)
  # Include this addon in the order
end
```

### Service: `Subscriptions::CreationService`
**File**: [app/services/subscriptions/creation_service.rb](app/services/subscriptions/creation_service.rb)

- Accepts `applicable_wash_numbers` from the API request
- Stores it in the `subscription_addons` record

### Service: `Subscriptions::OrderGeneratorService`
**File**: [app/services/subscriptions/order_generator_service.rb](app/services/subscriptions/order_generator_service.rb)

#### New Logic:
1. **Calculate Wash Number**: Determines which wash number this order represents (1st, 2nd, 3rd, etc.)
2. **Filter Addons**: Only includes addons that apply to the current wash number
3. **Order Notes**: Includes wash number in order notes for tracking

```ruby
# Example: Creating the 5th order for a subscription
wash_number = 5

# Only include addons that apply to wash #5
filtered_addons = subscription.subscription_addons.select do |addon|
  addon.applies_to_wash?(5)
end
```

## Validation Rules

### Frontend Validation (Recommended)
- Empty array should not be allowed (use UI to prevent this)
- All numbers must be positive integers
- All numbers must be within range [1, total_washes]
- No duplicate numbers

### Backend Validation (Enforced)
- Automatically removes duplicates and sorts the array
- Validates all values are positive integers
- Validates all wash numbers are within the subscription's total wash count
- Returns validation error if any number is out of range

## Testing the Feature

### 1. Create a Subscription with Addons
```bash
curl -X POST http://localhost:3000/api/v1/subscriptions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "customer_id": 1,
    "vehicle_type": "sedan",
    "start_date": "2026-02-10",
    "months_duration": 1,
    "packages": [{
      "package_id": 1,
      "quantity": 1,
      "unit_price": 500,
      "price": 500
    }],
    "addons": [{
      "addon_id": 1,
      "quantity": 1,
      "unit_price": 100,
      "price": 200,
      "applicable_wash_numbers": [1, 3]
    }],
    "washing_schedules": [
      {"date": "2026-02-15", "time_from": "09:00", "time_to": "10:00"},
      {"date": "2026-02-17", "time_from": "09:00", "time_to": "10:00"},
      {"date": "2026-02-19", "time_from": "09:00", "time_to": "10:00"},
      {"date": "2026-02-21", "time_from": "09:00", "time_to": "10:00"}
    ],
    "payment_amount": 700,
    "payment_method": "cash"
  }'
```

### 2. Generate Orders
The scheduled job or manual trigger will create orders, and:
- Order #1 (1st wash): Will include the addon
- Order #2 (2nd wash): Will NOT include the addon
- Order #3 (3rd wash): Will include the addon
- Order #4 (4th wash): Will NOT include the addon

### 3. Verify in Database
```ruby
# Rails console
subscription = Subscription.last
addon = subscription.subscription_addons.first

# Check applicable wash numbers
addon.applicable_wash_numbers
# => [1, 3]

# Check if applies to specific washes
addon.applies_to_wash?(1)  # => true
addon.applies_to_wash?(2)  # => false
addon.applies_to_wash?(3)  # => true
```

## Migration Instructions

### Running the Migration
```bash
rails db:migrate
```

### Rolling Back (if needed)
```bash
rails db:rollback
```

### Checking Migration Status
```bash
rails db:migrate:status
```

## Notes

1. **Backward Compatibility**: Existing subscription addons will have an empty array `[]` by default, meaning they won't be applied to any wash. You may need to update existing records if needed.

2. **Performance**: The wash number calculation uses the subscription order's position in the sequence, so it's important that subscription orders are created in the correct order.

3. **Edge Cases**:
   - If `applicable_wash_numbers` is empty, the addon won't be added to any order
   - If a wash number exceeds total washes, validation will fail
   - Array is automatically sorted and deduplicated

4. **Future Enhancements**:
   - UI for easily selecting wash numbers (checkboxes, range selector, patterns)
   - Preset patterns like "every nth wash", "first/last wash of each month"
   - Bulk update for existing subscriptions
