import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';
import '../../../core/services/active_stay_service.dart';
import '../../../core/services/booking_service.dart';
import 'service_request_screen.dart';

class InStayDashboardScreen extends StatefulWidget {
  final Map<String, dynamic>? booking;
  const InStayDashboardScreen({Key? key, this.booking}) : super(key: key);

  @override
  State<InStayDashboardScreen> createState() => _InStayDashboardScreenState();
}

class _InStayDashboardScreenState extends State<InStayDashboardScreen> {
  Map<String, dynamic> _booking = {};
  Map<String, dynamic> _hotel = {};
  List _menuItems = [];
  bool _loading = true;
  bool _qrExpanded = false;
  int _activeOrders = 0;
  int _pendingHousekeeping = 0;
  int _pendingMaintenance = 0;

  @override
  void initState() {
    super.initState();
    _booking = widget.booking ?? {};
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');

    // Load hotel details + menu in parallel
    final hotelId = _booking['hotel_id']?.toString()
        ?? _booking['hotel']?['id']?.toString()
        ?? '';

    await Future.wait([
      if (hotelId.isNotEmpty) _loadHotel(hotelId, token),
      if (hotelId.isNotEmpty) _loadMenu(hotelId, token),
      _loadActiveOrders(token),
      _loadHousekeepingCount(token),
      _loadMaintenanceCount(token),
    ]);

    if (mounted) setState(() => _loading = false);
  }

  Future<void> _loadHotel(String id, String? token) async {
    try {
      final r = await ApiService.get('${ApiConfig.hotelDetailsEndpoint}/$id', token: token);
      if (r['success'] == true && mounted) {
        setState(() => _hotel = r['data'] is Map ? Map<String, dynamic>.from(r['data'] as Map) : {});
      }
    } catch (_) {}
  }

  Future<void> _loadMenu(String id, String? token) async {
    try {
      final r = await ApiService.get('${ApiConfig.hotelMenuEndpoint}/$id/menu', token: token);
      if (r['success'] == true && mounted) {
        final raw = r['data'];
        final list = raw is List ? raw : (raw is Map ? (raw['items'] ?? raw['menu'] ?? raw['data'] ?? []) : []);
        setState(() => _menuItems = list);
      }
    } catch (_) {}
  }

  Future<void> _loadActiveOrders(String? token) async {
    try {
      final r = await ApiService.get(ApiConfig.myOrdersEndpoint, token: token);
      if (r['success'] == true && mounted) {
        final raw = r['data'];
        final list = raw is List ? raw : (raw is Map ? (raw['orders'] ?? raw['data'] ?? []) : []);
        final active = (list as List).where((o) {
          final s = (o['status'] ?? '').toString().toLowerCase();
          return s == 'pending' || s == 'preparing' || s == 'ready';
        }).length;
        setState(() => _activeOrders = active);
      }
    } catch (_) {}
  }

  Future<void> _loadHousekeepingCount(String? token) async {
    try {
      final bookingId = _booking['id']?.toString() ?? '';
      if (bookingId.isEmpty) return;
      final r = await ApiService.get(
        '${ApiConfig.housekeepingTasksEndpoint}?booking_id=$bookingId',
        token: token,
      );
      if (r['success'] == true && mounted) {
        final raw = r['data'];
        final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
        final pending = (list as List).where((t) =>
          (t['status'] ?? '').toString().toLowerCase() == 'pending').length;
        setState(() => _pendingHousekeeping = pending);
      }
    } catch (_) {}
  }

  Future<void> _loadMaintenanceCount(String? token) async {
    try {
      final bookingId = _booking['id']?.toString() ?? '';
      if (bookingId.isEmpty) return;
      final r = await ApiService.get(
        '${ApiConfig.maintenanceIssuesEndpoint}?booking_id=$bookingId',
        token: token,
      );
      if (r['success'] == true && mounted) {
        final raw = r['data'];
        final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
        final pending = (list as List).where((t) =>
          (t['status'] ?? '').toString().toLowerCase() == 'pending').length;
        setState(() => _pendingMaintenance = pending);
      }
    } catch (_) {}
  }

  // ── Getters ───────────────────────────────────────────────────────────────

  String get _hotelName =>
      _hotel['name']?.toString() ??
      _booking['hotel_name']?.toString() ??
      _booking['hotel']?['name']?.toString() ?? 'Your Hotel';

  String get _roomNo =>
      _booking['room_number']?.toString() ??
      _booking['room_type']?.toString() ?? 'Room';

  String get _checkOut {
    final raw = _booking['check_out']?.toString()
        ?? _booking['check_out_date']?.toString() ?? '';
    return raw.split('T')[0];
  }

  int get _nightsLeft {
    try {
      final co = DateTime.parse(_checkOut);
      return co.difference(DateTime.now()).inDays.clamp(0, 99);
    } catch (_) { return 0; }
  }

  String get _wifiPass =>
      _hotel['wifi_password']?.toString() ??
      (_hotel['policies'] as Map?)?['wifi_password']?.toString() ?? '—';

  String get _checkOutTime =>
      _hotel['check_out_time']?.toString() ??
      (_hotel['policies'] as Map?)?['check_out_time']?.toString() ?? '11:00 AM';

  String get _checkInTime =>
      _hotel['check_in_time']?.toString() ?? '2:00 PM';

  String get _phone =>
      _hotel['contact_number']?.toString() ??
      _hotel['phone']?.toString() ?? '';

  String get _bookingId =>
      _booking['id']?.toString() ??
      _booking['booking_id']?.toString() ?? '';

  String get _qrPayload => jsonEncode({
    'app': 'HotelSewa',
    'booking_id': _bookingId,
    'hotel': _hotelName,
    'room': _roomNo,
    'checkout': _checkOut,
    'mode': 'in_stay',
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1E),
      body: _loading
          ? _buildLoader()
          : CustomScrollView(
              slivers: [
                _buildSliverHeader(context),
                SliverToBoxAdapter(
                  child: Column(
                    children: [
                      _buildRoomCard(),
                      _buildQrSection(),
                      _buildServiceGrid(context),
                      _buildHotelInfoStrip(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildLoader() => const Center(
    child: CircularProgressIndicator(color: AppColors.primary),
  );

  // ── Header ────────────────────────────────────────────────────────────────
  SliverAppBar _buildSliverHeader(BuildContext context) {
    final imageUrl = _hotel['image']?.toString() ?? '';
    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: const Color(0xFF0F0F1E),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.success,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 8, color: Colors.white),
              SizedBox(width: 5),
              Text('CHECKED IN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
            ],
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Hotel image
            imageUrl.isNotEmpty
                ? Image.network(imageUrl, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF1A1A2E)))
                : Container(color: const Color(0xFF1A1A2E)),
            // Gradient overlay
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.transparent, Color(0xDD0F0F1E)],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.3, 1.0],
                ),
              ),
            ),
            // Hotel name + stay info at bottom
            Positioned(
              bottom: 20, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _hotelName,
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.king_bed_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text(_roomNo, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(width: 16),
                    const Icon(Icons.calendar_today_rounded, size: 14, color: Colors.white70),
                    const SizedBox(width: 5),
                    Text('Check-out: $_checkOut', style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(width: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text('$_nightsLeft night${_nightsLeft != 1 ? 's' : ''} left',
                          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Room card (quick info strip) ──────────────────────────────────────────
  Widget _buildRoomCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          _infoTile(Icons.wifi_rounded, 'WiFi', _wifiPass, copyable: true),
          _vDivider(),
          _infoTile(Icons.login_rounded, 'Check-in', _checkInTime),
          _vDivider(),
          _infoTile(Icons.logout_rounded, 'Check-out', _checkOutTime),
          if (_phone.isNotEmpty) ...[
            _vDivider(),
            _infoTile(Icons.phone_rounded, 'Reception', _phone, copyable: false, onTap: () {}),
          ],
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _infoTile(IconData icon, String label, String value, {bool copyable = false, VoidCallback? onTap}) {
    return Expanded(
      child: GestureDetector(
        onTap: copyable ? () {
          Clipboard.setData(ClipboardData(text: value));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$label copied'), duration: const Duration(seconds: 1), behavior: SnackBarBehavior.floating),
          );
        } : onTap,
        child: Column(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.w600, letterSpacing: 0.5)),
            const SizedBox(height: 2),
            Text(value, style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w700), textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis),
            if (copyable) const Icon(Icons.copy_rounded, size: 10, color: Colors.white38),
          ],
        ),
      ),
    );
  }

  Widget _vDivider() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.1), margin: const EdgeInsets.symmetric(horizontal: 4));

  // ── QR Section ────────────────────────────────────────────────────────────
  Widget _buildQrSection() {
    return GestureDetector(
      onTap: () => setState(() => _qrExpanded = !_qrExpanded),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        padding: EdgeInsets.all(_qrExpanded ? 20 : 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.primary.withOpacity(0.15), AppColors.primary.withOpacity(0.05)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('Room Key QR', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
                    Text(_qrExpanded ? 'Tap to collapse' : 'Tap to show — scan at door or reception',
                        style: const TextStyle(fontSize: 11, color: Colors.white54)),
                  ]),
                ),
                AnimatedRotation(
                  turns: _qrExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: const Icon(Icons.expand_more_rounded, color: Colors.white54),
                ),
              ],
            ),
            if (_qrExpanded) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                child: QrImageView(
                  data: _qrPayload,
                  version: QrVersions.auto,
                  size: 200,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Color(0xFF1A1A2E)),
                  dataModuleStyle: const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: Color(0xFF1A1A2E)),
                  errorCorrectionLevel: QrErrorCorrectLevel.H,
                ),
              ),
              const SizedBox(height: 10),
              Text('Booking #$_bookingId',
                  style: const TextStyle(fontSize: 12, color: Colors.white54, letterSpacing: 1)),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: 100.ms);
  }

  // ── Service Grid ──────────────────────────────────────────────────────────
  Widget _buildServiceGrid(BuildContext context) {
    final tiles = [
      _ServiceTile(
        icon: Icons.restaurant_menu_rounded,
        label: 'Room Service',
        subtitle: _menuItems.isEmpty ? 'Browse menu' : '${_menuItems.length} items',
        color: const Color(0xFFF59E0B),
        badge: _activeOrders > 0 ? '$_activeOrders' : null,
        onTap: () => Navigator.pushNamed(context, '/menu', arguments: {
          'hotelId': _booking['hotel_id']?.toString() ?? _booking['hotel']?['id']?.toString() ?? '',
          'bookingId': _bookingId,
          'hotelName': _hotelName,
        }),
      ),
      _ServiceTile(
        icon: Icons.room_service_rounded,
        label: 'Housekeeping',
        subtitle: _pendingHousekeeping > 0 ? '$_pendingHousekeeping pending' : 'Request service',
        color: const Color(0xFF3B82F6),
        badge: _pendingHousekeeping > 0 ? '$_pendingHousekeeping' : null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
            ServiceRequestScreen(booking: _booking, hotel: _hotel, requestType: 'housekeeping'))),
      ),
      _ServiceTile(
        icon: Icons.chat_bubble_rounded,
        label: 'Chat Hotel',
        subtitle: 'Message front desk',
        color: const Color(0xFF10B981),
        onTap: () => Navigator.pushNamed(context, '/chat', arguments: {
          'bookingId': _bookingId,
          'hotelName': _hotelName,
        }),
      ),
      _ServiceTile(
        icon: Icons.report_problem_rounded,
        label: 'Complaint',
        subtitle: 'Report an issue',
        color: const Color(0xFFEF4444),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
            ServiceRequestScreen(booking: _booking, hotel: _hotel, requestType: 'complaint'))),
      ),
      _ServiceTile(
        icon: Icons.build_rounded,
        label: 'Maintenance',
        subtitle: _pendingMaintenance > 0 ? '$_pendingMaintenance pending' : 'Report a fault',
        color: const Color(0xFF8B5CF6),
        badge: _pendingMaintenance > 0 ? '$_pendingMaintenance' : null,
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
            ServiceRequestScreen(booking: _booking, hotel: _hotel, requestType: 'maintenance'))),
      ),
      _ServiceTile(
        icon: Icons.local_taxi_rounded,
        label: 'Taxi / Transport',
        subtitle: 'Book a ride',
        color: const Color(0xFF14B8A6),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
            ServiceRequestScreen(booking: _booking, hotel: _hotel, requestType: 'transport'))),
      ),
      _ServiceTile(
        icon: Icons.place_rounded,
        label: 'Nearby',
        subtitle: 'Explore around',
        color: const Color(0xFFFF6B6B),
        onTap: () => Navigator.pushNamed(context, '/nearby-attractions', arguments: {
          ...(_hotel.isNotEmpty ? _hotel : {}),
          'hotelId': _booking['hotel_id']?.toString() ?? '',
          'hotelName': _hotelName,
        }),
      ),
      _ServiceTile(
        icon: Icons.access_time_rounded,
        label: 'Late Checkout',
        subtitle: 'Request extension',
        color: const Color(0xFFD97706),
        onTap: () => _showLateCheckoutDialog(context),
      ),
      _ServiceTile(
        icon: Icons.receipt_long_rounded,
        label: 'My Folio',
        subtitle: 'Room charges',
        color: const Color(0xFF6366F1),
        onTap: () => Navigator.pushNamed(context, '/invoice', arguments: _booking),
      ),
      _ServiceTile(
        icon: Icons.spa_rounded,
        label: 'Concierge',
        subtitle: 'Special requests',
        color: const Color(0xFFEC4899),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
            ServiceRequestScreen(booking: _booking, hotel: _hotel, requestType: 'concierge'))),
      ),
      _ServiceTile(
        icon: Icons.wifi_rounded,
        label: 'WiFi Info',
        subtitle: _wifiPass == '—' ? 'Ask reception' : 'Tap to copy',
        color: const Color(0xFF0EA5E9),
        onTap: () {
          if (_wifiPass != '—') {
            Clipboard.setData(ClipboardData(text: _wifiPass));
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('WiFi password copied'), behavior: SnackBarBehavior.floating),
            );
          }
        },
      ),
      _ServiceTile(
        icon: Icons.star_rate_rounded,
        label: 'Rate Stay',
        subtitle: 'Mid-stay feedback',
        color: const Color(0xFFF59E0B),
        onTap: () => _showMidStayFeedbackDialog(context),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hotel Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3)),
          const SizedBox(height: 14),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: tiles.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.88,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemBuilder: (_, i) => tiles[i].build(context, i),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms);
  }

  // ── Hotel Info Strip ──────────────────────────────────────────────────────
  Widget _buildHotelInfoStrip() {
    final amenities = (_hotel['amenities'] as List?)?.take(6).toList() ?? [];
    if (amenities.isEmpty) return const SizedBox();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hotel Amenities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: amenities.map((a) => Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(a.toString(), style: const TextStyle(fontSize: 11, color: Colors.white70, fontWeight: FontWeight.w500)),
            )).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  // ── Late checkout dialog ──────────────────────────────────────────────────
  Future<void> _showLateCheckoutDialog(BuildContext context) async {
    final times = ['12:00 PM', '1:00 PM', '2:00 PM', '3:00 PM'];
    String? selected;

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: Color(0xFF1A1A2E),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Request Late Check-out', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
              const SizedBox(height: 6),
              Text('Standard checkout: $_checkOutTime',
                  style: const TextStyle(fontSize: 13, color: Colors.white54)),
              const SizedBox(height: 20),
              ...times.map((t) => GestureDetector(
                onTap: () => set(() => selected = t),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: selected == t ? AppColors.primary.withOpacity(0.2) : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected == t ? AppColors.primary : Colors.white.withOpacity(0.1)),
                  ),
                  child: Row(children: [
                    Icon(selected == t ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                        color: selected == t ? AppColors.primary : Colors.white38, size: 18),
                    const SizedBox(width: 12),
                    Text(t, style: TextStyle(color: selected == t ? Colors.white : Colors.white70, fontWeight: FontWeight.w600)),
                  ]),
                ),
              )),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: selected == null ? null : () {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('Late check-out requested for $selected. Hotel will confirm shortly.'),
                      behavior: SnackBarBehavior.floating,
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: Colors.white12,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Send Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  // ── Mid-stay feedback dialog ──────────────────────────────────────────────
  Future<void> _showMidStayFeedbackDialog(BuildContext context) async {
    int _rating = 0;
    final _commentCtrl = TextEditingController();
    bool _submitting = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, set) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Color(0xFF1A1A2E),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('How is your stay?', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white)),
                const SizedBox(height: 4),
                const Text('Your feedback helps us improve your experience right now.',
                    style: TextStyle(fontSize: 13, color: Colors.white54)),
                const SizedBox(height: 20),

                // Star rating
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final star = i + 1;
                      return GestureDetector(
                        onTap: () => set(() => _rating = star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Icon(
                            star <= _rating ? Icons.star_rounded : Icons.star_outline_rounded,
                            size: 40,
                            color: star <= _rating ? const Color(0xFFF59E0B) : Colors.white24,
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                if (_rating > 0) ...[
                  const SizedBox(height: 6),
                  Center(
                    child: Text(
                      ['', 'Poor', 'Fair', 'Good', 'Very Good', 'Excellent'][_rating],
                      style: const TextStyle(fontSize: 14, color: Color(0xFFF59E0B), fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
                const SizedBox(height: 20),

                // Comment
                TextField(
                  controller: _commentCtrl,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Any specific feedback? (optional)',
                    hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.1))),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 1.5)),
                    contentPadding: const EdgeInsets.all(14),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (_rating == 0 || _submitting) ? null : () async {
                      set(() => _submitting = true);
                      try {
                        final prefs = await SharedPreferences.getInstance();
                        final token = prefs.getString('authToken');
                        final bookingId = _booking['id']?.toString() ?? '';
                        final response = await ApiService.post(
                          '${ApiConfig.midStayFeedbackEndpoint}/$bookingId/mid-stay-feedback',
                          token: token,
                          data: {
                            'rating': _rating,
                            'comment': _commentCtrl.text.trim(),
                            'categories': {'overall': _rating},
                          },
                        );
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(response['error'] == false || response['success'] == true
                                ? 'Thank you for your feedback!'
                                : (response['message'] ?? 'Feedback submitted')),
                            backgroundColor: response['error'] == false || response['success'] == true
                                ? AppColors.success : AppColors.error,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } catch (_) {
                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Thank you for your feedback!'),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                          ));
                        }
                      } finally {
                        _commentCtrl.dispose();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF59E0B),
                      disabledBackgroundColor: Colors.white12,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Submit Feedback',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Service tile data class ──────────────────────────────────────────────────
class _ServiceTile {
  final IconData icon;
  final String label;
  final String subtitle;
  final Color color;
  final String? badge;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.badge,
  });

  Widget build(BuildContext context, int index) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: color, size: 22),
                  ),
                  const SizedBox(height: 10),
                  Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(subtitle, style: const TextStyle(fontSize: 10, color: Colors.white38), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (badge != null)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 20, height: 20,
                  decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                  child: Center(child: Text(badge!, style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w800))),
                ),
              ),
          ],
        ),
      ).animate(delay: Duration(milliseconds: index * 30)).fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }
}
