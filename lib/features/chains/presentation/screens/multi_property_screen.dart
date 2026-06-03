import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class MultiPropertyScreen extends StatefulWidget {
  const MultiPropertyScreen({Key? key}) : super(key: key);

  @override
  State<MultiPropertyScreen> createState() => _MultiPropertyScreenState();
}

class _MultiPropertyScreenState extends State<MultiPropertyScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _chains = [];

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
      final response = await ApiService.get('/chains/my', token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['chains'] ?? []) : []);
        setState(() { _chains = List<Map<String, dynamic>>.from(raw); _loading = false; });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load chains'; _loading = false; });
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
        title: const Text('Multi-Property', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: _showCreateChainDialog),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _chains.isEmpty ? _buildEmpty() : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _chains.length,
                    itemBuilder: (_, i) => _buildChainCard(_chains[i]),
                  ),
                ),
    );
  }

  Widget _buildChainCard(Map<String, dynamic> chain) {
    final hotels = List.from(chain['hotels'] ?? []);
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.account_balance_rounded, color: Colors.white, size: 24)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(chain['name'] ?? 'Chain', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
                  Text('${hotels.length} properties', style: const TextStyle(fontSize: 12, color: Colors.white70)),
                ])),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
                  onSelected: (action) {
                    if (action == 'analytics') _viewAnalytics(chain['id']);
                    if (action == 'bulk_pricing') _showBulkPricingDialog(chain['id']);
                    if (action == 'add_hotel') _showAddHotelDialog(chain['id']);
                  },
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'analytics', child: Text('View Analytics')),
                    const PopupMenuItem(value: 'bulk_pricing', child: Text('Bulk Pricing')),
                    const PopupMenuItem(value: 'add_hotel', child: Text('Add Hotel')),
                  ],
                ),
              ],
            ),
          ),
          if (hotels.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: hotels.take(3).map<Widget>((h) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(children: [
                    const Icon(Icons.hotel_rounded, size: 16, color: AppColors.gray),
                    const SizedBox(width: 8),
                    Text(h['name'] ?? 'Hotel', style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
                    const Spacer(),
                    Text(h['city'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                  ]),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  void _viewAnalytics(int chainId) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    await ApiService.get('/chains/$chainId/analytics', token: token);
  }

  void _showBulkPricingDialog(int chainId) {
    final adjustmentCtrl = TextEditingController();
    String adjustmentType = 'percentage';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Bulk Pricing Update', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: adjustmentType,
                decoration: InputDecoration(filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray))),
                items: ['percentage', 'fixed'].map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1)))).toList(),
                onChanged: (v) => setModalState(() => adjustmentType = v ?? 'percentage'),
              ),
              const SizedBox(height: 12),
              TextField(controller: adjustmentCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: adjustmentType == 'percentage' ? 'e.g. 10 (for 10%)' : 'Amount', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post('/chains/$chainId/bulk-pricing', data: {'adjustment_type': adjustmentType, 'adjustment': double.tryParse(adjustmentCtrl.text) ?? 0}, token: token);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bulk pricing applied'), backgroundColor: AppColors.success));
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Apply', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        )),
      ),
    );
  }

  void _showAddHotelDialog(int chainId) {
    final hotelIdCtrl = TextEditingController();
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
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Add Hotel to Chain', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(controller: hotelIdCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Hotel ID', prefixIcon: const Icon(Icons.hotel_rounded, color: AppColors.gray), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post('/chains/$chainId/add-hotel', data: {'hotel_id': int.tryParse(hotelIdCtrl.text) ?? 0}, token: token);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Add Hotel', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateChainDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
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
              const Text('Create Hotel Chain', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(controller: nameCtrl, decoration: InputDecoration(hintText: 'Chain name', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 12),
              TextField(controller: descCtrl, maxLines: 2, decoration: InputDecoration(hintText: 'Description', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post('/chains', data: {'name': nameCtrl.text, 'description': descCtrl.text}, token: token);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Create Chain', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
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

  Widget _buildEmpty() {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.account_balance_rounded, size: 40, color: AppColors.info)),
      const SizedBox(height: 20),
      const Text('No Hotel Chains', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 8),
      const Text('Create a hotel chain to manage multiple properties from one place.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
    ])));
  }
}
