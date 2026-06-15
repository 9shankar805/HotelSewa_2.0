import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/brand_trust_service.dart';

class GuestProtectionScreen extends StatefulWidget {
  const GuestProtectionScreen({super.key});
  @override
  State<GuestProtectionScreen> createState() => _GuestProtectionScreenState();
}

class _GuestProtectionScreenState extends State<GuestProtectionScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    try {
      final res = await BrandTrustService.getGuestProtection();
      if (res['success'] == true && mounted) setState(() { _data = res['data']; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // Default guarantees if API not yet live
  static const _guarantees = [
    _Guarantee('Every Hotel Verified', Icons.verified_rounded, Color(0xFF10B981),
        'Our team physically visits and inspects every hotel before listing it on HotelSewa. We verify cleanliness, safety, and that photos match reality.'),
    _Guarantee('Real Photos Only', Icons.photo_camera_rounded, Color(0xFF3B82F6),
        'All photos are taken by or verified by our team. No stock images, no misleading angles. What you see is exactly what you get.'),
    _Guarantee('No Hidden Charges', Icons.receipt_long_rounded, Color(0xFFF59E0B),
        'Full price breakdown before you confirm. Taxes, fees, everything shown upfront. No surprise charges at checkout.'),
    _Guarantee('Verified Guest Reviews', Icons.star_rounded, Color(0xFF8B5CF6),
        'Only guests who completed a stay can leave reviews. Fake reviews are detected and removed. You can trust what other travelers say.'),
    _Guarantee('24-Hour Support', Icons.support_agent_rounded, Color(0xFFEC4899),
        'Issues during your stay? Our support team responds within 2 hours. We stand behind every booking made through HotelSewa.'),
    _Guarantee('Satisfaction Guarantee', Icons.shield_rounded, AppColors.primary,
        'If your room doesn\'t match the listing in a significant way, we\'ll rebook you or refund you. No arguments, no hassle.'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: CustomScrollView(slivers: [
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: AppColors.primary,
          automaticallyImplyLeading: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 18),
            onPressed: () => context.pop(),
          ),
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFE60023), Color(0xFF1A1A2E)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight,
                ),
              ),
              child: SafeArea(child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.shield_rounded, color: Colors.white, size: 14),
                      SizedBox(width: 6),
                      Text('HotelSewa Promise', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                    ]),
                  ),
                  const SizedBox(height: 12),
                  const Text('Book with\nConfidence', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w900, height: 1.2)),
                  const SizedBox(height: 8),
                  const Text('Every booking is protected by the HotelSewa standard', style: TextStyle(color: Colors.white70, fontSize: 13)),
                ]),
              )),
            ),
          ),
        ),
        if (_loading)
          const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
        else ...[
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Padding(
                  padding: EdgeInsets.only(bottom: 16),
                  child: Text('What We Guarantee', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
                ),
                ..._guarantees.map((g) => _guaranteeCard(g)),
                const SizedBox(height: 8),
                _statsRow(),
                const SizedBox(height: 20),
                _howItWorks(),
                const SizedBox(height: 20),
                _raiseIssueButton(context),
                const SizedBox(height: 40),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  Widget _guaranteeCard(_Guarantee g) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: g.color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
          child: Icon(g.icon, color: g.color, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(g.title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 5),
          Text(g.description, style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280), height: 1.5)),
        ])),
      ]),
    );
  }

  Widget _statsRow() {
    final stats = [
      ('Hotels\nVerified', '100%', const Color(0xFF10B981)),
      ('Fake Review\nRemoval', '24hr', const Color(0xFF3B82F6)),
      ('Issue\nResolution', '24hr', AppColors.primary),
    ];
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
            begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: stats.map((s) => Expanded(child: Column(children: [
        Text(s.$2, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: s.$3)),
        const SizedBox(height: 4),
        Text(s.$1, textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10, color: Colors.white60, fontWeight: FontWeight.w600)),
      ]))).toList()),
    );
  }

  Widget _howItWorks() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('How We Protect You', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 14),
        _step('1', 'We verify', 'Every hotel inspected before listing'),
        _step('2', 'You book', 'Clear pricing, no hidden fees'),
        _step('3', 'You stay', 'Standards enforced during your visit'),
        _step('4', 'You review', 'Genuine feedback improves our network'),
      ]),
    );
  }

  Widget _step(String num, String title, String sub) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(children: [
        Container(width: 28, height: 28,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), shape: BoxShape.circle),
            child: Center(child: Text(num, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900, color: AppColors.primary)))),
        const SizedBox(width: 12),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          Text(sub, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF))),
        ]),
      ]),
    );
  }

  Widget _raiseIssueButton(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push('/raise-complaint'),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          Container(width: 46, height: 46,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
              child: const Icon(Icons.report_problem_rounded, color: AppColors.primary, size: 22)),
          const SizedBox(width: 14),
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Had an issue?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
            Text('Report it — we\'ll resolve it in 24 hours', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFD1D5DB)),
        ]),
      ),
    );
  }
}

class _Guarantee {
  final String title, description;
  final IconData icon;
  final Color color;
  const _Guarantee(this.title, this.icon, this.color, this.description);
}
