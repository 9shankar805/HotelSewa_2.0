import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'menu_management_screen.dart';
import 'order_management_screen.dart';
import 'order_analytics_screen.dart';
import '../../../../../../../core/constants/app_colors.dart';

class OrderingDashboardScreen extends StatelessWidget {
  const OrderingDashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In-Stay Ordering System'),
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            title: 'Menu Management',
            subtitle: 'Manage items & categories',
            icon: Icons.restaurant_menu,
            color: AppColors.warning,
            onTap: () => context.push('/menu-management'),
          ),
          _buildDashboardCard(
            context,
            title: 'Orders',
            subtitle: 'View & manage orders',
            icon: Icons.receipt_long,
            color: AppColors.info,
            onTap: () => context.push('/order-management'),
          ),
          _buildDashboardCard(
            context,
            title: 'Analytics',
            subtitle: 'Revenue & insights',
            icon: Icons.analytics,
            color: AppColors.success,
            onTap: () => context.push('/order-analytics'),
          ),
          _buildDashboardCard(
            context,
            title: 'Settings',
            subtitle: 'Configure ordering',
            icon: Icons.settings,
            color: Colors.purple,
            onTap: () => context.push('/settings'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 32, color: color),
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: AppColors.gray[600],
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
