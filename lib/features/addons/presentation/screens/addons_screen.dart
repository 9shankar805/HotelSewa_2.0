import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class AddonsScreen extends StatefulWidget {
  const AddonsScreen({Key? key}) : super(key: key);

  @override
  State<AddonsScreen> createState() => _AddonsScreenState();
}

class _AddonsScreenState extends State<AddonsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _addons = [];
  List<Map<String, dynamic>> _orders = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final results = await Future.wait([
        ApiService.get(ApiConfig.ownerAddonsEndpoint, token: token),
        ApiService.get(ApiConfig.ownerAddonOrdersEndpoint,
            token: token),
      ]);
      if (results[0]['success'] == true) {
        final data = results[0]['data'];
        List raw = data is List
            ? data
            : (data is Map
                ? (data['data'] ?? data['addons'] ?? [])
                : []);
        _addons = List<Map<String, dynamic>>.from(raw);
      }
      if (results[1]['success'] == true) {
        final data = results[1]['data'];
        List raw = data is List
            ? data
            : (data is Map
                ? (data['data'] ?? data['orders'] ?? [])
                : []);
        _orders = List<Map<String, dynamic>>.from(raw);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load add-ons';
        _loading = false;
      });
    }
  }

  Future<void> _toggleAvailability(
      int id, bool currentValue) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    await ApiService.put(
      '${ApiConfig.ownerAddonsEndpoint}/$id',
      data: {'is_available': !currentValue},
      token: token,
    );
    _load();
  }

  Future<void> _updateOrderStatus(int id, String status) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    await ApiService.put(
      '${ApiConfig.ownerAddonOrderStatusEndpoint}/$id/status',
      data: {'status': status},
      token: token,
    );
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add-ons & Upselling',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(
              icon:
                  const Icon(Icons.add_rounded, color: AppColors.primary),
              onPressed: _showCreateDialog),
          IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.darkGray),
              onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Add-ons'), Tab(text: 'Orders')],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildAddonsTab(),
                    _buildOrdersTab()
                  ],
                ),
    );
  }

  Widget _buildAddonsTab() {
    if (_addons.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.add_shopping_cart_rounded,
                    size: 40, color: AppColors.gold),
              ),
              const SizedBox(height: 20),
              const Text('No Add-ons',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 8),
              const Text(
                  'Create add-ons like airport transfer, breakfast, spa to upsell to guests.',
                  style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray,
                      height: 1.5),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _addons.length,
      itemBuilder: (_, i) => _buildAddonCard(_addons[i]),
    );
  }

  Widget _buildAddonCard(Map<String, dynamic> addon) {
    final isAvailable = addon['is_available'] == true;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: isAvailable
                    ? AppColors.goldLight
                    : AppColors.lightGray,
                borderRadius: BorderRadius.circular(14)),
            child: Icon(Icons.add_shopping_cart_rounded,
                color: isAvailable ? AppColors.gold : AppColors.gray,
                size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(addon['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray)),
                Text('NPR ${addon['price'] ?? 0}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ],
            ),
          ),
          Switch(
            value: isAvailable,
            onChanged: (_) =>
                _toggleAvailability(addon['id'], isAvailable),
            activeColor: AppColors.success,
          ),
          PopupMenuButton<String>(
            onSelected: (action) async {
              if (action == 'delete') {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('authToken');
                await ApiService.delete(
                    '${ApiConfig.ownerAddonsEndpoint}/${addon['id']}',
                    token: token);
                _load();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete',
                      style: TextStyle(color: AppColors.error))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersTab() {
    if (_orders.isEmpty) {
      return const Center(
          child: Text('No add-on orders yet',
              style: TextStyle(color: AppColors.gray)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _orders.length,
      itemBuilder: (_, i) {
        final order = _orders[i];
        final status = order['status'] ?? 'pending';
        final statusColor = status == 'delivered'
            ? AppColors.success
            : status == 'cancelled'
                ? AppColors.error
                : AppColors.warning;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.goldLight,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.shopping_bag_rounded,
                    color: AppColors.gold, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        order['addon_name'] ??
                            order['addon']?['name'] ??
                            'Add-on',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGray)),
                    Text(
                        'Booking #${order['booking_id'] ?? ''} · Qty: ${order['quantity'] ?? 1}',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ),
                  if (status == 'pending') ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () =>
                          _updateOrderStatus(order['id'], 'delivered'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Deliver',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Create Add-on',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 16),
              _field('Add-on Name (e.g. Airport Transfer)', nameCtrl),
              const SizedBox(height: 10),
              _field('Price (NPR)', priceCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _field('Description', descCtrl, maxLines: 2),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs =
                        await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(
                      ApiConfig.ownerAddonsEndpoint,
                      data: {
                        'name': nameCtrl.text,
                        'price':
                            double.tryParse(priceCtrl.text) ?? 0,
                        'description': descCtrl.text,
                        'is_available': true,
                      },
                      token: token,
                    );
                    _load();
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Create Add-on',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.placeholder),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.gray),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
