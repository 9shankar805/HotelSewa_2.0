import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/app_mode_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/profile_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loadingHotel = false;
  Map<String, dynamic>? _hotelData;

  // ── Stats (pulled from auth / local) ────────────────────────────────────
  String get _ownerName  => context.read<AuthProvider>().user?.name        ?? 'Owner';
  String get _ownerEmail => context.read<AuthProvider>().user?.email       ?? '';
  String get _ownerPhone => context.read<AuthProvider>().user?.phoneNumber ?? '';
  String get _initials {
    final n = _ownerName;
    return n.isNotEmpty ? n[0].toUpperCase() : 'O';
  }

  @override
  void initState() {
    super.initState();
    _fetchHotelData();
  }

  Future<void> _fetchHotelData() async {
    setState(() => _loadingHotel = true);
    try {
      final svc = ProfileService();
      final res = await svc.getUserProfile();
      if (res is Map) setState(() => _hotelData = Map<String, dynamic>.from(res as Map));
    } catch (_) {}
    setState(() => _loadingHotel = false);
  }

  Future<void> _switchToCustomer() async {
    final appMode = context.read<AppModeProvider>();
    await appMode.setOwnerMode(false);
    if (mounted) context.go('/home');
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text('Log Out', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to log out of your owner account?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: AppColors.gray))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      final svc = ProfileService();
      await svc.logout();
      final auth = context.read<AuthProvider>();
      await auth.logout();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('user_role');
      if (mounted) context.go('/login');
    }
  }

  // ════════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final auth    = context.watch<AuthProvider>();
    final name    = auth.user?.name        ?? _ownerName;
    final email   = auth.user?.email       ?? _ownerEmail;
    final phone   = auth.user?.phoneNumber ?? _ownerPhone;
    final isApproved = auth.isHotelApproved;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: _fetchHotelData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── Collapsible header ──────────────────────────────────────
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: AppColors.primary,
              automaticallyImplyLeading: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                  onPressed: () {},
                  tooltip: 'Notifications',
                ),
                const SizedBox(width: 4),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE60023), Color(0xFF1A1A2E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(height: 8),
                        // Avatar
                        Stack(alignment: Alignment.bottomRight, children: [
                          CircleAvatar(
                            radius: 42,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            child: Text(_initials,
                                style: const TextStyle(
                                    fontSize: 34, fontWeight: FontWeight.w900, color: Colors.white)),
                          ),
                          // Verified badge
                          if (isApproved)
                            Container(
                              width: 22, height: 22,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF22C55E), shape: BoxShape.circle),
                              child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
                            ),
                        ]),
                        const SizedBox(height: 10),
                        Text(name.isNotEmpty ? name : 'Hotel Owner',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                        const SizedBox(height: 3),
                        if (email.isNotEmpty)
                          Text(email,
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        const SizedBox(height: 8),
                        // Approval badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: isApproved
                                ? const Color(0xFF22C55E).withOpacity(0.2)
                                : const Color(0xFFF59E0B).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isApproved
                                  ? const Color(0xFF22C55E).withOpacity(0.6)
                                  : const Color(0xFFF59E0B).withOpacity(0.6),
                            ),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(
                              isApproved ? Icons.verified_rounded : Icons.schedule_rounded,
                              size: 12,
                              color: isApproved ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isApproved ? 'Verified Hotel Owner' : 'Pending Approval',
                              style: TextStyle(
                                fontSize: 11, fontWeight: FontWeight.w700,
                                color: isApproved ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                              ),
                            ),
                          ]),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // ── Body ────────────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // ── Hotel info card ──────────────────────────────────
                  _hotelCard(),
                  const SizedBox(height: 16),

                  // ── Quick stats row ──────────────────────────────────
                  _statsRow(),
                  const SizedBox(height: 16),

                  // ── Account section ──────────────────────────────────
                  _section('My Account', [
                    _tile(Icons.person_outline_rounded,       'Personal Information', () => _editProfile(context, name, email, phone)),
                    _tile(Icons.lock_outline_rounded,         'Security & Password',  () => context.push('/security-2fa')),
                    _tile(Icons.notifications_outlined,       'Notification Settings',() {}),
                    _tile(Icons.language_rounded,             'Language & Region',    () => context.push('/multi-currency')),
                  ]),
                  const SizedBox(height: 12),

                  // ── Hotel management ─────────────────────────────────
                  _section('Hotel Management', [
                    _tile(Icons.hotel_rounded,                'My Hotel Details',     () => context.push('/my-hotel-details')),
                    _tile(Icons.meeting_room_rounded,         'Manage Rooms',         () => context.push('/rooms')),
                    _tile(Icons.image_outlined,               'Gallery Management',   () => context.push('/gallery-management')),
                    _tile(Icons.local_offer_outlined,         'Offers & Deals',       () => context.push('/offers')),
                    _tile(Icons.attach_money_rounded,         'Pricing',              () => context.push('/pricing')),
                    _tile(Icons.spa_outlined,                 'Amenities',            () => context.push('/amenities-management')),
                  ]),
                  const SizedBox(height: 12),

                  // ── Finance ─────────────────────────────────────────
                  _section('Finance', [
                    _tile(Icons.account_balance_wallet_outlined, 'Earnings',          () => context.push('/earnings')),
                    _tile(Icons.south_rounded,                'Withdrawals',          () => context.push('/withdrawals')),
                    _tile(Icons.receipt_long_outlined,        'Tax Reports',          () => context.push('/tax-report')),
                  ]),
                  const SizedBox(height: 12),

                  // ── Analytics ───────────────────────────────────────
                  _section('Analytics & Reports', [
                    _tile(Icons.bar_chart_rounded,            'Analytics',            () => context.push('/analytics')),
                    _tile(Icons.summarize_outlined,           'Reports',              () => context.push('/reports')),
                    _tile(Icons.reviews_outlined,             'Guest Reviews',        () => context.push('/reviews')),
                    _tile(Icons.star_rate_outlined,           'Reputation',           () => context.push('/reputation')),
                  ]),
                  const SizedBox(height: 12),

                  // ── Tools ────────────────────────────────────────────
                  _section('Tools', [
                    _tile(Icons.qr_code_scanner_rounded,      'QR Check-In',          () => context.push('/qr-checkin')),
                    _tile(Icons.calendar_month_outlined,      'Calendar Sync',        () => context.push('/ical-sync')),
                    _tile(Icons.headset_mic_outlined,         'Help & Support',       () => context.push('/help')),
                    _tile(Icons.settings_outlined,            'Settings',             () => context.push('/settings')),
                  ]),
                  const SizedBox(height: 12),

                  // ── Switch to Customer ───────────────────────────────
                  _switchModeCard(),
                  const SizedBox(height: 12),

                  // ── Danger zone ──────────────────────────────────────
                  _section('Account', [
                    _tile(Icons.delete_outline_rounded, 'Delete Account',
                        () => context.push('/delete-account'), color: AppColors.error),
                  ]),
                  const SizedBox(height: 16),

                  // ── Logout ───────────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Log Out',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                        elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Hotel card ─────────────────────────────────────────────────────────────
  Widget _hotelCard() {
    final hotelName    = _hotelData?['hotel_name'] ?? _hotelData?['name'] ?? 'Your Hotel';
    final hotelCity    = _hotelData?['city'] ?? _hotelData?['district'] ?? '';
    final hotelRooms   = _hotelData?['total_rooms']?.toString() ?? '—';
    final hotelRating  = (_hotelData?['rating'] as num?)?.toStringAsFixed(1) ?? '—';

    return GestureDetector(
      onTap: () => context.push('/my-hotel-details'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [BoxShadow(
              color: const Color(0xFF1A1A2E).withOpacity(0.35),
              blurRadius: 18, offset: const Offset(0, 6))],
        ),
        child: _loadingHotel
            ? const Center(child: CircularProgressIndicator(color: Colors.white54))
            : Row(children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(hotelName,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (hotelCity.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: Colors.white54),
                      const SizedBox(width: 4),
                      Text(hotelCity,
                          style: const TextStyle(color: Colors.white54, fontSize: 12)),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    _hotelStat(Icons.meeting_room_outlined, '$hotelRooms rooms'),
                    const SizedBox(width: 14),
                    _hotelStat(Icons.star_rounded, '$hotelRating rating'),
                  ]),
                ])),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.white38),
              ]),
      ),
    );
  }

  Widget _hotelStat(IconData icon, String label) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: Colors.white54),
    const SizedBox(width: 4),
    Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
  ]);

  // ── Quick stats ───────────────────────────────────────────────────────────
  Widget _statsRow() {
    final stats = [
      (Icons.calendar_today_rounded,        'Bookings',    '/bookings',   const Color(0xFF3B82F6)),
      (Icons.account_balance_wallet_rounded,'Earnings',    '/earnings',   const Color(0xFF22C55E)),
      (Icons.analytics_rounded,             'Analytics',   '/analytics',  const Color(0xFFF59E0B)),
      (Icons.reviews_outlined,              'Reviews',     '/reviews',    const Color(0xFF8B5CF6)),
    ];
    return Row(
      children: stats.map((s) => Expanded(
        child: GestureDetector(
          onTap: () => context.push(s.$3),
          child: Container(
            margin: EdgeInsets.only(right: stats.indexOf(s) < stats.length - 1 ? 10 : 0),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Column(children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(
                  color: s.$4.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                child: Icon(s.$1, size: 20, color: s.$4),
              ),
              const SizedBox(height: 6),
              Text(s.$2,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
            ]),
          ),
        ),
      )).toList(),
    );
  }

  // ── Switch to Customer card ───────────────────────────────────────────────
  Widget _switchModeCard() {
    return GestureDetector(
      onTap: _switchToCustomer,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
            child: const Icon(Icons.person_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Switch to Customer Mode',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
            SizedBox(height: 2),
            Text('Browse hotels and make bookings',
                style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary, borderRadius: BorderRadius.circular(20),
            ),
            child: const Text('Switch',
                style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ]),
      ),
    );
  }

  // ── Section + Tile helpers ────────────────────────────────────────────────
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
              style: const TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800,
                  color: Color(0xFF9CA3AF), letterSpacing: 0.8)),
        ),
        ...tiles.asMap().entries.map((e) => Column(children: [
          if (e.key > 0) const Divider(height: 1, indent: 66, endIndent: 16),
          e.value,
        ])),
      ]),
    );
  }

  Widget _tile(IconData icon, String label, VoidCallback onTap, {Color? color}) {
    final c = color ?? const Color(0xFF374151);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Icon(Icons.arrow_forward_ios_rounded, size: 13,
              color: color ?? const Color(0xFFD1D5DB)),
        ]),
      ),
    );
  }

  // ── Edit profile bottom sheet ─────────────────────────────────────────────
  void _editProfile(BuildContext context, String name, String email, String phone) {
    final nameCtrl  = TextEditingController(text: name);
    final phoneCtrl = TextEditingController(text: phone);
    bool saving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Edit Profile',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1F2937))),
            const SizedBox(height: 20),
            _inputField('Full Name', nameCtrl, Icons.person_outline_rounded),
            const SizedBox(height: 12),
            _inputField('Phone Number', phoneCtrl, Icons.phone_outlined,
                keyboardType: TextInputType.phone),
            const SizedBox(height: 8),
            // Email is read-only
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                const Icon(Icons.email_outlined, size: 18, color: Color(0xFF9CA3AF)),
                const SizedBox(width: 10),
                Expanded(child: Text(email,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF9CA3AF)))),
                const Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFFD1D5DB)),
              ]),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: saving ? null : () async {
                  setS(() => saving = true);
                  try {
                    final svc = ProfileService();
                    await svc.updateProfile({
                      'name': nameCtrl.text.trim(),
                      'phone': phoneCtrl.text.trim(),
                    });
                    if (ctx.mounted) Navigator.pop(ctx);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Profile updated'),
                        backgroundColor: Color(0xFF22C55E),
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  } catch (_) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Failed to update profile'),
                        backgroundColor: AppColors.primary,
                        behavior: SnackBarBehavior.floating,
                      ));
                    }
                  }
                  setS(() => saving = false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: saving
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Changes',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ]),
        ),
      )),
    );
  }

  Widget _inputField(String hint, TextEditingController ctrl, IconData icon,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        filled: true, fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
