import 'package:flutter/material.dart';

class OnboardingItem {
  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  /// Path to a Lottie animation asset (optional — falls back to icon if null)
  final String? lottiePath;
  final Color accentColor;

  const OnboardingItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    this.lottiePath,
    this.accentColor = const Color(0xFFE60023),
  });
}

const List<OnboardingItem> onboardingData = [
  OnboardingItem(
    id: '1',
    title: 'Find Perfect Hotels',
    subtitle: 'Browse hundreds of verified hotels across Nepal — from budget stays to luxury resorts.',
    icon: Icons.hotel_rounded,
    accentColor: Color(0xFFE60023),
  ),
  OnboardingItem(
    id: '2',
    title: 'Book in Seconds',
    subtitle: 'Secure your room instantly with Khalti, eSewa, or card. Instant confirmation, every time.',
    icon: Icons.bolt_rounded,
    accentColor: Color(0xFF667EEA),
  ),
  OnboardingItem(
    id: '3',
    title: 'Earn While You Stay',
    subtitle: 'Collect loyalty points on every booking. Redeem for discounts, upgrades, and more.',
    icon: Icons.workspace_premium_rounded,
    accentColor: Color(0xFFFFB800),
  ),
];
