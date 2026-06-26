import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/bookings/presentation/screens/booking_management_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart'
    as owner_profile;

class OwnerNavigation extends StatefulWidget {
  const OwnerNavigation({super.key});

  @override
  State<OwnerNavigation> createState() => _OwnerNavigationState();
}

class _OwnerNavigationState extends State<OwnerNavigation> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    // Ensure tokens are refreshed when owner navigation is initialized
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTokens();
    });
  }

  void _refreshTokens() {
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.refreshAllServiceTokens();
      debugPrint('✅ Owner navigation tokens refreshed');
    } catch (e) {
      debugPrint('❌ Error refreshing tokens: $e');
    }
  }

  // 4 tabs: Dashboard, Bookings, Earnings, Profile (QR FAB opens separate route)
  // NOT const - screens must rebuild with fresh provider data on each navigation
  final _screens = [
    const DashboardScreen(),
    const BookingManagementScreen(),
    const EarningsScreen(),
    const owner_profile.ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    if (_selectedIndex == index) return;
    HapticFeedback.selectionClick();
    setState(() => _selectedIndex = index);
  }

  void _openQrScanner() {
    HapticFeedback.mediumImpact();
    context.push('/qr-checkin');
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    debugPrint(
      '🏠 OwnerNavigation: Building with selectedIndex: $_selectedIndex',
    );

    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      // Floating QR button sits above the navbar
      floatingActionButton: _QrFab(onTap: _openQrScanner),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: _OwnerBottomNav(
        selectedIndex: _selectedIndex,
        onTap: _onItemTapped,
        isDark: isDark,
      ),
    );
  }
}

// ─── QR FAB ──────────────────────────────────────────────────────────────────

class _QrFab extends StatelessWidget {
  final VoidCallback onTap;
  const _QrFab({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 58,
        height: 58,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE60023), Color(0xFFB0001A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFE60023).withOpacity(0.45),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: const Icon(
          Icons.qr_code_scanner_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }
}

// ─── Bottom Nav ───────────────────────────────────────────────────────────────

class _OwnerBottomNav extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onTap;
  final bool isDark;

  const _OwnerBottomNav({
    required this.selectedIndex,
    required this.onTap,
    required this.isDark,
  });

  // 4 real tabs — center slot is the FAB notch
  static const _leftItems = [
    _NavItem(Icons.dashboard_rounded, Icons.dashboard_outlined, 'Dashboard', 0),
    _NavItem(
      Icons.calendar_today_rounded,
      Icons.calendar_today_outlined,
      'Bookings',
      1,
    ),
  ];

  static const _rightItems = [
    _NavItem(
      Icons.account_balance_wallet_rounded,
      Icons.account_balance_wallet_outlined,
      'Earnings',
      2,
    ),
    _NavItem(Icons.person_rounded, Icons.person_outline_rounded, 'Profile', 3),
  ];

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    const primary = Color(0xFFE60023);

    debugPrint(
      '📱 OwnerBottomNav: Building with selectedIndex: $selectedIndex',
    );

    return BottomAppBar(
      color: bg,
      elevation: 12,
      notchMargin: 8,
      shape: const CircularNotchedRectangle(),
      child: SizedBox(
        height: 60,
        child: Row(
          children: [
            // Left tabs
            ..._leftItems.map((item) => _buildTab(item, primary, isDark)),
            // Center spacer for FAB notch
            const Expanded(child: SizedBox()),
            // Right tabs
            ..._rightItems.map((item) => _buildTab(item, primary, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(_NavItem item, Color primary, bool isDark) {
    final isSelected = selectedIndex == item.index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(item.index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected
                    ? primary.withOpacity(0.12)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                isSelected ? item.activeIcon : item.icon,
                size: 22,
                color: isSelected
                    ? primary
                    : (isDark ? Colors.white38 : const Color(0xFF9AA0A6)),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? primary
                    : (isDark ? Colors.white38 : const Color(0xFF9AA0A6)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData activeIcon;
  final IconData icon;
  final String label;
  final int index;
  const _NavItem(this.activeIcon, this.icon, this.label, this.index);
}
