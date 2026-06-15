import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';

class HotelPoliciesScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const HotelPoliciesScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<HotelPoliciesScreen> createState() => _HotelPoliciesScreenState();
}

class _HotelPoliciesScreenState extends State<HotelPoliciesScreen> {
  Map<String, dynamic> _policies = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final hotelId = widget.arguments?['hotelId']?.toString() ?? widget.arguments?['id']?.toString();
    if (hotelId == null) {
      setState(() { _loading = false; });
      return;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get('${ApiConfig.hotelPoliciesEndpoint}/$hotelId', token: token);
      if (mounted) {
        final data = response['data'] ?? response;
        setState(() { _policies = data is Map ? Map<String, dynamic>.from(data) : {}; _loading = false; });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hotelName = widget.arguments?['hotelName'] ?? widget.arguments?['name'] ?? 'Hotel Policies';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(hotelName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildPolicySection(
                    index: 0,
                    icon: Icons.login_rounded,
                    color: AppColors.success,
                    title: 'Check-in Policy',
                    items: [
                      _policyItem('Check-in Time', _policies['check_in_time'] ?? '2:00 PM'),
                      _policyItem('Early Check-in', _policies['early_check_in'] ?? 'Subject to availability (extra charge may apply)'),
                      _policyItem('ID Requirement', _policies['id_required'] ?? 'Valid government-issued photo ID required'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPolicySection(
                    index: 1,
                    icon: Icons.logout_rounded,
                    color: AppColors.error,
                    title: 'Check-out Policy',
                    items: [
                      _policyItem('Check-out Time', _policies['check_out_time'] ?? '11:00 AM'),
                      _policyItem('Late Check-out', _policies['late_check_out'] ?? 'Subject to availability (extra charge may apply)'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPolicySection(
                    index: 2,
                    icon: Icons.cancel_outlined,
                    color: AppColors.warning,
                    title: 'Cancellation Policy',
                    items: [
                      _policyItem('Free Cancellation', _policies['free_cancellation'] ?? 'Up to 24 hours before check-in'),
                      _policyItem('Late Cancellation', _policies['late_cancellation'] ?? '1 night charge if cancelled within 24 hours'),
                      _policyItem('No Show', _policies['no_show'] ?? 'Full booking amount will be charged'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPolicySection(
                    index: 3,
                    icon: Icons.payment_rounded,
                    color: AppColors.primary,
                    title: 'Payment Policy',
                    items: [
                      _policyItem('Accepted Methods', _policies['payment_methods'] ?? 'Cash, Cards, eSewa, Khalti, UPI'),
                      _policyItem('Deposit', _policies['deposit'] ?? 'No advance deposit required'),
                      _policyItem('Currency', _policies['currency'] ?? 'NPR (Nepalese Rupee)'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPolicySection(
                    index: 4,
                    icon: Icons.smoke_free_rounded,
                    color: AppColors.darkGray,
                    title: 'House Rules',
                    items: [
                      _policyItem('Smoking', _policies['smoking'] ?? 'Smoking allowed in designated areas only'),
                      _policyItem('Pets', _policies['pets'] ?? 'Pets not allowed'),
                      _policyItem('Parties & Events', _policies['parties'] ?? 'Parties and events not allowed'),
                      _policyItem('Quiet Hours', _policies['quiet_hours'] ?? '10:00 PM – 7:00 AM'),
                      _policyItem('Age Restriction', _policies['age_restriction'] ?? 'Guests under 18 must be accompanied by an adult'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildPolicySection(
                    index: 5,
                    icon: Icons.child_friendly_rounded,
                    color: AppColors.info,
                    title: 'Children & Extra Beds',
                    items: [
                      _policyItem('Children', _policies['children_policy'] ?? 'Children of all ages are welcome'),
                      _policyItem('Extra Beds', _policies['extra_beds'] ?? 'Available on request (additional charge)'),
                      _policyItem('Cribs', _policies['cribs'] ?? 'Available on request at no extra charge'),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
                    child: Row(
                      children: const [
                        Icon(Icons.info_outline_rounded, size: 18, color: AppColors.info),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Policies may vary. Contact the hotel directly for any special requirements or clarifications.',
                            style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
    );
  }

  Widget _buildPolicySection({required int index, required IconData icon, required Color color, required String title, required List<Widget> items}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightGray),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: items),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 80)).slideY(begin: 0.1);
  }

  Widget _policyItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontSize: 13, color: AppColors.darkGray, fontWeight: FontWeight.w600, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
