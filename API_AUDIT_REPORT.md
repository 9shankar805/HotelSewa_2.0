# API Audit Report - All Screens

## Executive Summary
Comprehensive audit of all API integrations across the HotelSewa Flutter app.

**Status**: ✅ Most APIs working | ⚠️ Some screens need verification

---

## 1. Authentication Screens

### ✅ Login Screen (`login_screen.dart`)
- **API**: `/user-signup` (POST) with type='email'
- **Service**: `AuthService.login()`
- **Status**: Working
- **Error Handling**: ✅ DioException caught
- **Token Management**: ✅ Saves to SharedPreferences

### ✅ Signup Screen (`signup_screen.dart`)
- **API**: `/user-signup` (POST)
- **Service**: `AuthService.signup()`
- **Status**: Working
- **Error Handling**: ✅ DioException caught

### ✅ OTP Login Screen (`otp_login_screen.dart`)
- **API**: `/get-otp` (GET), `/verify-otp` (GET)
- **Service**: `AuthService.requestOtp()`, `AuthService.verifyOtp()`
- **Status**: Working
- **Error Handling**: ✅ DioException caught

### ✅ Forgot Password Screen
- **API**: `/get-otp` (GET), `/verify-otp` (GET)
- **Service**: `AuthService.requestPasswordReset()`
- **Status**: Working

### ✅ Google Sign-In
- **API**: `/user-signup` (POST) with type='google'
- **Service**: `AuthService.googleLogin()`
- **Status**: Working

---

## 2. Hotel Browsing Screens

### ✅ Home Screen (`home_screen.dart`)
- **APIs**:
  - `/get-home-data` (GET) - cacheTtl: 5 min
  - `/get-slider` (GET) - cacheTtl: 10 min
  - `/get-featured-section` (GET) - cacheTtl: 10 min
  - `/hotels` (GET) - cacheTtl: 5 min
- **Services**: `HomeService`, `HotelService`
- **Status**: ✅ Working
- **Error Handling**: ✅ Silent failures with {success: false}

### ✅ Hotel List Screen (`hotel_list_screen.dart`)
- **API**: `/hotels` (GET) with filters
- **Service**: `HotelService.getHotels()`
- **Status**: ✅ Working (returns 6 hotels)
- **Error Handling**: ✅ DioException caught
- **Caching**: 5 minutes

### ✅ Hotel Details Screen (`hotel_details_screen.dart`)
- **API**: `/hotel-details/{id}` (GET)
- **Service**: `HotelService.getHotelDetails()`
- **Status**: ✅ Working (returns room types)
- **Error Handling**: ✅ DioException caught
- **Caching**: 30 minutes

### ⚠️ Hotel Policies Screen
- **API**: `/hotel-policies/{id}` (GET)
- **Service**: `HotelService.getHotelPolicies()`
- **Status**: ⚠️ Needs verification
- **Caching**: 60 minutes

### ⚠️ Nearby Hotels Screen
- **API**: `/hotels/nearby` (GET)
- **Service**: `HotelService.getNearbyHotels()`
- **Status**: ⚠️ Needs verification
- **Parameters**: latitude, longitude, radius

---

## 3. Booking Screens

### ✅ Booking Form Screen (`booking_form_screen.dart`)
- **API**: `/create-booking` (POST)
- **Service**: `BookingService.createBooking()`
- **Status**: ✅ Working (backend fix applied)
- **Error Handling**: ✅ DioException caught
- **Required Fields**:
  - hotel_id, room_type_id
  - check_in_date, check_out_date (YYYY-MM-DD format)
  - adults, children, room_count
  - guest_name, guest_email, guest_phone
  - total_amount, payment_method, status

### ✅ My Trips Screen (`my_trips_screen.dart`)
- **API**: `/my-bookings` (GET)
- **Service**: `BookingService.getMyBookings()`
- **Status**: ✅ Working
- **Error Handling**: ✅ DioException caught
- **Auth**: ✅ Requires Bearer token

### ⚠️ Booking Cancellation
- **API**: `/cancel-booking/{id}` (POST)
- **Service**: `BookingService.cancelBooking()`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

### ⚠️ Price Preview Screen
- **API**: `/preview-price` (GET)
- **Service**: `BookingService.previewPrice()`
- **Status**: ⚠️ Needs verification

---

## 4. Payment Screens

### ⚠️ Payment Screen (`payment_screen.dart`)
- **APIs**:
  - `/get-payment-settings` (GET)
  - `/payment-intent` (POST)
  - `/payment/khalti/initiate` (POST)
  - `/payment/esewa/initiate` (POST)
- **Service**: `PaymentService`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

### ⚠️ Payment Confirmation
- **API**: `/confirm-payment` (POST)
- **Service**: `BookingService.confirmPayment()`
- **Status**: ⚠️ Needs verification

---

## 5. Review Screens

### ⚠️ Hotel Reviews Screen (`hotel_reviews_screen.dart`)
- **API**: `/hotel-details/{id}` (GET) - reviews embedded
- **Service**: `ReviewService.getHotelReviews()`
- **Status**: ⚠️ Needs verification

### ⚠️ Rate Stay Screen (`rate_stay_screen.dart`)
- **API**: `/rate-hotel` (POST)
- **Service**: `ReviewService.submitReview()`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

### ⚠️ My Reviews Screen
- **API**: `/my-review` (GET)
- **Service**: `ReviewService.getMyReviews()`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

---

## 6. In-Stay Ordering Screens

### ⚠️ Menu Screen (`menu_screen.dart`)
- **API**: `/hotels/{hotelId}/menu` (GET)
- **Service**: `OrderService.getHotelMenu()`
- **Status**: ⚠️ Needs verification
- **Auth**: ❌ Public endpoint

### ⚠️ Cart Screen (`cart_screen.dart`)
- **API**: `/orders/place` (POST)
- **Service**: `OrderService.placeOrder()`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

### ⚠️ My Orders Screen (`my_orders_screen.dart`)
- **API**: `/orders/my-orders` (GET)
- **Service**: `OrderService.getMyOrders()`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token
- **Optional**: booking_id filter

### ⚠️ Order Cancellation
- **API**: `/orders/{id}/cancel` (POST)
- **Service**: `OrderService.cancelOrder()`
- **Status**: ⚠️ Needs verification

---

## 7. Profile & Account Screens

### ⚠️ Profile Screen (`profile_screen.dart`)
- **API**: Reads from SharedPreferences (cached user data)
- **Status**: ✅ Working (no API call)
- **Data Source**: Cached from login response

### ⚠️ Loyalty Program Screen (`loyalty_program_screen.dart`)
- **APIs**:
  - `/loyalty/balance` (GET)
  - `/loyalty/referral-code` (GET)
  - `/loyalty/apply-referral` (POST)
- **Service**: `LoyaltyService`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

### ⚠️ Referral History Screen
- **API**: `/loyalty/referral-code` (GET)
- **Service**: `LoyaltyService.getReferralCode()`
- **Status**: ⚠️ Needs verification

### ⚠️ Delete Account Screen
- **API**: `/delete-user` (DELETE)
- **Service**: `AuthService.deleteAccount()`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

---

## 8. Favorites Screen

### ⚠️ Saved Screen (`saved_screen.dart`)
- **APIs**:
  - `/get-favourite-item` (GET)
  - `/manage-favourite` (POST) - add/remove
- **Service**: `FavoriteService`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

---

## 9. Notifications Screen

### ⚠️ Notifications Screen (`notifications_screen.dart`)
- **APIs**:
  - `/get-notification-list` (GET)
  - `/notifications/{id}/read` (PUT)
  - `/notifications/read-all` (PUT)
  - `/notifications/{id}` (DELETE)
- **Service**: `NotificationService`
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

---

## 10. Support Screens

### ⚠️ Support Ticket Screen (`support_ticket_screen.dart`)
- **APIs**:
  - `/support/tickets` (GET, POST)
  - `/support/tickets/{id}` (GET)
- **Status**: ⚠️ Needs verification
- **Auth**: ✅ Requires Bearer token

### ⚠️ Support Chat Screen
- **API**: `/support/chat/{token}/message` (POST)
- **Status**: ⚠️ Needs verification

---

## 11. Other Screens

### ⚠️ Online Check-in Screen (`online_checkin_screen.dart`)
- **API**: Unknown - needs investigation
- **Status**: ❌ Not documented

### ⚠️ Contact Us Screen
- **API**: `/contact-us` (POST)
- **Service**: `HomeService.contactUs()`
- **Status**: ⚠️ Needs verification

### ⚠️ FAQ Screen
- **API**: `/faq` (GET)
- **Service**: `HomeService.getFaqs()`
- **Status**: ⚠️ Needs verification
- **Caching**: 60 minutes

### ⚠️ Tips Screen
- **API**: `/tips` (GET)
- **Service**: `HomeService.getTips()`
- **Status**: ⚠️ Needs verification
- **Caching**: 60 minutes

### ⚠️ Blogs Screen
- **API**: `/blogs` (GET)
- **Service**: `HomeService.getBlogs()`
- **Status**: ⚠️ Needs verification
- **Caching**: 15 minutes

---

## Common Issues Found

### 1. ❌ Inconsistent Error Handling
**Problem**: Some services return silent failures without error messages
```dart
// HomeService - no error message
return {'success': false};
```
**Recommendation**: Add descriptive error messages

### 2. ⚠️ Token Management
**Problem**: Each service manually loads token
```dart
Future<void> _setToken() async {
  final prefs = await SharedPreferences.getInstance();
  final token = prefs.getString('authToken');
  if (token != null) _api.setAuthToken(token);
}
```
**Recommendation**: Centralize token management in ApiService

### 3. ⚠️ Response Data Parsing
**Problem**: Inconsistent response structure handling
```dart
// Multiple ways to extract data
final data = response.data is Map ? response.data['data'] : response.data;
List bookings = (raw['data'] ?? raw['bookings'] ?? raw['items'] ?? []) as List;
```
**Recommendation**: Standardize backend response format

### 4. ❌ Missing Null Safety
**Problem**: Some fields accessed without null checks
```dart
booking['hotel']?['name'] ?? 'Hotel'  // Good
booking['hotel']['name']  // Bad - can throw
```

### 5. ⚠️ Hardcoded Timeouts
**Problem**: 30-second timeout for all requests
```dart
connectTimeout: const Duration(seconds: 30),
receiveTimeout: const Duration(seconds: 30),
```
**Recommendation**: Make configurable per endpoint

---

## Testing Recommendations

### Priority 1 - Critical Screens (Test First)
1. ✅ Login/Signup - WORKING
2. ✅ Hotel List - WORKING
3. ✅ Hotel Details - WORKING
4. ✅ Booking Creation - WORKING
5. ✅ My Trips - WORKING

### Priority 2 - Important Features
6. ⚠️ Payment Flow - NEEDS TESTING
7. ⚠️ In-Stay Ordering - NEEDS TESTING
8. ⚠️ Reviews - NEEDS TESTING
9. ⚠️ Loyalty Program - NEEDS TESTING

### Priority 3 - Secondary Features
10. ⚠️ Favorites - NEEDS TESTING
11. ⚠️ Notifications - NEEDS TESTING
12. ⚠️ Support Tickets - NEEDS TESTING

---

## Test Script

Run these curl commands to verify each endpoint:

```bash
# 1. Get auth token
curl -X GET "http://209.50.241.46:2000/api/get-otp?mobile=YOUR_PHONE"
curl -X GET "http://209.50.241.46:2000/api/verify-otp?mobile=YOUR_PHONE&otp=YOUR_OTP"

# 2. Test hotels
curl -X GET "http://209.50.241.46:2000/api/hotels"
curl -X GET "http://209.50.241.46:2000/api/hotel-details/1"

# 3. Test booking
curl -X POST "http://209.50.241.46:2000/api/create-booking" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"hotel_id":"1","room_type_id":"1","check_in_date":"2026-04-20","check_out_date":"2026-04-22","adults":2,"children":0,"room_count":1,"guest_name":"Test","guest_email":"test@test.com","guest_phone":"+977","total_amount":17000,"payment_method":"card","status":"confirmed"}'

# 4. Test my bookings
curl -X GET "http://209.50.241.46:2000/api/my-bookings" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 5. Test menu
curl -X GET "http://209.50.241.46:2000/api/hotels/1/menu"

# 6. Test loyalty
curl -X GET "http://209.50.241.46:2000/api/loyalty/balance" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 7. Test favorites
curl -X GET "http://209.50.241.46:2000/api/get-favourite-item" \
  -H "Authorization: Bearer YOUR_TOKEN"

# 8. Test notifications
curl -X GET "http://209.50.241.46:2000/api/get-notification-list" \
  -H "Authorization: Bearer YOUR_TOKEN"
```

---

## Summary

### ✅ Working (Verified)
- Authentication (Login, Signup, OTP)
- Hotel Browsing (List, Details)
- Booking Creation
- My Trips

### ⚠️ Needs Testing
- Payment Integration
- In-Stay Ordering
- Reviews & Ratings
- Loyalty Program
- Favorites
- Notifications
- Support Tickets

### ❌ Issues Found
- Inconsistent error handling
- Manual token management in each service
- Inconsistent response parsing
- Some missing null safety checks

### 📊 Statistics
- **Total Screens**: 30+
- **Total API Endpoints**: 50+
- **Total Service Files**: 13
- **Verified Working**: 5 screens
- **Needs Testing**: 25+ screens
