import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';

/// Manual booking creation screen for hotel owners (walk-in guests).
class AddBookingScreen extends StatefulWidget {
  const AddBookingScreen({super.key});
  @override
  State<AddBookingScreen> createState() => _AddBookingScreenState();
}

class _AddBookingScreenState extends State<AddBookingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _roomCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _checkIn = DateTime.now();
  DateTime _checkOut = DateTime.now().add(const Duration(days: 1));
  int _adults = 1;
  int _children = 0;
  String _paymentMethod = 'cash';
  bool _submitting = false;

  static const _paymentMethods = [('cash', 'Cash'), ('card', 'Card'), ('khalti', 'Khalti'), ('esewa', 'eSewa')];

  @override
  void dispose() {
    for (final c in [_nameCtrl, _emailCtrl, _phoneCtrl, _roomCtrl, _amountCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? _checkIn : _checkOut,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)), child: child!),
    );
    if (picked != null) setState(() { if (isCheckIn) { _checkIn = picked; if (_checkOut.isBefore(_checkIn)) _checkOut = _checkIn.add(const Duration(days: 1)); } else _checkOut = picked; });
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  int get _nights => _checkOut.difference(_checkIn).inDays.clamp(1, 365);

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final resp = await ApiService.post(ApiConfig.ownerManualBookingEndpoint, token: token, data: {
        'guest_name': _nameCtrl.text.trim(),
        'guest_email': _emailCtrl.text.trim(),
        'guest_phone': _phoneCtrl.text.trim(),
        'room_type_id': _roomCtrl.text.trim(),
        'check_in_date': '${_checkIn.year}-${_checkIn.month.toString().padLeft(2, '0')}-${_checkIn.day.toString().padLeft(2, '0')}',
        'check_out_date': '${_checkOut.year}-${_checkOut.month.toString().padLeft(2, '0')}-${_checkOut.day.toString().padLeft(2, '0')}',
        'adults': _adults,
        'children': _children,
        'total_amount': double.tryParse(_amountCtrl.text) ?? 0,
        'payment_method': _paymentMethod,
        'status': 'confirmed',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resp['success'] == true ? 'Booking created successfully!' : resp['message'] ?? 'Failed'),
          backgroundColor: resp['success'] == true ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
        if (resp['success'] == true) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: AppColors.darkGray,
        title: const Text('Add Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _card('Guest Information', [
                  _field('Guest Name *', _nameCtrl, Icons.person_outline_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
                  _field('Email', _emailCtrl, Icons.email_outlined, type: TextInputType.emailAddress),
                  _field('Phone', _phoneCtrl, Icons.phone_rounded, type: TextInputType.phone),
                ]),
                const SizedBox(height: 14),
                _card('Stay Details', [
                  // Dates
                  Row(children: [
                    Expanded(child: GestureDetector(onTap: () => _pickDate(true), child: _dateField('Check-in', _fmtDate(_checkIn), Icons.login_rounded))),
                    const SizedBox(width: 12),
                    Expanded(child: GestureDetector(onTap: () => _pickDate(false), child: _dateField('Check-out', _fmtDate(_checkOut), Icons.logout_rounded))),
                  ]),
                  const SizedBox(height: 10),
                  Text('$_nights night${_nights > 1 ? "s" : ""}', style: const TextStyle(fontSize: 13, color: AppColors.gray, fontWeight: FontWeight.w500), textAlign: TextAlign.center),
                  const SizedBox(height: 14),
                  _field('Room Type ID *', _roomCtrl, Icons.hotel_rounded, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 14),
                  // Adults/children
                  Row(children: [
                    Expanded(child: _counter('Adults', _adults, (v) => setState(() => _adults = v), 1, 10)),
                    const SizedBox(width: 12),
                    Expanded(child: _counter('Children', _children, (v) => setState(() => _children = v), 0, 6)),
                  ]),
                ]),
                const SizedBox(height: 14),
                _card('Payment', [
                  _field('Total Amount (NPR) *', _amountCtrl, Icons.payments_outlined, type: TextInputType.number, validator: (v) => v!.isEmpty ? 'Required' : null),
                  const SizedBox(height: 14),
                  const Text('Payment Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray)),
                  const SizedBox(height: 10),
                  Wrap(spacing: 8, runSpacing: 8, children: _paymentMethods.map((m) {
                    final sel = _paymentMethod == m.$1;
                    return GestureDetector(
                      onTap: () => setState(() => _paymentMethod = m.$1),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? AppColors.primary : Colors.white,
                          border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(m.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.gray)),
                      ),
                    );
                  }).toList()),
                ]),
              ]),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _submitting ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)) : const Text('Create Booking', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _card(String title, List<Widget> children) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 14),
      ...children,
    ]),
  );

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType type = TextInputType.text, String? Function(String?)? validator}) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: TextFormField(
      controller: ctrl, keyboardType: type, validator: validator,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, size: 20, color: AppColors.gray), filled: true, fillColor: AppColors.background, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5))),
    ),
  );

  Widget _dateField(String label, String value, IconData icon) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Icon(icon, size: 14, color: AppColors.gray), const SizedBox(width: 4), Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray))]),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
    ]),
  );

  Widget _counter(String label, int value, ValueChanged<int> onChange, int min, int max) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
    decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray))),
      GestureDetector(onTap: value > min ? () => onChange(value - 1) : null, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: value > min ? AppColors.primary.withOpacity(0.1) : AppColors.lightGray, borderRadius: BorderRadius.circular(7)), child: Icon(Icons.remove, size: 14, color: value > min ? AppColors.primary : AppColors.placeholder))),
      Padding(padding: const EdgeInsets.symmetric(horizontal: 10), child: Text('$value', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray))),
      GestureDetector(onTap: value < max ? () => onChange(value + 1) : null, child: Container(width: 28, height: 28, decoration: BoxDecoration(color: value < max ? AppColors.primary : AppColors.lightGray, borderRadius: BorderRadius.circular(7)), child: Icon(Icons.add, size: 14, color: value < max ? Colors.white : AppColors.placeholder))),
    ]),
  );
}
