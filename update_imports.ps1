# Automated Import Update Script
# This script updates import paths to match the new organized structure

Write-Host "Starting import updates..." -ForegroundColor Green

$dartFiles = Get-ChildItem -Path "lib" -Recurse -Filter "*.dart"
$totalFiles = $dartFiles.Count
$updatedFiles = 0

foreach ($file in $dartFiles) {
    $content = Get-Content $file.FullName -Raw
    $originalContent = $content
    
    # Update shared service imports
    $content = $content -replace "import '(\.\./)+(core/services/)api_service\.dart'", "import '`$1`$2shared/api_service.dart'"
    $content = $content -replace "import '(\.\./)+(core/services/)auth_service\.dart'", "import '`$1`$2shared/auth_service.dart'"
    $content = $content -replace "import '(\.\./)+(core/services/)cache_service\.dart'", "import '`$1`$2shared/cache_service.dart'"
    $content = $content -replace "import '(\.\./)+(core/services/)firebase_notification_handler\.dart'", "import '`$1`$2shared/firebase_notification_handler.dart'"
    
    # Update customer service imports
    $content = $content -replace "import '(\.\./)+(core/services/)home_service\.dart'", "import '`$1`$2customer/home_service.dart'"
    $content = $content -replace "import '(\.\./)+(core/services/)recommendation_service\.dart'", "import '`$1`$2customer/recommendation_service.dart'"
    
    # Update owner service imports
    $ownerServices = @(
        "auth_account_service", "blackout_dates_service", "booking_requests_service",
        "bookings_management_service", "chat_service", "checkin_service",
        "competitor_service", "currency_service", "dashboard_service",
        "earnings_service", "guest_messaging_service", "hotel_management_service",
        "ical_service", "invoice_service", "loyalty_service",
        "media_service", "offers_service", "ordering_service",
        "orders_service", "payment_service", "price_alerts_service",
        "pricing_service", "reviews_service", "tax_service", "waitlist_service"
    )
    
    foreach ($service in $ownerServices) {
        $content = $content -replace "import '(\.\./)+(core/services/)$service\.dart'", "import '`$1`$2owner/$service.dart'"
    }
    
    # Update shared feature imports
    $content = $content -replace "import '(\.\./)+(features/)splash/", "import '`$1`$2shared/splash/"
    $content = $content -replace "import '(\.\./)+(features/)onboarding/", "import '`$1`$2shared/onboarding/"
    $content = $content -replace "import '(\.\./)+(features/)role_selection/", "import '`$1`$2shared/role_selection/"
    $content = $content -replace "import '(\.\./)+(features/)notifications/", "import '`$1`$2shared/notifications/"
    
    # Update customer feature imports
    $customerFeatures = @(
        "home", "search", "hotel", "booking", "trips", "saved", "wallet",
        "payment_methods", "coupons", "filters", "gallery", "amenities",
        "room_types", "pricing", "reviews", "map", "ai_chat", "advanced",
        "location", "help", "about", "settings", "invite", "privacy",
        "in_stay_ordering", "debug", "auth", "profile", "chat"
    )
    
    foreach ($feature in $customerFeatures) {
        $content = $content -replace "import '(\.\./)+(features/)$feature/", "import '`$1`$2customer/$feature/"
    }
    
    # Update owner feature imports
    $ownerFeatures = @(
        "analytics", "dashboard", "bookings", "calendar", "checkin",
        "documents", "earnings", "loyalty", "messaging", "offers",
        "orders", "price_alerts", "reports", "rooms", "support", "withdrawals"
    )
    
    foreach ($feature in $ownerFeatures) {
        $content = $content -replace "import '(\.\./)+(features/)$feature/", "import '`$1`$2owner/$feature/"
    }
    
    # Save if changed
    if ($content -ne $originalContent) {
        Set-Content $file.FullName $content -NoNewline
        $updatedFiles++
        Write-Host "Updated: $($file.Name)" -ForegroundColor Yellow
    }
}

Write-Host "`nImport update complete!" -ForegroundColor Green
Write-Host "Total files scanned: $totalFiles" -ForegroundColor Cyan
Write-Host "Files updated: $updatedFiles" -ForegroundColor Cyan
Write-Host "`nNext steps:" -ForegroundColor Green
Write-Host "1. Run: flutter pub get" -ForegroundColor White
Write-Host "2. Run: flutter analyze" -ForegroundColor White
Write-Host "3. Fix any remaining errors manually" -ForegroundColor White
Write-Host "4. Run: flutter build apk --debug" -ForegroundColor White
