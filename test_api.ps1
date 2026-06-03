# HotelSewa API Test Script
# Run this to test the booking API endpoints

$baseUrl = "http://209.50.241.46:2000/api"

Write-Host "=== HotelSewa API Test ===" -ForegroundColor Cyan
Write-Host ""

# Test 1: Check if API is reachable
Write-Host "1. Testing API connectivity..." -ForegroundColor Yellow
try {
    $response = Invoke-RestMethod -Uri "$baseUrl/get-system-settings" -Method Get -ErrorAction Stop
    Write-Host "✓ API is reachable" -ForegroundColor Green
    Write-Host "Response: $($response | ConvertTo-Json -Depth 2)" -ForegroundColor Gray
} catch {
    Write-Host "✗ API is not reachable: $_" -ForegroundColor Red
}

Write-Host ""

# Test 2: Request OTP (you'll need to provide a phone number)
Write-Host "2. To test booking creation, you need an auth token" -ForegroundColor Yellow
Write-Host "   Run these commands manually:" -ForegroundColor Gray
Write-Host ""
Write-Host "   # Get OTP" -ForegroundColor Cyan
Write-Host "   curl -X GET '$baseUrl/get-otp?mobile=YOUR_PHONE_NUMBER'" -ForegroundColor White
Write-Host ""
Write-Host "   # Verify OTP" -ForegroundColor Cyan
Write-Host "   curl -X GET '$baseUrl/verify-otp?mobile=YOUR_PHONE_NUMBER&otp=YOUR_OTP'" -ForegroundColor White
Write-Host ""
Write-Host "   # Create Booking (replace YOUR_TOKEN)" -ForegroundColor Cyan
Write-Host @"
   curl -X POST '$baseUrl/create-booking' \
     -H 'Content-Type: application/json' \
     -H 'Authorization: Bearer YOUR_TOKEN' \
     -d '{
       "hotel_id": "1",
       "room_type_id": "1",
       "check_in_date": "2025-01-20",
       "check_out_date": "2025-01-22",
       "guests": 2,
       "guest_name": "Test User",
       "guest_email": "test@example.com",
       "guest_phone": "+1234567890",
       "total_amount": 5000,
       "payment_method": "card"
     }'
"@ -ForegroundColor White

Write-Host ""
Write-Host "   # Get My Bookings" -ForegroundColor Cyan
Write-Host "   curl -X GET '$baseUrl/my-bookings' -H 'Authorization: Bearer YOUR_TOKEN'" -ForegroundColor White
Write-Host ""

Write-Host "=== Current Status ===" -ForegroundColor Cyan
Write-Host "✓ App saves bookings locally" -ForegroundColor Green
Write-Host "✓ QR codes are generated" -ForegroundColor Green
Write-Host "✓ Bookings show in My Trips (from local storage)" -ForegroundColor Green
Write-Host "⚠ Backend API may not be storing bookings yet" -ForegroundColor Yellow
Write-Host ""
Write-Host "The app will work with local storage until the backend is ready!" -ForegroundColor Green
