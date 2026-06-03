import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class LanguageSelectorScreen extends StatefulWidget {
  const LanguageSelectorScreen({Key? key}) : super(key: key);

  @override
  State<LanguageSelectorScreen> createState() => _LanguageSelectorScreenState();
}

class _LanguageSelectorScreenState extends State<LanguageSelectorScreen> {
  String _selected = 'English';
  String _search = '';
  bool _saving = false;

  final _languages = [
    {'name': 'English', 'native': 'English', 'flag': '🇬🇧', 'code': 'en'},
    {'name': 'Nepali', 'native': 'नेपाली', 'flag': '🇳🇵', 'code': 'ne'},
    {'name': 'Hindi', 'native': 'हिन्दी', 'flag': '🇮🇳', 'code': 'hi'},
    {'name': 'Bengali', 'native': 'বাংলা', 'flag': '🇧🇩', 'code': 'bn'},
    {'name': 'Arabic', 'native': 'العربية', 'flag': '🇸🇦', 'code': 'ar'},
    {'name': 'French', 'native': 'Français', 'flag': '🇫🇷', 'code': 'fr'},
    {'name': 'German', 'native': 'Deutsch', 'flag': '🇩🇪', 'code': 'de'},
    {'name': 'Spanish', 'native': 'Español', 'flag': '🇪🇸', 'code': 'es'},
    {'name': 'Japanese', 'native': '日本語', 'flag': '🇯🇵', 'code': 'ja'},
    {'name': 'Chinese', 'native': '中文', 'flag': '🇨🇳', 'code': 'zh'},
  ];

  @override
  void initState() {
    super.initState();
    SharedPreferences.getInstance().then((p) {
      final saved = p.getString('app_language');
      if (saved != null && mounted) setState(() => _selected = saved);
    });
  }

  List<Map<String, dynamic>> get _filtered => _languages
      .where((l) => l['name']!.toLowerCase().contains(_search.toLowerCase()) || l['native']!.toLowerCase().contains(_search.toLowerCase()))
      .toList();

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
        title: const Text('Language', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
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
                hintText: 'Search language...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray, size: 20),
                filled: true,
                fillColor: AppColors.background,
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
                final lang = _filtered[i];
                final selected = _selected == lang['name'];
                return GestureDetector(
                  onTap: () => setState(() => _selected = lang['name']!),
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
                        Text(lang['flag']!, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(lang['name']!, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: selected ? AppColors.primary : AppColors.darkGray)),
                              Text(lang['native']!, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                            ],
                          ),
                        ),
                        if (selected) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 22),
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
                    await prefs.setString('app_language', _selected);
                    final token = prefs.getString('authToken');
                    final code = _languages.firstWhere((l) => l['name'] == _selected, orElse: () => {'code': 'en'})['code'];
                    await ApiService.put(ApiConfig.userPreferencesEndpoint, token: token, data: {'language': code});
                  } catch (_) {}
                  if (!mounted) return;
                  setState(() => _saving = false);
                  Navigator.pop(context, _selected);
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Language set to $_selected'), behavior: SnackBarBehavior.floating));
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Apply · $_selected', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
