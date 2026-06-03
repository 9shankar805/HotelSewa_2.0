import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class TermsScreen extends StatefulWidget {
  const TermsScreen({Key? key}) : super(key: key);

  @override
  State<TermsScreen> createState() => _TermsScreenState();
}

class _TermsScreenState extends State<TermsScreen> {
  int? _expanded;

  final _sections = [
    {
      'title': '1. Acceptance of Terms',
      'content': 'By accessing or using the HotelSewa application ("App"), you agree to be bound by these Terms of Service ("Terms"). If you do not agree to these Terms, please do not use the App. We reserve the right to update these Terms at any time, and your continued use of the App constitutes acceptance of any changes.',
    },
    {
      'title': '2. Use of the Service',
      'content': 'HotelSewa provides an online platform for hotel discovery, booking, and management. You agree to use the App only for lawful purposes and in accordance with these Terms. You must be at least 18 years old to make a booking. You are responsible for maintaining the confidentiality of your account credentials.',
    },
    {
      'title': '3. Bookings & Payments',
      'content': 'All bookings made through HotelSewa are subject to availability and confirmation by the hotel. Prices displayed are inclusive of applicable taxes unless stated otherwise. Payment is processed securely through our payment partners. HotelSewa is not responsible for any additional charges levied by the hotel at the time of check-in.',
    },
    {
      'title': '4. Cancellation & Refunds',
      'content': 'Cancellation policies vary by hotel and room type. The applicable policy is displayed at the time of booking. Refunds, where applicable, are processed within 5–10 business days to the original payment method. HotelSewa\'s cancellation fee, if any, will be clearly communicated before confirmation.',
    },
    {
      'title': '5. User Conduct',
      'content': 'You agree not to: (a) use the App for any fraudulent or unlawful purpose; (b) post false, misleading, or defamatory reviews; (c) attempt to gain unauthorized access to any part of the App; (d) use automated tools to scrape or extract data; (e) impersonate any person or entity.',
    },
    {
      'title': '6. Intellectual Property',
      'content': 'All content on the App, including text, graphics, logos, images, and software, is the property of HotelSewa or its content suppliers and is protected by applicable intellectual property laws. You may not reproduce, distribute, or create derivative works without our express written permission.',
    },
    {
      'title': '7. Limitation of Liability',
      'content': 'HotelSewa acts as an intermediary between users and hotels. We are not liable for the quality, safety, or legality of hotels listed on the platform. To the maximum extent permitted by law, HotelSewa\'s total liability for any claim arising from use of the App shall not exceed the amount paid for the booking in question.',
    },
    {
      'title': '8. Privacy',
      'content': 'Your use of the App is also governed by our Privacy Policy, which is incorporated into these Terms by reference. By using the App, you consent to the collection and use of your information as described in the Privacy Policy.',
    },
    {
      'title': '9. Governing Law',
      'content': 'These Terms shall be governed by and construed in accordance with the laws of India. Any disputes arising under these Terms shall be subject to the exclusive jurisdiction of the courts in Mumbai, Maharashtra.',
    },
    {
      'title': '10. Contact Us',
      'content': 'If you have any questions about these Terms, please contact us at:\n\nHotelSewa Support\nEmail: legal@hotelsewa.com\nPhone: +91-80-4718-8888\nAddress: HotelSewa Technologies Pvt. Ltd., Mumbai, Maharashtra, India.',
    },
  ];

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
        title: const Text('Terms of Service', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.gavel_rounded, color: AppColors.primary, size: 24),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Terms of Service', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                      Text('Last updated: January 1, 2025', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.lightGray),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _sections.length,
              itemBuilder: (_, i) {
                final section = _sections[i];
                final isExpanded = _expanded == i;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isExpanded ? AppColors.primary.withOpacity(0.3) : AppColors.lightGray),
                    boxShadow: isExpanded ? [] : AppColors.cardShadow,
                  ),
                  child: InkWell(
                    onTap: () => setState(() => _expanded = isExpanded ? null : i),
                    borderRadius: BorderRadius.circular(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  section['title']!,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: isExpanded ? AppColors.primary : AppColors.darkGray,
                                  ),
                                ),
                              ),
                              Icon(
                                isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                                color: isExpanded ? AppColors.primary : AppColors.gray,
                                size: 22,
                              ),
                            ],
                          ),
                        ),
                        if (isExpanded)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Text(
                              section['content']!,
                              style: const TextStyle(fontSize: 13, color: AppColors.gray, height: 1.6),
                            ),
                          ).animate().fadeIn(duration: 200.ms),
                      ],
                    ),
                  ),
                ).animate(delay: (i * 30).ms).fadeIn();
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            color: Colors.white,
            child: const Text(
              '© 2025 HotelSewa Technologies Pvt. Ltd. All rights reserved.',
              style: TextStyle(fontSize: 11, color: AppColors.placeholder),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
