# Authentication Token Test

## Issue
User is getting 302 redirect to `/login` when trying to create a booking, indicating the auth token is invalid or expired.

## Test Steps

### 1. Check if user is logged in
Ask the user to:
1. Open the app
2. Check if they see their profile/name in the app
3. Try to navigate to "My Trips" or "Profile" screen

### 2. Test the auth token with curl
If user can provide their auth token from SharedPreferences, test it:

```bash
# Replace YOUR_TOKEN_HERE with actual token
curl -X GET "http://209.50.241.46:2000/api/my-bookings" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -v
```

Expected responses:
- **200 OK**: Token is valid
- **302 Redirect to /login**: Token is invalid/expired
- **401 Unauthorized**: Token is invalid

### 3. Test booking creation with valid token
```bash
curl -X POST "http://209.50.241.46:2000/api/create-booking" \
  -H "Authorization: Bearer YOUR_TOKEN_HERE" \
  -H "Content-Type: application/json" \
  -d '{
    "hotel_id": "4",
    "room_type_id": "9",
    "check_in_date": "2026-04-15",
    "check_out_date": "2026-04-16",
    "adults": 2,
    "children": 0,
    "room_count": 1,
    "special_requests": ""
  }' \
  -v
```

## Possible Causes

1. **Token expired**: Laravel tokens may have expiration time
2. **Token not saved**: Login might not be saving token correctly
3. **Token format wrong**: Token might be missing "Bearer " prefix or have extra characters
4. **Session-based auth**: API might be using session cookies instead of token auth

## Fixes Applied

1. ✅ Added 302 redirect detection in `booking_service.dart`
2. ✅ Added better error handling for auth failures
3. ✅ Added debug logging to track token loading
4. ✅ Updated payment screen to show "Session expired" message and redirect to login
5. ✅ Configured Dio to not follow redirects (treat 302 as error)

## Next Steps

1. User should try logging out and logging back in
2. Check the console logs for token information when booking is attempted
3. If token is valid but still getting 302, the API might require additional headers or cookies
