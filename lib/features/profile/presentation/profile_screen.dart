import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});
  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName  = '';
  String _userEmail = '';
  String _userPhone = '';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  void _loadUser() {
    final auth = context.read<AuthProvider>();
    setState(() {
      _userName  = auth.user?.name        ?? '';
      _userEmail = auth.user?.email       ?? '';
      _userPhone = auth.user?.phoneNumber ?? '';
    });
  }

  Future<void> _switchToOwner() async {
    final auth    = context.read<AuthProvider>();
    final appMode = context.read<AppModeProvider>();

    if (!auth.isAuthenticated || (auth.token ?? '').isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please sign in to access Owner mode'),
        behavior: SnackBarBehavior.floating,
      ));
      context.push('/login');
      return;
    }

    await appMode.setOwnerMode(true);
    if (!mounted) return;
    auth.refreshAllServiceTokens();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
    );

    try {
      final route = await auth.checkHotelStatusAndNavigate();
      if (!mounted) return;
      Navigator.pop(context);
      if (route == 'registration')       context.go('/hotel-registration');
      else if (route == 'pending')        context.go('/hotel-pending-approval');
      else                                context.go('/owner/dashboard');
    } catch (_) {
      if (mounted) { Navigator.pop(context); context.go('/hotel-registration'); }
    }
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
        content: const Text('Are you sure you want to log out?', style: TextStyle(color: Color(0xFF6B7280))),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final auth = context.read<AuthProvider>();
      await auth.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      if (mounted) context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth     = context.watch<AuthProvider>();
    final name     = auth.user?.name        ?? _userName;
    final email    = auth.user?.email       ?? _userEmail;
    final phone    = auth.user?.phoneNumber ?? _userPhone;
    final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    final isLoggedIn = auth.isAuthenticated;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('My Profile',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined, color: Color(0xFF374151)),
            onPressed: () => context.push('/notifications'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [

          // ── Profile Header Card ─────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE60023), Color(0xFFFF4D6A)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Column(children: [
              Row(children: [
                // Avatar
                Container(
                  width: 70, height: 70,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                  ),
                  child: Center(child: Text(initials,
                      style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white))),
                ),
                const SizedBox(width: 16),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name.isNotEmpty ? name : 'Welcome!',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (email.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(email, style: const TextStyle(fontSize: 12, color: Colors.white70),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(phone, style: const TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ])),
                GestureDetector(
                  onTap: () => context.push('/personal-info'),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.4)),
                    ),
                    child: const Text('Edit', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
              const SizedBox(height: 16),
              // Stats row
              Row(children: [
                _statCard('My Trips', Icons.flight_takeoff_rounded, () => context.push('/my-trips')),
                const SizedBox(width: 10),
                _statCard('Saved', Icons.favorite_rounded, () => context.push('/saved')),
                const SizedBox(width: 10),
                _statCard('Rewards', Icons.card_giftcard_rounded, () => context.push('/invite-earn')),
                const SizedBox(width: 10),
                _statCard('Wallet', Icons.account_balance_wallet_rounded, () => context.push('/wallet')),
              ]),
            ]),
          ),
          const SizedBox(height: 16),

          // ── Switch to Owner Mode ────────────────────────────────────────
          if (isLoggedIn) _switchOwnerCard(),
          if (isLoggedIn) const SizedBox(height: 16),

          // ── Bookings & Activity ─────────────────────────────────────────
          _section('Bookings & Activity', [
            _tile(Icons.receipt_long_rounded,          'My Bookings',          () => context.push('/my-trips'),            badge: null),
            _tile(Icons.favorite_outline_rounded,      'Saved Hotels',         () => context.push('/saved'),               badge: null),
            _tile(Icons.rate_review_outlined,          'My Reviews',           () => context.push('/pending-reviews'),     badge: null),
            _tile(Icons.qr_code_rounded,               'Digital Key',          () => context.push('/digital-key'),         badge: 'NEW'),
          ]),
          const SizedBox(height: 12),

          // ── Account ─────────────────────────────────────────────────────
          _section('Account', [
            _tile(Icons.person_outline_rounded,        'Personal Information',  () => context.push('/personal-info'),       badge: null),
            _tile(Icons.lock_outline_rounded,          'Security & Password',   () => context.push('/security-settings'),   badge: null),
            _tile(Icons.location_on_outlined,          'Address Book',          () => context.push('/address-book'),        badge: null),
            _tile(Icons.link_rounded,                  'Linked Accounts',       () => context.push('/linked-accounts'),     badge: null),
          ]),
          const SizedBox(height: 12),

          // ── Rewards & Payments ──────────────────────────────────────────
          _section('Rewards & Payments', [
            _tile(Icons.star_outline_rounded,          'Loyalty Program',       () => context.push('/loyalty-program'),     badge: null),
            _tile(Icons.account_balance_wallet_outlined,'Wallet',              () => context.push('/wallet'),              badge: null),
            _tile(Icons.credit_card_rounded,           'Payment Methods',       () => context.push('/payment-methods'),     badge: null),
            _tile(Icons.local_offer_outlined,          'My Coupons',            () => context.push('/coupons'),             badge: null),
            _tile(Icons.person_add_rounded,            'Invite & Earn',         () => context.push('/invite-earn'),         badge: null),
          ]),
          const SizedBox(height: 12),

          // ── Preferences ─────────────────────────────────────────────────
          _section('Preferences', [
            _tile(Icons.flight_takeoff_rounded,        'Travel Preferences',    () => context.push('/travel-preferences'),  badge: null),
            _tile(Icons.notifications_outlined,        'Notifications',         () => context.push('/notification-settings'),badge: null),
            _tile(Icons.language_rounded,              'Language',              () => context.push('/language-selector'),   badge: null),
            _tile(Icons.attach_money_rounded,          'Currency',              () => context.push('/currency-selector'),   badge: null),
            _tile(Icons.accessibility_new_rounded,     'Accessibility',         () => context.push('/accessibility-settings'),badge: null),
          ]),
          const SizedBox(height: 12),

          // ── Support ─────────────────────────────────────────────────────
          _section('Support & Legal', [
            _tile(Icons.shield_rounded,                'HotelSewa Promise',     () => context.push('/guest-protection'),     badge: null),
            _tile(Icons.report_problem_rounded,        'Report an Issue',       () => context.push('/raise-complaint'),      badge: null),
            _tile(Icons.help_outline_rounded,          'Help Center',           () => context.push('/help-center'),          badge: null),
            _tile(Icons.chat_bubble_outline_rounded,   'Chat Support',          () => context.push('/chat'),                 badge: null),
            _tile(Icons.info_outline_rounded,          'About HotelSewa',       () => context.push('/about'),                badge: null),
            _tile(Icons.description_outlined,          'Terms & Conditions',    () => context.push('/terms'),               badge: null),
            _tile(Icons.privacy_tip_outlined,          'Privacy Policy',        () => context.push('/about'),               badge: null),
          ]),
          const SizedBox(height: 12),

          // ── Danger zone ─────────────────────────────────────────────────
          _section('Account Actions', [
            _tile(Icons.delete_outline_rounded, 'Delete Account',
                () => context.push('/delete-account'), badge: null, color: AppColors.error),
          ]),
          const SizedBox(height: 20),

          // ── Logout ──────────────────────────────────────────────────────
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout_rounded, size: 18),
              label: const Text('Log Out', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // App version
          const Text('HotelSewa v1.0.0',
              style: TextStyle(fontSize: 12, color: Color(0xFFADB5BD), fontWeight: FontWeight.w500)),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  // ── Stat shortcut card ──────────────────────────────────────────────────
  Widget _statCard(String label, IconData icon, VoidCallback onTap) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, size: 22, color: Colors.white),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
        ]),
      ),
    ));
  }

  // ── Switch to Owner card ─────────────────────────────────────────────────
  Widget _switchOwnerCard() {
    return GestureDetector(
      onTap: _switchToOwner,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.business_rounded, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Switch to Owner Mode',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            SizedBox(height: 2),
            Text('Manage your hotel & bookings',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Switch',
                style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  // ── Section wrapper ─────────────────────────────────────────────────────
  Widget _section(String title, List<Widget> tiles) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: Text(title,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800,
                  color: Color(0xFFADB5BD), letterSpacing: 0.8)),
        ),
        ...tiles.asMap().entries.map((e) => Column(children: [
          if (e.key > 0) const Divider(height: 1, indent: 66, endIndent: 16, color: Color(0xFFF3F4F6)),
          e.value,
        ])),
      ]),
    );
  }

  // ── Tile row ────────────────────────────────────────────────────────────
  Widget _tile(IconData icon, String label, VoidCallback onTap,
      {required String? badge, Color? color}) {
    final c = color ?? const Color(0xFF1A1A2E);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: (color ?? AppColors.primary).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color ?? AppColors.primary),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(label,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: c))),
          if (badge != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(badge,
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ),
            const SizedBox(width: 8),
          ],
          Icon(Icons.arrow_forward_ios_rounded, size: 13,
              color: color ?? const Color(0xFFD1D5DB)),
        ]),
      ),
    );
  }
}
