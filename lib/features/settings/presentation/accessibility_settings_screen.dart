import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';

class AccessibilitySettingsScreen extends StatefulWidget {
  const AccessibilitySettingsScreen({Key? key}) : super(key: key);

  @override
  State<AccessibilitySettingsScreen> createState() => _AccessibilitySettingsScreenState();
}

class _AccessibilitySettingsScreenState extends State<AccessibilitySettingsScreen> {
  double _fontSize = 1.0; // 0.8 small, 1.0 normal, 1.2 large, 1.4 xlarge
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _screenReader = false;
  bool _boldText = false;
  bool _largeButtons = false;
  bool _hapticFeedback = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _fontSize = prefs.getDouble('acc_fontSize') ?? 1.0;
      _highContrast = prefs.getBool('acc_highContrast') ?? false;
      _reduceMotion = prefs.getBool('acc_reduceMotion') ?? false;
      _screenReader = prefs.getBool('acc_screenReader') ?? false;
      _boldText = prefs.getBool('acc_boldText') ?? false;
      _largeButtons = prefs.getBool('acc_largeButtons') ?? false;
      _hapticFeedback = prefs.getBool('acc_hapticFeedback') ?? true;
    });
  }

  final _fontSizes = [
    {'label': 'Small', 'value': 0.8},
    {'label': 'Normal', 'value': 1.0},
    {'label': 'Large', 'value': 1.2},
    {'label': 'X-Large', 'value': 1.4},
  ];

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('acc_fontSize', _fontSize);
      await prefs.setBool('acc_highContrast', _highContrast);
      await prefs.setBool('acc_reduceMotion', _reduceMotion);
      await prefs.setBool('acc_screenReader', _screenReader);
      await prefs.setBool('acc_boldText', _boldText);
      await prefs.setBool('acc_largeButtons', _largeButtons);
      await prefs.setBool('acc_hapticFeedback', _hapticFeedback);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Accessibility settings saved'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to save settings'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
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
        title: const Text('Accessibility', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Font size
                  _sectionLabel('Text Size'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                    child: Column(
                      children: [
                        // Preview
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                          child: Text(
                            'Preview: Hotel booking made easy',
                            style: TextStyle(fontSize: 14 * _fontSize, color: AppColors.darkGray, fontWeight: _boldText ? FontWeight.w700 : FontWeight.w400),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: _fontSizes.map((s) {
                            final sel = _fontSize == s['value'];
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _fontSize = s['value'] as double),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  decoration: BoxDecoration(
                                    color: sel ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray, width: sel ? 1.5 : 1),
                                  ),
                                  child: Column(children: [
                                    Text('A', style: TextStyle(fontSize: 12 * (s['value'] as double), fontWeight: FontWeight.w700, color: sel ? AppColors.primary : AppColors.gray)),
                                    const SizedBox(height: 2),
                                    Text(s['label'] as String, style: TextStyle(fontSize: 9, color: sel ? AppColors.primary : AppColors.gray, fontWeight: sel ? FontWeight.w700 : FontWeight.w400)),
                                  ]),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 20),

                  _sectionLabel('Display'),
                  const SizedBox(height: 10),
                  _card(child: Column(children: [
                    _toggleRow(Icons.contrast_rounded, AppColors.darkGray, 'High Contrast', 'Increase contrast for better visibility', _highContrast, (v) => setState(() => _highContrast = v)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _toggleRow(Icons.format_bold_rounded, AppColors.info, 'Bold Text', 'Make all text bold', _boldText, (v) => setState(() => _boldText = v)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _toggleRow(Icons.touch_app_rounded, AppColors.success, 'Larger Buttons', 'Increase tap target sizes', _largeButtons, (v) => setState(() => _largeButtons = v)),
                  ])).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  _sectionLabel('Motion & Interaction'),
                  const SizedBox(height: 10),
                  _card(child: Column(children: [
                    _toggleRow(Icons.animation_rounded, AppColors.warning, 'Reduce Motion', 'Minimize animations and transitions', _reduceMotion, (v) => setState(() => _reduceMotion = v)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _toggleRow(Icons.vibration_rounded, AppColors.purple, 'Haptic Feedback', 'Vibration on button taps', _hapticFeedback, (v) => setState(() => _hapticFeedback = v)),
                  ])).animate().fadeIn(delay: 140.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  _sectionLabel('Screen Reader'),
                  const SizedBox(height: 10),
                  _card(child: Column(children: [
                    _toggleRow(Icons.record_voice_over_rounded, AppColors.primary, 'Screen Reader Support', 'Optimize for TalkBack / VoiceOver', _screenReader, (v) => setState(() => _screenReader = v)),
                  ])).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.info, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text('Some settings may require restarting the app to take full effect.',
                            style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
                      ],
                    ),
                  ).animate().fadeIn(delay: 260.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => setState(() {
                      _fontSize = 1.0; _highContrast = false; _reduceMotion = false;
                      _screenReader = false; _boldText = false; _largeButtons = false; _hapticFeedback = true;
                    }),
                    style: OutlinedButton.styleFrom(foregroundColor: AppColors.gray, side: const BorderSide(color: AppColors.lightGray), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: const Text('Reset', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _saving ? null : _save,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Save Settings', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray, letterSpacing: 0.5));

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
    child: child,
  );

  Widget _toggleRow(IconData icon, Color color, String title, String sub, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
            Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ])),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}
