import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'dynamic_pricing_screen.dart';

class PricingScreen extends StatefulWidget {
  const PricingScreen({super.key});
  @override
  State<PricingScreen> createState() => _PricingScreenState();
}

class _PricingScreenState extends State<PricingScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _roomTypes = [];
  String? _token;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('authToken');
      final resp = await ApiService.get(ApiConfig.ownerDashboardEndpoint, token: _token);
      if (resp['success'] == true) {
        final data = resp['data'] ?? {};
        final rooms = data['room_types'] ?? data['rooms'] ?? [];
        if (rooms is List && rooms.isNotEmpty) {
          setState(() => _roomTypes = List<Map<String, dynamic>>.from(rooms));
        }
      }
      // Fallback: try room-types endpoint
      if (_roomTypes.isEmpty) {
        final r2 = await ApiService.get(ApiConfig.roomTypesEndpoint, token: _token);
        if (r2['success'] == true) {
          final raw = r2['data'];
          List list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['room_types'] ?? []) : []);
          setState(() => _roomTypes = List<Map<String, dynamic>>.from(list));
        }
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _editPrice(Map<String, dynamic> room) async {
    final priceCtrl = TextEditingController(text: (room['price'] ?? room['base_price'] ?? '').toString());
    final hourlyCtrl = TextEditingController(text: (room['hourly_price'] ?? '').toString());
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(room['name'] ?? room['type'] ?? 'Room', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(
            controller: priceCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Base Price / Night (NPR)', border: OutlineInputBorder(), prefixText: 'NPR '),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: hourlyCtrl,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Hourly Price (NPR)', border: OutlineInputBorder(), prefixText: 'NPR '),
          ),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        final id = room['id']?.toString() ?? '';
        await ApiService.post(
          '${ApiConfig.updateRoomTypeEndpoint}/$id',
          token: _token,
          data: {
            'price': double.tryParse(priceCtrl.text) ?? 0,
            'hourly_price': double.tryParse(hourlyCtrl.text) ?? 0,
          },
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price updated'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
          _load();
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: AppColors.darkGray,
        title: const Text('Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome_rounded, color: AppColors.primary),
            tooltip: 'AI Dynamic Pricing',
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const DynamicPricingScreen())),
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _roomTypes.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildInfoBanner(),
                      const SizedBox(height: 16),
                      ..._roomTypes.map((r) => _buildRoomCard(r)),
                    ],
                  ),
                ),
    );
  }

  Widget _buildInfoBanner() => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withOpacity(0.2))),
    child: const Row(children: [
      Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
      SizedBox(width: 10),
      Expanded(child: Text('Tap any room to update its price. Use AI Dynamic Pricing for smart automated pricing.', style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
    ]),
  );

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final price = (room['price'] ?? room['base_price'] ?? room['min_price'] ?? 0) as num;
    final hourly = (room['hourly_price'] ?? 0) as num;
    final name = room['name'] ?? room['type'] ?? 'Room';
    final capacity = room['capacity'] ?? room['max_guests'] ?? 2;
    final available = room['available_count'] ?? room['available'] ?? 0;
    return GestureDetector(
      onTap: () => _editPrice(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
        child: Row(children: [
          Container(width: 52, height: 52, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.hotel_rounded, color: AppColors.primary, size: 26)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 4),
            Row(children: [
              _chip('${capacity} guests', AppColors.info),
              const SizedBox(width: 6),
              _chip('$available avail.', available > 0 ? AppColors.success : AppColors.error),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('NPR ${price.toInt()}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const Text('/night', style: TextStyle(fontSize: 10, color: AppColors.gray)),
            if (hourly > 0) ...[
              const SizedBox(height: 2),
              Text('NPR ${hourly.toInt()}/hr', style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
            ],
          ]),
          const SizedBox(width: 8),
          const Icon(Icons.edit_rounded, size: 16, color: AppColors.gray),
        ]),
      ),
    );
  }

  Widget _chip(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: color)),
  );

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Icon(Icons.price_change_rounded, size: 64, color: AppColors.placeholder),
    const SizedBox(height: 16),
    const Text('No room types found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray)),
    const SizedBox(height: 8),
    const Text('Add rooms first to set pricing', style: TextStyle(fontSize: 13, color: AppColors.placeholder)),
    const SizedBox(height: 24),
    ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0), child: const Text('Refresh', style: TextStyle(color: Colors.white))),
  ]));
}
