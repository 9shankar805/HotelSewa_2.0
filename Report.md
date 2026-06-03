Flutter Hotel Booking App — Code Audit Report
🔴 MISSING FILES (5 files — completely absent from disk)
File	Status
emi_screen.dart
MISSING — file does not exist
booking_cancellation_screen.dart
MISSING — file does not exist
booking_success_screen.dart
MISSING — file does not exist
referral_history_screen.dart
MISSING — file does not exist
loyalty_program_screen.dart
MISSING — file does not exist
deals_screen.dart
MISSING — file does not exist
recently_viewed_screen.dart
MISSING — file does not exist
hotel_policies_screen.dart
MISSING — file does not exist
compare_hotels_screen.dart
MISSING — file does not exist
That's 9 missing files total. Any navigation to these routes will crash at runtime.

📋 FULL SCREEN-BY-SCREEN AUDIT
1. notifications_screen.dart — 7,457 bytes
Status: ✅ Real implementation
Issues:

Tapping a notification only marks it read — no navigation to the relevant booking/offer
No swipe-to-delete gesture
_formatTime silently swallows parse errors, returning raw string instead of a fallback
2. wallet_screen.dart — 12,083 bytes
Status: ✅ Real implementation
Issues:

"Add Money", "Transfer", "Stats" buttons are dead — onPressed: () {} with no implementation
"View All" transactions button is dead — same
+12% Growth stat is hardcoded — not calculated from real data
_walletBalance and _pointsBalance default to 0 and are only populated if the API returns a Map with those exact keys; if the API returns a flat list, they stay 0 forever
3. payment_methods_screen.dart — 9,189 bytes
Status: ✅ Real implementation
Issues:

_setDefault posts to paymentTransactionsEndpoint — this is the wrong endpoint for setting a default payment method (should be a dedicated endpoint)
_remove only removes from local list, never calls a DELETE API endpoint — data reappears on refresh
No EMI option (the emi_screen.dart is missing)
4. add_card_screen.dart — 17,153 bytes
Status: ✅ Real implementation
Issues:

Duplicate submit logic bug: both _saveCard_() and _addCard() exist with identical API call bodies. _saveCard_() is never called (dead code). The _formKey is declared but _addCard() doesn't use _formKey.currentState!.validate() — the Form widget wraps nothing
CVV is sent to the server — this is a PCI-DSS violation. Real implementations tokenize via a payment SDK; CVV must never be transmitted to your own backend
Card number is sent raw to the server — same PCI concern
_saveCard bool toggle has no effect (card is always "saved" regardless)
5. add_upi_screen.dart — 14,907 bytes
Status: ✅ Real implementation
Issues:

UPI "verification" is fake — it just waits 800ms and marks verified based on format only. Comment in code acknowledges this
All 4 UPI app quick-select buttons set the suffix (e.g. @okicici) as the full UPI ID, not a prefix — user would need to prepend their username manually, but the field is pre-filled with just @okicici which is invalid
Posts to paymentTransactionsEndpoint instead of a payment methods endpoint
6. emi_screen.dart — MISSING
Status: ❌ File does not exist

7. help_center_screen.dart — 11,162 bytes
Status: ⚠️ Partial stub — hardcoded data, no API
Issues:

All FAQs are hardcoded (4 items) — no API call
Category filter sets _searchQuery to the category ID string (e.g. 'booking'), but FAQs are filtered by question/answer text — the category filter does nothing useful
Contact options ("Live Chat", "Call Us", "Email") all have onTap: () {} — completely non-functional
No AppBar (missing back button — relies on SafeArea only)
8. support_ticket_screen.dart — 15,614 bytes
Status: ✅ Real implementation
Issues:

_MyTicketsTab shows ticket ID as the raw API string — if the API returns a UUID, it displays a UUID to the user
No ability to view ticket replies or add a reply to an existing ticket
No attachment support (mentioned in UI but not implemented)
9. hotel_reviews_screen.dart — 16,858 bytes
Status: ✅ Real implementation
Issues:

Avatar Image.network has no errorBuilder — will show broken image widget if URL fails
_hotel['id'] is accessed without null check in _loadReviews() — will throw Null check operator used on a null value if screen is opened without arguments
Sort color hardcodes Color(0xFFE53E3E) instead of using AppColors.primary
No pagination — loads all reviews at once
10. review_submission_screen.dart — 9,221 bytes
Status: ✅ Real implementation
Issues:

Success dialog calls Navigator.pop(context) three times — this is fragile and will crash if the navigation stack doesn't have 3 routes above it
Hotel image uses Image.network with no errorBuilder
_hotel['state'] may be null, producing "Mumbai, null" in the subtitle
11. pending_reviews_screen.dart — 8,098 bytes
Status: ✅ Real implementation
Issues:

Navigates to ReviewSubmissionScreen but passes hotelId/hotelName without the full hotel map — ReviewSubmissionScreen expects arguments['hotel'] as a Map, so the hotel image and city won't display
No empty-state illustration for the "all caught up" state (uses a plain icon)
12. rate_stay_screen.dart — 15,493 bytes
Status: ✅ Real implementation
Issues:

Category ratings (_cleanlinessRating, _serviceRating, etc.) are collected but never sent to the API — only _overallRating and _reviewCtrl are submitted
_highlights set is collected but never sent to the API
"+50 loyalty points earned!" in the thank-you sheet is hardcoded — not from API response
booking['checkIn'] fallback is '15 Jan' — hardcoded placeholder visible if no arguments passed
13. personal_info_screen.dart — 8,787 bytes
Status: ✅ Real implementation
Issues:

Uses ApiConfig.getOwnerEndpoint — this is the owner/hotel management endpoint, not the customer profile endpoint. Customer users will likely get a 403 or wrong data
Email field is read-only (correct) but there's no "change email" flow
_dobController accepts free text — no date picker, no format validation
14. security_settings_screen.dart — 11,799 bytes
Status: ✅ Real implementation
Issues:

Biometric toggle is cosmetic only — toggling it does nothing (no local_auth integration, no API call)
2FA toggle is cosmetic only — same issue
"Active Sessions" row has onTap: () {} — dead
Password change posts to hardcoded '/update-profile' string instead of ApiConfig.updateProfileEndpoint
_loginAlerts toggle is never persisted
15. loyalty_program_screen.dart — MISSING
Status: ❌ File does not exist

16. travel_preferences_screen.dart — 11,526 bytes
Status: ✅ Real implementation
Issues:

Clean implementation, no major bugs
Minor: _dropdownRow padding vertical: 4 makes the rows feel cramped
17. delete_account_screen.dart — 10,250 bytes
Status: ✅ Real implementation
Issues:

_pwController.text is collected but never sent to the API — _authService.deleteAccount() takes no arguments. The password field is purely cosmetic
After successful deletion, navigates to /login but doesn't clear SharedPreferences — auth token and user data remain on device
18. address_book_screen.dart — 16,949 bytes
Status: ✅ Real implementation
Issues:

_setDefault has a try/catch that falls back to local state update on failure — this silently hides API errors
The "Add Address" dashed border uses BorderStyle.solid — the comment implies dashed was intended
No validation on line1Ctrl beyond isEmpty check
19. linked_accounts_screen.dart — 10,908 bytes
Status: ✅ Real implementation
Issues:

Apple Sign-In link shows onTap → ScaffoldMessenger.showSnackBar('coming soon') — stub
Phone number linking shows same "coming soon" — stub
firstWhere(..., orElse: () => null) — compile warning: orElse must return non-null in typed context; this will cause a type error at runtime in sound null-safety mode
Google Client ID is hardcoded in source: 664870792174-akgpqfbgcddbfn936e531lnjo52fqc61.apps.googleusercontent.com
20. booking_detail_screen.dart — 24,321 bytes
Status: ✅ Real implementation (most complete screen in the app)
Issues:

Price breakdown shows garbled text: 'â‚¹$roomCharge' — this is a UTF-8 encoding issue. The ₹ rupee symbol was corrupted. Will display as â‚¹2598 on screen
_share() just shows a SnackBar — no actual share sheet
"Download Invoice" navigates to /invoice — this route likely doesn't exist
"Modify Booking" navigates to /booking-modification — this route likely doesn't exist
Fetches bookings list and searches by ID rather than fetching a single booking by ID — inefficient
21. booking_cancellation_screen.dart — MISSING
Status: ❌ File does not exist — "Cancel" button in booking_detail_screen.dart will crash

22. booking_success_screen.dart — MISSING
Status: ❌ File does not exist — booking flow has no success screen

23. refund_status_screen.dart — 11,831 bytes
Status: ✅ Real implementation
Issues:

Falls back to _mockData with hardcoded hotel name "Grand Horizon Resort & Spa" and booking ID "HS-2024-001" — visible to users if API fails or no arguments passed
_buildSteps references _data['processedDate'] and _data['completedDate'] which are unlikely to be in the API response — will show empty strings in timeline
24. online_checkin_screen.dart — 20,678 bytes
Status: ✅ Real implementation
Issues:

ID number field has no validation — user can proceed with empty ID
Preferences (floor, bed, pillow, early check-in, late checkout, special requests) are never sent to the API — only the QR code is fetched; preferences are collected but discarded
ETA time is never sent to the API either
Falls back to raw bookingId as QR data if API fails — hotel scanner won't recognize a plain booking ID
25. language_selector_screen.dart — 7,372 bytes
Status: ✅ Real implementation
Issues:

Language change is cosmetic only — saves to SharedPreferences and calls API, but the app has no flutter_localizations / intl setup, so the UI language never actually changes
No restart prompt after language change
26. currency_selector_screen.dart — 7,818 bytes
Status: ✅ Real implementation
Issues:

Currency change is cosmetic only — saves preference but no currency conversion is applied anywhere in the app (all prices display as NPR/Rs regardless)
27. notification_settings_screen.dart — 14,839 bytes
Status: ✅ Real implementation
Issues:

Clean, well-structured. Minor: master toggle disables individual switches visually but the Switch.value still reflects individual state — if you re-enable master, all switches restore correctly (this is actually correct behavior)
No confirmation before saving
28. accessibility_settings_screen.dart — 11,469 bytes
Status: ⚠️ Partial stub
Issues:

_save() just does Future.delayed(1 second) — no API call, no SharedPreferences persistence
Font size, high contrast, bold text, large buttons, reduce motion, haptic feedback — none of these are applied anywhere in the app. The screen is purely cosmetic
Screen reader toggle does nothing
29. invite_earn_screen.dart — 12,092 bytes
Status: ✅ Real implementation
Issues:

_share() copies text to clipboard instead of using share_plus — no native share sheet
Referral code fallback generation: name.substring(0, name.length.clamp(0, 4)) — if name is empty string, substring(0, 0) returns '', producing code like HSUSER2025 which is wrong
"View Referral History" button is absent — the referral_history_screen.dart is missing
30. referral_history_screen.dart — MISSING
Status: ❌ File does not exist

31. about_screen.dart — 8,730 bytes
Status: ✅ Real implementation
Issues:

"Rate the App", "Share App" buttons have onTap: () {} — dead
"Cookie Policy" and "Licenses" have onTap: () {} — dead
Social media buttons (Twitter, LinkedIn, Facebook, YouTube) have onTap: () {} — dead
Version is hardcoded 1.0.0 (Build 100) — not read from package_info_plus
32. terms_screen.dart — 9,027 bytes
Status: ✅ Real implementation
Issues:

All content is hardcoded — not fetched from API/CMS
"Last updated: January 1, 2025" is hardcoded
No "Accept" button or acceptance tracking (relevant if shown during onboarding)
33. map_search_screen.dart — 15,976 bytes
Status: ⚠️ Significant stub — no real map
Issues:

No actual map widget — uses a Container with color: Color(0xFFE8F4FD) as a placeholder. No google_maps_flutter, flutter_map, or any mapping library
Hotel "pins" are Positioned widgets with hardcoded offsets calculated as (index * 60) % width — they don't correspond to actual coordinates
Search bar is non-interactive (no text input, just a display label)
Filter chips work (trigger API calls) but results only show in the bottom list, not on the "map"
34. chat_screen.dart — 4,821 bytes
Status: ⚠️ Stub / demo
Issues:

No real-time messaging — no WebSocket, no Firebase, no polling
Messages are stored in local List only — lost on screen dispose
Hardcoded initial messages: "Hello! How can I help you today?" / "Hi, I need help with my booking"
Hotel name defaults to 'Hotel Paradise' — hardcoded fallback
No AppBar back button (uses SafeArea only, no AppBar)
No message timestamps from server, no read receipts, no typing indicator
35. ai_chat_screen.dart — 10,348 bytes
Status: ✅ Real implementation (uses Groq API)
Issues:

GROQ_API_KEY is read from flutter_dotenv — if .env is missing or key absent, all messages silently fall back to a generic response with no error shown to user
API key is used client-side — security risk: the key is bundled in the app binary and can be extracted
Model llama-3.1-70b-versatile may be deprecated/renamed; no fallback model
Suggestion chips set _messageController.text = s but don't auto-send — user must tap send manually (minor UX issue)
No message scroll-to-bottom on new message
No conversation history sent to API — each message is sent without prior context (stateless)
36. deals_screen.dart — MISSING
Status: ❌ File does not exist

37. recently_viewed_screen.dart — MISSING
Status: ❌ File does not exist

38. hotel_policies_screen.dart — MISSING
Status: ❌ File does not exist

39. nearby_attractions_screen.dart — 10,565 bytes
Status: ⚠️ Stub — all hardcoded data
Issues:

All 10 attractions are hardcoded (Marine Drive, Gateway of India, etc.) — Mumbai landmarks, not relevant to a Nepal hotel app
No API call — data never changes regardless of which hotel is passed
Map section is a placeholder Container (same as map_search_screen)
"Open Map" button navigates to /map-search but doesn't pass hotel coordinates
40. compare_hotels_screen.dart — MISSING
Status: ❌ File does not exist

41. near_me_screen.dart — 21,395 bytes
Status: ✅ Real implementation (best-quality screen in the audit)
Issues:

Falls back to loading all hotels if nearby returns empty — good UX, but the fallback list isn't labeled differently, so user thinks they're seeing "nearby" hotels when they're not
ImageUrlHelper.fix() called on (hotel['image'] ?? hotel['images'] ?? '').toString() — if images is a List, .toString() produces [url1, url2] which is not a valid URL
📊 SUMMARY TABLE
Screen	Size	Stub?	Compile Risk	Key Issues
notifications_screen	7.5KB	No	Low	No tap navigation
wallet_screen	12KB	No	Low	3 dead action buttons, hardcoded growth stat
payment_methods_screen	9.2KB	No	Low	Remove doesn't call API
add_card_screen	17KB	No	Low	PCI violation (raw card/CVV to server), duplicate dead method
add_upi_screen	15KB	No	Low	Fake verification, wrong endpoint
emi_screen	—	MISSING	CRASH	File does not exist
help_center_screen	11KB	Partial	Low	Hardcoded FAQs, dead contact buttons
support_ticket_screen	16KB	No	Low	No reply-to-ticket feature
hotel_reviews_screen	17KB	No	Medium	Null crash if no arguments, no image error handler
review_submission_screen	9.2KB	No	Low	Triple-pop crash risk
pending_reviews_screen	8.1KB	No	Low	Wrong arguments to ReviewSubmissionScreen
rate_stay_screen	15KB	No	Low	Category ratings & highlights never sent to API
personal_info_screen	8.8KB	No	Low	Uses owner endpoint for customer profile
security_settings_screen	12KB	No	Low	Biometric/2FA toggles are cosmetic, hardcoded endpoint
loyalty_program_screen	—	MISSING	CRASH	File does not exist
travel_preferences_screen	12KB	No	Low	Clean
delete_account_screen	10KB	No	Low	Password never sent to API, no SharedPrefs clear
address_book_screen	17KB	No	Low	Dashed border uses solid style
linked_accounts_screen	11KB	No	Medium	firstWhere null-safety crash, Apple/Phone are stubs
booking_detail_screen	24KB	No	Low	₹ symbol corrupted (garbled UTF-8), dead share/invoice/modify routes
booking_cancellation_screen	—	MISSING	CRASH	File does not exist
booking_success_screen	—	MISSING	CRASH	File does not exist
refund_status_screen	12KB	No	Low	Hardcoded mock data fallback
online_checkin_screen	21KB	No	Low	Preferences/ETA never sent to API
language_selector_screen	7.4KB	No	Low	Language change is cosmetic (no i18n)
currency_selector_screen	7.8KB	No	Low	Currency change is cosmetic (no conversion)
notification_settings_screen	15KB	No	Low	Clean
accessibility_settings_screen	11KB	Stub	Low	Save does nothing, no settings applied anywhere
invite_earn_screen	12KB	No	Low	Share uses clipboard not share sheet
referral_history_screen	—	MISSING	CRASH	File does not exist
about_screen	8.7KB	No	Low	6 dead buttons, hardcoded version
terms_screen	9KB	Partial	Low	All content hardcoded
map_search_screen	16KB	Stub	Low	No real map, fake pins
chat_screen	4.8KB	Stub	Low	No real-time, local state only
ai_chat_screen	10KB	No	Low	API key client-side, no conversation context
deals_screen	—	MISSING	CRASH	File does not exist
recently_viewed_screen	—	MISSING	CRASH	File does not exist
hotel_policies_screen	—	MISSING	CRASH	File does not exist
nearby_attractions_screen	11KB	Stub	Low	All Mumbai hardcoded data in a Nepal app
compare_hotels_screen	—	MISSING	CRASH	File does not exist
near_me_screen	21KB	No	Low	Image list-to-string bug
🔥 TOP PRIORITY FIXES
Create the 9 missing files — any navigation to those routes crashes the app
Fix the ₹ symbol encoding in booking_detail_screen.dart (lines with 'â‚¹')
PCI compliance in add_card_screen.dart — never send raw card numbers or CVV to your own backend; use a payment SDK (Stripe, Razorpay, etc.)
linked_accounts_screen.dart — firstWhere(orElse: () => null) will throw a null-safety runtime error
hotel_reviews_screen.dart — _hotel['id'].toString() crashes if screen opened without arguments
delete_account_screen.dart — clear SharedPreferences on account deletion
nearby_attractions_screen.dart — replace Mumbai hardcoded data with API call
map_search_screen.dart — integrate a real map package or clearly mark as "coming soon"
accessibility_settings_screen.dart — wire up the save button to actually persist settings
chat_screen.dart — either integrate real-time messaging or remove from navigation

Invoked Context Gatherer
Need to read the specific files that were flagged as missing or broken to confirm their actual state before writing the report.
All data collected. Here's the full report:

File Audit Report — 15 Dart Screens
Summary Table
#	File	Size	Status
1	booking_success_screen.dart	3 bytes	🔴 Empty stub (BOM only)
2	booking_cancellation_screen.dart	3 bytes	🔴 Empty stub (BOM only)
3	booking_detail_screen.dart	24,321 bytes	✅ Real implementation
4	deals_screen.dart	3 bytes	🔴 Empty stub (BOM only)
5	recently_viewed_screen.dart	3 bytes	🔴 Empty stub (BOM only)
6	hotel_policies_screen.dart	3 bytes	🔴 Empty stub (BOM only)
7	compare_hotels_screen.dart	3 bytes	🔴 Empty stub (BOM only)
8	nearby_attractions_screen.dart	10,565 bytes	✅ Real implementation (hardcoded data)
9	loyalty_program_screen.dart	3 bytes	🔴 Empty stub (BOM only)
10	referral_history_screen.dart	3 bytes	🔴 Empty stub (BOM only)
11	emi_screen.dart	3 bytes	🔴 Empty stub (BOM only)
12	notifications_screen.dart	7,457 bytes	✅ Real implementation (API-connected)
13	chat_screen.dart	4,821 bytes	⚠️ Partial stub (hardcoded messages, no API)
14	map_search_screen.dart	15,976 bytes	✅ Real implementation (API-connected)
15	near_me_screen.dart	21,395 bytes	✅ Real implementation (GPS + API)
Detailed Findings
🔴 Empty Stubs (3 bytes — UTF-8 BOM only, no Dart code): These files exist on disk but contain only the 3-byte UTF-8 BOM marker (EF BB BF). They are completely empty — no class, no widget, nothing.

booking_success_screen.dart
booking_cancellation_screen.dart
deals_screen.dart
recently_viewed_screen.dart
hotel_policies_screen.dart
compare_hotels_screen.dart
loyalty_program_screen.dart
referral_history_screen.dart
emi_screen.dart
✅ Real Implementations:

booking_detail_screen.dart (24KB) — Full implementation. Fetches booking by ID from ApiConfig.myBookingsEndpoint, displays status card, hotel info, stay details, guest info, price breakdown, cancellation policy. Has Modify/Cancel/Check-in/Invoice actions for confirmed bookings, and Review/Book Again for completed ones.

nearby_attractions_screen.dart (10KB) — Real UI with category filter and list. However, attractions data is hardcoded (10 Mumbai landmarks). No API call. Functional screen but not dynamic.

notifications_screen.dart (7.5KB) — API-connected. Calls NotificationService.getNotifications(), markAsRead(), markAllAsRead(). Full UI with type-based icons/colors, unread badge, pull-to-refresh.

map_search_screen.dart (16KB) — API-connected. Uses ApiConfig.hotelsNearbyEndpoint and ApiConfig.hotelsEndpoint, GPS detection via LocationService, filter chips, simulated map pins, horizontal hotel card list at bottom. Map is a placeholder (no actual map SDK).

near_me_screen.dart (21KB) — Most complete. Full GPS permission flow (service disabled → denied → permanently denied → error states), calls HotelService.getNearbyHotels() with fallback to all hotels, proper hotel cards with ImageUrlHelper, navigates via go_router.

⚠️ Partial Stub:

chat_screen.dart (4.8KB) — Has a working UI (message bubbles, send button, text input) but uses hardcoded initial messages and no backend API. Sending a message only updates local state — nothing is persisted or sent to a server.
Bottom Line
9 of 15 files need to be built from scratch. The 5 real implementations are solid quality. chat_screen.dart needs API integration. nearby_attractions_screen.dart needs its hardcoded data replaced with an API call.