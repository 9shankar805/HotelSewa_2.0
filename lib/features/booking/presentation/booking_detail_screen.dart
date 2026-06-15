import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';
import '../../../core/services/qr_checkin_service.dart';

class BookingDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const BookingDetailScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends State<BookingDetailScreen> {
  Map<String, dynamic> _booking = {};
  bool _loading = true;
  String? _qrToken;        // from API
  bool _qrLoading = false;
  bool _qrExpanded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use passed arguments immediately for instant display
    if (widget.arguments != null && widget.arguments!.isNotEmpty) {
      setState(() { _booking = widget.arguments!; _loading = false; });
    }
    // Then try to fetch fresh data from API
    final bookingId = widget.arguments?['id']?.toString() ?? widget.arguments?['bookingId']?.toString();
    if (bookingId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken');
        final response = await ApiService.get(ApiConfig.myBookingsEndpoint, token: token);
        if (response['success'] == true) {
          final raw = response['data'];
          List bookings = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['bookings'] ?? []) : []);
          final found = bookings.firstWhere(
            (b) => b['id']?.toString() == bookingId,
            orElse: () => null,
          );
          if (found != null && mounted) {
            setState(() => _booking = Map<String, dynamic>.from(found));
          }
        }
      } catch (_) {}
    }
    if (mounted && _loading) setState(() => _loading = false);
  }

  Future<void> _fetchQr(String bookingId) async {
    if (_qrToken != null || _qrLoading) return;
    setState(() => _qrLoading = true);
    try {
      final result = await QrCheckinService().getCheckinQr(bookingId);
      if (mounted) {
        final data = result['data'];
        String token = '';
        if (data is Map) {
          token = data['qr_token']?.toString() ?? data['token']?.toString() ?? data['qr_code']?.toString() ?? '';
        } else if (data is String) {
          token = data;
        }
        setState(() {
          _qrToken = token.isNotEmpty ? token : bookingId;
          _qrLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() { _qrToken = bookingId; _qrLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    final booking = _booking.isNotEmpty ? _booking : _emptyBooking;
    final status = (booking['status'] as String? ?? 'confirmed').toLowerCase();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Booking Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.darkGray),
            onPressed: () => _share(context, booking),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusCard(booking, status).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 16),
            _buildHotelCard(context, booking).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            _buildStayDetails(booking).animate().fadeIn(delay: 140.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            _buildGuestDetails(booking).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            _buildPriceBreakdown(booking).animate().fadeIn(delay: 260.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            _buildPolicies(booking).animate().fadeIn(delay: 320.ms).slideY(begin: 0.1),
            const SizedBox(height: 16),
            if (status == 'confirmed' || status == 'pending')
              _buildQrSection(booking).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1),
            if (status == 'confirmed' || status == 'pending') const SizedBox(height: 16),
            if (status == 'confirmed') _buildActions(context, booking),
            if (status == 'completed') _buildPostStayActions(context, booking),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(Map<String, dynamic> booking, String status) {
    final color = _statusColor(status);
    final icon = _statusIcon(status);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(_statusLabel(status), style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          const SizedBox(height: 6),
          Text(_statusSubtitle(status, booking), style: const TextStyle(fontSize: 13, color: AppColors.gray), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => _copyToClipboard(booking['confirmationNumber'] ?? 'HS-2024-001'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.confirmation_number_outlined, size: 16, color: AppColors.gray),
                  const SizedBox(width: 8),
                  Text('Booking ID: ${booking['confirmationNumber'] ?? 'HS-2024-001'}',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                  const SizedBox(width: 8),
                  const Icon(Icons.copy_rounded, size: 14, color: AppColors.gray),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHotelCard(BuildContext context, Map<String, dynamic> booking) {
    return _card(
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              booking['hotelImage'] ?? 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400',
              width: 90, height: 90, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(width: 90, height: 90, color: AppColors.surfaceVariant,
                  child: const Icon(Icons.hotel_rounded, color: AppColors.placeholder, size: 36)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(booking['hotelName'] ?? 'Grand Hotel', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                  const SizedBox(width: 3),
                  Expanded(child: Text(booking['location'] ?? 'Kathmandu, Nepal',
                      style: const TextStyle(fontSize: 12, color: AppColors.gray), maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                const SizedBox(height: 4),
                Row(children: [
                  const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                  const SizedBox(width: 3),
                  Text('${booking['rating'] ?? 4.5}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                  const SizedBox(width: 4),
                  Text('(${booking['reviewCount'] ?? 128} reviews)', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                ]),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/hotel-details', arguments: {'hotelId': booking['hotelId']}),
                  child: const Text('View Hotel', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStayDetails(Map<String, dynamic> booking) {
    return _card(
      title: 'Stay Details',
      child: Column(
        children: [
          _detailRow(Icons.king_bed_outlined, 'Room Type', booking['roomType'] ?? 'Deluxe Room'),
          _divider(),
          Row(
            children: [
              Expanded(child: _detailCol('Check-in', booking['checkIn'] ?? '15 Jan 2025', Icons.login_rounded, AppColors.success)),
              Container(width: 1, height: 48, color: AppColors.lightGray),
              Expanded(child: _detailCol('Check-out', booking['checkOut'] ?? '17 Jan 2025', Icons.logout_rounded, AppColors.error)),
            ],
          ),
          _divider(),
          _detailRow(Icons.nights_stay_outlined, 'Duration', '${booking['nights'] ?? 2} Nights'),
          _divider(),
          _detailRow(Icons.people_outline_rounded, 'Guests', '${booking['adults'] ?? 2} Adults${(booking['children'] ?? 0) > 0 ? ', ${booking['children']} Children' : ''}'),
          _divider(),
          _detailRow(Icons.access_time_rounded, 'Check-in Time', booking['checkInTime'] ?? '2:00 PM'),
          _divider(),
          _detailRow(Icons.access_time_outlined, 'Check-out Time', booking['checkOutTime'] ?? '11:00 AM'),
        ],
      ),
    );
  }

  Widget _buildGuestDetails(Map<String, dynamic> booking) {
    return _card(
      title: 'Primary Guest',
      child: Column(
        children: [
          _detailRow(Icons.person_outline_rounded, 'Name', booking['guestName'] ?? 'John Doe'),
          _divider(),
          _detailRow(Icons.email_outlined, 'Email', booking['guestEmail'] ?? 'john@example.com'),
          _divider(),
          _detailRow(Icons.phone_outlined, 'Phone', booking['guestPhone'] ?? '+91 98765 43210'),
          if ((booking['specialRequests'] ?? '').isNotEmpty) ...[
            _divider(),
            _detailRow(Icons.notes_rounded, 'Special Requests', booking['specialRequests']),
          ],
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(Map<String, dynamic> booking) {
    final roomCharge = (booking['roomCharge'] as num?)?.toInt() ?? 2598;
    final taxes = (booking['taxes'] as num?)?.toInt() ?? 468;
    final discount = (booking['discount'] as num?)?.toInt() ?? 0;
    final total = (booking['totalAmount'] as num?)?.toInt() ?? (roomCharge + taxes - discount);

    return _card(
      title: 'Price Breakdown',
      child: Column(
        children: [
          _priceRow('Room charges', 'NPR $roomCharge'),
          const SizedBox(height: 10),
          _priceRow('Taxes & fees (18%)', 'NPR $taxes'),
          if (discount > 0) ...[
            const SizedBox(height: 10),
            _priceRow('Discount', '-NPR $discount', valueColor: AppColors.success),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(color: AppColors.lightGray, height: 1),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Paid', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              Text('NPR $total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_rounded, size: 14, color: AppColors.success),
                const SizedBox(width: 6),
                Text('Paid via ${booking['paymentMethod'] ?? 'UPI'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.success, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPolicies(Map<String, dynamic> booking) {
    return _card(
      title: 'Cancellation Policy',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _policyItem(Icons.cancel_outlined, AppColors.success, 'Free cancellation until ${booking['freeCancelDate'] ?? '13 Jan 2025'}'),
          const SizedBox(height: 10),
          _policyItem(Icons.warning_amber_rounded, AppColors.warning, '50% charge if cancelled after ${booking['freeCancelDate'] ?? '13 Jan 2025'}'),
          const SizedBox(height: 10),
          _policyItem(Icons.block_rounded, AppColors.error, 'Non-refundable after check-in date'),
        ],
      ),
    );
  }

  Widget _buildActions(BuildContext context, Map<String, dynamic> booking) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/booking-modification', arguments: booking),
                icon: const Icon(Icons.edit_calendar_outlined, size: 18),
                label: const Text('Modify'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/booking-cancellation', arguments: booking),
                icon: const Icon(Icons.cancel_outlined, size: 18),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.error,
                  side: const BorderSide(color: AppColors.error),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/online-checkin', arguments: booking),
            icon: const Icon(Icons.how_to_reg_outlined, size: 18, color: Colors.white),
            label: const Text('Online Check-in', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/invoice', arguments: booking),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Download Invoice'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGray,
              side: const BorderSide(color: AppColors.lightGray),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPostStayActions(BuildContext context, Map<String, dynamic> booking) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/review-submission', arguments: {'hotel': {'id': booking['hotelId'], 'name': booking['hotelName']}}),
            icon: const Icon(Icons.star_outline_rounded, size: 18, color: Colors.white),
            label: const Text('Write a Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 14),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/invoice', arguments: booking),
            icon: const Icon(Icons.receipt_long_outlined, size: 18),
            label: const Text('Download Invoice'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.darkGray,
              side: const BorderSide(color: AppColors.lightGray),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/booking-form', arguments: {'hotel': {'id': booking['hotelId'], 'name': booking['hotelName']}}),
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Book Again'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ),
      ],
    );
  }

  // ── QR Check-in Section ──────────────────────────────────────────────────
  Widget _buildQrSection(Map<String, dynamic> booking) {
    final bookingId = booking['id']?.toString()
        ?? booking['bookingId']?.toString()
        ?? booking['booking_id']?.toString()
        ?? '';
    final hotelName   = booking['hotelName']?.toString() ?? booking['hotel_name']?.toString() ?? 'Hotel';
    final roomType    = booking['roomType']?.toString() ?? booking['room_type']?.toString() ?? 'Room';
    final checkIn     = booking['checkIn']?.toString() ?? booking['check_in_date']?.toString() ?? '';
    final checkOut    = booking['checkOut']?.toString() ?? booking['check_out_date']?.toString() ?? '';
    final guestName   = booking['guestName']?.toString() ?? booking['guest_name']?.toString() ?? '';
    final confirmNum  = booking['confirmationNumber']?.toString() ?? booking['confirmation_number']?.toString() ?? bookingId;
    final amount      = (booking['totalAmount'] ?? booking['total_amount'] ?? 0).toString();

    // Build QR payload
    final qrPayload = _qrToken ?? jsonEncode({
      'app': 'HotelSewa',
      'booking_id': bookingId,
      'confirmation': confirmNum,
      'hotel': hotelName,
      'room': roomType,
      'guest': guestName,
      'check_in': checkIn,
      'check_out': checkOut,
      'amount': 'NPR $amount',
    });

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: [
          // ── Header (tappable to expand/collapse) ─────────────────────
          InkWell(
            onTap: () {
              setState(() => _qrExpanded = !_qrExpanded);
              if (!_qrExpanded && bookingId.isNotEmpty) _fetchQr(bookingId);
            },
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Row(
                children: [
                  Container(
                    width: 42, height: 42,
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.qr_code_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Check-in QR Code', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        Text('Show this at hotel reception', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _qrExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 250),
                    child: const Icon(Icons.keyboard_arrow_down_rounded, size: 22, color: AppColors.gray),
                  ),
                ],
              ),
            ),
          ),

          // ── Expandable QR Body ────────────────────────────────────────
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 300),
            crossFadeState: _qrExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Column(
              children: [
                // Perforated divider
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  child: Row(
                    children: List.generate(36, (i) => Expanded(
                      child: Container(
                        height: 1.5,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        color: i.isEven ? AppColors.lightGray : Colors.transparent,
                      ),
                    )),
                  ),
                ),
                const SizedBox(height: 20),

                // QR code + branding
                _qrLoading
                    ? const Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2.5),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.lightGray, width: 1.5),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Column(
                            children: [
                              // QR with center logo
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  QrImageView(
                                    data: qrPayload,
                                    version: QrVersions.auto,
                                    size: 190,
                                    backgroundColor: Colors.white,
                                    eyeStyle: const QrEyeStyle(
                                      eyeShape: QrEyeShape.square,
                                      color: AppColors.darkGray,
                                    ),
                                    dataModuleStyle: const QrDataModuleStyle(
                                      dataModuleShape: QrDataModuleShape.square,
                                      color: AppColors.darkGray,
                                    ),
                                    errorCorrectionLevel: QrErrorCorrectLevel.H,
                                  ),
                                  // Center HS logo
                                  Container(
                                    width: 42, height: 42,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(10),
                                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6)],
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        color: AppColors.primary,
                                        child: const Center(
                                          child: Text('HS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13, letterSpacing: -0.5)),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 14),

                              // Booking ID chip (tap to copy)
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(text: confirmNum));
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Booking ID copied'), duration: Duration(seconds: 2), behavior: SnackBarBehavior.floating),
                                  );
                                },
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F9FF),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.lightGray),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.confirmation_number_outlined, size: 15, color: AppColors.primary),
                                      const SizedBox(width: 8),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const Text('BOOKING ID', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
                                          Text(confirmNum, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkGray, letterSpacing: 0.5)),
                                        ],
                                      ),
                                      const SizedBox(width: 10),
                                      const Icon(Icons.copy_rounded, size: 14, color: AppColors.gray),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                // Info row: check-in / check-out
                if (checkIn.isNotEmpty || checkOut.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FF),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.lightGray),
                      ),
                      child: Row(
                        children: [
                          Expanded(child: _qrDateBlock('CHECK-IN', checkIn, AppColors.success)),
                          Container(width: 1, height: 40, color: AppColors.lightGray),
                          Expanded(child: _qrDateBlock('CHECK-OUT', checkOut, AppColors.error)),
                        ],
                      ),
                    ),
                  ),

                // Validity note
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded, size: 13, color: AppColors.success),
                      const SizedBox(width: 5),
                      const Text('Valid for check-in on arrival date only',
                          style: TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrDateBlock(String label, String date, Color color) {
    return Column(children: [
      Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
      const SizedBox(height: 4),
      Text(date, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color), textAlign: TextAlign.center),
    ]);
  }

  // Helpers
  Widget _card({String? title, required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null) ...[
            Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gray),
          const SizedBox(width: 10),
          Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
          const Spacer(),
          Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _detailCol(String label, String value, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.gray)),
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.darkGray)),
      ],
    );
  }

  Widget _policyItem(IconData icon, Color color, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.gray, height: 1.4))),
      ],
    );
  }

  Widget _divider() => const Divider(color: Color(0xFFF5F5F5), height: 16);

  Color _statusColor(String s) {
    switch (s) {
      case 'confirmed': return AppColors.success;
      case 'completed': return AppColors.info;
      case 'cancelled': return AppColors.error;
      case 'pending': return AppColors.warning;
      default: return AppColors.gray;
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'confirmed': return Icons.check_circle_rounded;
      case 'completed': return Icons.task_alt_rounded;
      case 'cancelled': return Icons.cancel_rounded;
      case 'pending': return Icons.hourglass_top_rounded;
      default: return Icons.info_rounded;
    }
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'confirmed': return 'Booking Confirmed';
      case 'completed': return 'Stay Completed';
      case 'cancelled': return 'Booking Cancelled';
      case 'pending': return 'Pending Confirmation';
      default: return 'Unknown Status';
    }
  }

  String _statusSubtitle(String s, Map<String, dynamic> b) {
    switch (s) {
      case 'confirmed': return 'Your booking is confirmed. We look forward to your stay!';
      case 'completed': return 'Hope you had a great stay. Share your experience!';
      case 'cancelled': return 'Your booking has been cancelled. Refund will be processed in 5-7 days.';
      case 'pending': return 'Your booking is being processed. You will receive a confirmation shortly.';
      default: return '';
    }
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
  }

  void _share(BuildContext context, Map<String, dynamic> booking) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sharing booking details...'), behavior: SnackBarBehavior.floating),
    );
  }

  Map<String, dynamic> get _emptyBooking => {
    'hotelName': 'Hotel', 'location': '', 'rating': 0, 'reviewCount': 0,
    'roomType': 'Room', 'checkIn': '', 'checkOut': '', 'nights': 1,
    'adults': 1, 'children': 0, 'checkInTime': '2:00 PM', 'checkOutTime': '11:00 AM',
    'guestName': '', 'guestEmail': '', 'guestPhone': '', 'specialRequests': '',
    'roomCharge': 0, 'taxes': 0, 'discount': 0, 'totalAmount': 0,
    'paymentMethod': 'Card', 'confirmationNumber': 'N/A', 'status': 'pending',
    'hotelId': '', 'hotelImage': '', 'bookingDate': '', 'freeCancelDate': '',
  };
  
}

