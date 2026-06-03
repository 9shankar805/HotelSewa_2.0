# HotelSewa - Unified Customer & Hotel Owner App

## Overview
This is a unified Flutter application that combines both customer and hotel owner functionalities into a single app. Users can select their role (Customer or Hotel Owner) and access role-specific features.

## Architecture

### Role-Based Navigation
The app uses a role selection mechanism that determines which features and screens are available to the user:

- **Customer Role**: Access to hotel search, booking, reviews, trips, and customer-specific features
- **Hotel Owner Role**: Access to dashboard, booking management, room management, earnings, and owner-specific features

### Key Components

#### 1. Role Selection (`lib/core/models/user_role.dart`)
- Defines `UserRole` enum with `customer` and `hotelOwner` values
- Stores user role in SharedPreferences for persistence

#### 2. Role Selection Screen (`lib/features/role_selection/presentation/role_selection_screen.dart`)
- First screen shown to new users
- Allows users to choose between Customer and Hotel Owner roles
- Saves selection and routes to appropriate login flow

#### 3. Unified Main App (`lib/main.dart`)
- Initializes both customer and hotel owner providers
- Supports Firebase, notifications, and caching for both roles
- Single entry point for the entire application

#### 4. Navigation System

##### Customer Navigation (`lib/core/navigation/main_navigation.dart`)
- Bottom navigation with: Home, Search, Trips, Saved, Profile
- Access to customer-specific features

##### Hotel Owner Navigation (`lib/core/navigation/owner_navigation.dart`)
- Bottom navigation with: Dashboard, Bookings, Rooms, Profile
- Access to hotel management features

##### Unified Routes (`lib/core/navigation/app_routes.dart`)
- Contains all routes for both customer and hotel owner
- Customer routes: `/home`, `/search`, `/hotel-details`, etc.
- Owner routes: `/owner/dashboard`, `/owner/bookings`, `/owner/rooms`, etc.

### Feature Organization

#### Customer Features (`lib/features/`)
- `auth/` - Login, signup, OTP verification
- `home/` - Home screen with hotel listings
- `search/` - Hotel search and filters
- `hotel/` - Hotel details, reviews, policies
- `booking/` - Booking flow, payment, confirmation
- `trips/` - My trips, booking history
- `profile/` - User profile, settings
- `wallet/` - Wallet and payment methods
- `reviews/` - Rate hotels, view reviews
- `chat/` - Customer support chat
- `notifications/` - Push notifications
- And many more...

#### Hotel Owner Features (`lib/features/`)
- `dashboard/` - Owner dashboard with analytics
- `bookings/` - Booking management for owners
- `rooms/` - Room management and availability
- `earnings/` - Revenue and earnings tracking
- `pricing/` - Dynamic pricing management
- `calendar/` - Availability calendar
- `gallery/` - Hotel photo management
- `reviews/` - Review management
- `offers/` - Special offers and promotions
- `orders/` - In-stay ordering system
- `analytics/` - Business analytics
- `reports/` - Financial and tax reports
- `withdrawals/` - Earnings withdrawal
- `settings/` - Hotel settings
- And many more...

### Shared Services (`lib/core/services/`)

#### Customer Services
- `auth_service.dart` - Customer authentication
- `home_service.dart` - Home screen data
- `booking_service.dart` - Booking operations
- `api_service.dart` - API client
- `cache_service.dart` - Data caching
- `firebase_notification_handler.dart` - Push notifications

#### Hotel Owner Services
- `auth_account_service.dart` - Owner authentication
- `dashboard_service.dart` - Dashboard data
- `hotel_management_service.dart` - Hotel operations
- `booking_requests_service.dart` - Booking management
- `earnings_service.dart` - Revenue tracking
- `pricing_service.dart` - Pricing management
- `media_service.dart` - Photo/video management
- `ordering_service.dart` - In-stay ordering
- And many more...

## How It Works

### 1. App Launch Flow
```
Splash Screen
    ↓
Check if role selected?
    ↓ No
Role Selection Screen → Save role → Login
    ↓ Yes
Check authentication?
    ↓ Authenticated
Route based on role:
    - Customer → Main Navigation (Customer UI)
    - Hotel Owner → Owner Navigation (Owner UI)
```

### 2. Role Switching
Users can switch roles by:
1. Logging out
2. Clearing app data
3. Selecting a different role on next login

### 3. Authentication
- Both roles use separate authentication flows
- Customer: Email/Phone + OTP or Google Sign-In
- Hotel Owner: Email + Password or Google Sign-In
- Tokens stored separately in SharedPreferences

## Setup Instructions

### Prerequisites
- Flutter SDK (latest stable version)
- Android Studio / VS Code
- Firebase project configured
- Backend API running

### Installation

1. **Clone and navigate to flutter directory**
   ```bash
   cd flutter
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure environment**
   - Copy `.env.example` to `.env`
   - Update API endpoints and keys

4. **Run the app**
   ```bash
   flutter run
   ```

### Configuration Files

#### `.env` file
```
API_BASE_URL=https://your-api-url.com
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

#### Firebase Configuration
- `android/app/google-services.json` - Android Firebase config
- `ios/Runner/GoogleService-Info.plist` - iOS Firebase config

## Key Features

### Customer Features
✅ Hotel search with filters
✅ Hotel details with photos and reviews
✅ Booking flow with payment integration
✅ Trip management
✅ Wallet and payment methods
✅ Review submission
✅ AI chat support
✅ Push notifications
✅ In-stay ordering
✅ Loyalty program

### Hotel Owner Features
✅ Dashboard with analytics
✅ Booking management
✅ Room management
✅ Earnings tracking
✅ Dynamic pricing
✅ Availability calendar
✅ Photo gallery management
✅ Review management
✅ Guest messaging
✅ In-stay ordering system
✅ Financial reports
✅ Withdrawal management

## Development Guidelines

### Adding New Features

#### For Customer Features
1. Create feature folder in `lib/features/`
2. Add screens in `presentation/`
3. Add services in `lib/core/services/`
4. Register routes in `app_routes.dart`
5. Update main navigation if needed

#### For Hotel Owner Features
1. Create feature folder in `lib/features/`
2. Add screens in `presentation/screens/`
3. Add services in `lib/core/services/`
4. Register routes with `/owner/` prefix in `app_routes.dart`
5. Update owner navigation if needed

### Code Organization
```
lib/
├── core/
│   ├── constants/      # App constants
│   ├── models/         # Shared models
│   ├── navigation/     # Navigation logic
│   ├── services/       # API services
│   ├── theme/          # App theme
│   └── widgets/        # Shared widgets
├── features/
│   ├── [feature_name]/
│   │   ├── data/       # Data models
│   │   └── presentation/
│   │       ├── screens/    # UI screens
│   │       ├── widgets/    # Feature widgets
│   │       ├── providers/  # State management
│   │       └── services/   # Feature services
└── main.dart
```

## Testing

### Run Tests
```bash
flutter test
```

### Build for Production

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Troubleshooting

### Common Issues

1. **Role not persisting**
   - Clear app data and restart
   - Check SharedPreferences implementation

2. **Navigation issues**
   - Verify route names match in `app_routes.dart`
   - Check role-based routing logic in splash screen

3. **API errors**
   - Verify `.env` configuration
   - Check network connectivity
   - Verify backend API is running

4. **Build errors**
   - Run `flutter clean`
   - Run `flutter pub get`
   - Check for dependency conflicts

## Future Enhancements

- [ ] Role switching without logout
- [ ] Multi-hotel management for owners
- [ ] Advanced analytics dashboard
- [ ] Real-time chat between customers and owners
- [ ] Integration with more payment gateways
- [ ] Multi-language support
- [ ] Dark mode improvements

## Support

For issues or questions:
- Check the documentation
- Review existing issues
- Contact the development team

## License

Copyright © 2024 HotelSewa. All rights reserved.
