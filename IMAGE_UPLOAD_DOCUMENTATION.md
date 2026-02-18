# Image Upload and Payment Tracking Feature

This document describes the image upload and payment tracking features for the Spado order management system.

## Overview

The system now supports:
- **Before/After Work Images**: Multiple images can be uploaded showing vehicle condition before and after service
- **Customer Signature**: Digital signature capture for order completion confirmation  
- **Tip Tracking**: Track additional amounts received from customers as tips
- **S3 Storage**: All files are stored in AWS S3 for reliability and scalability
- **Background Processing**: Image optimization and variant generation handled asynchronously via Sidekiq

## Database Changes

### New Fields in Orders Table

```ruby
# Migration: 20260216131126_add_image_and_tip_fields_to_orders.rb
- received_amount (decimal, precision: 10, scale: 2) - Total amount actually received from customer
- tip (decimal, precision: 10, scale: 2, default: 0) - Tip amount given by customer
```

### ActiveStorage Attachments

```ruby
# Order model associations
has_many_attached :before_images      # Multiple images before work starts
has_many_attached :after_images       # Multiple images after work completion
has_one_attached :customer_signature  # Customer's digital signature
```

## Configuration

### 1. AWS S3 Setup

Edit Rails credentials to add AWS configuration:

```bash
EDITOR="code --wait" rails credentials:edit
```

Add the following:

```yaml
aws:
  access_key_id: YOUR_AWS_ACCESS_KEY
  secret_access_key: YOUR_AWS_SECRET_KEY
  region: ap-south-1
  bucket: your-spado-bucket-name
```

### 2. Storage Configuration

File: `config/storage.yml`

```yaml
amazon:
  service: S3
  access_key_id: <%= Rails.application.credentials.dig(:aws, :access_key_id) %>
  secret_access_key: <%= Rails.application.credentials.dig(:aws, :secret_access_key) %>
  region: <%= Rails.application.credentials.dig(:aws, :region) || 'ap-south-1' %>
  bucket: <%= Rails.application.credentials.dig(:aws, :bucket) %>
```

Production environment uses S3 by default (`config/environments/production.rb`):

```ruby
config.active_storage.service = :amazon
```

### 3. Redis Setup

Sidekiq requires Redis. Set the Redis URL via environment variable:

```bash
# Development
export REDIS_URL=redis://localhost:6379/0

# Production
export REDIS_URL=redis://your-redis-host:6379/0
```

### 4. Sidekiq Configuration

Start Sidekiq worker:

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

Monitor Sidekiq jobs (development only):
- Web UI: http://localhost:3000/sidekiq

## API Usage

### Creating Order with Images

```bash
POST /api/v1/orders

Content-Type: multipart/form-data

Parameters:
- customer_id: integer (required)
- booking_date: date (required)
- booking_time_from: time (required)
- booking_time_to: time (required)
- contact_phone: string (required)
- area: string (required)
- before_images[]: file[] (optional, max 10MB each)
- after_images[]: file[] (optional, max 10MB each)
- customer_signature: file (optional, max 5MB)
- received_amount: decimal (optional)
- tip: decimal (optional)
... (other order fields)
```

### Updating Order with Images

```bash
PATCH /api/v1/orders/:id

Content-Type: multipart/form-data

Parameters:
- before_images[]: file[] (optional)
- after_images[]: file[] (optional)
- customer_signature: file (optional)
- received_amount: decimal (optional)
- tip: decimal (optional)
... (other updatable fields)
```

### Example cURL Request

```bash
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "customer_id=1" \
  -F "booking_date=2026-02-20" \
  -F "booking_time_from=10:00" \
  -F "booking_time_to=12:00" \
  -F "contact_phone=9876543210" \
  -F "area=Jayanagar" \
  -F "before_images[]=@/path/to/image1.jpg" \
  -F "before_images[]=@/path/to/image2.jpg" \
  -F "after_images[]=@/path/to/image3.jpg" \
  -F "customer_signature=@/path/to/signature.png" \
  -F "received_amount=550" \
  -F "tip=50"
```

## API Response

### Order Show Response

```json
{
  "order": {
    "id": 123,
    "order_number": "SP26021601",
    "total_price": 500,
    "received_amount": 550,
    "tip": 50,
    "district": "Bangalore South",
    
    "before_images": [
      {
        "id": 1,
        "url": "https://bucket.s3.amazonaws.com/...",
        "filename": "vehicle_front.jpg",
        "content_type": "image/jpeg",
        "byte_size": 2048576,
        "thumbnail_url": "https://bucket.s3.amazonaws.com/..."
      }
    ],
    
    "after_images": [
      {
        "id": 2,
        "url": "https://bucket.s3.amazonaws.com/...",
        "filename": "vehicle_clean.jpg",
        "content_type": "image/jpeg",
        "byte_size": 1876543,
        "thumbnail_url": "https://bucket.s3.amazonaws.com/..."
      }
    ],
    
    "customer_signature": {
      "id": 3,
      "url": "https://bucket.s3.amazonaws.com/...",
      "filename": "signature.png",
      "content_type": "image/png",
      "byte_size": 45678,
      "thumbnail_url": "https://bucket.s3.amazonaws.com/..."
    }
  }
}
```

## Image Processing

### Background Job

Images are processed asynchronously by `ProcessOrderImagesJob`:

- **Queue**: default
- **Retry**: 3 attempts with 5-second delay
- **Processing**:
  - Analyzes image metadata
  - Generates optimized variants:
    - Before/After Images: 800x600 (display), 200x150 (thumbnail)
    - Customer Signature: 400x200 (display)

### Monitoring

Check Sidekiq logs:

```bash
tail -f log/sidekiq.log
```

View queue status:
- Development: http://localhost:3000/sidekiq
- Production: Use Sidekiq monitoring tools

## Validation Rules

### Image Attachments

1. **Before Images**:
   - Format: JPEG, PNG, or GIF
   - Max size: 10MB per image
   - Multiple images allowed

2. **After Images**:
   - Format: JPEG, PNG, or GIF
   - Max size: 10MB per image
   - Multiple images allowed

3. **Customer Signature**:
   - Format: JPEG, PNG, or GIF
   - Max size: 5MB
   - Single image only

### Payment Fields

1. **received_amount**:
   - Must be >= 0
   - Optional field
   - Decimal with 2 decimal places

2. **tip**:
   - Must be >= 0
   - Optional field
   - Decimal with 2 decimal places
   - Auto-calculated: `received_amount - total_price` (if positive)

## Business Logic

### Automatic Tip Calculation

When `received_amount` is provided during order update, the system automatically calculates the tip:

```ruby
tip = max(received_amount - total_price, 0)
```

Example:
- `total_price`: ₹500
- `received_amount`: ₹550
- `tip`: ₹50 (auto-calculated)

### Order Model Methods

```ruby
# Calculate tip amount
order.calculate_tip
# => 50.0

# Get image URLs
order.image_urls
# => {
#   before_images: ["https://...", "https://..."],
#   after_images: ["https://..."],
#   customer_signature: "https://..."
# }
```

## Setup Instructions

### 1. Install Dependencies

```bash
cd spado-api
bundle install
```

New gems added:
- `sidekiq` (~> 7.2) - Background job processing
- `aws-sdk-s3` (~> 1.143) - AWS S3 integration
- `image_processing` (~> 1.12) - Image variant generation

### 2. Run Migrations

```bash
rails db:migrate
```

### 3. Start Redis

```bash
# macOS with Homebrew
brew services start redis

# Linux
sudo systemctl start redis

# Docker
docker run -d -p 6379:6379 redis:alpine
```

### 4. Start Sidekiq

```bash
bundle exec sidekiq -C config/sidekiq.yml
```

### 5. Configure AWS

1. Create S3 bucket in AWS Console
2. Configure bucket policy for public read (if needed)
3. Add credentials to Rails:
   ```bash
   EDITOR="code --wait" rails credentials:edit
   ```

### 6. Test Upload

```bash
# In Rails console
rails console

order = Order.first
order.before_images.attach(io: File.open('path/to/image.jpg'), filename: 'test.jpg')
order.before_images.attached? # => true
```

## Frontend Integration

### React/JavaScript Example

```javascript
// Create FormData for multipart upload
const formData = new FormData();

// Add text fields
formData.append('customer_id', customerId);
formData.append('booking_date', bookingDate);
formData.append('received_amount', receivedAmount);
formData.append('tip', tip);

// Add multiple before images
beforeImages.forEach(file => {
  formData.append('before_images[]', file);
});

// Add multiple after images
afterImages.forEach(file => {
  formData.append('after_images[]', file);
});

// Add signature
formData.append('customer_signature', signatureBlob);

// Send request
fetch('/api/v1/orders', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`
  },
  body: formData
})
.then(res => res.json())
.then(data => console.log(data));
```

## Security Considerations

1. **Authentication**: All endpoints require JWT authentication
2. **Authorization**: CanCanCan enforces role-based access
3. **File Validation**: Server-side validation of file types and sizes
4. **S3 Bucket**: Configure appropriate IAM policies and CORS
5. **Signed URLs**: ActiveStorage generates signed URLs with expiration

## Troubleshooting

### Issue: Images not uploading

- Check AWS credentials are correct
- Verify S3 bucket exists and permissions are set
- Check Rails logs for ActiveStorage errors

### Issue: Background jobs not processing

- Ensure Redis is running
- Check Sidekiq is started
- Review Sidekiq logs: `tail -f log/sidekiq.log`

### Issue: Image URLs returning 404

- Verify storage service is set to `:amazon` in environment
- Check S3 bucket policy allows public read (if needed)
- Ensure images were successfully uploaded to S3

### Issue: Large images timing out

- Increase server timeout settings
- Consider client-side image compression before upload
- Check network connectivity to S3

## Performance Optimization

1. **Image Compression**: Client-side compression before upload recommended
2. **Lazy Loading**: Use thumbnail URLs for list views
3. **CDN**: Configure CloudFront in front of S3 for faster delivery
4. **Sidekiq Concurrency**: Adjust worker count based on server resources

## Future Enhancements

- [ ] Image compression middleware
- [ ] Direct S3 upload from client (presigned URLs)
- [ ] Image metadata extraction (GPS, timestamp)
- [ ] Before/after image comparison view
- [ ] Bulk image download feature
- [ ] Image watermarking for branding
