# Spado API Documentation

## Base URL
```
http://localhost:3000/api/v1
```

## Authentication
All protected endpoints require a JWT token in the Authorization header:
```
Authorization: Bearer <your_jwt_token>
```

The JWT token is valid for 30 days from issuance.

---

## Table of Contents
- [Authentication Endpoints](#authentication-endpoints)
- [User Management Endpoints](#user-management-endpoints)
- [User Roles & Permissions](#user-roles--permissions)
- [Error Responses](#error-responses)

---

## Authentication Endpoints

### 1. Login
**Endpoint:** `POST /api/v1/auth/login`

**Description:** Authenticate user and receive JWT token.

**Headers:**
```
Content-Type: application/json
```

**Request Body:**
```json
{
  "email": "admin@spado.com",
  "password": "password123"
}
```

**Success Response (200 OK):**
```json
{
  "message": "Login successful",
  "user": {
    "id": 1,
    "name": "Admin User",
    "email": "admin@spado.com",
    "role": "admin",
    "last_activity_at": "2026-01-21T16:30:00.000Z",
    "created_at": "2026-01-21T10:00:00.000Z",
    "updated_at": "2026-01-21T16:30:00.000Z",
    "locked": false,
    "expired": false,
    "sign_in_count": 5,
    "current_sign_in_at": "2026-01-21T16:30:00.000Z",
    "last_sign_in_at": "2026-01-20T10:00:00.000Z"
  }
}
```

**Response Headers:**
```
Authorization: Bearer eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOjEsInNjcCI6InVzZXIi...
```

**Error Responses:**

- **401 Unauthorized** - Invalid credentials
```json
{
  "error": "Invalid email or password"
}
```

- **403 Forbidden** - Account locked
```json
{
  "error": "Account is locked due to too many failed login attempts. Please try again later or contact support."
}
```

- **403 Forbidden** - Account expired
```json
{
  "error": "Account has expired due to inactivity. Please contact support."
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@spado.com",
    "password": "password123"
  }'
```

---

### 2. Logout
**Endpoint:** `DELETE /api/v1/auth/logout`

**Description:** Logout user and revoke JWT token.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Success Response (200 OK):**
```json
{
  "message": "Logged out successfully"
}
```

**cURL Example:**
```bash
curl -X DELETE http://localhost:3000/api/v1/auth/logout \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json"
```

---

### 3. Get Current User
**Endpoint:** `GET /api/v1/auth/me`

**Description:** Get currently authenticated user's information.

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
{
  "id": 1,
  "name": "Admin User",
  "email": "admin@spado.com",
  "role": "admin",
  "last_activity_at": "2026-01-21T16:30:00.000Z",
  "created_at": "2026-01-21T10:00:00.000Z",
  "updated_at": "2026-01-21T16:30:00.000Z",
  "locked": false,
  "expired": false,
  "sign_in_count": 5,
  "current_sign_in_at": "2026-01-21T16:30:00.000Z",
  "last_sign_in_at": "2026-01-20T10:00:00.000Z"
}
```

**Error Response:**
- **401 Unauthorized** - Invalid or missing token

**cURL Example:**
```bash
curl -X GET http://localhost:3000/api/v1/auth/me \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

## User Management Endpoints

### 1. Get All Users
**Endpoint:** `GET /api/v1/users`

**Description:** Get list of all users (requires authentication).

**Permissions:**
- **Admin:** Can view all users
- **Sales Executive:** Can view all users
- **Accountant:** Can view all users
- **Agent:** Cannot access

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
{
  "users": [
    {
      "id": 1,
      "name": "Admin User",
      "email": "admin@spado.com",
      "role": "admin",
      "last_activity_at": "2026-01-21T16:30:00.000Z",
      "created_at": "2026-01-21T10:00:00.000Z",
      "updated_at": "2026-01-21T16:30:00.000Z",
      "locked": false,
      "expired": false,
      "sign_in_count": 5,
      "current_sign_in_at": "2026-01-21T16:30:00.000Z",
      "last_sign_in_at": "2026-01-20T10:00:00.000Z"
    },
    {
      "id": 2,
      "name": "John Agent",
      "email": "agent1@spado.com",
      "role": "agent",
      "last_activity_at": "2026-01-21T15:00:00.000Z",
      "created_at": "2026-01-21T10:00:00.000Z",
      "updated_at": "2026-01-21T15:00:00.000Z",
      "locked": false,
      "expired": false,
      "sign_in_count": 3,
      "current_sign_in_at": "2026-01-21T15:00:00.000Z",
      "last_sign_in_at": "2026-01-20T12:00:00.000Z"
    }
  ]
}
```

**Error Response:**
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions

**cURL Example:**
```bash
curl -X GET http://localhost:3000/api/v1/users \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 2. Get User by ID
**Endpoint:** `GET /api/v1/users/:id`

**Description:** Get specific user by ID.

**Permissions:**
- **Admin:** Can view any user
- **Sales Executive:** Can view any user
- **Accountant:** Can view any user
- **Agent:** Can only view their own profile

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
{
  "id": 1,
  "name": "Admin User",
  "email": "admin@spado.com",
  "role": "admin",
  "last_activity_at": "2026-01-21T16:30:00.000Z",
  "created_at": "2026-01-21T10:00:00.000Z",
  "updated_at": "2026-01-21T16:30:00.000Z",
  "locked": false,
  "expired": false,
  "sign_in_count": 5,
  "current_sign_in_at": "2026-01-21T16:30:00.000Z",
  "last_sign_in_at": "2026-01-20T10:00:00.000Z"
}
```

**Error Response:**
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - User not found

**cURL Example:**
```bash
curl -X GET http://localhost:3000/api/v1/users/1 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 3. Create User
**Endpoint:** `POST /api/v1/users`

**Description:** Create a new user (Admin only).

**Permissions:**
- **Admin:** Can create users

**Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "name": "New User",
  "email": "newuser@spado.com",
  "password": "password123",
  "password_confirmation": "password123",
  "role": "agent"
}
```

**Available Roles:**
- `admin`
- `agent`
- `sales_executive`
- `accountant`

**Success Response (201 Created):**
```json
{
  "message": "User created successfully",
  "user": {
    "id": 5,
    "name": "New User",
    "email": "newuser@spado.com",
    "role": "agent",
    "last_activity_at": "2026-01-21T16:30:00.000Z",
    "created_at": "2026-01-21T16:30:00.000Z",
    "updated_at": "2026-01-21T16:30:00.000Z",
    "locked": false,
    "expired": false,
    "sign_in_count": 0,
    "current_sign_in_at": null,
    "last_sign_in_at": null
  }
}
```

**Error Response:**
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions
- **422 Unprocessable Entity** - Validation errors
```json
{
  "errors": [
    "Email has already been taken",
    "Password is too short (minimum is 6 characters)"
  ]
}
```

**cURL Example:**
```bash
curl -X POST http://localhost:3000/api/v1/users \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "New User",
    "email": "newuser@spado.com",
    "password": "password123",
    "password_confirmation": "password123",
    "role": "agent"
  }'
```

---

### 4. Update User
**Endpoint:** `PUT /api/v1/users/:id` or `PATCH /api/v1/users/:id`

**Description:** Update user information.

**Permissions:**
- **Admin:** Can update any user (including role)
- **All users:** Can update their own profile (name, email only)

**Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Request Body (Admin):**
```json
{
  "name": "Updated Name",
  "email": "updated@spado.com",
  "role": "sales_executive"
}
```

**Request Body (Non-Admin):**
```json
{
  "name": "Updated Name",
  "email": "updated@spado.com"
}
```

**Success Response (200 OK):**
```json
{
  "message": "User updated successfully",
  "user": {
    "id": 2,
    "name": "Updated Name",
    "email": "updated@spado.com",
    "role": "sales_executive",
    "last_activity_at": "2026-01-21T16:30:00.000Z",
    "created_at": "2026-01-21T10:00:00.000Z",
    "updated_at": "2026-01-21T16:35:00.000Z",
    "locked": false,
    "expired": false,
    "sign_in_count": 3,
    "current_sign_in_at": "2026-01-21T15:00:00.000Z",
    "last_sign_in_at": "2026-01-20T12:00:00.000Z"
  }
}
```

**Error Response:**
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - User not found
- **422 Unprocessable Entity** - Validation errors

**cURL Example:**
```bash
curl -X PUT http://localhost:3000/api/v1/users/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "Updated Name",
    "email": "updated@spado.com"
  }'
```

---

### 5. Delete User
**Endpoint:** `DELETE /api/v1/users/:id`

**Description:** Delete a user (Admin only).

**Permissions:**
- **Admin:** Can delete any user

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
{
  "message": "User deleted successfully"
}
```

**Error Response:**
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - User not found

**cURL Example:**
```bash
curl -X DELETE http://localhost:3000/api/v1/users/2 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 6. Lock User Account
**Endpoint:** `POST /api/v1/users/:id/lock`

**Description:** Lock a user account (Admin only).

**Permissions:**
- **Admin:** Can lock any user account

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
{
  "message": "User account locked successfully"
}
```

**Error Response:**
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - User not found

**cURL Example:**
```bash
curl -X POST http://localhost:3000/api/v1/users/2/lock \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 7. Unlock User Account
**Endpoint:** `POST /api/v1/users/:id/unlock`

**Description:** Unlock a user account (Admin only).

**Permissions:**
- **Admin:** Can unlock any user account

**Headers:**
```
Authorization: Bearer <your_jwt_token>
```

**Success Response (200 OK):**
```json
{
  "message": "User account unlocked successfully"
}
```

**Error Response:**
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - User not found

**cURL Example:**
```bash
curl -X POST http://localhost:3000/api/v1/users/2/unlock \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

---

### 8. Update User Role
**Endpoint:** `PUT /api/v1/users/:id/role`

**Description:** Update user's role (Admin only).

**Permissions:**
- **Admin:** Can update any user's role

**Headers:**
```
Authorization: Bearer <your_jwt_token>
Content-Type: application/json
```

**Request Body:**
```json
{
  "role": "sales_executive"
}
```

**Available Roles:**
- `admin`
- `agent`
- `sales_executive`
- `accountant`

**Success Response (200 OK):**
```json
{
  "message": "User role updated successfully",
  "user": {
    "id": 2,
    "name": "John Agent",
    "email": "agent1@spado.com",
    "role": "sales_executive",
    "last_activity_at": "2026-01-21T16:30:00.000Z",
    "created_at": "2026-01-21T10:00:00.000Z",
    "updated_at": "2026-01-21T16:40:00.000Z",
    "locked": false,
    "expired": false,
    "sign_in_count": 3,
    "current_sign_in_at": "2026-01-21T15:00:00.000Z",
    "last_sign_in_at": "2026-01-20T12:00:00.000Z"
  }
}
```

**Error Response:**
- **401 Unauthorized** - Not authenticated
- **403 Forbidden** - Insufficient permissions
- **404 Not Found** - User not found
- **422 Unprocessable Entity** - Invalid role

**cURL Example:**
```bash
curl -X PUT http://localhost:3000/api/v1/users/2/role \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "role": "sales_executive"
  }'
```

---

## User Roles & Permissions

### Admin
- Full access to all endpoints
- Can manage all users (create, read, update, delete)
- Can lock/unlock accounts
- Can change user roles

### Sales Executive
- Can view all users
- Can update their own profile
- Cannot create, delete users or change roles

### Accountant
- Can view all users
- Can update their own profile
- Cannot create, delete users or change roles

### Agent
- Can only view their own profile
- Can update their own profile
- Cannot view other users or perform admin actions

---

## Error Responses

### Common HTTP Status Codes

| Status Code | Description |
|-------------|-------------|
| 200 | OK - Request successful |
| 201 | Created - Resource created successfully |
| 400 | Bad Request - Invalid request format |
| 401 | Unauthorized - Authentication required or token invalid |
| 403 | Forbidden - Insufficient permissions |
| 404 | Not Found - Resource not found |
| 422 | Unprocessable Entity - Validation errors |
| 500 | Internal Server Error - Server error |

### Error Response Format

```json
{
  "error": "Error message"
}
```

or for validation errors:

```json
{
  "errors": [
    "Field name error message",
    "Another field error message"
  ]
}
```

---

## Security Features

### JWT Token
- Tokens expire after 30 days
- Include token in `Authorization: Bearer <token>` header for all protected endpoints
- Tokens are revoked upon logout

### Account Locking
- Accounts are automatically locked after 5 failed login attempts
- Locked accounts automatically unlock after 1 hour
- Admins can manually lock/unlock accounts

### Inactivity Expiration
- Accounts expire after 30 days of inactivity
- Activity is tracked on each API request
- Expired accounts must contact support

---

## Health Check

### Endpoint: `GET /health`

**Description:** Check API server status.

**Response (200 OK):**
```
OK
```

**cURL Example:**
```bash
curl -X GET http://localhost:3000/health
```

---

## Testing Credentials

For development/testing purposes:

| Role | Email | Password |
|------|-------|----------|
| Admin | admin@spado.com | password123 |
| Agent | agent1@spado.com | password123 |
| Sales Executive | sales1@spado.com | password123 |
| Accountant | accountant1@spado.com | password123 |

---

## Postman Collection

### Quick Start with Postman

1. **Import Environment Variables:**
   - Create environment variable `base_url` = `http://localhost:3000/api/v1`
   - Create environment variable `jwt_token` (leave empty initially)

2. **Set Authorization Header:**
   - For protected endpoints, add header:
     ```
     Authorization: Bearer {{jwt_token}}
     ```

3. **After Login:**
   - Copy the `Authorization` header value from the login response
   - Remove "Bearer " prefix
   - Set the `jwt_token` environment variable with this value

### Example Workflow

1. **Login:**
   ```
   POST {{base_url}}/auth/login
   Body: {"email": "admin@spado.com", "password": "password123"}
   ```

2. **Copy JWT token from response header to `jwt_token` variable**

3. **Make authenticated requests:**
   ```
   GET {{base_url}}/users
   Headers: Authorization: Bearer {{jwt_token}}
   ```

---

## Support

For issues or questions, please contact the development team.

**API Version:** 1.0  
**Last Updated:** January 21, 2026
