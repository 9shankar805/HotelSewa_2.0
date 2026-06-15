import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';

class DynamicPricingScreen extends StatefulWidget {
  const DynamicPricingScreen({super.key});
  @override
  State<DynamicPricingScreen> createState() => _DynamicPricingScreenState();
}

class _DynamicPricingScreenState extends State<DynamicPricingScreen> {
  bool _loading = true;
  bool _applying = false;
  List<Map<String, dynamic>> _rules = [];
  Map<String, dynamic>? _suggestion;
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
      final resp = await ApiService.get(ApiConfig.aiPricingRulesEndpoint, token: _token);
      if (resp['success'] == true) {
        final raw = resp['data'];
        setState(() => _rules = raw is List ? List<Map<String, dynamic>>.from(raw) : []);
      }
      final sug = await ApiService.get(ApiConfig.aiPricingSuggestEndpoint, token: _token, queryParams: {'date': _today});
      if (sug['success'] == true) setState(() => _suggestion = sug['data'] as Map<String, dynamic>?);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  String get _today {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _autoApply() async {
    setState(() => _applying = true);
    try {
      final now = DateTime.now();
      final end = now.add(const Duration(days: 30));
      final resp = await ApiService.post(ApiConfig.aiPricingAutoApplyEndpoint, token: _token, data: {
        'start_date': _today,
        'end_date': '${end.year}-${end.month.toString().padLeft(2, '0')}-${end.day.toString().padLeft(2, '0')}',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resp['success'] == true ? 'AI pricing applied for next 30 days!' : resp['message'] ?? 'Failed'),
          backgroundColor: resp['success'] == true ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _applying = false);
    }
  }

  Future<void> _deleteRule(String id) async {
    try {
      await ApiService.delete('${ApiConfig.aiPricingRulesEndpoint}/$id', token: _token);
      _load();
    } catch (_) {}
  }

  Future<void> _addRule() async {
    final nameCtrl = TextEditingController();
    String type = 'weekend';
    final multiplierCtrl = TextEditingController(text: '1.2');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(builder: (ctx, setS) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Add Pricing Rule', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Rule Name', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: type,
            decoration: const InputDecoration(labelText: 'Trigger Type', border: OutlineInputBorder()),
            items: const [
              DropdownMenuItem(value: 'weekend', child: Text('Weekend')),
              DropdownMenuItem(value: 'holiday', child: Text('Holiday')),
              DropdownMenuItem(value: 'high_demand', child: Text('High Demand')),
              DropdownMenuItem(value: 'low_demand', child: Text('Low Demand')),
            ],
            onChanged: (v) => setS(() => type = v!),
          ),
          const SizedBox(height: 12),
          TextField(controller: multiplierCtrl, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Price Multiplier (e.g. 1.2 = +20%)', border: OutlineInputBorder())),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
            child: const Text('Add', style: TextStyle(color: Colors.white)),
          ),
        ],
      )),
    );
    if (result == true) {
      try {
        await ApiService.post(ApiConfig.aiPricingRulesEndpoint, token: _token, data: {
          'name': nameCtrl.text,
          'type': type,
          'multiplier': double.tryParse(multiplierCtrl.text) ?? 1.0,
        });
        _load();
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: AppColors.darkGray,
        title: const Text('AI Dynamic Pricing', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addRule,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Rule', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load, color: AppColors.primary,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // AI suggestion card
                  if (_suggestion != null) _buildSuggestionCard(),
                  const SizedBox(height: 16),
                  // Auto-apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _applying ? null : _autoApply,
                      icon: _applying ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.auto_awesome_rounded, size: 20, color: Colors.white),
                      label: Text(_applying ? 'Applying...' : 'Auto-Apply AI Pricing (30 days)', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF6366F1), padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Rules list
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    const Text('Pricing Rules', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                    Text('${_rules.length} rules', style: const TextStyle(fontSize: 13, color: AppColors.gray)),
                  ]),
                  const SizedBox(height: 12),
                  if (_rules.isEmpty) _buildEmptyRules()
                  else ..._rules.map((r) => _buildRuleCard(r)),
                  const SizedBox(height: 80),
                ]),
              ),
            ),
    );
  }

  Widget _buildSuggestionCard() => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Row(children: [
        Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 18),
        SizedBox(width: 8),
        Text("Today's AI Suggestion", style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
      ]),
      const SizedBox(height: 12),
      Row(children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Suggested Price', style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
          Text('NPR ${_suggestion!['suggested_price'] ?? _suggestion!['price'] ?? '–'}', style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
        ])),
        ElevatedButton(
          onPressed: () async {
            await ApiService.post(ApiConfig.aiPricingApplyEndpoint, token: _token, data: {'date': _today, 'price': _suggestion!['suggested_price'] ?? _suggestion!['price']});
            if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Price applied'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
          },
          style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF6366F1), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text('Apply', style: TextStyle(fontWeight: FontWeight.w700)),
        ),
      ]),
      if (_suggestion!['reason'] != null) ...[
        const SizedBox(height: 8),
        Text(_suggestion!['reason'].toString(), style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 12)),
      ],
    ]),
  );

  Widget _buildRuleCard(Map<String, dynamic> rule) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
    child: Row(children: [
      Container(width: 40, height: 40, decoration: BoxDecoration(color: const Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: const Icon(Icons.rule_rounded, color: Color(0xFF6366F1), size: 20)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(rule['name']?.toString() ?? 'Rule', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        Text('${rule['type'] ?? ''}  ×${rule['multiplier'] ?? rule['factor'] ?? '1.0'}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
      ])),
      Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)), child: const Text('Active', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.success))),
      const SizedBox(width: 8),
      GestureDetector(onTap: () => _deleteRule(rule['id']?.toString() ?? ''), child: const Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20)),
    ]),
  );

  Widget _buildEmptyRules() => Container(
    padding: const EdgeInsets.all(24),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
    child: const Column(children: [
      Icon(Icons.rule_rounded, size: 48, color: AppColors.placeholder),
      SizedBox(height: 12),
      Text('No pricing rules yet', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.gray)),
      SizedBox(height: 6),
      Text('Add rules to automate pricing for weekends, holidays, and demand changes.', textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.placeholder, height: 1.4)),
    ]),
  );
}
