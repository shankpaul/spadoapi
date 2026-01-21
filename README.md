# Spado API

A Rails 8 API-only application with PostgreSQL, featuring Devise-JWT authentication, Jbuilder for JSON responses, role-based authorization, account locking, and automatic timeout after inactivity.

## Features

- **Devise-JWT Authentication**: Robust JWT authentication using Devise with automatic token management
- **Jbuilder JSON Views**: Clean, maintainable JSON responses using Jbuilder templates
- **Token-based API Access**: Secure JWT token authentication for stateless API requests
- **User Management**: Complete user registration, login, and profile management
- **Role-based Authorization**: Support for multiple user roles (admin, moderator, user)
- **Account Locking**: Automatic account locking after 5 failed login attempts (via Devise lockable)
- **Inactivity Timeout**: Automatic timeout after 30 days of inactivity (via Devise timeoutable)
- **Activity Tracking**: Automatic tracking of sign-ins, IPs, and activity (via Devise trackable)
- **JWT Revocation**: Token denylist strategy for secure logout
- **CORS Support**: Configured for cross-origin requests

## Requirements

- Ruby 3.3.0
- Rails 8.0
- PostgreSQL 12 or higher

## Installation

1. Install dependencies:
```bash
bundle install
```

2. Configure database:
Edit `config/database.yml` with your PostgreSQL credentials.

3. Set up JWT secret key:
```bash
# Generate a secret key
rails secret

# Add to credentials (or use environment variable)
EDITOR="code --wait" rails credentials:edit

# Add this line:
# devise_jwt_secret_key: <your_generated_secret>

# Or set environment variable
export DEVISE_JWT_SECRET_KEY=<your_generated_secret>
```

4. Create and migrate database:
```bash
rails db:create
rails db:migrate
```

5. (Optional) Seed initial data:
```bash
rails db:seed
```

## Running the Application

Start the Rails server:
```bash
rails server
```

The API will be available at `http://localhost:3000`

## API Endpoints

### Authentication

#### Register a new user
```
POST /api/v1/auth/register
Content-Type: application/json

{
  "user": {
    "name": "John Doe",
    "email": "john@example.com",
    "password": "password123",
    "password_confirmation": "password123"
  }
}
```

Response:
```json
{
  "message": "User registered successfully",
  "user": {
    "id": 1,
    "name": "John Doe",
    "email": "john@example.com",
    "role": "user",
    "last_activity_at": "2026-01-19T10:00:00Z",
    "created_at": "2026-01-19T10:00:00Z",
    "updated_at": "2026-01-19T10:00:00Z",
    "locked": false,
    "expired": false,
    "sign_in_count": 0,
    "current_sign_in_at": null,
    "last_sign_in_at": null
  }
}
```

**Note:** JWT token is returned in the `Authorization` header as `Bearer <token>`

#### Login
```
POST /api/v1/auth/login
Content-Type: application/json

{
  "user": {
    "email": "john@example.com",
    "password": "password123"
  }
}
```

Response:
```json
{
  "message": "Login successful",
  "user": { ... }
}
```

**Note:** JWT token is returned in the `Authorization` header as `Bearer <token>`. Use this token for subsequent authenticated requests.

#### Logout
```
DELETE /api/v1/auth/logout
Authorization: Bearer YOUR_JWT_TOKEN
```

**Note:** This adds the JWT to the denylist, invalidating it.

#### Get current user
```
GET /api/v1/auth/me
Authorization: Bearer YOUR_JWT_TOKEN
```

### User Management

#### List all users (Admin only)
```
GET /api/v1/users
Authorization: Bearer ADMIN_JWT_TOKEN
```

#### Get user by ID
```
GET /api/v1/users/:id
Authorization: Bearer YOUR_JWT_TOKEN
```
Note: Users can view their own profile, admins can view any profile.

#### Update user
```
PUT /api/v1/users/:id
Authorization: Bearer YOUR_JWT_TOKEN
Content-Type: application/json

{
  "user": {
    "name": "Updated Name",
    "email": "newemail@example.com"
  }
}
```

#### Delete user (Admin only)
```
DELETE /api/v1/users/:id
Authorization: Bearer ADMIN_JWT_TOKEN
```

#### Lock user account (Admin only)
```
POST /api/v1/users/:id/lock
Authorization: Bearer ADMIN_JWT_TOKEN
```

#### Unlock user account (Admin only)
```
POST /api/v1/users/:id/unlock
Authorization: Bearer ADMIN_JWT_TOKEN
```

#### Update user role (Admin only)
```
PUT /api/v1/users/:id/role
Authorization: Bearer ADMIN_JWT_TOKEN
Content-Type: application/json

{
  "role": "admin"
}
```

Available roles: `user`, `admin`, `moderator`

## User Roles

- **user**: Default role for new registrations, basic access
- **moderator**: Can perform moderation tasks (customize based on needs)
- **admin**: Full access to all endpoints including user management

## Account Security Features

### Devise Lockable (Failed Login Attempts)
- After 5 failed login attempts, the account is automatically locked
- Locked accounts are automatically unlocked after 1 hour
- Lock strategy and duration configured in Devise initializer

### Devise Timeoutable (Inactivity Timeout)
- User sessions timeout after 30 days of inactivity
- Timeout period configured in Devise initializer
- Activity is tracked on every authenticated API request

### Devise Trackable
- Tracks sign-in count, timestamps, and IP addresses
- Provides audit trail for user authentication
- Stores current and last sign-in information

### JWT Token Management
- Tokens automatically included in Authorization header on login
- Tokens expire after 30 days (configurable)
- Logout adds token to denylist for revocation
- Automatic cleanup of expired tokens from denylist

### Account Locking
- Manual locking by administrators
- Automatic locking after failed login attempts via Devise
- Automatic unlock after configured duration

## Rake Tasks

### Expire inactive accounts
```bash
rails users:expire_inactive
```

### Unlock temporarily locked accounts
```bash
rails users:unlock_temporary
```

### Generate user status report
```bash
rails users:report
```

## Scheduled Jobs (Optional)

To automatically expire inactive accounts, you can set up a cron job:

```bash
# Run daily at 2 AM
0 2 * * * cd /path/to/spado-api && bundle exec rails users:expire_inactive
```

Or use a gem like `whenever` to manage scheduled tasks.

## Configuration

### Devise-JWT Settings (in config/initializers/devise.rb)

```ruby
config.jwt do |jwt|
  jwt.secret = Rails.application.credentials.devise_jwt_secret_key
  jwt.dispatch_requests = [['POST', %r{^/api/v1/auth/login$}]]
  jwt.revocation_requests = [['DELETE', %r{^/api/v1/auth/logout$}]]
  jwt.expiration_time = 30.days.to_i
end

config.timeout_in = 30.days           # Inactivity timeout
config.maximum_attempts = 5            # Lock after 5 failed attempts
config.unlock_in = 1.hour             # Auto-unlock after 1 hour
config.password_length = 6..128       # Password length requirements
```

### User Model Constants (in app/models/user.rb)

```ruby
INACTIVITY_PERIOD = 30.days    # Custom expiration check period
```

### CORS Configuration

Edit `config/initializers/cors.rb` to restrict origins in production:

```ruby
origins 'https://yourfrontend.com'
```

## Testing

Run tests:
```bash
rails test
```

## Security Considerations

1. **Token Storage**: API tokens should be stored securely on the client side
2. **HTTPS**: Always use HTTPS in production
3. **Token Rotation**: Implement regular token rotation for enhanced security
4. **Rate Limiting**: Consider adding rate limiting for authentication endpoints
5. **Password Policy**: Minimum 6 characters (customize in User model)

## Production Deployment

1. Set environment to production
2. Configure production database in `config/database.yml`
3. Set `SECRET_KEY_BASE` environment variable
4. Run migrations: `RAILS_ENV=production rails db:migrate`
5. Precompile assets if needed
6. Configure reverse proxy (nginx/Apache)
7. Set up SSL/TLS certificates
