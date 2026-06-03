import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class RefundStatusScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const RefundStatusScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<RefundStatusScreen> createState() => _RefundStatusScreenState();
}

class _RefundStatusScreenState extends State<RefundStatusScreen> {
  Map<String, dynamic> _data = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final bookingId = widget.arguments?['bookingId']?.toString() ?? widget.arguments?['id']?.toString();
    if (bookingId != null) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken');
        final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.bookingRefundStatusEndpoint, bookingId), token: token);
        if (response['success'] == true && response['data'] != null) {
          setState(() { _data = Map<String, dynamic>.from(response['data']); _loading = false; });
          return;
        }
      } catch (_) {}
    }
    // Use passed arguments as fallback
    setState(() { _data = widget.arguments ?? _mockData; _loading = false; });
  }

  static final _mockData = {
    'confirmationNumber': 'HS-2024-001',
    'hotelName': 'Grand Horizon Resort & Spa',
    'cancelledDate': '10 Jan 2025',
    'paymentMethod': 'UPI',
    'expectedDate': '15–17 Jan 2025',
    'refundAmount': 8258,
    'refundStatus': 'processing',
  };

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    final refundAmount = (_data['refundAmount'] as num?)?.toInt() ?? 0;
    final status = _data['refundStatus'] as String? ?? 'processing';
    final steps = _buildSteps(status);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Refund Status', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  const Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 36),
                  const SizedBox(height: 12),
                  const Text('Refund Amount', style: TextStyle(fontSize: 14, color: Colors.white70)),
                  const SizedBox(height: 4),
                  Text('Rs.$refundAmount', style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: Text(_statusLabel(status), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
              child: Column(
                children: [
                  _infoRow('Booking ID', _data['confirmationNumber']?.toString() ?? _data['booking_id']?.toString() ?? '—'),
                  const Divider(color: AppColors.lightGray, height: 16),
                  _infoRow('Hotel', _data['hotelName']?.toString() ?? _data['hotel_name']?.toString() ?? '—'),
                  const Divider(color: AppColors.lightGray, height: 16),
                  _infoRow('Cancelled On', _data['cancelledDate']?.toString() ?? _data['cancelled_at']?.toString() ?? '—'),
                  const Divider(color: AppColors.lightGray, height: 16),
                  _infoRow('Refund To', _data['paymentMethod']?.toString() ?? _data['payment_method']?.toString() ?? 'Original payment method'),
                  const Divider(color: AppColors.lightGray, height: 16),
                  _infoRow('Expected By', _data['expectedDate']?.toString() ?? _data['expected_date']?.toString() ?? '5–7 business days'),
                ],
              ),
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),

            // Timeline
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Refund Timeline', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  const SizedBox(height: 20),
                  ...steps.asMap().entries.map((e) => _buildTimelineStep(e.value, e.key, steps.length)),
                ],
              ),
            ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),

            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Refunds typically take 5–7 business days depending on your bank. Contact support if not received within 10 days.',
                      style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
                ],
              ),
            ).animate().fadeIn(delay: 240.ms),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pushNamed(context, '/help-center'),
                icon: const Icon(Icons.support_agent_rounded, size: 18),
                label: const Text('Contact Support'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ).animate().fadeIn(delay: 280.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(Map<String, dynamic> step, int index, int total) {
    final done = step['done'] as bool;
    final active = step['active'] as bool? ?? false;
    final color = done ? AppColors.success : active ? AppColors.primary : AppColors.placeholder;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: done ? AppColors.success : active ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant, shape: BoxShape.circle,
                  border: Border.all(color: color, width: done ? 0 : 1.5)),
              child: Center(child: done
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : active
                      ? Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle))
                      : null),
            ),
            if (index < total - 1)
              Container(width: 2, height: 40, color: done ? AppColors.success : AppColors.lightGray),
          ],
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(step['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: done || active ? AppColors.darkGray : AppColors.gray)),
                const SizedBox(height: 2),
                Text(step['subtitle'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                if (step['date'] != null) ...[
                  const SizedBox(height: 2),
                  Text(step['date'] as String, style: TextStyle(fontSize: 11, color: done ? AppColors.success : AppColors.placeholder, fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
        Flexible(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray), textAlign: TextAlign.right)),
      ],
    );
  }

  String _statusLabel(String s) {
    switch (s) {
      case 'initiated': return 'Refund Initiated';
      case 'processing': return 'Processing';
      case 'completed': return 'Refund Completed';
      default: return 'Pending';
    }
  }

  List<Map<String, dynamic>> _buildSteps(String status) {
    final allDone = status == 'completed';
    final processing = status == 'processing' || allDone;
    return [
      {'title': 'Cancellation Confirmed', 'subtitle': 'Your booking was successfully cancelled', 'done': true, 'date': _data['cancelledDate'] ?? ''},
      {'title': 'Refund Initiated', 'subtitle': 'Refund request sent to payment gateway', 'done': true, 'date': _data['cancelledDate'] ?? ''},
      {'title': 'Processing', 'subtitle': 'Bank is processing the refund', 'done': allDone, 'active': processing && !allDone, 'date': processing ? (_data['processedDate'] ?? '') : null},
      {'title': 'Refund Completed', 'subtitle': 'Amount credited to your account', 'done': allDone, 'active': false, 'date': allDone ? (_data['completedDate'] ?? '') : null},
    ];
  }
}
