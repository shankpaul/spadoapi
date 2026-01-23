# Customer API Documentation

## Base URL
```
http://localhost:3000/api/v1
```

## Authentication
All endpoints require JWT authentication:
```
Authorization: Bearer <your_jwt_token>
```

---

## Customer Endpoints

### 1. Get All Customers
**Endpoint:** `GET /api/v1/customers`

**Permissions:**
- **Admin:** Full access
- **Sales Executive:** Full access
- **Agent:** Full access
- **Accountant:** Read only

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
[
  {
    "id": 1,
    "name": "John Doe",
    "phone": "+1234567890",
    "email": "john@example.com",
    "has_whatsapp": true,
    "last_booked_at": "2026-01-20T10:00:00.000Z",
    "area": "Downtown",
    "city": "New York",
    "district": "Manhattan",
    "state": "NY",
    "latitude": "40.7128",
    "longitude": "-74.0060",
    "map_link": "https://maps.google.com/?q=40.7128,-74.0060",
    "last_whatsapp_message_sent_at": "2026-01-21T15:30:00.000Z",
    "created_at": "2026-01-15T10:00:00.000Z",
    "updated_at": "2026-01-21T15:30:00.000Z"
  }
]
```

**cURL Example:**
```bash
curl -X GET http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 2. Get Customer by ID
**Endpoint:** `GET /api/v1/customers/:id`

**Permissions:**
- **Admin:** Full access
- **Sales Executive:** Full access
- **Agent:** Full access
- **Accountant:** Read only

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
{
  "id": 1,
  "name": "John Doe",
  "phone": "+1234567890",
  "email": "john@example.com",
  "has_whatsapp": true,
  "last_booked_at": "2026-01-20T10:00:00.000Z",
  "area": "Downtown",
  "city": "New York",
  "district": "Manhattan",
  "state": "NY",
  "latitude": "40.7128",
  "longitude": "-74.0060",
  "map_link": "https://maps.google.com/?q=40.7128,-74.0060",
  "last_whatsapp_message_sent_at": "2026-01-21T15:30:00.000Z",
  "created_at": "2026-01-15T10:00:00.000Z",
  "updated_at": "2026-01-21T15:30:00.000Z"
}
```

**Error Responses:**
- **404 Not Found** - Customer not found
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions

**cURL Example:**
```bash
curl -X GET http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 3. Create Customer
**Endpoint:** `POST /api/v1/customers`

**Permissions:**
- **Admin:** Can create
- **Sales Executive:** Can create
- **Agent:** Can create
- **Accountant:** Cannot create

**Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "John Doe",
  "phone": "+1234567890",
  "email": "john@example.com",
  "has_whatsapp": true,
  "last_booked_at": "2026-01-20T10:00:00Z",
  "area": "Downtown",
  "city": "New York",
  "district": "Manhattan",
  "state": "NY",
  "latitude": 40.7128,
  "longitude": -74.0060,
  "map_link": "https://maps.google.com/?q=40.7128,-74.0060",
  "last_whatsapp_message_sent_at": "2026-01-21T15:30:00Z"
}
```

**Required Fields:**
- `name` (string)
- `phone` (string)

**Optional Fields:**
- `email` (string, must be valid email format)
- `has_whatsapp` (boolean, default: false)
- `last_booked_at` (datetime)
- `area` (string)
- `city` (string)
- `district` (string)
- `state` (string)
- `latitude` (decimal, range: -90 to 90)
- `longitude` (decimal, range: -180 to 180)
- `map_link` (string)
- `last_whatsapp_message_sent_at` (datetime)

**Success Response (201 Created):**
```json
{
  "message": "Customer created successfully",
  "customer": {
    "id": 2,
    "name": "John Doe",
    "phone": "+1234567890",
    "email": "john@example.com",
    "has_whatsapp": true,
    "last_booked_at": "2026-01-20T10:00:00.000Z",
    "area": "Downtown",
    "city": "New York",
    "district": "Manhattan",
    "state": "NY",
    "latitude": "40.7128",
    "longitude": "-74.0060",
    "map_link": "https://maps.google.com/?q=40.7128,-74.0060",
    "last_whatsapp_message_sent_at": "2026-01-21T15:30:00.000Z",
    "created_at": "2026-01-22T10:00:00.000Z",
    "updated_at": "2026-01-22T10:00:00.000Z"
  }
}
```

**Error Response (422 Unprocessable Entity):**
```json
{
  "errors": [
    "Name can't be blank",
    "Phone can't be blank",
    "Email is invalid"
  ]
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "phone": "+1234567890",
    "email": "john@example.com",
    "has_whatsapp": true,
    "city": "New York",
    "state": "NY"
  }'
```

---

### 4. Update Customer
**Endpoint:** `PUT /api/v1/customers/:id` or `PATCH /api/v1/customers/:id`

**Permissions:**
- **Admin:** Can update
- **Sales Executive:** Can update
- **Agent:** Can update
- **Accountant:** Cannot update

**Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "John Updated",
  "phone": "+1234567890",
  "email": "john.updated@example.com",
  "has_whatsapp": true,
  "city": "Los Angeles",
  "state": "CA"
}
```

**Success Response (200 OK):**
```json
{
  "message": "Customer updated successfully",
  "customer": {
    "id": 1,
    "name": "John Updated",
    "phone": "+1234567890",
    "email": "john.updated@example.com",
    "has_whatsapp": true,
    "last_booked_at": "2026-01-20T10:00:00.000Z",
    "area": "Downtown",
    "city": "Los Angeles",
    "district": "Manhattan",
    "state": "CA",
    "latitude": "40.7128",
    "longitude": "-74.0060",
    "map_link": "https://maps.google.com/?q=40.7128,-74.0060",
    "last_whatsapp_message_sent_at": "2026-01-21T15:30:00.000Z",
    "created_at": "2026-01-15T10:00:00.000Z",
    "updated_at": "2026-01-22T11:00:00.000Z"
  }
}
```

**Error Responses:**
- **404 Not Found** - Customer not found
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions
- **422 Unprocessable Entity** - Validation errors

**cURL Example:**
```bash
curl -X PUT http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Updated",
    "city": "Los Angeles",
    "state": "CA"
  }'
```

---

### 5. Delete Customer
**Endpoint:** `DELETE /api/v1/customers/:id`

**Permissions:**
- **Admin:** Can delete
- **Sales Executive:** Can delete
- **Agent:** Can delete
- **Accountant:** Cannot delete

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
{
  "message": "Customer deleted successfully"
}
```

**Error Responses:**
- **404 Not Found** - Customer not found
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions

**cURL Example:**
```bash
curl -X DELETE http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## Customer Model Features

### Scopes
The Customer model includes helpful scopes:

- `with_whatsapp` - Returns only customers with WhatsApp enabled
- `by_city(city)` - Filter customers by city
- `by_state(state)` - Filter customers by state
- `recently_booked` - Returns customers who booked in the last 30 days

### Helper Methods

**`full_address`**
Returns a formatted string of the complete address:
```ruby
customer.full_address
# => "Downtown, New York, Manhattan, NY"
```

**`coordinates`**
Returns a hash with latitude and longitude:
```ruby
customer.coordinates
# => { latitude: 40.7128, longitude: -74.0060 }
```

**`send_whatsapp_message_tracking`**
Updates the `last_whatsapp_message_sent_at` timestamp:
```ruby
customer.send_whatsapp_message_tracking
```

---

## Permissions Summary

| Role | List | View | Create | Update | Delete |
|------|------|------|--------|--------|--------|
| Admin | ✓ | ✓ | ✓ | ✓ | ✓ |
| Sales Executive | ✓ | ✓ | ✓ | ✓ | ✓ |
| Agent | ✓ | ✓ | ✓ | ✓ | ✓ |
| Accountant | ✓ | ✓ | ✗ | ✗ | ✗ |

---

## Field Validations

| Field | Type | Required | Validation |
|-------|------|----------|------------|
| name | string | Yes | Must be present |
| phone | string | Yes | Must be present |
| email | string | No | Must be valid email format |
| has_whatsapp | boolean | No | Default: false |
| last_booked_at | datetime | No | - |
| area | string | No | - |
| city | string | No | Indexed for performance |
| district | string | No | - |
| state | string | No | - |
| latitude | decimal | No | Range: -90 to 90 |
| longitude | decimal | No | Range: -180 to 180 |
| map_link | string | No | - |
| last_whatsapp_message_sent_at | datetime | No | - |

---

## Example Workflow

1. **Login to get JWT token:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "agent1@spado.com", "password": "password123"}'
```

2. **Create a new customer:**
```bash
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sarah Johnson",
    "phone": "+1234567890",
    "email": "sarah@example.com",
    "has_whatsapp": true,
    "city": "San Francisco",
    "state": "CA"
  }'
```

3. **Get all customers:**
```bash
curl -X GET http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

4. **Update customer:**
```bash
curl -X PUT http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "last_booked_at": "2026-01-22T10:00:00Z",
    "area": "Financial District"
  }'
```

---

## Error Codes

| Status Code | Description |
|-------------|-------------|
| 200 | OK - Request successful |
| 201 | Created - Customer created successfully |
| 400 | Bad Request - Invalid request format |
| 401 | Unauthorized - Authentication required |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Customer not found |
| 422 | Unprocessable Entity - Validation errors |
| 500 | Internal Server Error - Server error |

---

**Last Updated:** January 22, 2026
