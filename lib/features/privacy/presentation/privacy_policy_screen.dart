import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSection(
              'Last Updated',
              'January 2025',
            ),
            const SizedBox(height: 24),
            _buildSection(
              '1. Information We Collect',
              'We collect information you provide directly (name, email, phone, payment details), '
              'automatically (device info, location, usage data), and from third parties (social login providers).',
            ),
            _buildSection(
              '2. How We Use Your Information',
              'To process bookings, provide customer support, send notifications, improve services, '
              'personalize recommendations, and ensure security.',
            ),
            _buildSection(
              '3. Information Sharing',
              'We share data with hotel partners for bookings, payment processors, service providers, '
              'and as required by law. We never sell your personal information.',
            ),
            _buildSection(
              '4. Data Security',
              'We implement industry-standard security measures including encryption, secure servers, '
              'and regular security audits to protect your information.',
            ),
            _buildSection(
              '5. Your Rights',
              'You can access, update, or delete your data. Contact us to exercise these rights. '
              'You can opt-out of marketing communications anytime.',
            ),
            _buildSection(
              '6. Cookies & Tracking',
              'We use cookies and similar technologies to enhance user experience, analyze usage, '
              'and provide personalized content.',
            ),
            _buildSection(
              '7. Children\'s Privacy',
              'Our services are not intended for users under 18. We do not knowingly collect '
              'information from children.',
            ),
            _buildSection(
              '8. Changes to Policy',
              'We may update this policy periodically. Continued use after changes constitutes acceptance.',
            ),
            _buildSection(
              '9. Contact Us',
              'For privacy concerns, contact us at privacy@hotelsewa.com or through the app support.',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.darkGray,
            ),
          ),
        ],
      ),
    );
  }
}
