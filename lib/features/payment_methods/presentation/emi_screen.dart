import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';

class EmiScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const EmiScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<EmiScreen> createState() => _EmiScreenState();
}

class _EmiScreenState extends State<EmiScreen> {
  int _selectedTenure = 3;
  bool _loading = false;
  Map? _preview;

  final List<Map<String, dynamic>> _tenures = [
    {'months': 3, 'label': '3 Months', 'rate': 0.0},
    {'months': 6, 'label': '6 Months', 'rate': 1.5},
    {'months': 9, 'label': '9 Months', 'rate': 2.0},
    {'months': 12, 'label': '12 Months', 'rate': 2.5},
  ];

  double get _totalAmount => (widget.arguments?['totalAmount'] ?? widget.arguments?['amount'] ?? 0).toDouble();

  double get _selectedRate => _tenures.firstWhere((t) => t['months'] == _selectedTenure, orElse: () => _tenures[0])['rate'] as double;

  double get _emiAmount {
    if (_totalAmount == 0) return 0;
    final rate = _selectedRate / 100;
    final principal = _totalAmount;
    if (rate == 0) return principal / _selectedTenure;
    final emi = principal * rate * (1 + rate) / ((1 + rate) - 1);
    return emi;
  }

  double get _totalPayable => _emiAmount * _selectedTenure;
  double get _interest => _totalPayable - _totalAmount;

  Future<void> _previewInstallment() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final bookingId = widget.arguments?['bookingId']?.toString() ?? widget.arguments?['id']?.toString();
      final data = {
        'booking_id': bookingId ?? '',
        'amount': _totalAmount,
        'tenure_months': _selectedTenure,
      };
      final response = await ApiService.post(ApiConfig.installmentEndpoint, token: token, data: data);
      if (mounted) {
        setState(() {
          _preview = response['success'] == true ? response['data'] : null;
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _confirmEmi() async {
    await _previewInstallment();
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Confirm EMI Plan', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _confirmRow('Amount', 'NPR ${_totalAmount.toStringAsFixed(0)}'),
            _confirmRow('Tenure', '$_selectedTenure months'),
            _confirmRow('Monthly EMI', 'NPR ${_emiAmount.toStringAsFixed(0)}'),
            _confirmRow('Interest (${_selectedRate}%)', 'NPR ${_interest.toStringAsFixed(0)}'),
            _confirmRow('Total Payable', 'NPR ${_totalPayable.toStringAsFixed(0)}'),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('EMI plan activated successfully!'), behavior: SnackBarBehavior.floating),
              );
              Navigator.pop(context, {'emi': true, 'tenure': _selectedTenure, 'monthly': _emiAmount});
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Confirm EMI', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _confirmRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 13)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: AppColors.darkGray)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Pay in Installments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount summary
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppColors.primaryShadow,
              ),
              child: Column(
                children: [
                  const Text('Total Booking Amount', style: TextStyle(fontSize: 13, color: Colors.white70)),
                  const SizedBox(height: 8),
                  Text('NPR ${_totalAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 36, fontWeight: FontWeight.w900, color: Colors.white)),
                  if (widget.arguments?['hotelName'] != null) ...[
                    const SizedBox(height: 4),
                    Text(widget.arguments!['hotelName'].toString(), style: const TextStyle(fontSize: 13, color: Colors.white60)),
                  ],
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 24),
            const Text('Select EMI Plan', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 4),
            const Text('Choose how many months to spread your payments', style: TextStyle(fontSize: 13, color: AppColors.gray)),
            const SizedBox(height: 14),
            ..._tenures.asMap().entries.map((entry) {
              final i = entry.key;
              final tenure = entry.value;
              final months = tenure['months'] as int;
              final rate = tenure['rate'] as double;
              final selected = _selectedTenure == months;
              final monthlyAmt = _totalAmount == 0 ? 0.0 : (rate == 0 ? _totalAmount / months : (_totalAmount * (rate / 100) * (1 + rate / 100)) / ((1 + rate / 100) - 1));

              return GestureDetector(
                onTap: () => setState(() => _selectedTenure = months),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: selected ? AppColors.primary : AppColors.lightGray, width: selected ? 1.5 : 1),
                    boxShadow: selected ? [] : AppColors.cardShadow,
                  ),
                  child: Row(
                    children: [
                      Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                          color: selected ? AppColors.primary : AppColors.placeholder, size: 22),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(tenure['label'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: selected ? AppColors.primary : AppColors.darkGray)),
                            Text(rate == 0 ? 'No interest' : '${rate}% interest p.a.', style: TextStyle(fontSize: 12, color: rate == 0 ? AppColors.success : AppColors.gray)),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('NPR ${monthlyAmt.toStringAsFixed(0)}/mo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: selected ? AppColors.primary : AppColors.darkGray)),
                          if (rate == 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)),
                              child: const Text('0% EMI', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w700)),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideY(begin: 0.1);
            }).toList(),
            const SizedBox(height: 20),
            // Summary card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
              child: Column(
                children: [
                  _summaryRow('Principal Amount', 'NPR ${_totalAmount.toStringAsFixed(0)}'),
                  const Divider(height: 20, color: AppColors.lightGray),
                  _summaryRow('Interest (${_selectedRate}%)', _interest > 0 ? 'NPR ${_interest.toStringAsFixed(0)}' : 'Free'),
                  const Divider(height: 20, color: AppColors.lightGray),
                  _summaryRow('Total Payable', 'NPR ${_totalPayable.toStringAsFixed(0)}'),
                  const Divider(height: 20, color: AppColors.lightGray),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Monthly EMI', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                      Text('NPR ${_emiAmount.toStringAsFixed(0)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.primary)),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 400.ms),
            const SizedBox(height: 24),
            // Bank eligibility note
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
              child: Row(
                children: const [
                  Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'EMI availability is subject to your bank and card eligibility. Applicable on select cards only.',
                      style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 500.ms),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _confirmEmi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(
                        'Pay NPR ${_emiAmount.toStringAsFixed(0)}/month × $_selectedTenure months',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15),
                      ),
              ),
            ).animate().fadeIn(delay: 600.ms),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _summaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
        Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
      ],
    );
  }
}
