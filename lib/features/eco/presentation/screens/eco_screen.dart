import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class EcoScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const EcoScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<EcoScreen> createState() => _EcoScreenState();
}

class _EcoScreenState extends State<EcoScreen> {
  bool _loading = true;
  List<Map<String, dynamic>> _myOptOuts = [];
  List<String> _selectedDates = [];
  bool _submitting = false;

  int get _bookingId => arguments?['booking_id'] ?? 0;
  Map<String, dynamic>? get arguments => widget.arguments;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get('/eco/my', token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['opt_outs'] ?? []) : []);
        setState(() => _myOptOuts = List<Map<String, dynamic>>.from(raw));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _submit() async {
    if (_selectedDates.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post('/eco/opt-out', data: {'booking_id': _bookingId, 'opt_out_dates': _selectedDates}, token: token);
      if (response['success'] == true) {
        setState(() => _selectedDates.clear());
        _load();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eco opt-out saved. Thank you for helping the environment!'), backgroundColor: AppColors.success),
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
        title: const Text('Eco & Sustainability', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [BoxShadow(color: const Color(0xFF059669).withOpacity(0.4), blurRadius: 20, offset: const Offset(0, 8))],
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.eco_rounded, color: Colors.white, size: 48),
                        const SizedBox(height: 12),
                        const Text('Go Green During Your Stay', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: Colors.white)),
                        const SizedBox(height: 8),
        const Text('Skip daily housekeeping to reduce water, energy, and chemical usage. Every small action counts.', style: TextStyle(fontSize: 13, color: Colors.white70, height: 1.5), textAlign: TextAlign.center),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(16)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              _ecoStat('💧', '40L', 'Water saved'),
                              _ecoStat('⚡', '2kWh', 'Energy saved'),
                              _ecoStat('🌿', '200g', 'CO₂ reduced'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Opt-out section
                  const Text('Skip Housekeeping', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  const SizedBox(height: 8),
                  const Text('Select dates during your stay when you\'d like to skip daily housekeeping.', style: TextStyle(fontSize: 13, color: AppColors.gray, height: 1.5)),
                  const SizedBox(height: 16),

                  // Date input
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                decoration: InputDecoration(
                                  hintText: 'Add date (YYYY-MM-DD)',
                                  prefixIcon: const Icon(Icons.calendar_today_rounded, color: AppColors.gray, size: 18),
                                  filled: true, fillColor: AppColors.surfaceVariant,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                ),
                                onSubmitted: (v) {
                                  if (v.isNotEmpty && !_selectedDates.contains(v)) {
                                    setState(() => _selectedDates.add(v));
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                        if (_selectedDates.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8, runSpacing: 8,
                            children: _selectedDates.map((d) => Chip(
                              label: Text(d),
                              deleteIcon: const Icon(Icons.close, size: 14),
                              onDeleted: () => setState(() => _selectedDates.remove(d)),
                              backgroundColor: AppColors.successLight,
                              labelStyle: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w600, fontSize: 12),
                            )).toList(),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _submitting ? null : _submit,
                              style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, padding: const EdgeInsets.symmetric(vertical: 12), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                              child: _submitting
                                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Text('Save Eco Preferences', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Past opt-outs
                  if (_myOptOuts.isNotEmpty) ...[
                    const Text('Your Eco History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                    const SizedBox(height: 12),
                    ..._myOptOuts.map((o) => Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppColors.cardShadow),
                      child: Row(
                        children: [
                          const Icon(Icons.eco_rounded, color: AppColors.success, size: 20),
                          const SizedBox(width: 10),
                          Text('Booking #${o['booking_id']} — ${(o['opt_out_dates'] as List?)?.join(', ') ?? ''}', style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
                        ],
                      ),
                    )),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _ecoStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white70)),
      ],
    );
  }
}
