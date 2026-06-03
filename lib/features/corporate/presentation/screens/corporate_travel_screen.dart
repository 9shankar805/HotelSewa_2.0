import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class CorporateTravelScreen extends StatefulWidget {
  const CorporateTravelScreen({Key? key}) : super(key: key);

  @override
  State<CorporateTravelScreen> createState() => _CorporateTravelScreenState();
}

class _CorporateTravelScreenState extends State<CorporateTravelScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _account;
  List<Map<String, dynamic>> _bookings = [];
  List<Map<String, dynamic>> _travelers = [];

  // Registration form
  final _companyCtrl = TextEditingController();
  final _gstCtrl = TextEditingController();
  final _billingCtrl = TextEditingController();
  bool _registering = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _companyCtrl.dispose();
    _gstCtrl.dispose();
    _billingCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final results = await Future.wait([
        ApiService.get(ApiConfig.corporateAccountEndpoint, token: token),
        ApiService.get(ApiConfig.corporateBookingsEndpoint, token: token),
      ]);
      final accountResp = results[0];
      final bookingsResp = results[1];
      if (accountResp['success'] == true) {
        final data = accountResp['data'];
        _account = data is Map ? Map<String, dynamic>.from(data) : null;
        _travelers = List<Map<String, dynamic>>.from(_account?['travelers'] ?? []);
      }
      if (bookingsResp['success'] == true) {
        final data = bookingsResp['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['bookings'] ?? []) : []);
        _bookings = List<Map<String, dynamic>>.from(raw);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load corporate account'; _loading = false; });
    }
  }

  Future<void> _register() async {
    if (_companyCtrl.text.isEmpty) return;
    setState(() => _registering = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(
        ApiConfig.corporateRegisterEndpoint,
        data: {'company_name': _companyCtrl.text, 'gst_number': _gstCtrl.text, 'billing_address': _billingCtrl.text},
        token: token,
      );
      if (response['success'] == true) {
        await _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Corporate account registered'), backgroundColor: AppColors.success),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Registration failed'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _registering = false);
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
        title: const Text('Corporate Travel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        bottom: _account != null ? TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Account'), Tab(text: 'Bookings'), Tab(text: 'Travelers')],
        ) : null,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : _account == null
                  ? _buildRegistrationForm()
                  : TabBarView(
                      controller: _tabController,
                      children: [_buildAccountTab(), _buildBookingsTab(), _buildTravelersTab()],
                    ),
    );
  }

  Widget _buildRegistrationForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                  child: const Icon(Icons.business_rounded, color: Colors.white, size: 28)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Corporate Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Register to access GST invoices, centralized billing & team management.', style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildField('Company Name', _companyCtrl, Icons.business_outlined, required: true),
          const SizedBox(height: 16),
          _buildField('GST Number', _gstCtrl, Icons.receipt_long_outlined),
          const SizedBox(height: 16),
          _buildField('Billing Address', _billingCtrl, Icons.location_on_outlined, maxLines: 3),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _registering ? null : _register,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _registering
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Register Corporate Account', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController ctrl, IconData icon, {bool required = false, int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$label${required ? ' *' : ''}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: AppColors.gray, size: 20),
            hintText: label,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }

  Widget _buildAccountTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
            child: Column(
              children: [
                _accountRow(Icons.business_rounded, 'Company', _account?['company_name'] ?? ''),
                const Divider(height: 24, color: AppColors.lightGray),
                _accountRow(Icons.receipt_long_outlined, 'GST Number', _account?['gst_number'] ?? 'Not set'),
                const Divider(height: 24, color: AppColors.lightGray),
                _accountRow(Icons.location_on_outlined, 'Billing Address', _account?['billing_address'] ?? 'Not set'),
                const Divider(height: 24, color: AppColors.lightGray),
                _accountRow(Icons.people_outline_rounded, 'Travelers', '${_travelers.length} registered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _accountRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.info, size: 18)),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        ])),
      ],
    );
  }

  Widget _buildBookingsTab() {
    if (_bookings.isEmpty) {
      return const Center(child: Text('No corporate bookings yet', style: TextStyle(color: AppColors.gray)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (_, i) {
        final b = _bookings[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.hotel_rounded, color: AppColors.info, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(b['hotel_name'] ?? b['hotel']?['name'] ?? 'Hotel', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                Text('${b['check_in'] ?? ''} → ${b['check_out'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
              ])),
              Text('NPR ${b['total_amount'] ?? b['amount'] ?? ''}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTravelersTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._travelers.map((t) => Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.infoLight, child: Text((t['name'] ?? 'T')[0].toUpperCase(), style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w700))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(t['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                Text(t['email'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
              ])),
            ],
          ),
        )),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showAddTravelerDialog,
          icon: const Icon(Icons.person_add_outlined),
          label: const Text('Add Traveler'),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ],
    );
  }

  void _showAddTravelerDialog() {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Add Traveler', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              _buildField('Name', nameCtrl, Icons.person_outline, required: true),
              const SizedBox(height: 12),
              _buildField('Email', emailCtrl, Icons.email_outlined),
              const SizedBox(height: 12),
              _buildField('Mobile', mobileCtrl, Icons.phone_outlined),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.corporateAddTravelerEndpoint, data: {'name': nameCtrl.text, 'email': emailCtrl.text, 'mobile': mobileCtrl.text}, token: token);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Add Traveler', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
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
