import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class CurrencySelectorScreen extends StatefulWidget {
  const CurrencySelectorScreen({Key? key}) : super(key: key);
  @override
  State<CurrencySelectorScreen> createState() => _CurrencySelectorScreenState();
}

class _CurrencySelectorScreenState extends State<CurrencySelectorScreen> {
  String _selected = 'NPR';
  String _search = '';
  bool _saving = false;

  final _currencies = [
    {'code': 'NPR', 'name': 'Nepali Rupee', 'symbol': 'Rs.', 'flag': '🇳🇵'},
    {'code': 'INR', 'name': 'Indian Rupee', 'symbol': 'Rs', 'flag': '🇮🇳'},
    {'code': 'USD', 'name': 'US Dollar', 'symbol': 'USD', 'flag': '🇺🇸'},
    {'code': 'EUR', 'name': 'Euro', 'symbol': 'EUR', 'flag': '🇪🇺'},
    {'code': 'GBP', 'name': 'British Pound', 'symbol': 'GBP', 'flag': '🇬🇧'},
    {'code': 'AED', 'name': 'UAE Dirham', 'symbol': 'AED', 'flag': '🇦🇪'},
    {'code': 'SGD', 'name': 'Singapore Dollar', 'symbol': 'SGD', 'flag': '🇸🇬'},
    {'code': 'AUD', 'name': 'Australian Dollar', 'symbol': 'AUD', 'flag': '🇦🇺'},
    {'code': 'CAD', 'name': 'Canadian Dollar', 'symbol': 'CAD', 'flag': '🇨🇦'},
    {'code': 'JPY', 'name': 'Japanese Yen', 'symbol': 'JPY', 'flag': '🇯🇵'},
    {'code': 'CNY', 'name': 'Chinese Yuan', 'symbol': 'CNY', 'flag': '🇨🇳'},
    {'code': 'CHF', 'name': 'Swiss Franc', 'symbol': 'CHF', 'flag': '🇨🇭'},
    {'code': 'SAR', 'name': 'Saudi Riyal', 'symbol': 'SAR', 'flag': '🇸🇦'},
    {'code': 'MYR', 'name': 'Malaysian Ringgit', 'symbol': 'MYR', 'flag': '🇲🇾'},
    {'code': 'THB', 'name': 'Thai Baht', 'symbol': 'THB', 'flag': '🇹🇭'},
  ];

  List<Map<String, dynamic>> get _filtered => _currencies
      .where((c) => c['code']!.toLowerCase().contains(_search.toLowerCase()) || c['name']!.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final saved = p.getString('app_currency');
      if (saved != null && mounted) setState(() => _selected = saved);
    });
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
        title: const Text('Currency', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              onChanged: (v) => setState(() => _search = v),
              decoration: InputDecoration(
                hintText: 'Search currency...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray, size: 20),
                filled: true, fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final cur = _filtered[i];
                final selected = _selected == cur['code'];
                return GestureDetector(
                  onTap: () => setState(() => _selected = cur['code']!),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: selected ? AppColors.primary : AppColors.lightGray, width: selected ? 1.5 : 1),
                      boxShadow: selected ? [] : AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Text(cur['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(cur['name']!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.darkGray)),
                          Text(cur['code']!, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                        ])),
                        Container(
                          width: 44, height: 36,
                          decoration: BoxDecoration(color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                          child: Center(child: Text(cur['symbol']!, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: selected ? AppColors.primary : AppColors.gray))),
                        ),
                        if (selected) ...[const SizedBox(width: 8), const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20)],
                      ],
                    ),
                  ).animate(delay: (i * 20).ms).fadeIn(),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : () async {
                  setState(() => _saving = true);
                  try {
                    final prefs = await SharedPreferences.getInstance();
                    await prefs.setString('app_currency', _selected);
                    final token = prefs.getString('authToken');
                    await ApiService.put(ApiConfig.userPreferencesEndpoint, token: token, data: {'currency': _selected});
                  } catch (_) {}
                  if (!mounted) return;
                  setState(() => _saving = false);
                  Navigator.pop(context, _selected);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Currency set to $_selected'), behavior: SnackBarBehavior.floating));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Apply - $_selected', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}