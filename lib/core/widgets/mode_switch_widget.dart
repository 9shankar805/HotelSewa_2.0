import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../providers/app_mode_provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';

/// Pill toggle that switches between Customer and Owner mode.
class ModeSwitchWidget extends StatelessWidget {
  const ModeSwitchWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppModeProvider>();
    final isOwner = provider.isOwnerMode;

    return GestureDetector(
      onTap: () => _switchMode(context, provider),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: isOwner ? const Color(0xFF1A1A2E) : const Color(0xFFE60023),
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _pill('Customer', Icons.person_outline, !isOwner, const Color(0xFFE60023)),
            const SizedBox(width: 2),
            _pill('Owner', Icons.business_outlined, isOwner, const Color(0xFF1A1A2E)),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, IconData icon, bool active, Color activeColor) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: active ? Colors.white : Colors.transparent,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: active ? activeColor : Colors.white70),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: active ? activeColor : Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _switchMode(BuildContext context, AppModeProvider provider) async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    if (provider.isOwnerMode) {
      // Already in owner mode — switch back to customer
      await provider.setOwnerMode(false);
      if (context.mounted) context.go('/home');
      return;
    }

    // Switching TO owner mode — must be authenticated
    if (!auth.isAuthenticated || auth.token == null || auth.token!.isEmpty) {
      // Not logged in — go to login, then come back
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please sign in to access Owner mode'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.push('/login');
      }
      return;
    }

    // Mark as owner mode first
    await provider.setOwnerMode(true);
    if (!context.mounted) return;

    // IMPORTANT: Refresh tokens for all services when switching to owner mode
    auth.refreshAllServiceTokens();

    // Show loading while checking hotel status
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(
        child: CircularProgressIndicator(color: Color(0xFFE60023)),
      ),
    );

    try {
      final route = await auth.checkHotelStatusAndNavigate();
      if (context.mounted) {
        Navigator.pop(context); // close loader
        if (route == 'registration') {
          context.go('/hotel-registration');
        } else if (route == 'pending') {
          context.go('/hotel-pending-approval');
        } else {
          context.go('/owner/dashboard');
        }
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        context.go('/hotel-registration');
      }
    }
  }
}
