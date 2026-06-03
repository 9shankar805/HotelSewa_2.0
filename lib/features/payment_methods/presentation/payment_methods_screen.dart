import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({Key? key}) : super(key: key);

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  List<Map<String, dynamic>> _methods = [];
  bool _loading = true;
  String? _error;

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
      final response = await ApiService.get(ApiConfig.getPaymentSettingsEndpoint, token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List methods = [];
        if (data is Map) methods = data['payment_methods'] ?? data['methods'] ?? data['cards'] ?? [];
        if (data is List) methods = data;
        setState(() {
          _methods = methods.map<Map<String, dynamic>>((m) => {
            'id': m['id']?.toString() ?? '',
            'type': m['type']?.toString() ?? 'card',
            'name': m['name'] ?? m['card_number'] ?? m['upi_id'] ?? 'Payment Method',
            'isDefault': m['is_default'] == true || m['default'] == true,
            'brand': m['brand'] ?? m['card_brand'] ?? '',
            'last4': m['last4'] ?? m['last_four'] ?? '',
          }).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load payment methods'; _loading = false; });
    }
  }

  Future<void> _setDefault(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(ApiConfig.paymentMethodsEndpoint, token: token, data: {'method_id': id, 'set_default': true});
      if (response['success'] == true) {
        setState(() {
          for (final m in _methods) m['isDefault'] = m['id'] == id;
        });
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Default payment method updated'), behavior: SnackBarBehavior.floating));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to update default'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to update default payment method'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _remove(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Remove Payment Method'),
        content: const Text('Are you sure you want to remove this payment method?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Remove', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (confirm != true) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      // Assuming a DELETE or POST to remove
      final response = await ApiService.post('${ApiConfig.paymentMethodsEndpoint}/remove', token: token, data: {'method_id': id});
      
      if (response['success'] == true) {
        setState(() => _methods.removeWhere((m) => m['id'] == id));
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Payment method removed'), behavior: SnackBarBehavior.floating));
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to remove'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to remove payment method'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray), onPressed: () => Navigator.pop(context)),
        title: const Text('Payment Methods', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () => Navigator.pushNamed(context, '/add-card').then((_) => _load())),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.placeholder),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.gray)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (_methods.isEmpty)
                        _emptyState()
                      else
                        ..._methods.map((m) => _methodCard(m)),
                      const SizedBox(height: 16),
                      _addButtons(),
                    ],
                  ),
                ),
    );
  }

  Widget _methodCard(Map<String, dynamic> m) {
    final isCard = m['type'] == 'card';
    final isUpi = m['type'] == 'upi';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: m['isDefault'] == true ? Border.all(color: AppColors.primary, width: 1.5) : null,
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(isCard ? Icons.credit_card_rounded : isUpi ? Icons.account_balance_wallet_rounded : Icons.payment_rounded,
              color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(m['name'], style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              if (m['isDefault'] == true)
                Container(
                  margin: const EdgeInsets.only(top: 4),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                  child: const Text('Default', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
            ]),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'default') _setDefault(m['id']);
              if (v == 'remove') _remove(m['id']);
            },
            itemBuilder: (_) => [
              if (m['isDefault'] != true)
                const PopupMenuItem(value: 'default', child: Text('Set as Default')),
              const PopupMenuItem(value: 'remove', child: Text('Remove', style: TextStyle(color: AppColors.error))),
            ],
            child: const Icon(Icons.more_vert_rounded, color: AppColors.gray),
          ),
        ],
      ),
    );
  }

  Widget _emptyState() => Padding(
    padding: const EdgeInsets.symmetric(vertical: 40),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.credit_card_off_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      const Text('No payment methods saved', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
      const SizedBox(height: 8),
      const Text('Add a card or UPI to pay faster', style: TextStyle(fontSize: 13, color: AppColors.gray)),
    ]),
  );

  Widget _addButtons() => Column(children: [
    _addBtn(Icons.credit_card_rounded, 'Add Credit / Debit Card', () => Navigator.pushNamed(context, '/add-card').then((_) => _load())),
    const SizedBox(height: 10),
    _addBtn(Icons.account_balance_wallet_rounded, 'Add UPI ID', () => Navigator.pushNamed(context, '/add-upi').then((_) => _load())),
  ]);

  Widget _addBtn(IconData icon, String label, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: AppColors.cardShadow,
      ),
      child: Row(children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: AppColors.primary, size: 20)),
        const SizedBox(width: 14),
        Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const Spacer(),
        const Icon(Icons.add_rounded, color: AppColors.primary),
      ]),
    ),
  );
}
