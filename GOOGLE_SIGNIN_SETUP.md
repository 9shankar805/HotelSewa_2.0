# Google Sign-In Setup for Flutter Customer App

## Issue
Google login was using mock/demo implementation. Now updated to real Google OAuth.

## Changes Made

### 1. Flutter App
✅ Added `google_sign_in: ^6.2.2` to pubspec.yaml
✅ Updated login_screen.dart with real GoogleSignIn implementation
✅ Added googleLogin method to auth_service.dart

### 2. Backend
✅ Backend already has `/auth/google` endpoint with OAuth2Client

## Setup Required

### Step 1: Install Flutter Package
```bash
cd customer-app/flutter
flutter pub get
```

### Step 2: Android Configuration
Add to `android/app/build.gradle`:
```gradle
android {
    defaultConfig {
        // Add this
        manifestPlaceholders = [
            'appAuthRedirectScheme': 'com.mrpr0c0d.oyocustomerapp'
        ]
    }
}
```

### Step 3: Get SHA-1 Certificate
```bash
cd android
./gradlew signingReport
```
Copy the SHA-1 fingerprint.

### Step 4: Firebase Console Setup
1. Go to https://console.firebase.google.com
2. Select project: hotelsewa-66c35
3. Project Settings → Add Android App (if not exists)
4. Package name: `com.mrpr0c0d.oyocustomerapp`
5. Add SHA-1 fingerprint
6. Download new `google-services.json`
7. Replace in `android/app/google-services.json`

### Step 5: Enable Google Sign-In in Firebase
1. Firebase Console → Authentication → Sign-in method
2. Enable Google provider
3. Add support email

### Step 6: Update .env Files
Flutter `.env`:
```
GOOGLE_CLIENT_ID=664870792174-akgpqfbgcddbfn936e531lnjo52fqc61.apps.googleusercontent.com
```

Backend `.env`:
```
GOOGLE_CLIENT_ID=664870792174-akgpqfbgcddbfn936e531lnjo52fqc61.apps.googleusercontent.com
```

## Testing
1. Run app: `flutter run`
2. Click "Continue with Gmail"
3. Select Google account
4. Should redirect to HomeScreen with token

## Troubleshooting

### Error: "PlatformException(sign_in_failed)"
- Check SHA-1 is added to Firebase
- Verify google-services.json is updated
- Ensure package name matches

### Error: "Invalid Google token"
- Backend GOOGLE_CLIENT_ID not set
- Client ID mismatch between Flutter and Backend

### Error: "Google account has no email"
- User denied email permission
- Google account has no email

## Current Status
- ✅ Code updated
- ⏳ Need to run `flutter pub get`
- ⏳ Need to add SHA-1 to Firebase
- ⏳ Need to update google-services.json
- ⏳ Test on device/emulator
