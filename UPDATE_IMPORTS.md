# Import Update Guide

## Old vs New Import Paths

### Services

#### Shared Services
```dart
// OLD
import '../../../core/services/api_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/cache_service.dart';

// NEW
import '../../../core/services/shared/api_service.dart';
import '../../../core/services/shared/auth_service.dart';
import '../../../core/services/shared/cache_service.dart';

// OR use barrel export
import '../../../core/services/shared/services.dart';
```

#### Customer Services
```dart
// OLD
import '../../../core/services/home_service.dart';

// NEW
import '../../../core/services/customer/home_service.dart';
```

#### Owner Services
```dart
// OLD
import '../../../core/services/dashboard_service.dart';

// NEW
import '../../../core/services/owner/dashboard_service.dart';
```

### Features

#### Shared Features
```dart
// OLD
import '../../features/splash/presentation/splash_screen.dart';

// NEW
import '../../features/shared/splash/presentation/splash_screen.dart';
```

#### Customer Features
```dart
// OLD
import '../../features/home/presentation/home_screen.dart';

// NEW
import '../../features/customer/home/presentation/home_screen.dart';
```

#### Owner Features
```dart
// OLD
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';

// NEW
import '../../features/owner/dashboard/presentation/screens/dashboard_screen.dart';
```

## Automated Update Script

Run this PowerShell script to update all imports:

```powershell
# Update service imports
Get-ChildItem -Path "flutter/lib" -Recurse -Filter "*.dart" | ForEach-Object {
    $content = Get-Content $_.FullName -Raw
    
    # Update shared service imports
    $content = $content -replace "import '([\.\/]+)core/services/api_service\.dart'", "import '`$1core/services/shared/api_service.dart'"
    $content = $content -replace "import '([\.\/]+)core/services/auth_service\.dart'", "import '`$1core/services/shared/auth_service.dart'"
    $content = $content -replace "import '([\.\/]+)core/services/cache_service\.dart'", "import '`$1core/services/shared/cache_service.dart'"
    
    # Update customer service imports
    $content = $content -replace "import '([\.\/]+)core/services/home_service\.dart'", "import '`$1core/services/customer/home_service.dart'"
    
    # Update feature imports
    $content = $content -replace "import '([\.\/]+)features/splash/", "import '`$1features/shared/splash/"
    $content = $content -replace "import '([\.\/]+)features/home/", "import '`$1features/customer/home/"
    
    Set-Content $_.FullName $content -NoNewline
}
```

## Manual Updates Required

Some imports may need manual review:
1. Conflicting feature names (auth, profile, chat)
2. Relative path depth changes
3. Circular dependencies

## Verification

After updating imports:
1. Run `flutter analyze`
2. Fix any remaining import errors
3. Test build: `flutter build apk --debug`
