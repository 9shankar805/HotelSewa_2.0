import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';

class MultiCurrencyScreen extends StatefulWidget {
  const MultiCurrencyScreen({super.key});
  @override
  State<MultiCurrencyScreen> createState() => _MultiCurrencyScreenState();
}

class _MultiCurrencyScreenState extends State<MultiCurrencyScreen> {
  bool _loading = true;
  String _baseCurrency = 'NPR';
  List<Map<String, dynamic>> _currencies = [];
  List<Map<String, dynamic>> _enabledCurrencies = [];
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
      final resp = await ApiService.get(ApiConfig.currenciesEndpoint, token: _token);
      if (resp['success'] == true) {
        final raw = resp['data'];
        final list = raw is List ? raw : (raw is Map ? (raw['currencies'] ?? raw['data'] ?? []) : []);
        setState(() => _currencies = List<Map<String, dynamic>>.from(list));
      }
      final pref = await ApiService.get(ApiConfig.currenciesPreferenceEndpoint, token: _token);
      if (pref['success'] == true) {
        final d = pref['data'];
        setState(() {
          _baseCurrency = d?['base_currency'] ?? 'NPR';
          _enabledCurrencies = List<Map<String, dynamic>>.from(d?['enabled'] ?? []);
        });
      }
    } catch (_) {
      // Use defaults
      _currencies = [
        {'code': 'NPR', 'name': 'Nepalese Rupee', 'symbol': 'रू', 'rate': 1.0},
        {'code': 'USD', 'name': 'US Dollar', 'symbol': '\$', 'rate': 0.0075},
        {'code': 'EUR', 'name': 'Euro', 'symbol': '€', 'rate': 0.0069},
        {'code': 'GBP', 'name': 'British Pound', 'symbol': '£', 'rate': 0.0059},
        {'code': 'INR', 'name': 'Indian Rupee', 'symbol': '₹', 'rate': 0.625},
        {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': '¥', 'rate': 0.054},
        {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'A\$', 'rate': 0.011},
        {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': '¥', 'rate': 1.12},
      ];
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _save() async {
    try {
      final resp = await ApiService.post(ApiConfig.currenciesPreferenceEndpoint, token: _token, data: {
        'base_currency': _baseCurrency,
        'enabled_currencies': _enabledCurrencies.map((c) => c['code']).toList(),
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(resp['success'] == true ? 'Currency settings saved' : resp['message'] ?? 'Failed'),
        backgroundColor: resp['success'] == true ? AppColors.success : AppColors.error,
        behavior: SnackBarBehavior.floating,
      ));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  bool _isEnabled(String code) => _enabledCurrencies.any((c) => c['code'] == code) || code == _baseCurrency;

  void _toggle(Map<String, dynamic> currency) {
    final code = currency['code'] as String;
    if (code == _baseCurrency) return;
    setState(() {
      if (_isEnabled(code)) {
        _enabledCurrencies.removeWhere((c) => c['code'] == code);
      } else {
        _enabledCurrencies.add(currency);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: AppColors.darkGray,
        title: const Text('Multi-Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          TextButton(onPressed: _save, child: const Text('Save', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 15))),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                // Info
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.info.withOpacity(0.2))),
                  child: const Row(children: [
                    Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                    SizedBox(width: 10),
                    Expanded(child: Text('Enable currencies to let guests view prices in their preferred currency. Rates update automatically.', style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
                  ]),
                ),
                const SizedBox(height: 20),
                // Base currency
                const Text('Base Currency', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray)),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
                  child: DropdownButtonFormField<String>(
                    value: _baseCurrency,
                    decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: InputBorder.none),
                    items: _currencies.map((c) => DropdownMenuItem(value: c['code'] as String, child: Text('${c['code']} — ${c['name']}', style: const TextStyle(fontSize: 14)))).toList(),
                    onChanged: (v) => setState(() => _baseCurrency = v!),
                  ),
                ),
                const SizedBox(height: 20),
                // Enabled currencies
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Text('Accepted Currencies', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.gray)),
                  Text('${_enabledCurrencies.length + 1} enabled', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ]),
                const SizedBox(height: 10),
                Container(
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
                  child: Column(
                    children: _currencies.map((c) {
                      final code = c['code'] as String;
                      final isBase = code == _baseCurrency;
                      final enabled = _isEnabled(code);
                      return ListTile(
                        onTap: () => _toggle(c),
                        leading: Container(
                          width: 42, height: 42,
                          decoration: BoxDecoration(color: enabled ? AppColors.primary.withOpacity(0.1) : const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(10)),
                          child: Center(child: Text(c['symbol'] ?? code[0], style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: enabled ? AppColors.primary : AppColors.gray))),
                        ),
                        title: Text(code, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        subtitle: Text(c['name'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                        trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                          if (isBase) Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                            child: const Text('Base', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          ) else Switch(value: enabled, onChanged: (_) => _toggle(c), activeColor: AppColors.primary),
                        ]),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 24),
              ]),
            ),
    );
  }
}
