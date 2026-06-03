import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class PreArrivalScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const PreArrivalScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<PreArrivalScreen> createState() => _PreArrivalScreenState();
}

class _PreArrivalScreenState extends State<PreArrivalScreen> {
  bool _loading = true;
  bool _saving = false;
  String? _error;
  Map<String, dynamic>? _preArrival;

  final _arrivalTimeCtrl = TextEditingController();
  final _requestsCtrl = TextEditingController();
  String _dietary = 'none';

  int get _bookingId => widget.arguments?['booking_id'] ?? 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _arrivalTimeCtrl.dispose();
    _requestsCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get('${ApiConfig.bookingPreArrivalEndpoint}/$_bookingId/pre-arrival', token: token);
      if (response['success'] == true) {
        final data = response['data'];
        if (data is Map) {
          _preArrival = Map<String, dynamic>.from(data);
          _arrivalTimeCtrl.text = _preArrival?['arrival_time'] ?? '';
          _requestsCtrl.text = _preArrival?['special_requests'] ?? '';
          _dietary = _preArrival?['dietary'] ?? 'none';
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _loading = false; });
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(
        '${ApiConfig.bookingPreArrivalEndpoint}/$_bookingId/pre-arrival',
        data: {'arrival_time': _arrivalTimeCtrl.text, 'special_requests': _requestsCtrl.text, 'dietary': _dietary},
        token: token,
      );
      if (response['success'] == true) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pre-arrival info saved'), backgroundColor: AppColors.success),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Save failed'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
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
        title: const Text('Pre-Arrival Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header banner
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                          child: const Icon(Icons.flight_land_rounded, color: Colors.white, size: 26)),
                        const SizedBox(width: 16),
                        const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Pre-Arrival Setup', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                          SizedBox(height: 4),
                          Text('Help us prepare for your arrival by sharing your preferences.', style: TextStyle(fontSize: 12, color: Colors.white70, height: 1.4)),
                        ])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  _sectionTitle('Arrival Time'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _arrivalTimeCtrl,
                    decoration: InputDecoration(
                      hintText: 'e.g. 14:30',
                      prefixIcon: const Icon(Icons.access_time_rounded, color: AppColors.gray),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 20),

                  _sectionTitle('Dietary Preference'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: ['none', 'vegetarian', 'vegan', 'halal', 'gluten_free', 'kosher'].map((d) {
                      final selected = _dietary == d;
                      return ChoiceChip(
                        label: Text(d.replaceAll('_', ' ')[0].toUpperCase() + d.replaceAll('_', ' ').substring(1)),
                        selected: selected,
                        onSelected: (_) => setState(() => _dietary = d),
                        selectedColor: AppColors.primary.withOpacity(0.15),
                        labelStyle: TextStyle(color: selected ? AppColors.primary : AppColors.gray, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 20),

                  _sectionTitle('Special Requests'),
                  const SizedBox(height: 10),
                  TextField(
                    controller: _requestsCtrl,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Birthday decoration, extra pillows, high floor...',
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _saving ? null : _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save Pre-Arrival Info', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray));
  }
}
