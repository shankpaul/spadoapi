# Order Management API Documentation

## Base URL
`/api/v1`

## Authentication
All endpoints require JWT authentication via `Authorization: Bearer <token>` header.

---

## Orders API

### List Orders
`GET /api/v1/orders`

**Query Parameters:**
- `status` - Filter by status (draft, tentative, booked, in_progress, completed, cancelled)
- `assigned_to_id` - Filter by assigned agent ID
- `customer_id` - Filter by customer ID
- `from_date` - Start date for date range filter (YYYY-MM-DD)
- `to_date` - End date for date range filter (YYYY-MM-DD)
- `bookable_type` - Filter by bookable type (User, Customer)
- `page` - Page number (default: 1)
- `per_page` - Items per page (default: 25)

**Response:**
```json
{
  "orders": [
    {
      "id": 1,
      "order_number": "SP26012401",
      "customer_id": 1,
      "status": "booked",
      "total_amount": "550.00",
      "packages_count": 1,
      "addons_count": 1,
      ...
    }
  ],
  "pagination": {
    "current_page": 1,
    "next_page": 2,
    "prev_page": null,
    "total_pages": 10,
    "total_count": 250,
    "per_page": 25
  }
}
```

**Authorization:**
- Admin/Sales Executive: All orders
- Agent: Only assigned orders
- Accountant: All orders (read-only)

---

### Show Order
`GET /api/v1/orders/:id`

**Response:**
```json
{
  "order": {
    "id": 1,
    "order_number": "SP26012401",
    "customer": {
      "id": 1,
      "name": "John Doe",
      "phone": "+1234567890"
    },
    "bookable": {
      "id": 5,
      "name": "Sales Executive Name",
      "type": "User",
      "role": "sales_executive"
    },
    "assigned_to": {
      "id": 10,
      "name": "Agent Name",
      "email": "agent@example.com"
    },
    "contact_phone": "+1234567890",
    "address_line1": "123 Main St",
    "area": "Downtown",
    "city": "New York",
    "booking_date": "2026-01-25",
    "booking_time_from": "10:00:00",
    "booking_time_to": "12:00:00",
    "status": "booked",
    "payment_status": "pending",
    "payment_method": "cod",
    "total_amount": "550.00",
    "gst_amount": "99.00",
    "gst_percentage": "18.0",
    "packages": [
      {
        "id": 1,
        "quantity": 1,
        "price": "500.00",
        "vehicle_type": "sedan",
        "discount": "50.00",
        "total_price": "450.00",
        "package": {
          "id": 1,
          "name": "Premium Wash",
          "description": "Complete exterior and interior cleaning"
        }
      }
    ],
    "addons": [
      {
        "id": 1,
        "quantity": 1,
        "price": "100.00",
        "discount": "0.00",
        "total_price": "100.00",
        "addon": {
          "id": 2,
          "name": "Wax Polish",
          "description": "Premium wax coating"
        }
      }
    ],
    "status_logs": [
      {
        "id": 1,
        "from_status": "draft",
        "to_status": "booked",
        "changed_at": "2026-01-24T10:30:00Z",
        "changed_by": {
          "id": 5,
          "name": "Sales Executive"
        }
      }
    ],
    "assignment_history": [
      {
        "id": 1,
        "assigned_at": "2026-01-24T10:30:00Z",
        "status": "booked",
        "notes": null,
        "assigned_to": {
          "id": 10,
          "name": "Agent Name"
        },
        "assigned_by": {
          "id": 5,
          "name": "Sales Executive"
        }
      }
    ]
  }
}
```

---

### Create Order
`POST /api/v1/orders`

**Request Body:**
```json
{
  "order": {
    "customer_id": 1,
    "contact_phone": "+1234567890",
    "address_line1": "123 Main St",
    "address_line2": "Apt 4B",
    "area": "Downtown",
    "city": "New York",
    "state": "NY",
    "latitude": 40.7128,
    "longitude": -74.0060,
    "map_link": "https://maps.google.com/...",
    "booking_date": "2026-01-25",
    "booking_time_from": "10:00",
    "booking_time_to": "12:00",
    "assigned_to_id": 10,
    "payment_method": "cod",
    "notes": "Customer prefers morning slot",
    "packages": [
      {
        "package_id": 1,
        "quantity": 1,
        "price": 500,
        "vehicle_type": "sedan",
        "discount": 50,
        "notes": "Use premium products"
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

**Notes:**
- If address fields are omitted, they are copied from customer
- Order number is auto-generated (format: SPYYMMDDNN)
- GST percentage is copied from Settings
- Total amount is auto-calculated
- Status starts as "draft"

**Response:** (Same as Show Order with message)
```json
{
  "message": "Order created successfully",
  "order": { ... }
}
```

**Authorization:** Sales Executive, Admin

---

### Update Order
`PATCH /api/v1/orders/:id`

**Request Body:**
```json
{
  "order": {
    "notes": "Updated notes",
    "booking_date": "2026-01-26",
    "booking_time_from": "14:00",
    "booking_time_to": "16:00",
    "payment_status": "paid",
    "actual_start_time": "2026-01-25T10:05:00Z",
    "actual_end_time": "2026-01-25T11:50:00Z"
  },
  "recalculate_totals": true
}
```

**Allowed Fields by Role:**
- **Admin/Sales Executive**: booking_date, booking_time_from, booking_time_to, payment_method, payment_status, notes
- **Agent**: actual_start_time, actual_end_time, notes
- **All**: notes

**Query Parameters:**
- `recalculate_totals=true` - Recalculate total amount after update

**Authorization:** 
- Sales Executive/Admin: All orders
- Agent: Only assigned orders

---

### Assign Order to Agent
`POST /api/v1/orders/:id/assign`

**Request Body:**
```json
{
  "agent_id": 10,
  "notes": "Assigned based on proximity"
}
```

**Validations:**
- Agent must exist and have "agent" role
- Agent must not be deleted
- No booking conflicts with agent's schedule

**Response:**
```json
{
  "message": "Order assigned successfully",
  "order": { ... }
}
```

**Authorization:** Sales Executive, Admin

---

### Update Order Status
`POST /api/v1/orders/:id/update_status`

**Request Body:**
```json
{
  "status": "in_progress",
  "actual_start_time": "2026-01-25T10:05:00Z"
}
```

**Status Transitions:**
- `tentative` - draft → tentative (Sales Executive/Admin)
- `booked` - tentative → booked (Sales Executive/Admin)
- `in_progress` - booked → in_progress (Agent/Sales Executive/Admin)
- `completed` - in_progress → completed (Agent/Sales Executive/Admin)
- `cancelled` - any → cancelled (Sales Executive/Admin, requires cancel_reason)

**Response:**
```json
{
  "message": "Order status updated successfully",
  "order": { ... }
}
```

**Authorization:** Role-based (see transitions above)

---

### Cancel Order
`POST /api/v1/orders/:id/cancel`

**Request Body:**
```json
{
  "cancel_reason": "Customer requested cancellation due to weather"
}
```

**Notes:**
- Cancel reason is required
- Sets cancelled_at timestamp
- Sets cancelled_by to current user
- Creates status log entry

**Response:**
```json
{
  "message": "Order cancelled successfully",
  "order": { ... }
}
```

**Authorization:** Sales Executive, Admin

---

### Add Customer Feedback
`POST /api/v1/orders/:id/add_feedback`

**Request Body:**
```json
{
  "order": {
    "rating": 5,
    "comments": "Excellent service! Very satisfied with the car wash quality."
  }
}
```

**Notes:**
- Only allowed on completed orders
- Rating must be 1-5
- Sets feedback_submitted_at timestamp
- Typically added by sales executive after calling customer

**Response:**
```json
{
  "message": "Feedback added successfully",
  "order": { ... }
}
```

**Authorization:** Sales Executive, Admin

---

### Calendar View
`GET /api/v1/orders/calendar`

**Query Parameters:**
- `start_date` - Start date (YYYY-MM-DD, default: today)
- `end_date` - End date (YYYY-MM-DD, default: start_date + 30 days)
- `assigned_to_id` - Filter by agent ID (optional)

**Response:** Same as List Orders

**Use Case:** Display orders on a calendar interface, showing bookings by date and agent

**Authorization:** 
- Admin/Sales Executive: All orders
- Agent: Only assigned orders

---

## Packages API

### List Packages
`GET /api/v1/packages`

**Query Parameters:**
- `active=true` - Show only active packages
- `vehicle_type` - Filter by vehicle type (hatchback, sedan, suv, luxury)
- `page`, `per_page`

**Response:**
```json
{
  "packages": [
    {
      "id": 1,
      "name": "Premium Wash",
      "description": "Complete exterior and interior cleaning",
      "base_price": "500.00",
      "vehicle_type": "sedan",
      "active": true,
      "display_name": "Premium Wash (Sedan)",
      "created_at": "2026-01-24T10:00:00Z",
      "updated_at": "2026-01-24T10:00:00Z"
    }
  ],
  "pagination": { ... }
}
```

**Authorization:** 
- Admin/Sales Executive: Full access
- Agent/Accountant: Read-only

---

### Create Package
`POST /api/v1/packages`

**Request Body:**
```json
{
  "package": {
    "name": "Premium Wash",
    "description": "Complete exterior and interior cleaning",
    "base_price": 500,
    "vehicle_type": "sedan",
    "active": true
  }
}
```

**Vehicle Types:** hatchback, sedan, suv, luxury

**Authorization:** Sales Executive, Admin

---

### Update Package
`PATCH /api/v1/packages/:id`

**Request Body:** Same as Create

**Authorization:** Sales Executive, Admin

---

### Delete Package
`DELETE /api/v1/packages/:id`

**Notes:** Soft delete (acts_as_paranoid)

**Authorization:** Sales Executive, Admin

---

## Addons API

### List Addons
`GET /api/v1/addons`

**Query Parameters:**
- `active=true` - Show only active addons
- `page`, `per_page`

**Response:**
```json
{
  "addons": [
    {
      "id": 1,
      "name": "Wax Polish",
      "description": "Premium wax coating for shine protection",
      "price": "100.00",
      "active": true,
      "created_at": "2026-01-24T10:00:00Z",
      "updated_at": "2026-01-24T10:00:00Z"
    }
  ],
  "pagination": { ... }
}
```

---

### Create Addon
`POST /api/v1/addons`

**Request Body:**
```json
{
  "addon": {
    "name": "Wax Polish",
    "description": "Premium wax coating",
    "price": 100,
    "active": true
  }
}
```

**Authorization:** Sales Executive, Admin

---

### Update Addon
`PATCH /api/v1/addons/:id`

**Request Body:** Same as Create

**Authorization:** Sales Executive, Admin

---

### Delete Addon
`DELETE /api/v1/addons/:id`

**Notes:** Soft delete (acts_as_paranoid)

**Authorization:** Sales Executive, Admin

---

## Error Responses

### Validation Error (422)
```json
{
  "errors": [
    "Booking time to must be after booking start time",
    "Cancel reason can't be blank"
  ]
}
```

### Authorization Error (403)
```json
{
  "error": "You are not authorized to perform this action"
}
```

### Authentication Error (401)
```json
{
  "error": "Token has expired"
}
```

### Not Found (404)
```json
{
  "error": "Record not found"
}
```

---

## Order Status Flow

```
draft → tentative → booked → in_progress → completed
  ↓         ↓         ↓           ↓
  ↓→→→→→→→ cancelled ←←←←←←←←←←←←↓
```

**Transitions:**
1. **draft → tentative**: Sales executive marks order as tentative
2. **tentative → booked**: Sales executive confirms booking
3. **booked → in_progress**: Agent starts service
4. **in_progress → completed**: Agent completes service
5. **any → cancelled**: Admin/Sales executive cancels (with reason)

---

## Settings Configuration

To update system settings (Admin only):

```ruby
# Rails console
Setting.set('gst_percentage', '20.0', value_type: 'decimal', description: 'Updated GST rate')
Setting.set('booking_buffer_minutes', '45', value_type: 'integer', description: 'Increased buffer time')
```

**Available Settings:**
- `gst_percentage` (decimal) - Default: 18.0
- `booking_buffer_minutes` (integer) - Default: 30

---

## Notes

1. **Order Numbers**: Auto-generated in format SPYYMMDDNN (e.g., SP26012401). Unique per day with race-condition handling.

2. **Booking Conflicts**: System automatically checks for overlapping bookings when assigning agents, considering buffer time.

3. **Address Copying**: Order addresses are copied from customer at creation but can be overridden.

4. **GST Calculation**: GST percentage is copied from Settings to order at creation for historical accuracy.

5. **Soft Deletes**: All main entities use soft delete (acts_as_paranoid).

6. **Audit Trail**: All status changes and assignments are automatically logged.

7. **Pagination**: Default 25 items per page, customizable via `per_page` parameter.

8. **Timestamps**: All records include `created_at` and `updated_at` fields.
