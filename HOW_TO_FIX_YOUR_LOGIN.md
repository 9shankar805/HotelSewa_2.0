# How to Fix Your Login Issue - Step by Step

## What's Happening?

You're seeing this error:
```
❌ Status Code: 302
📝 Booking API message: Session expired. Please login again.
```

This means **you don't have a valid authentication token saved**. This happens because:
1. You logged in via OTP before I fixed the OTP login bug
2. Your token expired
3. You never logged in

## Quick Fix (Do This Now!)

### Step 1: Log Out
1. Open the app
2. Go to **Profile** or **Settings**
3. Click **Log Out**

### Step 2: Log Back In
Choose ONE method:

**Option A: Email/Password Login**
1. Enter your email: `98059shankar@gmail.com`
2. Enter your password
3. Click Login

**Option B: OTP Login (Now Fixed!)**
1. Enter your phone number
2. Request OTP
3. Enter the 6-digit code
4. Your token will now be saved correctly!

**Option C: Google Login**
1. Click "Sign in with Google"
2. Select your account
3. Token will be saved automatically

### Step 3: Verify Token is Saved

I created a debug screen for you. To access it:

1. **Temporary**: Add this to your app's navigation or profile screen
2. Navigate to `AuthDebugScreen`
3. You should see: ✅ Token exists

**To add the debug screen temporarily:**

Add this import to your profile screen or any screen:
```dart
import '../debug/auth_debug_screen.dart';
```

Add a button:
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AuthDebugScreen()),
    );
  },
  child: const Text('Check Auth Status'),
)
```

### Step 4: Try Booking Again
1. Go to a hotel
2. Select a room
3. Fill in details
4. Go to payment
5. Click "Pay Now"

**Expected Result**: Booking should be created successfully!

---

## What the Logs Should Show

### Before Login (Bad):
```
🔑 Loading auth token: No token found
⚠️ No auth token available - user may need to login
❌ Status Code: 302
```

### After Login (Good):
```
🔑 Loading auth token: Token exists (eyJ0eXAiOiJKV1QiLCJhbGc...)
✅ Auth token set in API service
🔐 Setting Authorization header with token: eyJ0eXAiOiJKV1Qi...
🌐 Creating booking with data: {...}
✅ Booking API Response: 200
```

---

## Still Not Working?

### Check 1: Are you actually logged in?
- Can you see your name/email in the profile screen?
- Can you access "My Trips" without errors?

### Check 2: Is the API server running?
Test with curl:
```bash
curl http://209.50.241.46:2000/api/hotels
```

Should return hotel data, not an error.

### Check 3: Clear app data
If nothing works:
1. Uninstall the app
2. Reinstall it
3. Log in fresh
4. Try booking

---

## Why This Happened

The OTP login screen had a bug where it showed "OTP Verified Successfully!" but never actually called the API to get your authentication token. So you thought you were logged in, but you weren't really.

I fixed this bug, but you need to log in again for the fix to work.

---

## Technical Details

**What I Fixed:**
1. ✅ OTP verification now calls actual API
2. ✅ Token is saved to SharedPreferences
3. ✅ Token is loaded before API calls
4. ✅ 302 redirects are detected and handled
5. ✅ Clear error messages shown to user

**Files Changed:**
- `otp_verification_screen.dart` - Fixed OTP login
- `booking_service.dart` - Added auth error detection
- `api_service.dart` - Configured redirect handling
- `payment_screen.dart` - Added session expiry handling

---

## Bottom Line

**Just log out and log back in.** That's it. Your token will be saved correctly and bookings will work.

If you're still having issues after that, use the AuthDebugScreen to check if your token is actually saved.
