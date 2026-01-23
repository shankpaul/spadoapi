# Customer API - cURL Commands for Postman

## Setup
Replace `YOUR_JWT_TOKEN` with your actual JWT token from login.

---

## 1. Get All Customers

```bash
curl -X GET http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

---

## 2. Get Single Customer

```bash
curl -X GET http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

---

## 3. Create Customer (Minimal)

```bash
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "John Doe",
    "phone": "+1234567890"
  }'
```

---

## 4. Create Customer (Full)

```bash
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sarah Johnson",
    "phone": "+1234567890",
    "email": "sarah@example.com",
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
  }'
```

---

## 5. Update Customer (Partial)

```bash
curl -X PUT http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "city": "Los Angeles",
    "state": "CA"
  }'
```

---

## 6. Update Customer (Full)

```bash
curl -X PUT http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Sarah Updated",
    "phone": "+9876543210",
    "email": "sarah.updated@example.com",
    "has_whatsapp": true,
    "last_booked_at": "2026-01-22T10:00:00Z",
    "area": "Financial District",
    "city": "San Francisco",
    "district": "Downtown",
    "state": "CA",
    "latitude": 37.7749,
    "longitude": -122.4194,
    "map_link": "https://maps.google.com/?q=37.7749,-122.4194",
    "last_whatsapp_message_sent_at": "2026-01-22T09:00:00Z"
  }'
```

---

## 7. Delete Customer

```bash
curl -X DELETE http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

---

## Postman Import Instructions

### Method 1: Import as Raw cURL

1. Open Postman
2. Click **Import** button
3. Select **Raw text** tab
4. Paste any of the above cURL commands
5. Click **Continue** and then **Import**

### Method 2: Manual Setup

**Base Settings:**
- Base URL: `http://localhost:3000/api/v1`
- Create an environment variable: `jwt_token`

**For each request:**

1. **Get All Customers**
   - Method: `GET`
   - URL: `{{base_url}}/customers`
   - Headers:
     - `Authorization: Bearer {{jwt_token}}`
     - `Content-Type: application/json`

2. **Get Customer by ID**
   - Method: `GET`
   - URL: `{{base_url}}/customers/1`
   - Headers:
     - `Authorization: Bearer {{jwt_token}}`
     - `Content-Type: application/json`

3. **Create Customer**
   - Method: `POST`
   - URL: `{{base_url}}/customers`
   - Headers:
     - `Authorization: Bearer {{jwt_token}}`
     - `Content-Type: application/json`
   - Body (raw JSON):
     ```json
     {
       "name": "John Doe",
       "phone": "+1234567890",
       "email": "john@example.com",
       "has_whatsapp": true,
       "city": "New York",
       "state": "NY"
     }
     ```

4. **Update Customer**
   - Method: `PUT`
   - URL: `{{base_url}}/customers/1`
   - Headers:
     - `Authorization: Bearer {{jwt_token}}`
     - `Content-Type: application/json`
   - Body (raw JSON):
     ```json
     {
       "name": "John Updated",
       "city": "Los Angeles",
       "state": "CA"
     }
     ```

5. **Delete Customer**
   - Method: `DELETE`
   - URL: `{{base_url}}/customers/1`
   - Headers:
     - `Authorization: Bearer {{jwt_token}}`
     - `Content-Type: application/json`

---

## Complete Workflow Example

### Step 1: Login
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "agent1@spado.com",
    "password": "password123"
  }'
```

**Response:**
```json
{
  "message": "Login successful",
  "user": { ... }
}
```

**Copy the token from response header:** `Authorization: Bearer eyJhbGc...`

---

### Step 2: Create Customer
```bash
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Test Customer",
    "phone": "+1234567890",
    "email": "test@example.com",
    "has_whatsapp": true,
    "city": "New York",
    "state": "NY"
  }'
```

**Response:**
```json
{
  "message": "Customer created successfully",
  "customer": {
    "id": 1,
    "name": "Test Customer",
    "phone": "+1234567890",
    "email": "test@example.com",
    "has_whatsapp": true,
    "city": "New York",
    "state": "NY",
    ...
  }
}
```

---

### Step 3: Get All Customers
```bash
curl -X GET http://localhost:3000/api/v1/customers \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json"
```

**Response:**
```json
[
  {
    "id": 1,
    "name": "Test Customer",
    "phone": "+1234567890",
    ...
  }
]
```

---

### Step 4: Update Customer
```bash
curl -X PUT http://localhost:3000/api/v1/customers/1 \
  -H "Authorization: Bearer eyJhbGc..." \
  -H "Content-Type: application/json" \
  -d '{
    "last_booked_at": "2026-01-22T10:00:00Z",
    "area": "Downtown"
  }'
```

**Response:**
```json
{
  "message": "Customer updated successfully",
  "customer": {
    "id": 1,
    "last_booked_at": "2026-01-22T10:00:00.000Z",
    "area": "Downtown",
    ...
  }
}
```

---

## Quick Test Script

Run all operations in sequence:

```bash
# 1. Login and save token
TOKEN=$(curl -s -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email": "agent1@spado.com", "password": "password123"}' \
  | grep -o 'Bearer [^"]*' | head -1)

# 2. Create customer
curl -X POST http://localhost:3000/api/v1/customers \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Quick Test",
    "phone": "+1111111111",
    "city": "Test City"
  }'

# 3. Get all customers
curl -X GET http://localhost:3000/api/v1/customers \
  -H "Authorization: $TOKEN" \
  -H "Content-Type: application/json"
```

---

## Field Reference

### Required Fields
- `name` (string)
- `phone` (string)

### Optional Fields
- `email` (string, valid email)
- `has_whatsapp` (boolean, default: false)
- `last_booked_at` (datetime, ISO 8601 format)
- `area` (string)
- `city` (string)
- `district` (string)
- `state` (string)
- `latitude` (decimal, -90 to 90)
- `longitude` (decimal, -180 to 180)
- `map_link` (string)
- `last_whatsapp_message_sent_at` (datetime, ISO 8601 format)

---

## Error Examples

### 401 Unauthorized (Missing/Invalid Token)
```json
{
  "error": "Unauthorized"
}
```

### 403 Forbidden (Insufficient Permissions)
```json
{
  "error": "You are not authorized to access this page."
}
```

### 422 Validation Error
```json
{
  "errors": [
    "Name can't be blank",
    "Phone can't be blank",
    "Email is invalid"
  ]
}
```

### 404 Not Found
```json
{
  "error": "Couldn't find Customer with 'id'=999"
}
```
