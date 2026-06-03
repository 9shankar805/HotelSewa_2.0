import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '';
  String _userEmail = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _userName  = auth.user?.name        ?? '';
      _userEmail = auth.user?.email       ?? '';
      _userPhone = auth.user?.phoneNumber ?? '';
    });
  }

  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.gray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      final auth = context.read<AuthProvider>();
      await auth.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final name   = auth.user?.name  ?? _userName;
    final email  = auth.user?.email ?? _userEmail;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF374151)),
            onPressed: () => context.push('/security-settings'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // ── Avatar card ─────────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 14, offset: const Offset(0, 3))],
            ),
            child: Column(children: [
              CircleAvatar(
                radius: 42,
                backgroundColor: AppColors.primary.withOpacity(0.12),
                child: Text(initials,
                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ),
              const SizedBox(height: 14),
              Text(name.isNotEmpty ? name : 'User',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(email, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              ],
              const SizedBox(height: 16),
              OutlinedButton(
                onPressed: () => context.push('/personal-info'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                ),
                child: const Text('Edit Profile',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
              ),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Account section ─────────────────────────────────────────────
          _section('Account', [
            _tile(Icons.person_outline_rounded,  'Personal Information', () => context.push('/personal-info')),
            _tile(Icons.lock_outline_rounded,     'Security Settings',    () => context.push('/security-settings')),
            _tile(Icons.location_on_outlined,     'Address Book',         () => context.push('/address-book')),
            _tile(Icons.link_rounded,             'Linked Accounts',      () => context.push('/linked-accounts')),
          ]),
          const SizedBox(height: 12),

          // ── Preferences ─────────────────────────────────────────────────
          _section('Preferences', [
            _tile(Icons.flight_takeoff_rounded,   'Travel Preferences',   () => context.push('/travel-preferences')),
            _tile(Icons.notifications_outlined,   'Notification Settings',() => context.push('/notification-settings')),
            _tile(Icons.language_rounded,         'Language',             () => context.push('/language-selector')),
            _tile(Icons.attach_money_rounded,     'Currency',             () => context.push('/currency-selector')),
            _tile(Icons.accessibility_new_rounded,'Accessibility',        () => context.push('/accessibility-settings')),
          ]),
          const SizedBox(height: 12),

          // ── Rewards & Wallet ────────────────────────────────────────────
          _section('Rewards & Wallet', [
            _tile(Icons.star_outline_rounded,     'Loyalty Program',      () => context.push('/loyalty-program')),
            _tile(Icons.account_balance_wallet_outlined, 'Wallet',        () => context.push('/wallet')),
            _tile(Icons.card_giftcard_rounded,    'Invite & Earn',        () => context.push('/invite-earn')),
            _tile(Icons.local_offer_outlined,     'My Coupons',           () => context.push('/coupons')),
          ]),
          const SizedBox(height: 12),

          // ── Support ─────────────────────────────────────────────────────
          _section('Support', [
            _tile(Icons.help_outline_rounded,     'Help Center',          () => context.push('/help-center')),
            _tile(Icons.info_outline_rounded,     'About HotelSewa',      () => context.push('/about')),
            _tile(Icons.description_outlined,     'Terms & Conditions',   () => context.push('/terms')),
            _tile(Icons.privacy_tip_outlined,     'Privacy Policy',       () => context.push('/about')),
          ]),
          const SizedBox(height: 12),

          // ── Danger zone ─────────────────────────────────────────────────
          _section('Account Actions', [
            _tile(Icons.delete_outline_rounded,   'Delete Account',       () => context.push('/delete-account'),
                color: AppColors.error),
          ]),
          const SizedBox(height: 16),

          // ── Logout button ───────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _section(String title, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
          child: Text(title,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                  color: Color(0xFF9CA3AF), letterSpacing: 0.5)),
        ),
        ...tiles,
      ]),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? const Color(0xFF374151);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color ?? AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c))),
          Icon(Icons.arrow_forward_ios_rounded, size: 14, color: color ?? const Color(0xFFD1D5DB)),
        ]),
      ),
    );
  }
}
