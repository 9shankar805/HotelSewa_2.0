import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import 'ordering_dashboard_screen.dart';

/// Re-export: orders_screen redirects to the full ordering dashboard.
class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});
  @override
  Widget build(BuildContext context) => const OrderingDashboardScreen();
}
