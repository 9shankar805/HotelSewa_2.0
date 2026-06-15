import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/booking_service.dart';

class BookingCancellationScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const BookingCancellationScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<BookingCancellationScreen> createState() => _BookingCancellationScreenState();
}

class _BookingCancellationScreenState extends State<BookingCancellationScreen> {
  final BookingService _bookingService = BookingService();
  String _selectedReason = '';
  bool _loading = false;

  final _reasons = [
    'Change of plans',
    'Found a better deal',
    'Travel disruption / Emergency',
    'Booked by mistake',
    'Hotel did not meet expectations',
    'Other',
  ];

  Map<String, dynamic> get _booking => widget.arguments ?? {};

  int get _nights => () {
    try {
      final ci = DateTime.parse(_booking['checkIn']?.toString().split('T')[0] ?? '');
      final co = DateTime.parse(_booking['checkOut']?.toString().split('T')[0] ?? '');
      return co.difference(ci).inDays;
    } catch (_) { return _booking['nights'] ?? 1; }
  }();

  Future<void> _cancel() async {
    if (_selectedReason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm Cancellation', style: TextStyle(fontWeight: FontWeight.w800)),
        content: const Text('Are you sure you want to cancel this booking? This action cannot be undone.', style: TextStyle(color: AppColors.gray, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Keep Booking', style: TextStyle(fontWeight: FontWeight.w600))),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Yes, Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    final bookingId = _booking['id']?.toString() ?? _booking['bookingId']?.toString() ?? '';
    final result = await _bookingService.cancelBooking(bookingId);
    setState(() => _loading = false);

    if (!mounted) return;
    if (result['success'] == true) {
      _showCancelledSuccess();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message'] ?? 'Cancellation failed'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
      );
    }
  }

  void _showCancelledSuccess() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 40),
            ),
            const SizedBox(height: 16),
            const Text('Booking Cancelled', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            const Text('Your booking has been cancelled. Refund will be processed in 5–7 business days.',
                textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.gray, height: 1.5)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, true);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hotelName = _booking['hotelName']?.toString() ?? 'Hotel';
    final roomType = _booking['roomType']?.toString() ?? 'Room';
    final checkIn = _booking['checkIn']?.toString().split('T')[0] ?? '';
    final checkOut = _booking['checkOut']?.toString().split('T')[0] ?? '';
    final totalAmount = (_booking['amount'] ?? _booking['totalAmount'] ?? 0) as num;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Cancel Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Warning banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.error.withOpacity(0.2))),
                    child: const Row(
                      children: [
                        Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 22),
                        SizedBox(width: 12),
                        Expanded(child: Text('Cancellation may be subject to charges as per the hotel\'s policy.',
                            style: TextStyle(fontSize: 13, color: AppColors.error, height: 1.4))),
                      ],
                    ),
                  ).animate().fadeIn(),

                  const SizedBox(height: 20),

                  // Booking summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Booking Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        const SizedBox(height: 14),
                        _row(Icons.hotel_rounded, 'Hotel', hotelName),
                        const Divider(color: AppColors.lightGray, height: 20),
                        _row(Icons.king_bed_outlined, 'Room', roomType),
                        const Divider(color: AppColors.lightGray, height: 20),
                        Row(children: [
                          Expanded(child: _compactRow(Icons.login_rounded, 'Check-in', checkIn)),
                          Container(width: 1, height: 36, color: AppColors.lightGray, margin: const EdgeInsets.symmetric(horizontal: 8)),
                          Expanded(child: _compactRow(Icons.logout_rounded, 'Check-out', checkOut)),
                        ]),
                        const Divider(color: AppColors.lightGray, height: 20),
                        _row(Icons.nights_stay_outlined, 'Duration', '$_nights Night${_nights > 1 ? "s" : ""}'),
                        const Divider(color: AppColors.lightGray, height: 20),
                        _row(Icons.payment_rounded, 'Total Paid', 'NPR ${totalAmount.toInt()}'),
                      ],
                    ),
                  ).animate().fadeIn(delay: 80.ms),

                  const SizedBox(height: 20),

                  // Refund policy
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.info.withOpacity(0.2))),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(children: [
                          Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                          SizedBox(width: 8),
                          Text('Refund Policy', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.info)),
                        ]),
                        const SizedBox(height: 10),
                        const Text('• Refunds are processed in 5–7 business days\n• Amount will be credited to original payment method\n• Cancellation charges may apply as per hotel policy',
                            style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.6)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 120.ms),

                  const SizedBox(height: 20),

                  // Reason selection
                  const Text('Reason for Cancellation', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  const SizedBox(height: 12),
                  ..._reasons.asMap().entries.map((e) {
                    final selected = _selectedReason == e.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedReason = e.value),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.lightGray, width: selected ? 1.5 : 1),
                          boxShadow: selected ? [] : AppColors.cardShadow,
                        ),
                        child: Row(children: [
                          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                              size: 20, color: selected ? AppColors.primary : AppColors.placeholder),
                          const SizedBox(width: 12),
                          Expanded(child: Text(e.value, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                              color: selected ? AppColors.primary : AppColors.darkGray))),
                        ]),
                      ).animate(delay: (e.key * 40).ms).fadeIn().slideX(begin: 0.05),
                    );
                  }),
                ],
              ),
            ),
          ),

          // Cancel button
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 16, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _cancel,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Confirm Cancellation', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(children: [
      Icon(icon, size: 16, color: AppColors.gray),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
      const Spacer(),
      Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray), textAlign: TextAlign.right, maxLines: 2)),
    ]);
  }

  Widget _compactRow(IconData icon, String label, String value) {
    return Column(children: [
      Icon(icon, size: 16, color: AppColors.gray),
      const SizedBox(height: 4),
      Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
      Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
    ]);
  }
}
