import 'package:flutter/material.dart';
import '../constants/app_constants.dart';

/// Shared filter chip used across bookings, rooms, and other screens.
/// Uses InkWell instead of GestureDetector+AnimatedContainer for zero jank.
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? activeColor;

  const AppFilterChip({
    Key? key,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.activeColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = activeColor ?? const Color(AppConstants.primaryRed);

    return Material(
      color: isSelected ? color : (isDark ? const Color(0xFF2C2C2C) : Colors.white),
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? color : const Color(AppConstants.mediumGray).withOpacity(0.3),
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.white : const Color(AppConstants.mediumGray),
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}
