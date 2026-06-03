# 🧪 Room API Testing with cURL

## API Base URL
```
http://209.50.241.46:2000/api
```

## Test Commands

### 1. Get Hotel Details (includes room_types)
```bash
curl -X GET "http://209.50.241.46:2000/api/hotel-details/1" \
  -H "Content-Type: application/json"
```

### 2. Get Specific Room Type Gallery
```bash
curl -X GET "http://209.50.241.46:2000/api/room-types/1/gallery" \
  -H "Content-Type: application/json"
```

### 3. Get Room Type Videos
```bash
curl -X GET "http://209.50.241.46:2000/api/room-types/1/videos" \
  -H "Content-Type: application/json"
```

## Expected Room Type Data Structure

Based on the code, the API should return `room_types` array with these fields:

```json
{
  "room_types": [
    {
      "id": 1,
      "name": "Deluxe Room",
      "images": ["url1", "url2", "url3"],
      "base_price": 3000,
      "effective_price": 2500,
      "weekend_price": 3500,
      "is_available": true,
      "max_adults": 2,
      "max_children": 1,
      "room_size_sqft": 300,
      "bed_type": "King Bed",
      "amenities": ["WiFi", "AC", "TV", "Minibar"],
      "hourly_available": true,
      "hourly_price": 500,
      "min_hours": 3,
      "max_hours": 12,
      "currency": "INR",
      "description": "Spacious deluxe room with modern amenities"
    }
  ]
}
```

## How to Run Tests

### Windows PowerShell:
```powershell
# Test hotel details
Invoke-WebRequest -Uri "http://209.50.241.46:2000/api/hotel-details/1" -Method GET | Select-Object -ExpandProperty Content

# Test room gallery
Invoke-WebRequest -Uri "http://209.50.241.46:2000/api/room-types/1/gallery" -Method GET | Select-Object -ExpandProperty Content
```

### Using curl (if installed):
```bash
curl "http://209.50.241.46:2000/api/hotel-details/1"
curl "http://209.50.241.46:2000/api/room-types/1/gallery"
```

## Fields Currently Used in App

The app extracts these fields from `room_types`:

1. **Basic Info**:
   - `id` - Room type ID
   - `name` - Room type name
   - `images` - Array of image URLs (first one used as thumbnail)

2. **Pricing**:
   - `base_price` - Regular price
   - `effective_price` - Current/discounted price
   - `weekend_price` - Weekend pricing
   - `hourly_price` - Price per hour (if hourly booking available)

3. **Availability**:
   - `is_available` - Boolean availability status
   - `hourly_available` - Boolean for hourly booking support

4. **Capacity**:
   - `max_adults` - Maximum adults allowed
   - `max_children` - Maximum children allowed

5. **Room Details**:
   - `room_size_sqft` - Room size in square feet
   - `bed_type` - Type of bed (King, Queen, etc.)
   - `amenities` - Array of amenity strings

6. **Hourly Booking**:
   - `min_hours` - Minimum hours for hourly booking
   - `max_hours` - Maximum hours for hourly booking
   - `currency` - Currency code (INR, USD, etc.)

## Missing Fields (Optional Enhancements)

Consider adding these to the API response:

- `description` - Detailed room description
- `max_occupancy` - Total maximum occupancy
- `view_type` - Room view (City, Garden, Pool, etc.)
- `floor_range` - Available floors
- `smoking_allowed` - Boolean
- `pets_allowed` - Boolean
- `cancellation_policy` - Policy details
- `check_in_time` - Room-specific check-in
- `check_out_time` - Room-specific check-out
- `videos` - Array of video URLs
- `virtual_tour_url` - 360° tour link
- `room_features` - Detailed features object
- `bathroom_type` - Bathroom details
- `balcony` - Boolean
- `wifi_speed` - WiFi speed info

---

**Run these commands to see actual API responses!**
