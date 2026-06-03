import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class ConciergeScreen extends StatefulWidget {
  const ConciergeScreen({Key? key}) : super(key: key);

  @override
  State<ConciergeScreen> createState() => _ConciergeScreenState();
}

class _ConciergeScreenState extends State<ConciergeScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _requests = [];
  bool _submitting = false;

  final _descCtrl = TextEditingController();
  String _requestType = 'room_service';
  String _priority = 'normal';

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.conciergeMyEndpoint, token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['requests'] ?? []) : []);
        setState(() { _requests = List<Map<String, dynamic>>.from(raw); _loading = false; });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load concierge requests'; _loading = false; });
    }
  }

  Future<void> _submit(int bookingId) async {
    if (_descCtrl.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(
        ApiConfig.conciergeRequestEndpoint,
        data: {'booking_id': bookingId, 'request_type': _requestType, 'description': _descCtrl.text, 'priority': _priority},
        token: token,
      );
      if (response['success'] == true) {
        Navigator.pop(context);
        _descCtrl.clear();
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request submitted'), backgroundColor: AppColors.success),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to submit'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
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
        title: const Text('Digital Concierge', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showRequestForm,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _requests.isEmpty ? _buildEmpty() : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _requests.length,
                    itemBuilder: (_, i) => _buildCard(_requests[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> req) {
    final status = req['status'] ?? 'pending';
    final statusColor = status == 'fulfilled' ? AppColors.success : status == 'cancelled' ? AppColors.error : AppColors.warning;
    final typeIcons = {
      'room_service': Icons.room_service_rounded,
      'housekeeping': Icons.cleaning_services_rounded,
      'transport': Icons.directions_car_rounded,
      'restaurant': Icons.restaurant_rounded,
    };
    final icon = typeIcons[req['request_type']] ?? Icons.support_agent_rounded;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(14)),
            child: Icon(icon, color: AppColors.teal, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(req['request_type']?.toString().replaceAll('_', ' ').toUpperCase() ?? 'Request', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray, letterSpacing: 0.5)),
                const SizedBox(height: 2),
                Text(req['description'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray), maxLines: 2, overflow: TextOverflow.ellipsis),
                if ((req['note'] ?? '').isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text('Staff: ${req['note']}', style: const TextStyle(fontSize: 12, color: AppColors.gray, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
            child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
          ),
        ],
      ),
    );
  }

  void _showRequestForm() {
    // In a real app, you'd pick from active bookings. Using a simple text field here.
    final bookingIdCtrl = TextEditingController();
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
              const Text('New Concierge Request', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              const Text('Request Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['room_service', 'housekeeping', 'transport', 'restaurant', 'other'].map((type) {
                  final selected = _requestType == type;
                  return ChoiceChip(
                    label: Text(type.replaceAll('_', ' ')),
                    selected: selected,
                    onSelected: (_) => setState(() => _requestType = type),
                    selectedColor: AppColors.primary.withOpacity(0.15),
                    labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.gray, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              const Text('Priority', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              const SizedBox(height: 8),
              Row(
                children: ['low', 'normal', 'high', 'urgent'].map((p) {
                  final selected = _priority == p;
                  final color = p == 'urgent' ? AppColors.error : p == 'high' ? AppColors.warning : AppColors.success;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: selected ? color.withOpacity(0.15) : AppColors.surfaceVariant,
                          borderRadius: BorderRadius.circular(10),
                          border: selected ? Border.all(color: color) : null,
                        ),
                        child: Text(p[0].toUpperCase() + p.substring(1), textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: selected ? color : AppColors.gray)),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Describe your request...',
                  filled: true, fillColor: AppColors.surfaceVariant,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: bookingIdCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: 'Booking ID',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.gray),
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : () => _submit(int.tryParse(bookingIdCtrl.text) ?? 0),
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: _submitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Submit Request', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
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
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.tealLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.support_agent_rounded, size: 40, color: AppColors.teal)),
      const SizedBox(height: 20),
      const Text('No Requests Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 8),
      const Text('Need something during your stay? Tap the button below to request room service, housekeeping, transport and more.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
    ])));
  }
}
