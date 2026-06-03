import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../widgets/in_stay_ordering_card.dart';
import 'menu_screen.dart';
import 'my_orders_screen.dart';

/// Demo screen to showcase the In-Stay Ordering System
/// This can be used for testing or as a reference implementation
class OrderingDemoScreen extends StatelessWidget {
  const OrderingDemoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('In-Stay Ordering Demo'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF667EEA),
                  Color(0xFF764BA2),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🛎️ In-Stay Ordering System',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'A complete ordering solution for hotel guests',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Features
          const Text(
            'Features',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _FeatureCard(
            icon: Icons.restaurant_menu,
            title: 'Browse Menu',
            description: 'View categorized menu with images and prices',
            color: AppColors.primary,
          ),
          _FeatureCard(
            icon: Icons.shopping_cart,
            title: 'Smart Cart',
            description: 'Add items, adjust quantities, add special notes',
            color: AppColors.info,
          ),
          _FeatureCard(
            icon: Icons.payment,
            title: 'Multiple Payment Methods',
            description: 'Room charge, cash, or card payment',
            color: AppColors.success,
          ),
          _FeatureCard(
            icon: Icons.track_changes,
            title: 'Real-time Tracking',
            description: 'Monitor order status with visual timeline',
            color: AppColors.purple,
          ),
          _FeatureCard(
            icon: Icons.notifications_active,
            title: 'Push Notifications',
            description: 'Get notified on every status change',
            color: AppColors.warning,
          ),
          const SizedBox(height: 24),

          // Demo Actions
          const Text(
            'Try It Out',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),

          // Entry Point Widget Demo
          InStayOrderingCard(
            hotelId: 1, // Demo hotel ID
            hotelName: 'Grand Hotel Demo',
            bookingId: 1, // Demo booking ID
            isActiveBooking: true,
          ),
          const SizedBox(height: 16),

          // Direct Navigation Buttons
          _DemoButton(
            icon: Icons.restaurant_menu,
            label: 'Browse Menu',
            description: 'View the full menu with categories',
            color: AppColors.primary,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MenuScreen(
                    hotelId: 1,
                    hotelName: 'Grand Hotel Demo',
                    bookingId: 1,
                  ),
                ),
              );
            },
          ),
          _DemoButton(
            icon: Icons.receipt_long,
            label: 'My Orders',
            description: 'View order history and track status',
            color: AppColors.info,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const MyOrdersScreen(
                    bookingId: 1,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Categories
          const Text(
            'Service Categories',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            children: const [
              _CategoryCard(icon: '🍽️', label: 'Food'),
              _CategoryCard(icon: '🥤', label: 'Drinks'),
              _CategoryCard(icon: '💆', label: 'Spa'),
              _CategoryCard(icon: '👕', label: 'Laundry'),
              _CategoryCard(icon: '🚗', label: 'Transport'),
              _CategoryCard(icon: '📦', label: 'Other'),
            ],
          ),
          const SizedBox(height: 24),

          // Order Status Flow
          const Text(
            'Order Status Flow',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                _StatusStep(
                  icon: '⏳',
                  label: 'Pending',
                  description: 'Order received',
                  color: AppColors.warning,
                ),
                _StatusArrow(),
                _StatusStep(
                  icon: '✅',
                  label: 'Confirmed',
                  description: 'Order accepted',
                  color: AppColors.info,
                ),
                _StatusArrow(),
                _StatusStep(
                  icon: '👨‍🍳',
                  label: 'Preparing',
                  description: 'Being prepared',
                  color: AppColors.info,
                ),
                _StatusArrow(),
                _StatusStep(
                  icon: '🔔',
                  label: 'Ready',
                  description: 'On the way',
                  color: AppColors.purple,
                ),
                _StatusArrow(),
                _StatusStep(
                  icon: '✅',
                  label: 'Delivered',
                  description: 'Enjoy!',
                  color: AppColors.success,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.info),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'This is a demo screen. Replace demo IDs with real hotel and booking IDs in production.',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.info,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  const _FeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.gray,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DemoButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _DemoButton({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.gray,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.gray),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final String icon;
  final String label;

  const _CategoryCard({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(icon, style: const TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusStep extends StatelessWidget {
  final String icon;
  final String label;
  final String description;
  final Color color;

  const _StatusStep({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(icon, style: const TextStyle(fontSize: 24)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.gray,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatusArrow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          const SizedBox(width: 24),
          Container(
            width: 2,
            height: 20,
            color: AppColors.lightGray,
          ),
        ],
      ),
    );
  }
}


