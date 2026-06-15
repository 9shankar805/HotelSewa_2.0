import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import 'multi_currency_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _loading = true;
  bool _saving = false;
  Map<String, dynamic> _hotel = {};
  String? _token;

  // Controllers
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _checkInCtrl = TextEditingController(text: '2:00 PM');
  final _checkOutCtrl = TextEditingController(text: '11:00 AM');

  // Toggles
  bool _allowPets = false;
  bool _allowSmoking = false;
  bool _instantBook = true;
  bool _notificationsEnabled = true;
  bool _autoReply = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    for (final c in [_nameCtrl, _phoneCtrl, _emailCtrl, _descCtrl, _checkInCtrl, _checkOutCtrl]) c.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('authToken');
      final resp = await ApiService.get(ApiConfig.myHotelsEndpoint, token: _token);
      if (resp['success'] == true) {
        final raw = resp['data'];
        final hotel = raw is List && raw.isNotEmpty ? Map<String, dynamic>.from(raw[0]) : (raw is Map ? Map<String, dynamic>.from(raw) : <String, dynamic>{});
        setState(() {
          _hotel = hotel;
          _nameCtrl.text = hotel['name'] ?? '';
          _phoneCtrl.text = hotel['phone'] ?? hotel['hotel_phone'] ?? '';
          _emailCtrl.text = hotel['email'] ?? '';
          _descCtrl.text = hotel['description'] ?? '';
          _checkInCtrl.text = hotel['check_in_time'] ?? '2:00 PM';
          _checkOutCtrl.text = hotel['check_out_time'] ?? '11:00 AM';
          _allowPets = hotel['allow_pets'] == true || hotel['allow_pets'] == 1;
          _allowSmoking = hotel['allow_smoking'] == true || hotel['allow_smoking'] == 1;
          _instantBook = hotel['instant_book'] != false;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final id = _hotel['id']?.toString() ?? '';
      final resp = await ApiService.post(
        id.isNotEmpty ? '${ApiConfig.updateHotelEndpoint}/$id' : ApiConfig.updateHotelEndpoint,
        token: _token,
        data: {
          'name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'email': _emailCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'check_in_time': _checkInCtrl.text.trim(),
          'check_out_time': _checkOutCtrl.text.trim(),
          'allow_pets': _allowPets,
          'allow_smoking': _allowSmoking,
          'instant_book': _instantBook,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resp['success'] == true ? 'Settings saved successfully' : resp['message'] ?? 'Failed to save'),
          backgroundColor: resp['success'] == true ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: AppColors.darkGray,
        title: const Text('Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)) : const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15)),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(children: [
                _section('Hotel Information', [
                  _field('Hotel Name', _nameCtrl, Icons.hotel_rounded),
                  _field('Phone Number', _phoneCtrl, Icons.phone_rounded, type: TextInputType.phone),
                  _field('Email Address', _emailCtrl, Icons.email_rounded, type: TextInputType.emailAddress),
                  _field('Description', _descCtrl, Icons.description_rounded, maxLines: 3),
                ]),
                const SizedBox(height: 16),
                _section('Check-in / Check-out', [
                  _field('Check-in Time', _checkInCtrl, Icons.login_rounded),
                  _field('Check-out Time', _checkOutCtrl, Icons.logout_rounded),
                ]),
                const SizedBox(height: 16),
                _section('Policies', [
                  _toggle('Allow Pets', 'Guests can bring pets', Icons.pets_rounded, _allowPets, (v) => setState(() => _allowPets = v)),
                  _toggle('Allow Smoking', 'Smoking areas available', Icons.smoke_free_rounded, _allowSmoking, (v) => setState(() => _allowSmoking = v)),
                  _toggle('Instant Book', 'Confirm bookings automatically', Icons.flash_on_rounded, _instantBook, (v) => setState(() => _instantBook = v)),
                ]),
                const SizedBox(height: 16),
                _section('Notifications', [
                  _toggle('Push Notifications', 'Get alerts for new bookings', Icons.notifications_rounded, _notificationsEnabled, (v) => setState(() => _notificationsEnabled = v)),
                  _toggle('Auto Reply', 'Send automatic guest messages', Icons.auto_awesome_rounded, _autoReply, (v) => setState(() => _autoReply = v)),
                ]),
                const SizedBox(height: 16),
                _section('Advanced', [
                  _navTile('Multi-Currency Settings', Icons.currency_exchange_rounded, AppColors.info, () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MultiCurrencyScreen()))),
                  _navTile('Notification Preferences', Icons.tune_rounded, AppColors.primary, () {}),
                  _navTile('API & Integrations', Icons.integration_instructions_rounded, AppColors.purple, () {}),
                ]),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }

  Widget _section(String title, List<Widget> children) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(padding: const EdgeInsets.fromLTRB(16, 16, 16, 8), child: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray, letterSpacing: 0.3))),
      ...children,
    ]),
  );

  Widget _field(String label, TextEditingController ctrl, IconData icon, {TextInputType type = TextInputType.text, int maxLines = 1}) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
    child: TextField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: AppColors.gray),
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    ),
  );

  Widget _toggle(String title, String subtitle, IconData icon, bool value, ValueChanged<bool> onChanged) => ListTile(
    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: AppColors.primary)),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
    subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
    trailing: Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
  );

  Widget _navTile(String title, IconData icon, Color color, VoidCallback onTap) => ListTile(
    onTap: onTap,
    leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
    title: Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray, size: 20),
  );
}
