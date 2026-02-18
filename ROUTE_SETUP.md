# Route Calculation API - Quick Setup

## ✅ What's Been Implemented

### 1. Google Maps Service Integration
- ✅ Created `GoogleMapsService` class for Directions API integration
- ✅ Calculates optimal driving routes
- ✅ Returns distance, duration, polyline, and turn-by-turn steps
- ✅ Error handling and logging

### 2. API Endpoint
- ✅ **Route:** `POST /api/v1/routes/calculate`
- ✅ **Parameters:** `from_latitude`, `from_longitude`, `to_latitude`, `to_longitude`
- ✅ **Authorization:** JWT authentication required
- ✅ **Returns:** Route details with polyline for map plotting

### 3. Response Data
```json
{
  "success": true,
  "route": {
    "distance_km": 5.2,
    "duration_minutes": 18,
    "overview_polyline": "encoded_string",
    "steps": [...],
    "bounds": {...}
  }
}
```

## 🚀 Setup Steps

### 1. Install Dependencies
```bash
cd /Users/shan/works/spado/spado-api
bundle install  # HTTParty gem already installed ✓
```

### 2. Get Google Maps API Key

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create/select a project
3. Enable **Directions API**
4. Create API Key
5. **Important:** Set up billing (required for Directions API)
6. (Optional) Restrict key to Directions API only

### 3. Configure API Key

**Option A: Rails Credentials (Recommended)**
```bash
cd /Users/shan/works/spado/spado-api
EDITOR="code --wait" rails credentials:edit
```

Add:
```yaml
google_maps:
  api_key: YOUR_GOOGLE_MAPS_API_KEY_HERE
```

Save and close.

**Option B: Environment Variable**
```bash
export GOOGLE_MAPS_API_KEY="your_api_key_here"
```

### 4. Test the API

**Using cURL:**
```bash
curl -X POST "http://localhost:3000/api/v1/routes/calculate" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "from_latitude": 12.9716,
    "from_longitude": 77.5946,
    "to_latitude": 12.9352,
    "to_longitude": 77.6245
  }'
```

**Expected Response:**
```json
{ "address": "..."
  },
  "route": {
    "distance_km": 5.2,
    "duration_minutes": 18,
    "overview_polyline": "...",
    "steps": [...]
  },
  "summary": {
    "distance": "5.2 km",
    "estimated_time": "18 minutes"
  }
}
```

## 📱 Mobile App Integration

### React Native Example

```javascript
// Request route
const getRouteToOrder = async (orderId, currentLocation) => {
  const response = await fetch(
    `${API_URL}/api/v1/orders/${orderId}/route_to_order`,
    {
      method: 'POST',
      headers: {
        'Authorization': `Bearer ${token}`,
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        current_latitude: currentLocation.latitude,
        current_longitude: currentLocation.longitude
      })
    }
  );
  
  return await response.json();
};

// Decode polyline and display on map
import Polyline from '@mapbox/polyline';

const routeCoordinates = Polyline.decode(
  routeData.route.overview_polyline
).map(([lat, lng]) => ({
  latitude: lat,
  longitude: lng
}));

// Use with react-native-maps
<Polyline
  coordinates={routeCoordinates}
  strokeColor="#4285F4"
  strokeWidth={4}
/>
```

### Deep Link to Google Maps

```javascript
// Open route in Google Maps app
const openNavigationApp = (routeData) => {
  const url = `https://www.google.com/maps/dir/?api=1&origin=${currentLat},${currentLng}&destination=${destLat},${destLng}&travelmode=driving`;
  
  Linking.openURL(url);
};
```

## 📊 API Features

| Feature | Status | Description |
|---------|--------|-------------|
| Distance Calculation | ✅ | Road distance in km |
| Duration Estimate | ✅ | Travel time in minutes |
| Route Polyline | ✅ | Encoded string for map plotting |
| Turn-by-Turn Steps | ✅ | Navigation instructions |
| Map Bounds | ✅ | Viewport coordinates |
| Best Route | ✅ | Optimized driving route |
| Traffic Data | ⚠️ | Available with premium API |

## 🔒 Security Notes

1. **Never commit API keys** to version control
2. **Use Rails credentials** or environment variables
3. **Restrict API key** to Directions API in Google Cloud Console
4. **Monitor usage** to avoid unexpected charges
5. **Implement rate limiting** if needed

## 💰 Cost Considerations

**Google Maps Directions API Pricing (as of 2024):**
- $5 per 1,000 requests
- $200 free credit per month
- ~40,000 free requests/month

**Optimization Tips:**
- Cache routes for 5-10 minutes
- Only calculate when user explicitly requests
- Use straight-line distance for less critical views

## 📂 New Files Created

```
spado-api/
├── app/
│   └── services/
│       └── google_maps_service.rb       # Google Maps API integration
├── app/controllers/api/v1/
│   └── orders_controller.rb             # Added route_to_order method
├── config/
│   └── routes.rb                         # Added POST /orders/:id/route_to_order
├── Gemfile                               # Added httparty gem
├── ROUTE_CALCULATION_API.md             # Full API documentation
└── ROUTE_SETUP.md                       # This file
```

## 🧪 Testing

### 1. Test Service in Console

```ruby
rails console

# Test Google Maps service
service = GoogleMapsService.new
result = service.calculate_route(
  12.9716, 77.5946,  # Origin
  12.9352, 77.6245   # Destination
)

puts "Distance: #{result[:distance][:kilometers]} km"
puts "Duration: #{result[:duration][:minutes]} minutes"
```

### 2. Test API Endpoint

Make sure:
- Order exists with valid latitude/longitude
- You have a valid JWT token
- Google Maps API key is configured

```bash
# Get JWT token first
TOYou have a valid JWT token
- Google Maps API key is configured

```bash
# Get JWT token first
TOKEN=$(curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"agent@example.com","password":"password"}' \
  | jq -r .token)

# Test route calculation
curl -X POST "http://localhost:3000/api/v1/routes/calculate" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "from_latitude": 12.9716,
    "from_longitude": 77.5946,
    "to_latitude": 12.9352,
    "to_longitude": 77.6245not configured"
**Solution:** Add API key to credentials or set environment variable

### Error: "REQUEST_DENIED"
**Causes:**
- API key invalid
- Directions API not enabled
- Billing not configured

**Solution:** Check Google Cloud Console

### Error: "OrUse the generic `/api/v1/routes/calculate` endpoint with explicit coordinates
**Solution:** Ensure order has latitude and longitude set

### Error: "ZERO_RESULTS"
**Solution:** Check coordinates are valid and reachable

## 📖 Full Documentation

See [ROUTE_CALCULATION_API.md](./ROUTE_CALCULATION_API.md) for:
- Complete API reference
- Mobile app integration examples (React Native, Flutter)
- Error handling
- Cost optimization strategies
- Security best practices

## ✨ Usage Summary

**FGet current GPS location in mobile app
2. Get destination coordinates (from order or manually)
3. Call `/api/v1/routes/calculate`utton
3. App fetches route from API
4. Route displayed on map with distance/time
5. Option to open in Google Maps for navigation

**Benefits:**
- Accurate road distance (not straight-line)
- Real-time traffic considerations (with premium API)
- Turn-by-turn navigation
- Better route planning

## 🎉 You're Ready!

Just add your Google Maps API key and test the endpoint. The mobile app can now:
- Calculate accurate routes
- Display routes on maps
- Show distance and duration
- Provide navigation capabilities
