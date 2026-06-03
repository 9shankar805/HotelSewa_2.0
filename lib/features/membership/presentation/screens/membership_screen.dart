import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class MembershipScreen extends StatefulWidget {
  const MembershipScreen({Key? key}) : super(key: key);

  @override
  State<MembershipScreen> createState() => _MembershipScreenState();
}

class _MembershipScreenState extends State<MembershipScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _plans = [];
  Map<String, dynamic>? _myMembership;
  bool _subscribing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final results = await Future.wait([
        ApiService.get(ApiConfig.membershipsEndpoint),
        ApiService.get(ApiConfig.membershipsMyEndpoint, token: token),
      ]);
      if (results[0]['success'] == true) {
        final data = results[0]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['plans'] ?? []) : []);
        _plans = List<Map<String, dynamic>>.from(raw);
      }
      if (results[1]['success'] == true) {
        final data = results[1]['data'];
        _myMembership = data is Map ? Map<String, dynamic>.from(data) : null;
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load memberships'; _loading = false; });
    }
  }

  Future<void> _subscribe(int planId, String paymentMethod) async {
    setState(() => _subscribing = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(
        ApiConfig.membershipsSubscribeEndpoint,
        data: {'plan_id': planId, 'payment_method': paymentMethod},
        token: token,
      );
      if (response['success'] == true) {
        await _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Membership activated!'), backgroundColor: AppColors.success),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Subscription failed'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _subscribing = false);
    }
  }

  Future<void> _cancel() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final response = await ApiService.post(ApiConfig.membershipsCancelEndpoint, token: token);
    if (response['success'] == true) {
      setState(() => _myMembership = null);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membership cancelled'), backgroundColor: AppColors.success),
      );
    }
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
        title: const Text('Membership Plans', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_myMembership != null) _buildActiveMembership(),
                        const SizedBox(height: 8),
                        if (_plans.isEmpty)
                          const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('No plans available', style: TextStyle(color: AppColors.gray))))
                        else
                          ..._plans.asMap().entries.map((e) => _buildPlanCard(e.value, e.key)),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildActiveMembership() {
    final plan = _myMembership!;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: const Color(0xFF667EEA).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Active Membership', style: TextStyle(fontSize: 12, color: Colors.white70)),
                Text(plan['plan_name'] ?? plan['name'] ?? 'Premium', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: const Text('ACTIVE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Expires: ${plan['expires_at'] ?? plan['end_date'] ?? 'N/A'}', style: const TextStyle(fontSize: 13, color: Colors.white70)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: _confirmCancel,
            style: TextButton.styleFrom(foregroundColor: Colors.white70, padding: EdgeInsets.zero),
            child: const Text('Cancel Membership', style: TextStyle(fontSize: 13, decoration: TextDecoration.underline)),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCard(Map<String, dynamic> plan, int index) {
    final isPopular = index == 1;
    final colors = [
      [const Color(0xFF3B82F6), const Color(0xFF1D4ED8)],
      [const Color(0xFFE60023), const Color(0xFFB8001C)],
      [const Color(0xFF10B981), const Color(0xFF059669)],
    ];
    final color = colors[index % colors.length];
    final features = List<String>.from(plan['features'] ?? plan['benefits'] ?? []);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
        border: isPopular ? Border.all(color: AppColors.primary, width: 2) : null,
      ),
      child: Column(
        children: [
          if (isPopular)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: color, begin: Alignment.centerLeft, end: Alignment.centerRight),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: const Text('MOST POPULAR', textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: 1)),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48, height: 48,
                      decoration: BoxDecoration(gradient: LinearGradient(colors: color, begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(14)),
                      child: const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(plan['name'] ?? 'Plan', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                      Text(plan['description'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                    ])),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text('NPR ${plan['price'] ?? 0}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: color[0])),
                      Text('/${plan['duration'] ?? 'month'}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                    ]),
                  ],
                ),
                if (features.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(color: AppColors.lightGray),
                  const SizedBox(height: 12),
                  ...features.map((f) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      Icon(Icons.check_circle_rounded, size: 16, color: color[0]),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: const TextStyle(fontSize: 13, color: AppColors.darkGray))),
                    ]),
                  )),
                ],
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _subscribing ? null : () => _showPaymentPicker(plan['id']),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color[0],
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Subscribe', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showPaymentPicker(int planId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Text('Choose Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 20),
            ...['khalti', 'esewa', 'stripe'].map((method) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: InkWell(
                onTap: () { Navigator.pop(context); _subscribe(planId, method); },
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.lightGray), borderRadius: BorderRadius.circular(14)),
                  child: Row(children: [
                    const Icon(Icons.payment_rounded, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Text(method[0].toUpperCase() + method.substring(1), style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                    const Spacer(),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.gray),
                  ]),
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _confirmCancel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            const Icon(Icons.cancel_outlined, size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            const Text('Cancel Membership?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            const Text('You will lose all membership benefits at the end of the current billing period.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14), side: const BorderSide(color: AppColors.lightGray), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Keep', style: TextStyle(color: AppColors.darkGray, fontWeight: FontWeight.w600)))),
              const SizedBox(width: 12),
              Expanded(child: ElevatedButton(onPressed: () { Navigator.pop(context); _cancel(); }, style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: const Text('Cancel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)))),
            ]),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry', style: TextStyle(color: Colors.white))),
    ])));
  }
}
