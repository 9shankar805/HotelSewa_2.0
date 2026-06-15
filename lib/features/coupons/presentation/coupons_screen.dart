import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/coupon_service.dart';

class CouponsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const CouponsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<CouponsScreen> createState() => _CouponsScreenState();
}

class _CouponsScreenState extends State<CouponsScreen> {
  final _couponController = TextEditingController();
  final _couponService = CouponService();

  bool _loading = true;
  bool _applying = false;
  Map<String, dynamic>? _appliedCoupon;
  List<Map<String, dynamic>> _coupons = [];
  double _bookingAmount = 0;

  static const _fallbackCoupons = [
    {
      'id': '1', 'code': 'FIRST50', 'title': 'First Booking Offer',
      'description': 'Get 50% off on your first booking',
      'discount': 50, 'type': 'percentage', 'minAmount': 1000,
      'maxDiscount': 1000, 'validUntil': '2026-12-31',
    },
    {
      'id': '2', 'code': 'SAVE200', 'title': 'Flat NPR 200 Off',
      'description': 'Flat NPR 200 discount on bookings above NPR 2000',
      'discount': 200, 'type': 'fixed', 'minAmount': 2000,
      'maxDiscount': 200, 'validUntil': '2026-12-31',
    },
    {
      'id': '3', 'code': 'WEEKEND30', 'title': 'Weekend Special',
      'description': '30% off on weekend bookings',
      'discount': 30, 'type': 'percentage', 'minAmount': 1500,
      'maxDiscount': 800, 'validUntil': '2026-12-31',
    },
    {
      'id': '4', 'code': 'LOYALTY15', 'title': 'Loyalty Reward',
      'description': '15% off for returning customers',
      'discount': 15, 'type': 'percentage', 'minAmount': 1000,
      'maxDiscount': 500, 'validUntil': '2026-12-31',
    },
  ];

  @override
  void initState() {
    super.initState();
    _bookingAmount = (widget.arguments?['bookingAmount'] as num?)?.toDouble() ?? 0;
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    setState(() => _loading = true);
    try {
      final result = await _couponService.getAvailableCoupons();
      if (result['success'] == true) {
        final data = result['coupons'];
        if (data is List && data.isNotEmpty) {
          // Map real API fields → internal fields used by the UI
          // API returns: id, code, discount, discount_type, expires_at, usage_limit, usage_count
          final mapped = data.map<Map<String, dynamic>>((c) {
            final m = Map<String, dynamic>.from(c as Map);
            return {
              'id': m['id']?.toString(),
              'code': m['code'] ?? '',
              'title': m['title'] ?? m['code'] ?? 'Coupon',
              'description': m['description'] ?? _buildCouponDesc(m),
              'discount': m['discount'] ?? m['discount_value'] ?? 0,
              'type': m['discount_type'] ?? m['type'] ?? 'percentage',
              'minAmount': (m['min_order_amount'] ?? m['minimum_amount'] ?? m['minAmount'] ?? 0),
              'maxDiscount': (m['max_discount'] ?? m['maxDiscount'] ?? double.infinity),
              'validUntil': _formatExpiry(m['expires_at'] ?? m['valid_to'] ?? m['validUntil']),
              'usageLimit': m['usage_limit'],
              'usageCount': m['usage_count'] ?? 0,
            };
          }).toList();
          setState(() { _coupons = mapped; _loading = false; });
          return;
        }
      }
    } catch (_) {}
    setState(() {
      _coupons = List<Map<String, dynamic>>.from(_fallbackCoupons);
      _loading = false;
    });
  }

  String _buildCouponDesc(Map m) {
    final discount = m['discount'] ?? 0;
    final type = m['discount_type'] ?? 'percentage';
    if (type == 'percentage') return 'Get $discount% off on your booking';
    return 'Get NPR $discount off on your booking';
  }

  String _formatExpiry(dynamic raw) {
    if (raw == null) return '';
    final s = raw.toString();
    try {
      final dt = DateTime.parse(s);
      return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
    } catch (_) {
      return s.split('T')[0];
    }
  }

  double _calculateDiscount(Map<String, dynamic> coupon) {
    final minAmount = (coupon['minAmount'] as num?)?.toDouble() ?? 0;
    if (_bookingAmount > 0 && _bookingAmount < minAmount) return 0;
    final discountVal = (coupon['discount'] as num?)?.toDouble() ?? 0;
    final maxDiscount = (coupon['maxDiscount'] as num?)?.toDouble() ?? double.infinity;
    if (coupon['type'] == 'percentage') {
      final amount = _bookingAmount > 0 ? _bookingAmount : minAmount;
      final disc = amount * discountVal / 100;
      return disc < maxDiscount ? disc : maxDiscount;
    }
    return discountVal;
  }

  Future<void> _applyByCode() async {
    final code = _couponController.text.trim().toUpperCase();
    if (code.isEmpty) return;
    final local = _coupons.where((c) => (c['code'] as String?)?.toUpperCase() == code).toList();
    if (local.isNotEmpty) { _applyLocally(local.first); _couponController.clear(); return; }
    setState(() => _applying = true);
    try {
      final result = await _couponService.validateCoupon(code, amount: _bookingAmount);
      if (result['success'] == true && result['coupon'] != null) {
        _applyLocally(Map<String, dynamic>.from(result['coupon'] as Map));
        _couponController.clear();
      } else {
        _showSnack('Invalid or expired coupon code', isError: true);
      }
    } catch (_) {
      _showSnack('Could not validate coupon. Try again.', isError: true);
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  void _applyLocally(Map<String, dynamic> coupon) {
    final discount = _calculateDiscount(coupon);
    final minAmount = (coupon['minAmount'] as num?)?.toDouble() ?? 0;
    if (_bookingAmount > 0 && _bookingAmount < minAmount) {
      _showSnack('Minimum booking NPR ${minAmount.toInt()} required', isError: true);
      return;
    }
    setState(() => _appliedCoupon = {...coupon, 'discountAmount': discount});
    if (widget.arguments != null) {
      Navigator.pop(context, {'coupon': coupon, 'discount': discount});
    } else {
      _showSnack('Coupon "${coupon['code']}" applied!');
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  void dispose() { _couponController.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final fromBooking = widget.arguments != null && _bookingAmount > 0;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('My Coupons', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.gray), onPressed: _loadCoupons),
        ],
      ),
      body: Column(
        children: [
          if (fromBooking) _buildAmountBanner(),
          _buildCodeInput(),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _coupons.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadCoupons,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: _coupons.length,
                          itemBuilder: (_, i) => _buildCouponCard(_coupons[i], i),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountBanner() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
        child: const Icon(Icons.receipt_long_outlined, color: AppColors.primary, size: 20),
      ),
      const SizedBox(width: 12),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Booking Amount', style: TextStyle(fontSize: 12, color: AppColors.gray)),
        Text('NPR ${_bookingAmount.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      ]),
      if (_appliedCoupon != null) ...[
        const Spacer(),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          const Text('You Save', style: TextStyle(fontSize: 12, color: AppColors.gray)),
          Text('NPR ${(_appliedCoupon!['discountAmount'] as double).toInt()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.success)),
        ]),
      ],
    ]),
  );

  Widget _buildCodeInput() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    margin: const EdgeInsets.only(bottom: 2),
    child: Row(children: [
      Expanded(
        child: TextField(
          controller: _couponController,
          textCapitalization: TextCapitalization.characters,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, letterSpacing: 1),
          decoration: InputDecoration(
            hintText: 'Enter coupon code',
            hintStyle: const TextStyle(fontWeight: FontWeight.normal, letterSpacing: 0),
            prefixIcon: const Icon(Icons.local_offer_outlined, color: AppColors.gray, size: 20),
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
          onSubmitted: (_) => _applyByCode(),
        ),
      ),
      const SizedBox(width: 10),
      SizedBox(
        height: 50,
        child: ElevatedButton(
          onPressed: _applying ? null : _applyByCode,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 20),
          ),
          child: _applying
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        ),
      ),
    ]),
  );

  Widget _buildCouponCard(Map<String, dynamic> coupon, int index) {
    final discount = _calculateDiscount(coupon);
    final minAmount = (coupon['minAmount'] as num?)?.toDouble() ?? 0;
    final isEligible = _bookingAmount == 0 || discount > 0;
    final isApplied = _appliedCoupon?['id'] == coupon['id'];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isApplied ? const Color(0xFFF0FDF4) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isApplied ? AppColors.success : isEligible ? AppColors.primary.withOpacity(0.3) : AppColors.lightGray,
          width: isApplied ? 1.5 : 1,
        ),
        boxShadow: AppColors.cardShadow,
      ),
      child: Opacity(
        opacity: isEligible ? 1.0 : 0.55,
        child: Column(children: [
          // Code strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isApplied ? AppColors.success.withOpacity(0.08) : AppColors.primary.withOpacity(0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () {
                  Clipboard.setData(ClipboardData(text: coupon['code'] as String));
                  _showSnack('Code copied!');
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isApplied ? AppColors.success : AppColors.primary,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(coupon['code'] as String, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 0.5)),
                    const SizedBox(width: 6),
                    const Icon(Icons.copy_rounded, color: Colors.white, size: 13),
                  ]),
                ),
              ),
              const Spacer(),
              if (isApplied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.success, borderRadius: BorderRadius.circular(6)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.check_rounded, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text('APPLIED', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 10)),
                  ]),
                ),
            ]),
          ),
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(coupon['title'] as String? ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 4),
              Text(coupon['description'] as String? ?? '', style: const TextStyle(fontSize: 13, color: AppColors.gray, height: 1.4)),
              const SizedBox(height: 12),
              Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    _bookingAmount > 0 ? 'Save NPR ${discount.toInt()}' : coupon['type'] == 'percentage' ? '${coupon['discount']}% OFF' : 'NPR ${coupon['discount']} OFF',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success),
                  ),
                ),
                const SizedBox(width: 8),
                Text('Min. NPR ${minAmount.toInt()}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                const Spacer(),
                Text('Valid till ${coupon['validUntil'] ?? '—'}', style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
              ]),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: isApplied
                    ? OutlinedButton.icon(
                        onPressed: () => setState(() => _appliedCoupon = null),
                        icon: const Icon(Icons.close_rounded, size: 16),
                        label: const Text('Remove Coupon'),
                        style: OutlinedButton.styleFrom(foregroundColor: AppColors.error, side: BorderSide(color: AppColors.error.withOpacity(0.4)), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                      )
                    : isEligible
                        ? ElevatedButton(
                            onPressed: () => _applyLocally(coupon),
                            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), padding: const EdgeInsets.symmetric(vertical: 10)),
                            child: const Text('Apply Coupon', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                          )
                        : Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(10)),
                            child: Text('Add NPR ${(minAmount - _bookingAmount).toInt()} more to unlock', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                          ),
              ),
            ]),
          ),
        ]),
      ),
    ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.08, end: 0);
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.local_offer_outlined, size: 64, color: AppColors.lightGray),
    const SizedBox(height: 16),
    const Text('No coupons available', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray)),
    const SizedBox(height: 8),
    const Text('Check back later for exciting offers', style: TextStyle(fontSize: 13, color: AppColors.placeholder)),
    const SizedBox(height: 24),
    TextButton.icon(onPressed: _loadCoupons, icon: const Icon(Icons.refresh_rounded), label: const Text('Refresh')),
  ]));
}
