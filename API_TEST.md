# HotelSewa API Testing Guide

## Base URL
```
http://209.50.241.46:2000/api
```

## API Status: ✅ CONNECTED AND WORKING

The API is live and responding correctly. Hotels are being fetched successfully.

## Authentication
All authenticated endpoints require a Bearer token in the Authorization header:
```
Authorization: Bearer YOUR_TOKEN_HERE
```

## Test Results

### ✅ System Settings (Working)
```bash
curl -X GET "http://209.50.241.46:2000/api/get-system-settings"
```
Response: Success - Returns app configuration

### ✅ Hotels List (Working)
```bash
curl -X GET "http://209.50.241.46:2000/api/hotels"
```
Response: Success - Returns 6 hotels including:
- Hotel Yak & Yeti (ID: 1)
- Pokhara Grande Hotel (ID: 2)
- Chitwan Jungle Lodge (ID: 3)

### ✅ Hotel Details (Working)
```bash
curl -X GET "http://209.50.241.46:2000/api/hotel-details/1"
```
Response: Success - Returns hotel with room types

## Booking Flow

### Step 1: Get Auth Token
```bash
# Request OTP
curl -X GET "http://209.50.241.46:2000/api/get-otp?mobile=YOUR_PHONE"

# Verify OTP (returns token)
curl -X GET "http://209.50.241.46:2000/api/verify-otp?mobile=YOUR_PHONE&otp=YOUR_OTP"
```

### Step 2: Create Booking
```bash
curl -X POST "http://209.50.241.46:2000/api/create-booking" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "hotel_id": "1",
    "room_type_id": "1",
    "check_in_date": "2025-01-20",
    "check_out_date": "2025-01-22",
    "guests": 2,
    "guest_name": "John Doe",
    "guest_email": "john@example.com",
    "guest_phone": "+9779800000000",
    "special_requests": "Late check-in",
    "total_amount": 17000,
    "payment_method": "card",
    "status": "confirmed"
  }'
```

### Step 3: Get My Bookings
```bash
curl -X GET "http://209.50.241.46:2000/api/my-bookings" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Current App Behavior

### ✅ What's Working:
1. **API Connection** - App successfully connects to API
2. **Hotels Display** - Hotels fetched and displayed from API
3. **Booking Creation** - Booking data sent to API and persisted
4. **QR Code Generation** - QR codes generated from API booking response
5. **My Trips** - Displays bookings fetched from API
6. **Auto-fill Forms** - User profile data pre-fills booking forms

### ✅ API Endpoint Status:
- `/hotels` - ✅ Working (returns 6 hotels)
- `/hotel-details/{id}` - ✅ Working (returns room types)
- `/create-booking` - ✅ Working (backend fix applied - bookings persist correctly)
- `/my-bookings` - ✅ Working (returns user's bookings with all fields)

## Data Structure

### Hotel Object
```json
{
  "id": 1,
  "name": "Hotel Yak & Yeti",
  "city": "Kathmandu",
  "state": "Bagmati",
  "min_price": 6500,
  "max_price": 15000,
  "rating": 4.7,
  "total_reviews": 21
}
```

### Room Type Object
```json
{
  "id": 1,
  "name": "Deluxe Room",
  "base_price": 8500,
  "effective_price": 8500,
  "max_adults": 2,
  "max_children": 1,
  "is_available": true
}
```

### Booking Request Format
```json
{
  "hotel_id": "1",
  "room_type_id": "1",
  "check_in_date": "2025-01-20",
  "check_out_date": "2025-01-22",
  "guests": 2,
  "guest_name": "John Doe",
  "guest_email": "john@example.com",
  "guest_phone": "+9779800000000",
  "special_requests": "Late check-in",
  "total_amount": 17000,
  "payment_method": "card",
  "status": "confirmed"
}
```

## Troubleshooting

### Issue: Hotels not showing in app
**Solution**: ✅ FIXED - Hotels are fetched from API

### Issue: Bookings not persisting to database
**Status**: ✅ FIXED

**Backend Fix Applied**:
1. Added missing fillable fields to Booking model (`app/Models/Booking.php`):
   - `loyalty_points_redeemed`
   - `discount_from_points`
   - `referral_code_used`

2. Fixed transaction closure in HotelBookingController (`app/Http/Controllers/HotelBookingController.php`):
   - Added `$pointsRedeemed` and `$pointsDiscount` to `use` clause
   - Variables now properly available inside transaction

**Result**: 
- Bookings persist correctly to database with all fields
- `/my-bookings` endpoint returns complete booking data
- App displays bookings from API in My Trips screen

