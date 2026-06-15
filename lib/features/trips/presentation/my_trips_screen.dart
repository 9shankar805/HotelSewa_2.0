import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/common_header.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen>
    with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;

  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _bookingService.getMyBookings();
      if (result['success'] == true) {
        setState(() {
          _bookings = (result['bookings'] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() {
          _error = result['message'] ?? 'Failed to load bookings';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load bookings';
        _loading = false;
      });
    }
  }

  // ── helpers to safely read API fields with multiple name fallbacks ──────────

  String _str(Map b, List<String> keys, [String fallback = '']) {
    for (final k in keys) {
      final v = b[k];
      if (v != null && v.toString().trim().isNotEmpty) return v.toString().trim();
    }
    return fallback;
  }

  String _getCheckIn(Map b) =>
      _str(b, ['check_in_date', 'check_in', 'checkIn', 'checkin', 'from_date'], '--');

  String _getCheckOut(Map b) =>
      _str(b, ['check_out_date', 'check_out', 'checkOut', 'checkout', 'to_date'], '--');

  String _getHotelName(Map b) {
    // Booking may have nested hotel object or flat fields
    final hotel = b['hotel'];
    if (hotel is Map) {
      final n = _str(hotel, ['name', 'hotel_name', 'title']);
      if (n.isNotEmpty) return n;
    }
    return _str(b, ['hotel_name', 'hotelName', 'property_name'], 'Hotel');
  }

  String _getHotelImage(Map b) {
    final hotel = b['hotel'];
    if (hotel is Map) {
      final img = _str(hotel, ['image', 'photo', 'thumbnail', 'cover_image']);
      if (img.isNotEmpty) return img;
    }
    return _str(b, ['hotel_image', 'hotelImage', 'image']);
  }

  String _getRoomType(Map b) {
    final rt = b['room_type'];
    if (rt is Map) {
      final n = _str(rt, ['type', 'name', 'room_type', 'title']);
      if (n.isNotEmpty) return n;
    }
    return _str(b, ['room_type', 'roomType', 'room_name', 'room'], 'Room');
  }

  String _getStatus(Map b) =>
      _str(b, ['status', 'booking_status'], 'pending').toLowerCase();

  String _getAmount(Map b) =>
      _str(b, ['total_amount', 'totalAmount', 'amount', 'price'], '0');

  String _getNights(Map b) =>
      _str(b, ['nights', 'total_nights', 'no_of_nights'], '');

  String _getGuests(Map b) =>
      _str(b, ['adults', 'guests', 'no_of_guests', 'guest_count'], '');

  String _getBookingId(Map b) =>
      _str(b, ['booking_id', 'id', 'confirmation_number', 'confirmationNumber'], '');

  // ── filter ──────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _filterByStatus(String filter) {
    return _bookings.where((b) {
      final s = _getStatus(b);
      if (filter == 'upcoming') return s == 'confirmed' || s == 'pending';
      if (filter == 'completed') return s == 'completed';
      if (filter == 'cancelled') return s == 'cancelled';
      return false;
    }).toList();
  }

  // ── status style ─────────────────────────────────────────────────────────────

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AppColors.success;
      case 'completed': return AppColors.info;
      case 'cancelled': return AppColors.error;
      default: return AppColors.warning;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'confirmed': return Icons.check_circle_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      default: return Icons.hourglass_top_rounded;
    }
  }

  // ── build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CommonHeader(title: 'My Trips'),

          // Tab bar
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.gray,
              indicatorColor: AppColors.primary,
              indicatorWeight: 3,
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
              tabs: [
                _tab('Upcoming', _filterByStatus('upcoming').length),
                _tab('Completed', _filterByStatus('completed').length),
                _tab('Cancelled', _filterByStatus('cancelled').length),
              ],
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildList(_filterByStatus('upcoming')),
                          _buildList(_filterByStatus('completed')),
                          _buildList(_filterByStatus('cancelled')),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Tab _tab(String label, int count) => Tab(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label),
        if (count > 0) ...[
          const SizedBox(width: 5),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
            child: Text('$count', style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w800)),
          ),
        ],
      ],
    ),
  );

  Widget _buildList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.luggage_outlined, size: 72, color: AppColors.placeholder.withOpacity(0.4)),
            const SizedBox(height: 16),
            const Text('No bookings here yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            const Text('Your bookings will appear here', style: TextStyle(fontSize: 13, color: AppColors.gray)),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => context.go('/home'),
              icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
              label: const Text('Explore Hotels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildCard(list[i], i),
      ),
    );
  }

  Widget _buildCard(Map<String, dynamic> booking, int index) {
    final hotelName  = _getHotelName(booking);
    final hotelImage = _getHotelImage(booking);
    final roomType   = _getRoomType(booking);
    final checkIn    = _getCheckIn(booking);
    final checkOut   = _getCheckOut(booking);
    final nights     = _getNights(booking);
    final guests     = _getGuests(booking);
    final amount     = _getAmount(booking);
    final status     = _getStatus(booking);
    final bookingId  = _getBookingId(booking);
    final statusColor = _statusColor(status);
    final statusIcon  = _statusIcon(status);

    return GestureDetector(
      onTap: () => context.push('/booking-detail', extra: booking),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Column(
          children: [
            // ── Hotel image + name row ──────────────────────────────────
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hotel image
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AppCachedImage(
                      url: hotelImage,
                      width: 88, height: 88,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Status badge
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: statusColor.withOpacity(0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(statusIcon, size: 11, color: statusColor),
                                  const SizedBox(width: 4),
                                  Text(status.toUpperCase(),
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: statusColor, letterSpacing: 0.3)),
                                ],
                              ),
                            ),
                            const Spacer(),
                            if (bookingId.isNotEmpty)
                              Text('#$bookingId',
                                style: const TextStyle(fontSize: 11, color: AppColors.placeholder, fontWeight: FontWeight.w500)),
                          ],
                        ),
                        const SizedBox(height: 7),
                        // Hotel name
                        Text(hotelName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.darkGray),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 3),
                        // Room type
                        Row(children: [
                          const Icon(Icons.king_bed_outlined, size: 13, color: AppColors.gray),
                          const SizedBox(width: 4),
                          Expanded(child: Text(roomType,
                            style: const TextStyle(fontSize: 12, color: AppColors.gray),
                            maxLines: 1, overflow: TextOverflow.ellipsis)),
                        ]),
                        const SizedBox(height: 6),
                        // Nights + guests chips
                        Row(children: [
                          if (nights.isNotEmpty) _miniChip(Icons.nights_stay_outlined, '$nights Night${nights == "1" ? "" : "s"}'),
                          if (nights.isNotEmpty && guests.isNotEmpty) const SizedBox(width: 6),
                          if (guests.isNotEmpty) _miniChip(Icons.people_outline_rounded, '$guests Guest${guests == "1" ? "" : "s"}'),
                        ]),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ── Check-in / Check-out divider row ───────────────────────
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 14),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8F9FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.lightGray),
              ),
              child: Row(
                children: [
                  // Check-in
                  Expanded(child: _dateBlock('CHECK-IN', checkIn, AppColors.success)),
                  // Arrow with nights pill
                  Column(children: [
                    if (nights.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text('$nights N', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)),
                      ),
                    const SizedBox(height: 2),
                    const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.gray),
                  ]),
                  // Check-out
                  Expanded(child: _dateBlock('CHECK-OUT', checkOut, AppColors.error)),
                ],
              ),
            ),

            // ── Footer: amount + view details ──────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total Paid', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                      Text('NPR $amount',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      children: [
                        Text('View Details', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Show QR button for confirmed bookings
            if (status == 'confirmed')
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/online-checkin', extra: booking),
                    icon: const Icon(Icons.qr_code_rounded, size: 16),
                    label: const Text('Check-in QR Code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: const BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 60), duration: 350.ms).slideY(begin: 0.08),
    );
  }

  Widget _dateBlock(String label, String date, Color color) {
    return Column(
      children: [
        Text(label,
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
        const SizedBox(height: 5),
        if (date == '--' || date.isEmpty)
          const Text('--', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.placeholder))
        else ...[
          Text(
            _formatDate(date),
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            _extractYear(date),
            style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w500),
          ),
        ],
      ],
    );
  }

  /// Formats "2025-01-20" → "20 Jan" — handles multiple formats gracefully
  String _formatDate(String raw) {
    if (raw.isEmpty || raw == '--') return '--';
    try {
      // ISO format: 2025-01-20 or 2025-01-20T00:00:00
      final parts = raw.split('T')[0].split('-');
      if (parts.length == 3) {
        final months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
                        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
        final month = int.tryParse(parts[1]) ?? 0;
        return '${parts[2]} ${month > 0 && month <= 12 ? months[month] : parts[1]}';
      }
    } catch (_) {}
    // Return as-is if can't parse
    return raw.length > 10 ? raw.substring(0, 10) : raw;
  }

  String _extractYear(String raw) {
    if (raw.isEmpty || raw == '--') return '';
    try {
      final parts = raw.split('T')[0].split('-');
      if (parts.length == 3) return parts[0];
    } catch (_) {}
    return '';
  }

  Widget _miniChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: AppColors.gray),
          const SizedBox(width: 3),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, size: 64, color: AppColors.placeholder),
            const SizedBox(height: 16),
            Text(_error ?? 'Something went wrong',
              style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBookings,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
