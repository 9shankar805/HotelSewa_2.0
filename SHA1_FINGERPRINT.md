# SHA-1 Certificate Fingerprint

## Package Name
**NEW:** `com.hotelsewa.app`

## Debug Certificate
**SHA-1:** `FF:30:51:45:A9:D7:92:F1:70:64:FF:27:64:A4:C6:9E:D0:CE:C2:DF`
**SHA-256:** `4A:F1:99:D9:E7:C4:CA:79:A3:94:C9:7D:E7:6D:98:61:A3:3C:86:B7:7D:86:AC:F6:81:25:72:6B:B7:44:DB:F7`

## Firebase Setup Steps

### 1. Add New Android App to Firebase
1. Go to https://console.firebase.google.com/project/hotelsewa-66c35/settings/general
2. Click "Add app" → Select Android
3. Package name: `com.hotelsewa.app`
4. App nickname: `HotelSewa Customer App`
5. Click "Register app"

### 2. Add SHA-1 Fingerprint
1. In the app settings, click "Add fingerprint"
2. Paste SHA-1: `FF:30:51:45:A9:D7:92:F1:70:64:FF:27:64:A4:C6:9E:D0:CE:C2:DF`
3. Click "Save"

### 3. Download google-services.json
1. Click "Download google-services.json"
2. Replace file at: `customer-app/flutter/android/app/google-services.json`

### 4. Enable Google Sign-In
1. Firebase Console → Authentication → Sign-in method
2. Enable "Google" provider
3. Add support email
4. Click "Save"

### 5. Clean and Rebuild
```bash
cd customer-app/flutter
flutter clean
flutter pub get
flutter run
```

## What Changed
- Package name: `com.mrpr0c0d.oyocustomerapp` → `com.hotelsewa.app`
- Updated `build.gradle.kts`
- Created new `MainActivity.kt` in `com/hotelsewa/app/`
- Updated `google-services.json`
