# 🛎️ In-Stay Ordering System

A beautiful, comprehensive in-stay ordering system for hotel guests to order food, drinks, spa services, laundry, and more directly to their room.

## ✨ Features

### Guest Features
- 📱 Browse hotel menu by category (Food, Drinks, Spa, Laundry, Transport, Other)
- 🛒 Add items to cart with quantity and special notes
- 💳 Multiple payment methods (Room Charge, Cash, Card)
- 📦 Real-time order tracking with status updates
- 🔔 Push notifications for order status changes
- ❌ Cancel orders (if pending/confirmed)
- 📜 View order history

### UI/UX Highlights
- 🎨 Beautiful gradient cards and modern design
- 🎉 Confetti animation on order confirmation
- 📊 Visual order timeline/progress tracker
- 🖼️ Image support for menu items
- 💫 Smooth animations and transitions
- 📱 Fully responsive design

## 📁 Project Structure

```
lib/features/in_stay_ordering/
├── data/
│   └── models/
│       ├── menu_item.dart          # Menu item model
│       ├── order.dart               # Order model
│       ├── order_item.dart          # Order item model
│       └── cart_item.dart           # Cart item model
├── presentation/
│   ├── providers/
│   │   └── cart_provider.dart       # Cart state management
│   ├── screens/
│   │   ├── menu_screen.dart         # Browse menu by category
│   │   ├── cart_screen.dart         # Review cart & checkout
│   │   ├── order_confirmation_screen.dart  # Success screen
│   │   ├── my_orders_screen.dart    # Order history
│   │   └── order_details_screen.dart # Track order status
│   └── widgets/
│       ├── menu_item_card.dart      # Menu item display
│       ├── cart_fab.dart            # Floating cart button
│       ├── order_card.dart          # Order list item
│       └── in_stay_ordering_card.dart # Entry point widget
└── README.md
```

## 🚀 Quick Start

### 1. Add to Your Screen

Add the entry point widget to hotel details or booking screens:

```dart
import 'package:hotelsewa_app/features/in_stay_ordering/presentation/widgets/in_stay_ordering_card.dart';

// In your widget build method:
InStayOrderingCard(
  hotelId: 12,
  hotelName: 'Grand Hotel',
  bookingId: 45, // Optional: current booking ID
  isActiveBooking: true, // Show "My Orders" button
)
```

### 2. Direct Navigation

Navigate directly to menu or orders:

```dart
// Browse Menu
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MenuScreen(
      hotelId: hotelId,
      hotelName: hotelName,
      bookingId: bookingId,
    ),
  ),
);

// My Orders
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => MyOrdersScreen(
      bookingId: bookingId, // Optional filter
    ),
  ),
);
```

## 🎯 User Flow

### Ordering Flow
1. **Browse Menu** → Guest views categorized menu items
2. **Add to Cart** → Select items, add notes, adjust quantity
3. **Review Cart** → View summary, add special instructions
4. **Select Payment** → Choose payment method
5. **Place Order** → Submit order
6. **Confirmation** → See order details with confetti 🎉
7. **Track Order** → Monitor real-time status updates

### Order Status Flow
```
Pending → Confirmed → Preparing → Ready → Delivered
```

## 🎨 Design System

### Colors
- Primary: `#667EEA` (Purple gradient)
- Success: `#10B981` (Green)
- Warning: `#F59E0B` (Orange)
- Error: `#EF4444` (Red)
- Info: `#3B82F6` (Blue)

### Category Icons
- 🍽️ Food
- 🥤 Drinks
- 💆 Spa & Wellness
- 👕 Laundry
- 🚗 Transport
- 📦 Other Services

## 📊 API Integration

The system uses the existing `OrderService` in `lib/core/services/order_service.dart`:

### Endpoints Used
- `GET /hotels/{hotelId}/menu` - Browse menu (public)
- `POST /orders/place` - Place order (auth required)
- `GET /orders/my-orders` - Get order history (auth required)
- `POST /orders/{id}/cancel` - Cancel order (auth required)

## 🔔 Push Notifications

The system automatically sends push notifications for:
- ✅ Order Confirmed
- 👨‍🍳 Order Being Prepared
- 🔔 Order Ready
- ✅ Order Delivered
- ❌ Order Cancelled

## 💡 Usage Examples

### Example 1: Hotel Details Screen
```dart
// Add to hotel details page
Column(
  children: [
    // ... other hotel info
    InStayOrderingCard(
      hotelId: hotel.id,
      hotelName: hotel.name,
      isActiveBooking: false, // Not checked in yet
    ),
  ],
)
```

### Example 2: Active Booking Screen
```dart
// Add to booking details during stay
InStayOrderingCard(
  hotelId: booking.hotelId,
  hotelName: booking.hotelName,
  bookingId: booking.id,
  isActiveBooking: true, // Show order tracking
)
```

### Example 3: Custom Menu Button
```dart
ElevatedButton(
  onPressed: () {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MenuScreen(
          hotelId: hotelId,
          hotelName: hotelName,
          bookingId: bookingId,
        ),
      ),
    );
  },
  child: const Text('Order Room Service'),
)
```

## 🛠️ Customization

### Change Category Icons
Edit `menu_item.dart`:
```dart
String get categoryIcon {
  switch (category) {
    case 'food':
      return '🍕'; // Change icon
    // ...
  }
}
```

### Modify Tax Rate
Edit `cart_provider.dart`:
```dart
double get tax => subtotal * 0.13; // Change from 13%
```

### Add New Payment Method
Edit `cart_screen.dart` and add new `_PaymentMethodTile`:
```dart
_PaymentMethodTile(
  value: 'wallet',
  groupValue: _paymentMethod,
  title: 'Digital Wallet',
  subtitle: 'Pay with e-wallet',
  icon: Icons.account_balance_wallet,
  onChanged: (value) {
    setState(() => _paymentMethod = value!);
  },
)
```

## 📦 Dependencies

Required packages (already added to `pubspec.yaml`):
- `provider: ^6.1.2` - State management
- `confetti: ^0.7.0` - Celebration animation
- `intl: ^0.19.0` - Date formatting
- `cached_network_image: ^3.3.1` - Image caching

## 🎯 Best Practices

1. **Always pass bookingId** when user has an active booking
2. **Check authentication** before allowing orders
3. **Validate booking dates** - only allow orders during stay
4. **Handle offline mode** - show appropriate messages
5. **Clear cart** after successful order
6. **Refresh orders** when returning to order list

## 🐛 Troubleshooting

### Cart not updating?
Make sure `CartProvider` is wrapped in `MultiProvider` in `main.dart`.

### Images not loading?
Check that `CachedImage` widget is properly configured with your API base URL.

### Orders not showing?
Verify the user is authenticated and has the correct `authToken` in SharedPreferences.

### Confetti not playing?
Ensure `confetti` package is added to `pubspec.yaml` and run `flutter pub get`.

## 🚀 Future Enhancements

- [ ] Schedule orders for later
- [ ] Repeat previous orders
- [ ] Favorite items
- [ ] Order ratings and reviews
- [ ] Dietary filters (vegan, halal, etc.)
- [ ] Multi-language menu
- [ ] Voice ordering
- [ ] AR menu preview

## 📝 License

Part of HotelSewa App - All rights reserved.

---

**Built with ❤️ using Flutter**
