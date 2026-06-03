import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class InvoiceScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const InvoiceScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<InvoiceScreen> createState() => _InvoiceScreenState();
}

class _InvoiceScreenState extends State<InvoiceScreen> {
  Map<String, dynamic> _invoice = {};
  bool _loading = true;
  bool _downloading = false;

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
        final response = await ApiService.get(
          ApiConfig.buildPath(ApiConfig.invoicePreviewEndpoint, '$bookingId/preview'),
          token: token,
        );
        if (response['success'] == true && response['data'] != null) {
          setState(() { _invoice = Map<String, dynamic>.from(response['data']); _loading = false; });
          return;
        }
      } catch (_) {}
    }
    setState(() { _invoice = widget.arguments ?? _mock; _loading = false; });
  }

  Future<void> _download() async {
    final bookingId = _invoice['bookingId']?.toString() ?? _invoice['id']?.toString();
    if (bookingId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice download not available'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _downloading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      await ApiService.get(
        ApiConfig.buildPath(ApiConfig.invoiceDownloadEndpoint, '$bookingId/download'),
        token: token,
      );
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice downloaded'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Download failed'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.primary)));
    final booking = _invoice;
    final roomCharge = (booking['roomCharge'] as num?)?.toInt() ?? 0;
    final taxes = (booking['taxes'] as num?)?.toInt() ?? 0;
    final discount = (booking['discount'] as num?)?.toInt() ?? 0;
    final total = (booking['totalAmount'] as num?)?.toInt() ?? (roomCharge + taxes - discount);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Invoice', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.darkGray),
            onPressed: () {
              final bookingId = _invoice['bookingId']?.toString() ?? _invoice['id']?.toString() ?? '';
              final text = 'HotelSewa Invoice\nBooking: $bookingId\nHotel: ${_invoice['hotelName'] ?? ''}\nTotal: NPR ${_invoice['totalAmount'] ?? 0}';
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invoice details copied: $text'), behavior: SnackBarBehavior.floating),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
              child: Column(
                children: [
                  // Header
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('HOTELSEWA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 1)),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                              child: const Text('INVOICE', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _invoiceLabel('Invoice No.', booking['confirmationNumber'] ?? 'HS-2024-001'),
                            _invoiceLabel('Date', booking['bookingDate'] ?? '10 Jan 2025', align: TextAlign.right),
                          ],
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),

                  Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Billed to
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _section('Billed To', [
                              booking['guestName'] ?? 'John Doe',
                              booking['guestEmail'] ?? 'john@example.com',
                              booking['guestPhone'] ?? '+91 98765 43210',
                            ])),
                            Expanded(child: _section('Hotel', [
                              booking['hotelName'] ?? 'Grand Horizon Resort',
                              booking['location'] ?? 'Mumbai, Maharashtra',
                            ], align: CrossAxisAlignment.end)),
                          ],
                        ),
                        const Divider(color: AppColors.lightGray, height: 28),

                        // Stay details
                        const Text('Stay Details', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        const SizedBox(height: 12),
                        _invoiceRow('Room Type', booking['roomType'] ?? 'Deluxe Sea View Room'),
                        const SizedBox(height: 6),
                        _invoiceRow('Check-in', booking['checkIn'] ?? '15 Jan 2025'),
                        const SizedBox(height: 6),
                        _invoiceRow('Check-out', booking['checkOut'] ?? '17 Jan 2025'),
                        const SizedBox(height: 6),
                        _invoiceRow('Duration', '${booking['nights'] ?? 2} Nights'),
                        const SizedBox(height: 6),
                        _invoiceRow('Guests', '${booking['adults'] ?? 2} Adults'),
                        const Divider(color: AppColors.lightGray, height: 28),

                        // Price breakdown
                        const Text('Price Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        const SizedBox(height: 12),
                        _priceRow('Room charges (${booking['nights'] ?? 2} nights)', 'â‚¹$roomCharge'),
                        const SizedBox(height: 8),
                        _priceRow('GST (18%)', 'â‚¹$taxes'),
                        if (discount > 0) ...[
                          const SizedBox(height: 8),
                          _priceRow('Discount', '-â‚¹$discount', valueColor: AppColors.success),
                        ],
                        const Divider(color: AppColors.lightGray, height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
                            Text('â‚¹$total', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                          ],
                        ),
                        const SizedBox(height: 12),
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
                        const SizedBox(height: 20),
                        const Divider(color: AppColors.lightGray, height: 1),
                        const SizedBox(height: 16),
                        const Center(
                          child: Text('Thank you for choosing HotelSewa!',
                              style: TextStyle(fontSize: 13, color: AppColors.gray, fontStyle: FontStyle.italic)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _downloading ? null : _download,
                icon: _downloading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.download_rounded, color: Colors.white, size: 20),
                label: Text(_downloading ? 'Downloading...' : 'Download PDF',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _invoiceLabel(String label, String value, {TextAlign align = TextAlign.left}) {
    return Column(
      crossAxisAlignment: align == TextAlign.right ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.7))),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
      ],
    );
  }

  Widget _section(String title, List<String> lines, {CrossAxisAlignment align = CrossAxisAlignment.start}) {
    return Column(
      crossAxisAlignment: align,
      children: [
        Text(title, style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        ...lines.map((l) => Text(l, style: const TextStyle(fontSize: 13, color: AppColors.darkGray, height: 1.5), textAlign: align == CrossAxisAlignment.end ? TextAlign.right : TextAlign.left)),
      ],
    );
  }

  Widget _invoiceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
      ],
    );
  }

  Widget _priceRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor ?? AppColors.darkGray)),
      ],
    );
  }

  Map<String, dynamic> get _mock => widget.arguments ?? {
    'bookingId': 'N/A', 'confirmationNumber': 'HS-2024-001',
    'guestName': 'Guest', 'guestEmail': '', 'guestPhone': '',
    'hotelName': 'Hotel', 'location': '', 'roomType': 'Room',
    'checkIn': '', 'checkOut': '', 'nights': 1, 'adults': 1,
    'roomCharge': 0, 'taxes': 0, 'discount': 0, 'totalAmount': 0,
    'paymentMethod': 'Card', 'bookingDate': '',
  };

}
