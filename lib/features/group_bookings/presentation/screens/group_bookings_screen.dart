import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class GroupBookingsScreen extends StatefulWidget {
  const GroupBookingsScreen({Key? key}) : super(key: key);

  @override
  State<GroupBookingsScreen> createState() => _GroupBookingsScreenState();
}

class _GroupBookingsScreenState extends State<GroupBookingsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _inquiries = [];

  // Form
  final _hotelIdCtrl = TextEditingController();
  final _checkInCtrl = TextEditingController();
  final _checkOutCtrl = TextEditingController();
  final _roomsCtrl = TextEditingController();
  final _guestsCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  String _eventType = 'conference';
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _hotelIdCtrl.dispose();
    _checkInCtrl.dispose();
    _checkOutCtrl.dispose();
    _roomsCtrl.dispose();
    _guestsCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.groupBookingsMyEndpoint, token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['inquiries'] ?? []) : []);
        setState(() { _inquiries = List<Map<String, dynamic>>.from(raw); _loading = false; });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load group bookings'; _loading = false; });
    }
  }

  Future<void> _submit() async {
    if (_checkInCtrl.text.isEmpty || _checkOutCtrl.text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(
        ApiConfig.groupBookingsInquiryEndpoint,
        data: {
          'hotel_id': int.tryParse(_hotelIdCtrl.text) ?? 0,
          'check_in': _checkInCtrl.text,
          'check_out': _checkOutCtrl.text,
          'rooms_needed': int.tryParse(_roomsCtrl.text) ?? 1,
          'guests': int.tryParse(_guestsCtrl.text) ?? 1,
          'event_type': _eventType,
          'notes': _notesCtrl.text,
        },
        token: token,
      );
      if (response['success'] == true) {
        Navigator.pop(context);
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Group booking inquiry submitted'), backgroundColor: AppColors.success),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Submission failed'), backgroundColor: AppColors.error),
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
        title: const Text('Group Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showInquiryForm,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('New Inquiry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _inquiries.isEmpty ? _buildEmpty() : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                    itemCount: _inquiries.length,
                    itemBuilder: (_, i) => _buildCard(_inquiries[i]),
                  ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item) {
    final status = item['status'] ?? 'pending';
    final statusColor = status == 'confirmed' ? AppColors.success : status == 'cancelled' ? AppColors.error : AppColors.warning;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.groups_rounded, color: AppColors.purple, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(item['hotel_name'] ?? item['hotel']?['name'] ?? 'Hotel', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                Text('${item['event_type'] ?? ''} · ${item['rooms_needed'] ?? 0} rooms · ${item['guests'] ?? 0} guests', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
              ])),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(children: [
            const Icon(Icons.calendar_today_rounded, size: 14, color: AppColors.gray),
            const SizedBox(width: 6),
            Text('${item['check_in'] ?? ''} → ${item['check_out'] ?? ''}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ]),
          if ((item['quoted_price'] ?? 0) > 0) ...[
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.attach_money_rounded, size: 14, color: AppColors.success),
              const SizedBox(width: 6),
              Text('Quoted: NPR ${item['quoted_price']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.success)),
            ]),
          ],
        ],
      ),
    );
  }

  void _showInquiryForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Group Booking Inquiry', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 20),
              _formField('Check-in Date', _checkInCtrl, Icons.calendar_today_rounded, hint: 'YYYY-MM-DD'),
              const SizedBox(height: 12),
              _formField('Check-out Date', _checkOutCtrl, Icons.calendar_today_rounded, hint: 'YYYY-MM-DD'),
              const SizedBox(height: 12),
              _formField('Rooms Needed', _roomsCtrl, Icons.hotel_rounded, hint: '10', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _formField('Total Guests', _guestsCtrl, Icons.people_rounded, hint: '20', keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              const Text('Event Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _eventType,
                decoration: InputDecoration(
                  filled: true, fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                ),
                items: ['conference', 'wedding', 'corporate', 'tour', 'other']
                    .map((e) => DropdownMenuItem(value: e, child: Text(e[0].toUpperCase() + e.substring(1))))
                    .toList(),
                onChanged: (v) => setState(() => _eventType = v ?? 'conference'),
              ),
              const SizedBox(height: 12),
              _formField('Notes', _notesCtrl, Icons.notes_rounded, hint: 'Special requirements...', maxLines: 3),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Submit Inquiry', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _formField(String label, TextEditingController ctrl, IconData icon, {String? hint, int maxLines = 1, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: AppColors.gray, size: 20),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
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
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.groups_rounded, size: 40, color: AppColors.purple)),
      const SizedBox(height: 20),
      const Text('No Group Bookings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 8),
      const Text('Submit a group booking inquiry for conferences, weddings, corporate events and more.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
    ])));
  }
}
