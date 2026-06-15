import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({Key? key}) : super(key: key);

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
        title: const Text('About HotelSewa', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 40),
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
              child: Column(
                children: [
                  Container(
                    width: 80, height: 80,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(22), boxShadow: AppColors.elevatedShadow),
                    child: const Center(child: Text('HS', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: AppColors.primary))),
                  ),
                  const SizedBox(height: 16),
                  const Text('HotelSewa', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
                  const SizedBox(height: 4),
                  const Text('Version 1.0.0 (Build 100)', style: TextStyle(fontSize: 13, color: Colors.white70)),
                ],
              ),
            ).animate().fadeIn(),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  _card(child: Column(
                    children: [
                      _infoRow(Icons.info_outline_rounded, AppColors.primary, 'App Version', '1.0.0'),
                      const Divider(color: AppColors.lightGray, height: 1),
                      _infoRow(Icons.build_outlined, AppColors.info, 'Build Number', '100'),
                      const Divider(color: AppColors.lightGray, height: 1),
                      _infoRow(Icons.calendar_today_outlined, AppColors.success, 'Release Date', 'January 2025'),
                    ],
                  )).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  _card(child: Column(
                    children: [
                      _linkRow(context, Icons.description_outlined, AppColors.primary, 'Terms of Service', () => Navigator.pushNamed(context, '/terms')),
                      const Divider(color: AppColors.lightGray, height: 1),
                      _linkRow(context, Icons.privacy_tip_outlined, AppColors.info, 'Privacy Policy', () => Navigator.pushNamed(context, '/privacy-policy')),
                      const Divider(color: AppColors.lightGray, height: 1),
                      _linkRow(context, Icons.cookie_outlined, AppColors.warning, 'Cookie Policy', () {}),
                      const Divider(color: AppColors.lightGray, height: 1),
                      _linkRow(context, Icons.gavel_outlined, AppColors.purple, 'Licenses', () {}),
                    ],
                  )).animate().fadeIn(delay: 140.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  _card(child: Column(
                    children: [
                      _linkRow(context, Icons.star_outline_rounded, AppColors.gold, 'Rate the App', () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Thank you! Redirecting to the app store...'), behavior: SnackBarBehavior.floating),
                        );
                      }),
                      const Divider(color: AppColors.lightGray, height: 1),
                      _linkRow(context, Icons.share_outlined, AppColors.success, 'Share App', () {
                        const shareText = 'Book hotels in Nepal with HotelSewa! Download at https://hotelsewa.com';
                        Clipboard.setData(const ClipboardData(text: shareText));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Share link copied to clipboard!'), behavior: SnackBarBehavior.floating),
                        );
                      }),
                      const Divider(color: AppColors.lightGray, height: 1),
                      _linkRow(context, Icons.bug_report_outlined, AppColors.error, 'Report a Bug', () => Navigator.pushNamed(context, '/support-ticket')),
                    ],
                  )).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  // Social links
                  _card(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
                        child: Text('Follow Us', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                      ),
                      const Divider(color: AppColors.lightGray, height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _socialBtn('𝕏', const Color(0xFF000000), 'Twitter'),
                            _socialBtn('in', const Color(0xFF0A66C2), 'LinkedIn'),
                            _socialBtn('f', const Color(0xFF1877F2), 'Facebook'),
                            _socialBtn('▶', const Color(0xFFFF0000), 'YouTube'),
                          ],
                        ),
                      ),
                    ],
                  )).animate().fadeIn(delay: 260.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),

                  const Text('Made with ❤️ in Nepal', style: TextStyle(fontSize: 13, color: AppColors.gray)),
                  const SizedBox(height: 4),
                  const Text('© 2025 HotelSewa. All rights reserved.', style: TextStyle(fontSize: 12, color: AppColors.placeholder)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
    child: child,
  );

  Widget _infoRow(IconData icon, Color color, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGray))),
          Text(value, style: const TextStyle(fontSize: 13, color: AppColors.gray, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _linkRow(BuildContext context, IconData icon, Color color, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, size: 18, color: color)),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGray))),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.placeholder),
          ],
        ),
      ),
    );
  }

  Widget _socialBtn(String letter, Color color, String label) {
    final urls = {
      'Twitter': 'https://twitter.com/hotelsewa',
      'LinkedIn': 'https://linkedin.com/company/hotelsewa',
      'Facebook': 'https://facebook.com/hotelsewa',
      'YouTube': 'https://youtube.com/@hotelsewa',
    };
    return GestureDetector(
      onTap: () {
        final url = urls[label] ?? 'https://hotelsewa.com';
        Clipboard.setData(ClipboardData(text: url));
      },
      child: Column(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text(letter, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color))),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
        ],
      ),
    );
  }
}
