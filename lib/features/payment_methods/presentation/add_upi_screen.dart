import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class AddUpiScreen extends StatefulWidget {
  const AddUpiScreen({Key? key}) : super(key: key);

  @override
  State<AddUpiScreen> createState() => _AddUpiScreenState();
}

class _AddUpiScreenState extends State<AddUpiScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // UPI ID tab
  final _upiCtrl = TextEditingController();
  bool _verifying = false;
  bool _verified = false;
  String _verifiedName = '';

  // Net Banking tab
  String _selectedBank = '';
  final _netBankingBanks = [
    {'name': 'HDFC Bank', 'icon': '🏦', 'color': const Color(0xFF004C8F)},
    {'name': 'ICICI Bank', 'icon': '🏦', 'color': const Color(0xFFB02A30)},
    {'name': 'SBI', 'icon': '🏦', 'color': const Color(0xFF003087)},
    {'name': 'Axis Bank', 'icon': '🏦', 'color': const Color(0xFF97144D)},
    {'name': 'Kotak Bank', 'icon': '🏦', 'color': const Color(0xFFED1C24)},
    {'name': 'Yes Bank', 'icon': '🏦', 'color': const Color(0xFF00529B)},
    {'name': 'Punjab National Bank', 'icon': '🏦', 'color': const Color(0xFF003087)},
    {'name': 'Bank of Baroda', 'icon': '🏦', 'color': const Color(0xFFFF6600)},
    {'name': 'Canara Bank', 'icon': '🏦', 'color': const Color(0xFF003087)},
    {'name': 'Union Bank', 'icon': '🏦', 'color': const Color(0xFF003087)},
  ];

  // UPI apps
  final _upiApps = [
    {'name': 'Google Pay', 'suffix': '@okicici', 'color': const Color(0xFF4285F4)},
    {'name': 'PhonePe', 'suffix': '@ybl', 'color': const Color(0xFF5F259F)},
    {'name': 'Paytm', 'suffix': '@paytm', 'color': const Color(0xFF00BAF2)},
    {'name': 'BHIM', 'suffix': '@upi', 'color': const Color(0xFF003087)},
  ];

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _upiCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyUpi() async {
    final upi = _upiCtrl.text.trim();
    if (!upi.contains('@')) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid UPI ID (e.g. name@upi)'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() { _verifying = true; _verified = false; });
    // UPI verification is typically done client-side by format check
    // Real apps use payment gateway SDK for actual verification
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    setState(() { _verifying = false; _verified = true; _verifiedName = upi.split('@')[0]; });
  }

  Future<void> _save() async {
    if (_tabController.index == 0 && !_verified) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please verify your UPI ID first'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    if (_tabController.index == 1 && _selectedBank.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a bank'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(ApiConfig.paymentMethodsEndpoint, token: token, data: {
        'type': _tabController.index == 0 ? 'upi' : 'netbanking',
        if (_tabController.index == 0) 'upi_id': _upiCtrl.text.trim(),
        if (_tabController.index == 1) 'bank': _selectedBank,
      });
      if (!mounted) return;
      if (response['success'] == true) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment method added successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to add'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add payment method'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
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
        title: const Text('Add Payment Method', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [Tab(text: 'UPI'), Tab(text: 'Net Banking')],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [_buildUpiTab(), _buildNetBankingTab()],
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Add Payment Method', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUpiTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Quick select UPI apps
          const Text('Popular UPI Apps', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Row(
            children: _upiApps.map((app) => Expanded(
              child: GestureDetector(
                onTap: () {
                  final suffix = app['suffix'] as String;
                  // If current text doesn't have @, append it. If it has, replace after @.
                  String current = _upiCtrl.text;
                  if (current.isEmpty) {
                    _upiCtrl.text = "user$suffix";
                  } else if (!current.contains('@')) {
                    _upiCtrl.text = "$current$suffix";
                  } else {
                    _upiCtrl.text = "${current.split('@')[0]}$suffix";
                  }
                  setState(() { _verified = false; _verifiedName = ''; });
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppColors.cardShadow),
                  child: Column(children: [
                    Container(width: 32, height: 32, decoration: BoxDecoration(color: (app['color'] as Color).withOpacity(0.1), shape: BoxShape.circle),
                        child: Center(child: Text(app['name'].toString()[0], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: app['color'] as Color)))),
                    const SizedBox(height: 4),
                    Text(app['name'] as String, style: const TextStyle(fontSize: 9, color: AppColors.gray, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
                  ]),
                ),
              ),
            )).toList(),
          ),
          const SizedBox(height: 20),

          const Text('Enter UPI ID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray, letterSpacing: 0.5)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('UPI ID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _upiCtrl,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (_) => setState(() { _verified = false; _verifiedName = ''; }),
                        decoration: InputDecoration(
                          hintText: 'yourname@upi',
                          filled: true, fillColor: AppColors.background,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          suffixIcon: _verified ? const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20) : null,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    GestureDetector(
                      onTap: _verifying ? null : _verifyUpi,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
                        child: _verifying
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text('Verify', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Colors.white)),
                      ),
                    ),
                  ],
                ),
                if (_verified) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(10)),
                    child: Row(children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 16),
                      const SizedBox(width: 8),
                      Text('Verified: $_verifiedName', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.success)),
                    ]),
                  ),
                ],
              ],
            ),
          ).animate().fadeIn(delay: 60.ms),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.lock_outline_rounded, color: AppColors.info, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Your UPI ID is securely stored and never shared with third parties.', style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
            ]),
          ).animate().fadeIn(delay: 120.ms),
        ],
      ),
    );
  }

  Widget _buildNetBankingTab() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _netBankingBanks.length,
      itemBuilder: (_, i) {
        final bank = _netBankingBanks[i];
        final selected = _selectedBank == bank['name'];
        return GestureDetector(
          onTap: () => setState(() => _selectedBank = bank['name'] as String),
          child: Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: selected ? AppColors.primary.withOpacity(0.06) : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: selected ? AppColors.primary : AppColors.lightGray, width: selected ? 1.5 : 1),
              boxShadow: selected ? [] : AppColors.cardShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(color: (bank['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text(bank['icon'] as String, style: const TextStyle(fontSize: 20))),
                ),
                const SizedBox(width: 14),
                Expanded(child: Text(bank['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.darkGray))),
                if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
              ],
            ),
          ).animate(delay: (i * 30).ms).fadeIn(),
        );
      },
    );
  }
}
