# API Fixes Required - Critical Issues Found

## 🚨 CRITICAL ISSUE #1: Payment Screen Sending Wrong Fields

### Location
`lib/features/booking/presentation/payment_screen.dart` (Lines 106-108)

### Problem
```dart
'guest_name': '${_guestDetails['firstName']} ${_guestDetails['lastName']}',
'guest_email': _guestDetails['email'] ?? '',
'guest_phone': _guestDetails['phone'] ?? '',
```

### Why It's Wrong
According to the corrected API documentation, `/create-booking` does NOT accept these fields. The API uses `Auth::user()` to get guest information automatically from the authenticated user.

### Required Fields (Correct)
```dart
{
  'hotel_id': string,
  'room_type_id': string,
  'check_in_date': 'YYYY-MM-DD',
  'check_out_date': 'YYYY-MM-DD',
  'adults': int,
  'children': int (optional),
  'room_count': int (optional),
  'booking_type': 'nightly' or 'hourly' (optional),
  'redeem_points': int (optional),
  'referral_code': string (optional),
  'special_requests': string (optional)
}
```

### Fix Required
Remove lines 106-108 from payment_screen.dart

---

## 🚨 CRITICAL ISSUE #2: Notification Delete API Doesn't Exist

### Location
`lib/core/services/notification_service.dart` (Lines 49-62)

### Problem
```dart
Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
  // ...
  final response = await _api.delete('/notifications/$notificationId');
  // ...
}
```

### Why It's Wrong
According to the corrected API documentation, the DELETE endpoint for notifications does NOT exist. Only these endpoints are available:
- `PUT /notifications/{id}/read` - Mark as read
- `PUT /notifications/read-all` - Mark all as read

### Fix Required
Remove the `deleteNotification()` method entirely OR change it to mark as read instead of delete.

---

## ⚠️ ISSUE #3: QR Check-in Service Incomplete

### Location
`lib/core/services/qr_checkin_service.dart`

### Problem
Only 2 methods implemented:
```dart
getCheckinQr(String bookingId)
scanCheckin(String token)
```

### Missing Methods
According to the corrected API documentation, these endpoints exist but are not implemented:

```dart
// POST /checkin/confirm - Confirm check-in
Future<Map<String, dynamic>> confirmCheckin(String qrToken) async {
  try {
    await _setToken();
    final response = await _api.post('/checkin/confirm', data: {'qr_token': qrToken});
    return {'success': true, 'data': response.data};
  } on DioException catch (e) {
    return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to confirm check-in'};
  }
}

// POST /checkin/checkout - Confirm check-out
Future<Map<String, dynamic>> confirmCheckout(String bookingId) async {
  try {
    await _setToken();
    final response = await _api.post('/checkin/checkout', data: {'booking_id': bookingId});
    return {'success': true, 'data': response.data};
  } on DioException catch (e) {
    return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to confirm check-out'};
  }
}

// GET /checkin/today - Today's check-ins (owner)
Future<Map<String, dynamic>> getTodayCheckins() async {
  try {
    await _setToken();
    final response = await _api.get('/checkin/today');
    return {'success': true, 'data': response.data};
  } on DioException catch (e) {
    return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to get today\'s check-ins'};
  }
}

// GET /checkin/active-guests - Active guests (owner)
Future<Map<String, dynamic>> getActiveGuests() async {
  try {
    await _setToken();
    final response = await _api.get('/checkin/active-guests');
    return {'success': true, 'data': response.data};
  } on DioException catch (e) {
    return {'success': false, 'message': e.response?.data['message'] ?? 'Failed to get active guests'};
  }
}
```

### Fix Required
Add the missing 4 methods to complete the QR check-in service.

---

## 📋 MISSING SERVICE FILES

According to the corrected API documentation, these service files are completely missing:

### 1. Two-Factor Authentication Service
**File**: `lib/core/services/two_factor_service.dart`

**Missing Endpoints**:
- `GET /2fa/status` - Check if 2FA enabled
- `POST /2fa/setup` - Setup 2FA (returns QR code)
- `POST /2fa/verify` - Verify 2FA setup
- `POST /2fa/disable` - Disable 2FA
- `POST /2fa/validate` - Validate OTP
- `POST /2fa/biometric/toggle` - Toggle biometric auth

### 2. Booking Requests Service
**File**: `lib/core/services/booking_request_service.dart`

**Missing Endpoints**:
- `POST /booking-requests/special-time` - Request early check-in/late check-out
- `POST /booking-requests/{id}/respond` - Respond to request (owner)
- `GET /booking-requests/my` - Guest's requests
- `GET /booking-requests/owner` - Owner's pending requests
- `POST /booking-modifications/request` - Request booking modification
- `POST /booking-modifications/{id}/respond` - Respond to modification

### 3. Guest-Hotel Chat Service
**File**: `lib/core/services/chat_service.dart`

**Missing Endpoints**:
- `GET /chat/{bookingId}/messages` - Get chat messages
- `POST /chat/send` - Send message
- `GET /chat/owner/all` - Owner's all chats

### 4. Waitlist Service
**File**: `lib/core/services/waitlist_service.dart`

**Missing Endpoints**:
- `POST /waitlist/join` - Join waitlist
- `GET /waitlist/my` - My waitlist entries
- `DELETE /waitlist/{id}` - Leave waitlist

### 5. Price Alerts Service
**File**: `lib/core/services/price_alert_service.dart`

**Missing Endpoints**:
- `POST /price-alerts` - Create price alert
- `GET /price-alerts/my` - My price alerts
- `DELETE /price-alerts/{id}` - Delete alert

### 6. AI Chatbot Service
**File**: `lib/core/services/ai_chat_service.dart`

**Missing Endpoints**:
- `POST /ai-chat/start` - Start chat session
- `POST /ai-chat/message` - Send message
- `GET /ai-chat/history/{token}` - Chat history
- `POST /ai-chat/end/{token}` - End session

### 7. Support Ticket Service
**File**: `lib/core/services/support_service.dart`

**Missing Endpoints**:
- `POST /support/tickets` - Create ticket
- `GET /support/tickets` - My tickets
- `GET /support/tickets/{id}` - Ticket details
- `POST /support/tickets/{id}/messages` - Add message
- `POST /support/chat/start` - Start live chat
- `GET /support/chat/{token}` - Get chat session
- `POST /support/chat/{token}/message` - Send chat message
- `POST /support/chat/{token}/end` - End chat

### 8. Room Type Media Service
**File**: `lib/core/services/room_media_service.dart`

**Missing Endpoints**:
- `GET /room-types/{roomTypeId}/gallery` - Room images
- `GET /room-types/{roomTypeId}/videos` - Room videos
- `POST /room-types/{roomTypeId}/media/images` - Upload images (owner)
- `POST /room-types/{roomTypeId}/media/video` - Upload video (owner)
- `POST /room-types/{roomTypeId}/media/video-link` - Add video link (owner)
- `PUT /room-types/media/{id}` - Update media (owner)
- `DELETE /room-types/media/{id}` - Delete media (owner)
- `POST /room-types/{roomTypeId}/media/reorder` - Reorder media (owner)

### 9. Recommendation Service
**File**: `lib/core/services/recommendation_service.dart`

**Missing Endpoints**:
- `GET /recommendations/trending` - Trending hotels
- `GET /recommendations/nearby-popular` - Nearby popular hotels
- `GET /recommendations/also-booked/{hotelId}` - Users also booked
- `GET /recommendations/for-you` - Personalized (auth)

### 10. Multi-Currency Service
**File**: `lib/core/services/currency_service.dart`

**Missing Endpoints**:
- `GET /currencies` - All currency rates
- `GET /currencies/detect` - Detect currency by country
- `PUT /currencies/preference` - Set currency preference
- `POST /currencies/convert` - Convert amount
- `GET /currencies/rates-map` - Bulk rates for frontend

### 11. Advanced Features Services

#### a) AI Pricing Service
**File**: `lib/core/services/ai_pricing_service.dart`

**Missing Endpoints**:
- `GET /ai-pricing/rules` - Get pricing rules
- `POST /ai-pricing/rules` - Save rule
- `DELETE /ai-pricing/rules/{id}` - Delete rule
- `GET /ai-pricing/suggest` - Get price suggestion
- `GET /ai-pricing/suggest-range` - Calendar view suggestions
- `POST /ai-pricing/apply` - Apply suggested price
- `POST /ai-pricing/auto-apply` - Auto-apply for date range

#### b) iCal/Channel Manager Service
**File**: `lib/core/services/ical_service.dart`

**Missing Endpoints**:
- `GET /ical/channels` - Get channels
- `POST /ical/channels` - Add channel
- `POST /ical/channels/{id}/sync` - Sync channel
- `DELETE /ical/channels/{id}` - Delete channel
- `GET /ical/export/{token}` - Export iCal (public)

#### c) Guest Messaging Service
**File**: `lib/core/services/guest_messaging_service.dart`

**Missing Endpoints**:
- `GET /guest-messaging/templates` - Get templates
- `POST /guest-messaging/templates` - Save template
- `DELETE /guest-messaging/templates/{id}` - Delete template
- `GET /guest-messaging/logs` - Message logs
- `POST /guest-messaging/test` - Test template

#### d) Competitor Benchmarking Service
**File**: `lib/core/services/competitor_service.dart`

**Missing Endpoints**:
- `GET /competitor/prices` - Get competitor prices
- `POST /competitor/prices` - Add price
- `DELETE /competitor/prices/{id}` - Delete price
- `GET /competitor/summary` - Summary
- `GET /competitor/parity-check` - Rate parity check
- `GET /competitor/trend` - 30-day trend

#### e) Tax Reporting Service
**File**: `lib/core/services/tax_service.dart`

**Missing Endpoints**:
- `GET /taxes` - Get tax rates
- `POST /taxes` - Save tax rate
- `DELETE /taxes/{id}` - Delete tax rate
- `GET /taxes/report` - Tax report
- `GET /taxes/report/export` - Export PDF

#### f) Video Tours Service
**File**: `lib/core/services/video_tour_service.dart`

**Missing Endpoints**:
- `POST /hotel-owner/videos/upload` - Upload video
- `POST /hotel-owner/videos/link` - Add YouTube/Vimeo
- `DELETE /hotel-owner/videos/{id}` - Delete video
- `POST /hotel-owner/videos/{id}/set-primary` - Set primary

#### g) Review Request Service
**File**: `lib/core/services/review_request_service.dart`

**Missing Endpoints**:
- `POST /review-requests/send` - Send review request

---

## 📊 Summary

### Critical Fixes (Must Fix Immediately)
1. ✅ Remove guest fields from booking API call in payment_screen.dart
2. ✅ Remove or fix deleteNotification() in notification_service.dart

### Important Additions
3. ⚠️ Complete QR check-in service with 4 missing methods

### Feature Gaps (Missing Services)
- 11 major service files completely missing
- 70+ API endpoints not implemented in Flutter app
- Most advanced features have no client-side implementation

### Recommendation
1. Fix critical issues #1 and #2 immediately
2. Complete QR check-in service
3. Prioritize missing services based on feature importance:
   - High Priority: Support tickets, Chat, Booking requests
   - Medium Priority: 2FA, Waitlist, Price alerts, Recommendations
   - Low Priority: Advanced owner features (AI pricing, competitor tracking, etc.)

---

## Next Steps

Would you like me to:
1. Fix the 2 critical issues now?
2. Complete the QR check-in service?
3. Create the missing service files?
4. All of the above?
