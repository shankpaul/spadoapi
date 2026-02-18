# Route Calculation API Documentation

## Overview

The Route Calculation API calculates the best driving route between any two locations using Google Maps Directions API. This endpoint is useful for:
- Getting accurate road distance (not straight-line)
- Viewing estimated travel time
- Getting turn-by-turn navigation
- Plotting routes on maps in mobile apps

## Endpoint

```
POST /api/v1/routes/calculate
```

**Authentication:** Required (JWT Token)

## Setup

### 1. Configure Google Maps API Key

You need a Google Maps Directions API key from Google Cloud Console.

**Edit Rails credentials:**

```bash
cd /Users/shan/works/spado/spado-api
EDITOR="code --wait" rails credentials:edit
```

**Add the following:**

```yaml
google_maps:
  api_key: YOUR_GOOGLE_MAPS_API_KEY
```

**Or set as environment variable:**

```bash
export GOOGLE_MAPS_API_KEY="your_api_key_here"
```

### 2. Enable Google Maps Directions API

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Enable **Directions API**
3. Create/use an API key
4. Set billing (Google requires billing for Directions API)
5. (Optional) Restrict API key to Directions API only for security

## Request

### Parameters

| Parameter | Type | Required | Description |
|-----------|------|----------|-------------|
| `from_latitude` | Float | Yes | Starting location latitude |
| `from_longitude` | Float | Yes | Starting location longitude |
| `to_latitude` | Float | Yes | Destination location latitude |
| `to_longitude` | Float | Yes | Destination location longitude |

### Example Request

**cURL:**

```bashroutes/calculate" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "from_latitude": 12.9716,
    "from_longitude": 77.5946,
    "to_latitude": 12.9352,
    "to_longitude": 77.6245
  }'
```

**JavaScript/Fetch:**

```javascript
const response = await fetch('/api/v1/routes/calculate', {
  method: 'POST',
  headers: {
    'Authorization': `Bearer ${token}`,
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    from_latitude: 12.9716,
    from_longitude: 77.5946,
    to_latitude: 12.9352,
    to_longitude: 77.6245
  })
});

const data = await response.json();
```

**React Native Example:**

```javascript
const calculateRoute = async (fromLocation, toLocation) => {
  try {
    const response = await fetch(
      `${API_BASE_URL}/api/v1/routes/calculate`,
      {
        method: 'POST',
        headers: {
          'Authorization': `Bearer ${authToken}`,
          'Content-Type': 'application/json'
        },
        body: JSON.stringify({
          from_latitude: fromLocation.latitude,
          from_longitude: fromLocation.longitude,
          to_latitude: toLocation.latitude,
          to_longitude: toocation.latitude,
          current_longitude: currentLocation.longitude
        })
      }
    );

    const result = await response.json();
    
    if (result.success) {
      // Use result.route to display on map
      return result;
    }
  } catch (error) {
    console.error('Route calculation failed:', error);
  }
};
```

## Response
 "address": "123 MG Road, Koramangala, Bangalore, Karnataka",
    "coordinates": {
      "latitude": 12.9352,
      "longitude": 77.6245
    }
  },
  "route": {
    "distance_km": 5.2,
    "distance_text": "5.2 km",
    "duration_minutes": 18,
    "duration_text": "18 mins",
    "start_address": "Indiranagar, Bengaluru, Karnataka, India",
    "end_address": "Koramangala, Bengaluru, Karnataka, India",
    
    "overview_polyline": "encoded_polyline_string_here",
    
    "steps": [
      {
        "distance": {
          "value": 245,
          "text": "245 m"
        },
        "duration": {
          "value": 60,
          "text": "1 min"
        },
        "start_location": {
          "lat": 12.9716,
          "lng": 77.5946
        },
        "end_location": {
          "lat": 12.9739,
          "lng": 77.5968
        },
        "html_instructions": "Head <b>northeast</b> on <b>100 Feet Rd</b>",
        "travel_mode": "DRIVING",
        "polyline": "step_polyline_string",
        "maneuver": "turn-left"
      }
    ],
    
    "bounds": {
      "northeast": {
        "lat": 12.9716,
        "lng": 77.6245
      },
      "southwest": {
        "lat": 12.9352,
        "lng": 77.5946
      }
    },
    
    "copyrights": "Map data ©2026 Google"
  },
  "summary": {
    "distance": "5.2 km",
    "estimated_time": "18 minutes",
    "message": "Best route calculated successfully"
  }
}
```

### Field Descriptions

#### route.overview_polyline
- Encoded polyline string representing the entire route
- Use Google Maps Polyline Decoder to decode for map display
- Most efficient way to draw the route on a map

#### route.steps
- Array of turn-by-turn navigation instructions
- Each step contains:
  - **distance**: How far for this step
  - **duration**: How long this step takes
  - **start_location/end_location**: GPS coordinates
  - **html_instructions**: Human-readable directions
  - **polyline**: Encoded polyline for this step only
  - **maneuver**: Turn type (turn-left, turn-right, etc.)

#### route.bounds
- Map viewport boundaries
- Use to automatically zoom/pan map to show entire route

## Error Responses

### Missing Parameters (422)

```json
{
  "error": "Current latitude and longitude are required"
}
```

### Order WiStarting location (from_latitude and from_longitude) is required"
}
```

Or:

```json
{
  "error": "Destination location (to_latitude and to_longitude) is required

```json
{
  "success": false,
  "error": "Google Maps API error: ZERO_RESULTS"
}
```

### Server Error (500)

```json
{
  "success": false,
  "error": "Failed to calculate route: Connection timeout"
}
```

## Mobile App Integration

### React Native with Google Maps

```javascript
import MapView, { Polyline, Marker } from 'react-native-maps';
import Polyline from '@mapbox/polyline';

const decodePolyline = (encoded) => {
  return Polyline.decode(encoded).map(([lat, lng]) => ({
    latitude: lat,
    longitude: lng
  }));
};

const RouteMap = ({ routeData }) => {
  const routeCoordinates = decodePolyline(routeData.route.overview_polyline);
  
  return (
    <MapView
      initialRegion={{
        latitude: routeData.order.coordinates.latitude,
        longitude: routeData.order.coordinates.longitude,
        latitudeDelta: 0.1,
        longitudeDelta: 0.1
      }}
    >
      {/* Route polyline */}
      <Polyline
        coordinates={routeCoordinates}
        strokeColor="#4285F4"
        strokeWidth={4}
      />
      
      {/* Start marker */}
      <Marker
        coordinate={routeCoordinates[0]}
        title="Your Location"
        pinColor="green"
      />
      
      {/* End marker */}
      <Marker
        coordinate={routeData.order.coordinates}
        title={routeData.order.customer_name}
        description={routeData.order.address}
        pinColor="red"
      />
    </MapView>
  );
};
```

### Flutter Integration

```dart
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';

Future<void> displayRoute(Map<String, dynamic> routeData) async {
  // Decode polyline
  PolylinePoints polylinePoints = PolylinePoints();
  List<PointLatLng> result = polylinePoints.decodePolyline(
    routeData['route']['overview_polyline']
  );
  
  List<LatLng> polylineCoordinates = result
      .map((point) => LatLng(point.latitude, point.longitude))
      .toList();
  
  // Create polyline
  Polyline polyline = Polyline(
    polylineId: PolylineId('route'),
    color: Colors.blue,
    points: polylineCoordinates,
    width: 5,
  );
  
  // Add markers
  Marker startMarker = Marker(
    markerId: MarkerId('start'),
    position: polylineCoordinates.first,
    infoWindow: InfoWindow(title: 'Your Location'),
  );
  
  Marker endMarker = Marker(
    markerId: MarkerId('end'),
    position: LatLng(
      routeData['order']['coordinates']['latitude'],
      routeData['order']['coordinates']['longitude']
    ),
    infoWindow: InfoWindow(
      title: routeData['order']['customer_name'],
      snippet: routeData['order']['address']
    ),
  );
  
  // Update map
  setState(() {
    _polylines.add(polyline);
    _markers.add(startMarker);
    _markers.add(endMarker);
  });
}
```

## Usage Workflow

### Agent Navigation Flow

1. **Agent opens order details**
   - Sees customer address and basic info

2. **Agent requests route**
   - App gets current GPS location
   - Calls `POST /api/v1/orders/:id/route_to_order`
   - Sends current lat/lng

3. **Display route summary**
   ```
   Distance: 5.2 km or navigation view**
   - Gets order/destination coordinates

2. **Agent requests route**
   - App gets current GPS location
   - Calls `POST /api/v1/routes/calculate`
   - Sends from/to coordinatesline`
   - Draw route line on map
   - Add start/end markers
   - Auto-zoom to show entire route

5. **Navigation (optional)**
   - Use `steps` array for turn-by-turn
   - Or deep-link to Google Maps/Apple Maps

### Deep Link to Native Maps

```javascript
// Open in Google Maps app
const openInGoogleMaps = (routeData) => {
  const origin = `${currentLat},${currentLng}`;
  const destination = `${routeData.order.coordinates.latitude},${routeData.order.coordinates.longitude}`;
  
  const url = `https://www.google.com/maps/dir/?api=1&origin=${origin}&destination=${destination}&travelmode=driving`;
  
  Linking.openURL(url);
};

// Open in Apple Maps
const openInAppleMaps = (routeData) => {
  const url = `http://maps.apple.com/?saddr=${currentLat},${currentLng}&daddr=${routeData.order.coordinates.latitude},${routeData.order.coordinates.longitude}`;
  
  Linking.openURL(url);
};
```

## Performance Considerations

1. **Caching**: Consider caching route data for 5-10 minutes
2. **Rate Limits**: Google Maps has API quotas and rate limits
3. **Cost**: Directions API charges per request (check Google pricing)
4. **Network**: Handle offline scenarios gracefully
5. **Alternative**: Store calculated routes temporarily to avoid recalculation

## Security Notes

1. **API Key Protection**:
   - Never commit API key to version control
   - Use Rails credentials or environment variables
   - Restrict API key to Directions API only

2. **Rate Limiting**:
   - Implement rate limiting on endpoint
   - Log usage for monitoring

3. **Authorization**:
   - Only authenticated users can access
   - Agents can only access their assigned orders (enforce in `set_order`)

## Testing

### Test in Rails Console

```ruby
rails console

# Test the service directly
service = GoogleMapsService.new
result = service.calculate_route(12.9716, 77.5946, 12.9352, 77.6245)

puts result[:distance][:kilometers]  # => 5.2
puts result[:duration][:minutes]     # => 18
```

### Test via API

```bash
# Get an order with valid coordinates
curl -X POST "http://localhost:3000/api/v1/orders/123/route_to_order" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"current_latitude": 12.9716, "current_longitude": 77.5946}'
```

## Troubleshooting

### Error: Google Maps API key not configured

**Solution:** Add API key to Rails credentials or set `GOOGLE_MAPS_API_KEY` env variable

### Error: REQUEST_DENIED

**Causes:**
- Invalid API key
- Directions API not enabled
- Billing not set up
- API key restrictions too strict

**Solution:** Check Google Cloud Console settings

### Error: ZERO_RESULTS

**Causes:**
- Invalid coordinates
- No route available between points
- Coordinates are too far apart

### Error: OVER_QUERY_LIMIT

**Cause:** Exceeded API quota

**Solution:** 
- Check usage in Google Cloud Console
- Increase quota or implement caching

## Cost Optimization

1. **Client-side caching**: Cache routes for 5-10 minutes
2. **Batch requests**: If querying multiple orders, consider batching
3. **Fallback to straight-line**: Show straight-line distance for non-critical views
4. **User-triggered**: Only calculate when user explicitly requests route

## Future Enhancements

- [ ] Alternative routes support
- [ ] Traffic-aware routing
- [ ] Avoid tolls/highways options
- [ ] Waypoints for multiple stops
- [ ] Real-time route updates
- [ ] ETA notifications
- [ ] Route history tracking
