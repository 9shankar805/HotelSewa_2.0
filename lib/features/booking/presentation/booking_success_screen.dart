import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/navigation/app_routes.dart';

class BookingSuccessScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const BookingSuccessScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<BookingSuccessScreen> createState() => _BookingSuccessScreenState();
}

class _BookingSuccessScreenState extends State<BookingSuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _checkController;
  late AnimationController _ticketController;

  @override
  void initState() {
    super.initState();
    _checkController = AnimationController(vsync: this, duration: const Duration(milliseconds: 600))..forward();
    _ticketController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _ticketController.forward();
    });
  }

  @override
  void dispose() {
    _checkController.dispose();
    _ticketController.dispose();
    super.dispose();
  }

  void _copyId(String id) {
    Clipboard.setData(ClipboardData(text: id));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Booking ID copied'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final args = widget.arguments ?? {};
    final bookingId    = args['booking_id']?.toString() ?? args['id']?.toString() ?? 'N/A';
    final hotelName    = args['hotel_name']?.toString() ?? args['hotelName']?.toString() ?? 'Hotel';
    final roomType     = args['room_type']?.toString() ?? args['roomType']?.toString() ?? 'Room';
    final checkIn      = args['check_in']?.toString() ?? args['checkIn']?.toString() ?? '--';
    final checkOut     = args['check_out']?.toString() ?? args['checkOut']?.toString() ?? '--';
    final guests       = args['guests']?.toString() ?? args['adults']?.toString() ?? '1';
    final amount       = args['total_amount']?.toString() ?? args['amount']?.toString() ?? '0';
    final guestName    = args['guest_name']?.toString() ?? args['guestName']?.toString() ?? 'Guest';
    final payMethod    = args['payment_method']?.toString() ?? args['paymentMethod']?.toString() ?? 'Card';
    final nights       = args['nights']?.toString() ?? '1';
    final confirmNum   = args['confirmation_number']?.toString()
        ?? 'HS-${bookingId.length > 6 ? bookingId.substring(0, 6).toUpperCase() : bookingId.toUpperCase()}';

    // QR encodes a rich JSON payload
    final qrPayload = jsonEncode({
      'app': 'HotelSewa',
      'booking_id': bookingId,
      'confirmation': confirmNum,
      'hotel': hotelName,
      'room': roomType,
      'guest': guestName,
      'check_in': checkIn,
      'check_out': checkOut,
      'nights': nights,
      'guests': guests,
      'amount': 'NPR $amount',
      'paid_via': payMethod,
    });

    return Scaffold(
      backgroundColor: const Color(0xFFF0F4FF),
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ───────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  const Spacer(),
                  const Text('Booking Confirmed', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
                  const Spacer(),
                  GestureDetector(
                    onTap: () => context.go('/home'),
                    child: Container(
                      width: 36, height: 36,
                      decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: AppColors.cardShadow),
                      child: const Icon(Icons.close_rounded, size: 18, color: AppColors.gray),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    // ── Success badge ─────────────────────────────────────
                    AnimatedBuilder(
                      animation: _checkController,
                      builder: (_, __) => Transform.scale(
                        scale: Curves.elasticOut.transform(_checkController.value.clamp(0.0, 1.0)),
                        child: Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, color: Colors.white, size: 42),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text('Your stay is booked!',
                      style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkGray, letterSpacing: -0.3),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                    const SizedBox(height: 4),
                    Text('Show the QR code at hotel reception',
                      style: const TextStyle(fontSize: 13, color: AppColors.gray),
                    ).animate().fadeIn(delay: 450.ms),
                    const SizedBox(height: 28),

                    // ── BOARDING PASS TICKET ──────────────────────────────
                    AnimatedBuilder(
                      animation: _ticketController,
                      builder: (_, child) => Opacity(
                        opacity: _ticketController.value,
                        child: Transform.translate(
                          offset: Offset(0, 40 * (1 - _ticketController.value)),
                          child: child,
                        ),
                      ),
                      child: _buildTicket(
                        context,
                        confirmNum: confirmNum,
                        bookingId: bookingId,
                        hotelName: hotelName,
                        roomType: roomType,
                        guestName: guestName,
                        checkIn: checkIn,
                        checkOut: checkOut,
                        nights: nights,
                        guests: guests,
                        amount: amount,
                        payMethod: payMethod,
                        qrPayload: qrPayload,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Action buttons ────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => context.go(AppRoutes.myTrips),
                        icon: const Icon(Icons.luggage_rounded, size: 20, color: Colors.white),
                        label: const Text('View My Bookings', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 900.ms),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => context.go('/home'),
                        icon: const Icon(Icons.home_outlined, size: 20),
                        label: const Text('Back to Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                      ),
                    ).animate().fadeIn(delay: 1000.ms),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicket(BuildContext context, {
    required String confirmNum,
    required String bookingId,
    required String hotelName,
    required String roomType,
    required String guestName,
    required String checkIn,
    required String checkOut,
    required String nights,
    required String guests,
    required String amount,
    required String payMethod,
    required String qrPayload,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(color: AppColors.primary.withOpacity(0.12), blurRadius: 32, offset: const Offset(0, 12)),
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          // ── HEADER SECTION ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            decoration: const BoxDecoration(
              gradient: AppColors.primaryGradient,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hotel icon badge
                    Container(
                      width: 52, height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                      ),
                      child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 28),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('HOTELSEWA', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1.5)),
                          ),
                          const SizedBox(height: 5),
                          Text(hotelName,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.3),
                            maxLines: 2, overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(roomType, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.8), fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: Colors.white),
                          SizedBox(width: 4),
                          Text('CONFIRMED', style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.5)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                // Confirmation number row
                GestureDetector(
                  onTap: () => _copyId(bookingId),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.confirmation_number_outlined, size: 16, color: Colors.white),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('CONFIRMATION NO.', style: TextStyle(fontSize: 9, color: Colors.white70, fontWeight: FontWeight.w600, letterSpacing: 1)),
                            Text(confirmNum, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── CHECK-IN / CHECK-OUT ROW ───────────────────────────────────
          Container(
            color: const Color(0xFFF8F9FF),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
            child: Row(
              children: [
                Expanded(child: _dateBlock('CHECK-IN', checkIn, Icons.login_rounded, AppColors.success)),
                Column(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Text('$nights', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        const SizedBox(width: 3),
                        Text(int.tryParse(nights) == 1 ? 'Night' : 'Nights',
                          style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(children: [
                    Container(width: 20, height: 1, color: AppColors.lightGray),
                    const Icon(Icons.arrow_forward_rounded, size: 14, color: AppColors.gray),
                    Container(width: 20, height: 1, color: AppColors.lightGray),
                  ]),
                ]),
                Expanded(child: _dateBlock('CHECK-OUT', checkOut, Icons.logout_rounded, AppColors.error)),
              ],
            ),
          ),

          // ── PERFORATED DIVIDER ─────────────────────────────────────────
          _buildPerforatedDivider(),

          // ── GUEST & PAYMENT INFO ──────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 4),
            child: Row(
              children: [
                Expanded(child: _infoChip(Icons.person_rounded, 'GUEST', guestName)),
                const SizedBox(width: 12),
                Expanded(child: _infoChip(Icons.people_rounded, 'GUESTS', '$guests Person${int.tryParse(guests) != 1 ? "s" : ""}')),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
            child: Row(
              children: [
                Expanded(child: _infoChip(Icons.payment_rounded, 'PAID VIA', payMethod.toUpperCase())),
                const SizedBox(width: 12),
                Expanded(child: _infoChip(Icons.currency_rupee_rounded, 'TOTAL PAID', 'NPR $amount')),
              ],
            ),
          ),

          // ── PERFORATED DIVIDER ─────────────────────────────────────────
          _buildPerforatedDivider(),

          // ── QR CODE SECTION ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            child: Column(
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, size: 16, color: AppColors.gray),
                    SizedBox(width: 6),
                    Text('SCAN AT RECEPTION', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1.5)),
                  ],
                ),
                const SizedBox(height: 16),
                // QR with branded frame
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.lightGray, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          QrImageView(
                            data: qrPayload,
                            version: QrVersions.auto,
                            size: 200,
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
                          // Center logo overlay
                          Container(
                            width: 44, height: 44,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 8)],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: Container(
                                color: AppColors.primary,
                                child: const Center(
                                  child: Text('HS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 14, letterSpacing: -0.5)),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Booking ID barcode-style display
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8F9FF),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.lightGray),
                        ),
                        child: Column(
                          children: [
                            // Fake barcode stripes
                            SizedBox(
                              height: 32,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(40, (i) {
                                  final w = [1.5, 1.0, 2.5, 1.0, 1.5, 3.0, 1.0, 2.0][i % 8];
                                  final gap = [1.0, 2.0, 1.0, 1.5, 1.0, 2.0, 1.5, 1.0][i % 8];
                                  return Row(children: [
                                    Container(width: w, height: 28, color: AppColors.darkGray),
                                    SizedBox(width: gap),
                                  ]);
                                }),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(bookingId,
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGray, letterSpacing: 2),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Valid note
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.verified_rounded, size: 14, color: AppColors.success),
                    const SizedBox(width: 5),
                    const Text('Valid for check-in on arrival date only',
                      style: TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
                  ],
                ),
              ],
            ),
          ),

          // ── FOOTER ────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
            decoration: const BoxDecoration(
              color: Color(0xFFF8F9FF),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.info_outline_rounded, size: 13, color: AppColors.placeholder),
                const SizedBox(width: 6),
                Text('HotelSewa — booking ID $bookingId',
                  style: const TextStyle(fontSize: 11, color: AppColors.placeholder, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Perforated edge effect (notched left + right + dashed center line)
  Widget _buildPerforatedDivider() {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Left notch
          Positioned(
            left: -12, top: 0,
            child: Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(color: Color(0xFFF0F4FF), shape: BoxShape.circle),
            ),
          ),
          // Right notch
          Positioned(
            right: -12, top: 0,
            child: Container(
              width: 24, height: 24,
              decoration: const BoxDecoration(color: Color(0xFFF0F4FF), shape: BoxShape.circle),
            ),
          ),
          // Dashed center line
          Positioned.fill(
            left: 12, right: 12, top: 11,
            child: Row(
              children: List.generate(40, (i) => Expanded(
                child: Container(
                  height: 1.5,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  color: i.isEven ? AppColors.lightGray : Colors.transparent,
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateBlock(String label, String date, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle),
          child: Icon(icon, size: 18, color: color),
        ),
        const SizedBox(height: 6),
        Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 1)),
        const SizedBox(height: 3),
        Text(date,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.darkGray),
          textAlign: TextAlign.center, maxLines: 2,
        ),
      ],
    );
  }

  Widget _infoChip(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F9FF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.lightGray),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 0.8)),
              const SizedBox(height: 2),
              Text(value,
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                maxLines: 1, overflow: TextOverflow.ellipsis,
              ),
            ],
          )),
        ],
      ),
    );
  }
}
