# App Reorganization Plan

## Current Issues
1. Hotel owner and customer features are mixed in the same folders
2. Some features have naming conflicts (auth, profile, bookings, etc.)
3. Services are not clearly separated by role
4. Constants and configurations are duplicated

## Proposed Structure

```
flutter/lib/
├── core/
│   ├── constants/
│   │   ├── app_colors.dart          # Customer colors
│   │   ├── api_config.dart          # All API endpoints
│   │   └── owner_constants.dart     # Owner-specific constants
│   ├── models/
│   │   └── user_role.dart           # Role enum
│   ├── navigation/
│   │   ├── app_routes.dart          # All routes
│   │   ├── main_navigation.dart     # Customer navigation
│   │   └── owner_navigation.dart    # Owner navigation
│   ├── services/
│   │   ├── shared/                  # Shared services
│   │   │   ├── api_service.dart
│   │   │   ├── auth_service.dart
│   │   │   └── cache_service.dart
│   │   ├── customer/                # Customer-only services
│   │   │   ├── home_service.dart
│   │   │   ├── booking_service.dart
│   │   │   └── recommendation_service.dart
│   │   └── owner/                   # Owner-only services
│   │       ├── dashboard_service.dart
│   │       ├── hotel_management_service.dart
│   │       └── ordering_service.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── widgets/
│       ├── shared/                  # Shared widgets
│       └── owner/                   # Owner-specific widgets
├── features/
│   ├── shared/                      # Shared features
│   │   ├── splash/
│   │   ├── onboarding/
│   │   └── role_selection/
│   ├── customer/                    # Customer features
│   │   ├── auth/
│   │   ├── home/
│   │   ├── search/
│   │   ├── hotel/
│   │   ├── booking/
│   │   ├── trips/
│   │   ├── profile/
│   │   └── ...
│   └── owner/                       # Owner features
│       ├── auth/
│       ├── dashboard/
│       ├── bookings/
│       ├── rooms/
│       ├── earnings/
│       ├── profile/
│       └── ...
└── main.dart
```

## Implementation Steps

### Phase 1: Organize Services (Priority: HIGH)
1. Create service folders: `shared/`, `customer/`, `owner/`
2. Move services to appropriate folders
3. Update imports across the app

### Phase 2: Organize Features (Priority: HIGH)
1. Create feature folders: `shared/`, `customer/`, `owner/`
2. Move features to appropriate folders
3. Rename conflicting features (e.g., `customer_auth`, `owner_auth`)
4. Update imports and routes

### Phase 3: Clean Up Constants (Priority: MEDIUM)
1. Consolidate color constants
2. Keep API config centralized
3. Separate owner-specific constants

### Phase 4: Update Navigation (Priority: HIGH)
1. Update route paths to reflect new structure
2. Update navigation imports
3. Test all navigation flows

### Phase 5: Testing (Priority: HIGH)
1. Fix all compilation errors
2. Test customer flow
3. Test owner flow
4. Test role switching

## Benefits
- Clear separation of concerns
- No naming conflicts
- Easy to maintain and extend
- Better code organization
- Easier onboarding for new developers
