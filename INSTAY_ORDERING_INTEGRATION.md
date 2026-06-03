# 🛎️ In-Stay Ordering System - Integration Guide

## 📋 Overview

This guide shows you how to integrate the beautiful in-stay ordering system into your HotelSewa app.

## ✅ What's Been Created

### Models
- ✅ `MenuItem` - Menu item with category, price, image, prep time
- ✅ `Order` - Order with status tracking and timeline
- ✅ `OrderItem` - Individual items in an order
- ✅ `CartItem` - Shopping cart item with quantity and notes

### Services
- ✅ `OrderService` - Updated with menu and order endpoints

### State Management
- ✅ `CartProvider` - Cart state with add, remove, update operations

### Screens
- ✅ `MenuScreen` - Browse menu by category with tabs
- ✅ `CartScreen` - Review cart and checkout
- ✅ `OrderConfirmationScreen` - Success screen with confetti
- ✅ `MyOrdersScreen` - Order history and tracking
- ✅ `OrderDetailsScreen` - Detailed order view with timeline

### Widgets
- ✅ `MenuItemCard` - Beautiful menu item display
- ✅ `CartFAB` - Floating cart button with badge
- ✅ `OrderCard` - Order list item
- ✅ `InStayOrderingCard` - Entry point widget

## 🚀 Quick Integration Steps

### Step 1: Install Dependencies

Run this command:
```bash
flutter pub get
```

This will install:
- `provider` - State management
- `confetti` - Celebration animation

### Step 2: Add to Hotel Details Screen

Find your hotel details screen (likely in `lib/features/hotel/presentation/screens/`) and add:

```dart
import 'package:hotelsewa_app/features/in_stay_ordering/presentation/widgets/in_stay_ordering_card.dart';

// In your build method, add this card:
InStayOrderingCard(
  hotelId: hotel.id,
  hotelName: hotel.name,
  isActiveBooking: false, // User hasn't checked in yet
)
```

### Step 3: Add to Active Booking Screen

Find your booking details screen (likely in `lib/features/booking/presentation/screens/`) and add:

```dart
import 'package:hotelsewa_app/features/in_stay_ordering/presentation/widgets/in_stay_ordering_card.dart';

// Only show if booking is active (between check-in and check-out dates)
if (booking.status == 'confirmed' && _isCurrentlyStaying(booking)) {
  InStayOrderingCard(
    hotelId: booking.hotelId,
    hotelName: booking.hotelName,
    bookingId: booking.id,
    isActiveBooking: true, // Shows "My Orders" button
  )
}

// Helper method to check if currently staying
bool _isCurrentlyStaying(Booking booking) {
  final now = DateTime.now();
  final checkIn = DateTime.parse(booking.checkInDate);
  final checkOut = DateTime.parse(booking.checkOutDate);
  return now.isAfter(checkIn) && now.isBefore(checkOut);
}
```

### Step 4: Add to Main Navigation (Optional)

If you want a dedicated "Room Service" tab in your main navigation:

```dart
// In your bottom navigation bar
BottomNavigationBarItem(
  icon: Icon(Icons.room_service),
  label: 'Room Service',
)

// In your navigation handler
case 2: // Room Service tab
  return MyOrdersScreen();
```

### Step 5: Add to Home Screen (Optional)

Add a quick access card on the home screen:

```dart
// In home screen
Container(
  margin: EdgeInsets.all(16),
  child: ElevatedButton.icon(
    onPressed: () {
      // Navigate to menu if user has active booking
      if (activeBooking != null) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(
              hotelId: activeBooking.hotelId,
              hotelName: activeBooking.hotelName,
              bookingId: activeBooking.id,
            ),
          ),
        );
      } else {
        // Show message to book first
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please book a hotel first')),
        );
      }
    },
    icon: Icon(Icons.restaurant_menu),
    label: Text('Order Room Service'),
  ),
)
```

## 🎨 Customization Examples

### Change Theme Colors

The system uses your app's existing color scheme from `AppColors`. To customize:

```dart
// In lib/core/constants/app_colors.dart
static const Color primary = Color(0xFFE60023); // Your brand color
```

### Add Custom Categories

To add new menu categories, update the backend API and then:

```dart
// In menu_item.dart, add new category icon
String get categoryIcon {
  switch (category) {
    case 'breakfast':
      return '🍳';
    case 'desserts':
      return '🍰';
    // ... existing categories
  }
}
```

### Customize Order Status Messages

```dart
// In order.dart
String get statusLabel {
  switch (status) {
    case 'pending':
      return 'Order Received'; // Custom message
    case 'confirmed':
      return 'We\'re on it!';
    // ... etc
  }
}
```

## 📱 Example Integration Locations

### 1. Hotel Details Page
**Location**: `lib/features/hotel/presentation/screens/hotel_details_screen.dart`

Add after hotel amenities section:
```dart
// Amenities section
_buildAmenities(),

SizedBox(height: 24),

// In-Stay Ordering Card
InStayOrderingCard(
  hotelId: widget.hotelId,
  hotelName: hotel.name,
),

SizedBox(height: 24),

// Reviews section
_buildReviews(),
```

### 2. Booking Confirmation Screen
**Location**: `lib/features/booking/presentation/screens/booking_confirmation_screen.dart`

Add as a quick action:
```dart
Column(
  children: [
    // Booking details
    _buildBookingDetails(),
    
    SizedBox(height: 20),
    
    // Quick Actions
    Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    SizedBox(height: 12),
    
    InStayOrderingCard(
      hotelId: booking.hotelId,
      hotelName: booking.hotelName,
      bookingId: booking.id,
      isActiveBooking: true,
    ),
  ],
)
```

### 3. My Trips Screen
**Location**: `lib/features/trips/presentation/screens/trips_screen.dart`

Add button to active bookings:
```dart
// For each active booking card
Row(
  children: [
    Expanded(
      child: ElevatedButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => MenuScreen(
              hotelId: booking.hotelId,
              hotelName: booking.hotelName,
              bookingId: booking.id,
            ),
          ),
        ),
        child: Text('Order Room Service'),
      ),
    ),
    SizedBox(width: 12),
    OutlinedButton(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => MyOrdersScreen(bookingId: booking.id),
        ),
      ),
      child: Text('My Orders'),
    ),
  ],
)
```

## 🔔 Push Notification Setup

The system automatically handles push notifications through your existing Firebase setup. Make sure:

1. ✅ Firebase is configured (already done in your app)
2. ✅ `FirebaseNotificationHandler` is initialized (already done)
3. ✅ Backend sends notifications on order status changes

No additional setup needed!

## 🧪 Testing Checklist

- [ ] Browse menu without authentication (public endpoint)
- [ ] Add items to cart
- [ ] Update quantities in cart
- [ ] Add special notes to items
- [ ] Place order with active booking
- [ ] View order confirmation with confetti
- [ ] Track order status
- [ ] Cancel pending order
- [ ] View order history
- [ ] Receive push notifications (test with backend)

## 🐛 Common Issues & Solutions

### Issue: "No route defined for MenuScreen"
**Solution**: You're using direct navigation, which is correct. No route definition needed.

### Issue: Cart not persisting
**Solution**: Cart is intentionally session-based. It clears after order placement or app restart.

### Issue: Images not loading
**Solution**: Check your API base URL in `EnvConfig` and ensure image URLs are absolute.

### Issue: Can't place order
**Solution**: Verify:
- User is authenticated (has authToken)
- Booking is active (between check-in and check-out)
- bookingId is passed correctly

## 📊 Analytics Integration (Optional)

Track ordering events:

```dart
// In menu_screen.dart
void _trackMenuView() {
  // Your analytics service
  AnalyticsService.logEvent('menu_viewed', {
    'hotel_id': widget.hotelId,
    'hotel_name': widget.hotelName,
  });
}

// In cart_screen.dart
void _trackOrderPlaced(Order order) {
  AnalyticsService.logEvent('order_placed', {
    'order_id': order.id,
    'total_amount': order.totalAmount,
    'items_count': order.items.length,
  });
}
```

## 🎯 Next Steps

1. ✅ Run `flutter pub get`
2. ✅ Add `InStayOrderingCard` to hotel details screen
3. ✅ Add to active booking screens
4. ✅ Test the complete flow
5. ✅ Customize colors/text as needed
6. ✅ Deploy and enjoy! 🎉

## 📞 Support

If you encounter any issues:
1. Check the README in `lib/features/in_stay_ordering/README.md`
2. Review the API documentation
3. Verify your backend endpoints are working

---

**Happy Ordering! 🛎️✨**
