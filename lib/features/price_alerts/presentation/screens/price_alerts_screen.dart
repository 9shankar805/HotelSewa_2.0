import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/price_alert_service.dart';

class PriceAlertsScreen extends StatefulWidget {
  const PriceAlertsScreen({super.key});
  @override
  State<PriceAlertsScreen> createState() => _PriceAlertsScreenState();
}

class _PriceAlertsScreenState extends State<PriceAlertsScreen> {
  final PriceAlertService _service = PriceAlertService();
  bool _loading = true;
  List<Map<String, dynamic>> _alerts = [];

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getMyAlerts();
    if (result['success'] == true && mounted) {
      final raw = result['data'];
      final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['alerts'] ?? []) : []);
      setState(() { _alerts = List<Map<String, dynamic>>.from(list); _loading = false; });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _delete(String id, int index) async {
    final removed = _alerts[index];
    setState(() => _alerts.removeAt(index));
    final result = await _service.delete(id);
    if (result['success'] != true && mounted) {
      setState(() => _alerts.insert(index, removed));
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to delete alert'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _addAlert() async {
    final hotelCtrl = TextEditingController();
    final roomCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Set Price Alert', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: hotelCtrl, decoration: const InputDecoration(labelText: 'Hotel ID or Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: roomCtrl, decoration: const InputDecoration(labelText: 'Room Type ID', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: priceCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Target Price (NPR)', border: OutlineInputBorder(), prefixText: 'NPR ')),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
            child: const Text('Create', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (result == true) {
      final price = double.tryParse(priceCtrl.text.trim());
      if (price != null) {
        await _service.create(hotelId: hotelCtrl.text.trim(), roomTypeId: roomCtrl.text.trim(), targetPrice: price);
        _load();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray), onPressed: () => Navigator.pop(context)),
        title: const Text('Price Alerts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAlert,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Alert', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _alerts.isEmpty
              ? Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  const Icon(Icons.notifications_none_rounded, size: 64, color: AppColors.placeholder),
                  const SizedBox(height: 16),
                  const Text('No price alerts', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.gray)),
                  const SizedBox(height: 8),
                  const Text('Get notified when hotel prices drop to your target.', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: AppColors.placeholder)),
                  const SizedBox(height: 24),
                  ElevatedButton(onPressed: _addAlert, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: const Text('Create Alert', style: TextStyle(color: Colors.white))),
                ]))
              : RefreshIndicator(
                  onRefresh: _load, color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _alerts.length,
                    itemBuilder: (_, i) {
                      final alert = _alerts[i];
                      final target = (alert['target_price'] ?? alert['price'] ?? 0).toDouble();
                      final current = (alert['current_price'] ?? 0).toDouble();
                      final isBelow = current > 0 && current <= target;
                      return Dismissible(
                        key: Key(alert['id']?.toString() ?? '$i'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight, padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(16)),
                          child: const Icon(Icons.delete_rounded, color: Colors.white),
                        ),
                        onDismissed: (_) => _delete(alert['id']?.toString() ?? '', i),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white, borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: isBelow ? AppColors.success.withOpacity(0.3) : AppColors.lightGray),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Row(children: [
                            Container(
                              width: 48, height: 48,
                              decoration: BoxDecoration(color: (isBelow ? AppColors.success : AppColors.primary).withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                              child: Icon(isBelow ? Icons.notifications_active_rounded : Icons.notifications_none_rounded, color: isBelow ? AppColors.success : AppColors.primary, size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(alert['hotel_name']?.toString() ?? alert['hotel_id']?.toString() ?? 'Hotel', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                              Text(alert['room_type']?.toString() ?? 'Any room', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                              const SizedBox(height: 4),
                              Row(children: [
                                Text('Target: NPR ${target.toInt()}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                                if (current > 0) ...[
                                  const SizedBox(width: 8),
                                  Text('Now: NPR ${current.toInt()}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isBelow ? AppColors.success : AppColors.error)),
                                ],
                              ]),
                            ])),
                            if (isBelow) Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(8)),
                              child: const Text('REACHED', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.success)),
                            ),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
