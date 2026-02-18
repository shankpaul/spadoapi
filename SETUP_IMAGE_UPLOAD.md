# Quick Setup Guide - Image Uploads & Tip Tracking

## ✅ What's Been Implemented

### 1. Database Changes
- ✅ Added `received_amount` field (tracks total amount received from customer)
- ✅ Added `tip` field (automatically calculated or manually set)
- ✅ Migration applied successfully

### 2. File Storage Configuration
- ✅ Configured AWS S3 for production file storage
- ✅ ActiveStorage set up with image attachments:
  - `before_images` - Multiple photos before work starts
  - `after_images` - Multiple photos after completion
  - `customer_signature` - Digital signature capture

### 3. Background Job Processing
- ✅ Sidekiq configured for async job processing
- ✅ `ProcessOrderImagesJob` created for image optimization
- ✅ Generates thumbnails and optimized variants automatically
- ✅ Redis integration for job queue

### 4. API Updates
- ✅ Order creation accepts image uploads
- ✅ Order update accepts image uploads
- ✅ Auto-calculates tip: `tip = received_amount - total_price`
- ✅ Returns image URLs and thumbnails in API responses
- ✅ Added validation for file types and sizes

### 5. Model Updates
- ✅ Order model with attachments and validations
- ✅ Image validation (10MB for work images, 5MB for signature)
- ✅ Helper methods: `calculate_tip`, `image_urls`

## 🚀 Next Steps to Use

### 1. Install Redis (Required for Sidekiq)

**Option A: Homebrew (macOS)**
```bash
brew install redis
brew services start redis
```

**Option B: Docker**
```bash
docker run -d -p 6379:6379 --name redis redis:alpine
```

**Option C: Linux**
```bash
sudo apt-get install redis-server
sudo systemctl start redis
```

### 2. Configure AWS Credentials

Edit Rails credentials:
```bash
cd /Users/shan/works/spado/spado-api
EDITOR="code --wait" rails credentials:edit
```

Add this configuration:
```yaml
aws:
  access_key_id: YOUR_AWS_ACCESS_KEY_ID
  secret_access_key: YOUR_AWS_SECRET_ACCESS_KEY
  region: ap-south-1
  bucket: your-spado-bucket-name
```

Save and close.

### 3. Create S3 Bucket

1. Go to AWS Console → S3
2. Create new bucket (e.g., `spado-orders-production`)
3. Set permissions:
   - Block public access: OFF (if you want public URLs)
   - Or configure bucket policy for authenticated access
4. Enable CORS if accessing from frontend:
   ```json
   [
     {
       "AllowedHeaders": ["*"],
       "AllowedMethods": ["GET", "POST", "PUT"],
       "AllowedOrigins": ["*"],
       "ExposeHeaders": []
     }
   ]
   ```

### 4. Start Sidekiq Worker

In a new terminal:
```bash
cd /Users/shan/works/spado/spado-api
bundle exec sidekiq -C config/sidekiq.yml
```

Keep this running in the background.

### 5. Start Rails Server

```bash
cd /Users/shan/works/spado/spado-api
rails server
```

### 6. Monitor Sidekiq (Development)

Visit: http://localhost:3000/sidekiq

## 📝 API Usage Examples

### Create Order with Images

```bash
curl -X POST http://localhost:3000/api/v1/orders \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "customer_id=1" \
  -F "booking_date=2026-03-01" \
  -F "booking_time_from=10:00" \
  -F "booking_time_to=12:00" \
  -F "contact_phone=9876543210" \
  -F "area=Koramangala" \
  -F "before_images[]=@before1.jpg" \
  -F "before_images[]=@before2.jpg" \
  -F "packages[0][package_id]=1" \
  -F "packages[0][quantity]=1" \
  -F "packages[0][price]=500"
```

### Update Order with After Images & Payment

```bash
curl -X PATCH http://localhost:3000/api/v1/orders/123 \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -F "after_images[]=@after1.jpg" \
  -F "after_images[]=@after2.jpg" \
  -F "customer_signature=@signature.png" \
  -F "received_amount=550" \
  -F "tip=50" \
  -F "status=completed"
```

### Response Format

```json
{
  "order": {
    "id": 123,
    "order_number": "SP26021601",
    "total_price": 500.0,
    "received_amount": 550.0,
    "tip": 50.0,
    
    "before_images": [
      {
        "id": 1,
        "url": "https://bucket.s3.amazonaws.com/xyz123",
        "thumbnail_url": "https://bucket.s3.amazonaws.com/thumb_xyz123",
        "filename": "before1.jpg",
        "byte_size": 2048576
      }
    ],
    
    "after_images": [...],
    
    "customer_signature": {
      "id": 3,
      "url": "https://...",
      "thumbnail_url": "https://..."
    }
  }
}
```

## 🧪 Testing

### Test in Rails Console

```ruby
rails console

# Create order
order = Order.first

# Attach images
order.before_images.attach(
  io: File.open('test_image.jpg'),
  filename: 'test.jpg',
  content_type: 'image/jpeg'
)

# Check attachment
order.before_images.attached? # => true

# Test tip calculation
order.update(total_price: 500, received_amount: 550)
order.calculate_tip # => 50.0
```

## 📂 New Files Created

```
spado-api/
├── app/
│   ├── jobs/
│   │   └── process_order_images_job.rb       # Background image processing
│   └── models/
│       └── order.rb                           # Updated with attachments
├── config/
│   ├── initializers/
│   │   └── sidekiq.rb                         # Sidekiq configuration
│   ├── sidekiq.yml                            # Queue configuration
│   └── storage.yml                            # Updated S3 config
├── db/
│   └── migrate/
│       └── 20260216131126_add_image_and_tip_fields_to_orders.rb
├── Gemfile                                    # Added sidekiq, aws-sdk-s3, image_processing
└── IMAGE_UPLOAD_DOCUMENTATION.md              # Full documentation
```

## 🔧 Environment Variables

Set these in your environment (or `.env` file):

```bash
# Redis (required for Sidekiq)
REDIS_URL=redis://localhost:6379/0

# AWS credentials (alternative to Rails credentials)
AWS_ACCESS_KEY_ID=your_key
AWS_SECRET_ACCESS_KEY=your_secret
AWS_REGION=ap-south-1
AWS_BUCKET=your-bucket-name
```

## 🎯 Features Summary

| Feature | Status | Description |
|---------|--------|-------------|
| Before Images | ✅ Ready | Multiple images before service |
| After Images | ✅ Ready | Multiple images after service |
| Customer Signature | ✅ Ready | Digital signature capture |
| S3 Storage | ✅ Configured | Cloud storage for files |
| Background Jobs | ✅ Ready | Async image processing |
| Tip Tracking | ✅ Ready | Auto-calculated from received_amount |
| Image Validation | ✅ Ready | Type & size checks |
| Thumbnails | ✅ Ready | Auto-generated on upload |
| API Integration | ✅ Ready | Full CRUD support |

## 📖 Full Documentation

See [IMAGE_UPLOAD_DOCUMENTATION.md](./IMAGE_UPLOAD_DOCUMENTATION.md) for:
- Detailed API examples
- Security configuration
- Troubleshooting guide
- Performance optimization tips
- Frontend integration examples

## ⚠️ Important Notes

1. **Redis Required**: Sidekiq needs Redis running for background jobs
2. **AWS Credentials**: Must configure before production use
3. **File Sizes**: Large files may need nginx/server timeout adjustments
4. **Development**: Local storage used by default (change to S3 if needed)
5. **Production**: S3 storage automatically used in production environment

## 🆘 Troubleshooting

**Images not uploading?**
- Check AWS credentials are set correctly
- Verify S3 bucket exists and has proper permissions
- Check Rails logs: `tail -f log/development.log`

**Background jobs not running?**
- Ensure Redis is running: `redis-cli ping` (should return "PONG")
- Check Sidekiq is started: Look for process with `ps aux | grep sidekiq`
- View Sidekiq logs: `tail -f log/sidekiq.log`

**Can't access Sidekiq web UI?**
- Only available in development mode
- Visit: http://localhost:3000/sidekiq
- For production, add authentication middleware

## 🎉 You're All Set!

The system is now ready to handle image uploads and tip tracking. Just:
1. Start Redis
2. Configure AWS credentials
3. Start Sidekiq worker
4. Start Rails server
5. Test the API!
