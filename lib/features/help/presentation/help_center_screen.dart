import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  String _searchQuery = '';
  String? _expandedFAQ;

  final _categories = [
    {'id': 'booking', 'title': 'Booking Help', 'icon': Icons.event, 'color': const Color(0xFF1890FF)},
    {'id': 'payment', 'title': 'Payment Issues', 'icon': Icons.payment, 'color': const Color(0xFF52C41A)},
    {'id': 'cancellation', 'title': 'Cancellation', 'icon': Icons.cancel, 'color': const Color(0xFFFA8C16)},
    {'id': 'account', 'title': 'Account Settings', 'icon': Icons.person, 'color': const Color(0xFF722ED1)},
  ];

  final _faqs = [
    {'id': '1', 'question': 'How do I cancel my booking?', 'answer': 'You can cancel your booking from the My Trips section. Free cancellation is available up to 24 hours before check-in.'},
    {'id': '2', 'question': 'When will I be charged?', 'answer': 'Payment is processed immediately after booking confirmation. You will receive a confirmation email with payment details.'},
    {'id': '3', 'question': 'Can I modify my booking dates?', 'answer': 'Yes, you can modify your booking dates subject to availability. Additional charges may apply for date changes.'},
    {'id': '4', 'question': 'What if I arrive late for check-in?', 'answer': 'Please inform the hotel about late arrival. Most hotels accommodate late check-ins, but it\'s best to confirm in advance.'},
  ];

  final _contactOptions = [
    {'id': 'chat', 'title': 'Live Chat', 'subtitle': 'Chat with our support team', 'icon': Icons.chat},
    {'id': 'call', 'title': 'Call Us', 'subtitle': '+91-80-4718-8888', 'icon': Icons.phone},
    {'id': 'email', 'title': 'Email Support', 'subtitle': 'support@hotelsewa.com', 'icon': Icons.email},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredFAQs = _faqs.where((faq) =>
      faq['question']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
      faq['answer']!.toLowerCase().contains(_searchQuery.toLowerCase())
    ).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Help Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Search bar
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 20, color: Color(0xFF666666)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: const InputDecoration(
                        hintText: 'Search help topics...',
                        border: InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Categories
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Browse by Category', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: _categories.map((cat) {
                      return GestureDetector(
                        onTap: () {},
                        child: Container(
                          width: (MediaQuery.of(context).size.width - 72) / 2,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: (cat['color'] as Color).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(cat['icon'] as IconData, size: 20, color: cat['color'] as Color),
                              const SizedBox(width: 8),
                              Text(cat['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),

            // FAQs
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Frequently Asked Questions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 16),
                  ...filteredFAQs.map((faq) {
                    final isExpanded = _expandedFAQ == faq['id'];
                    return InkWell(
                      onTap: () => setState(() => _expandedFAQ = isExpanded ? null : faq['id'] as String),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(faq['question'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF333333)))),
                                const SizedBox(width: 16),
                                Icon(isExpanded ? Icons.expand_less : Icons.expand_more, size: 24, color: const Color(0xFF666666)),
                              ],
                            ),
                            if (isExpanded) ...[
                              const SizedBox(height: 12),
                              Text(faq['answer'] as String, style: const TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.4)),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),

            // Contact support
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Contact Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 16),
                  ..._contactOptions.map((option) {
                    return InkWell(
                      onTap: () {
                        if (option['id'] == 'chat') {
                          context.push('/chat');
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('${option['title']}: ${option['subtitle']}')),
                          );
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
                        child: Row(
                          children: [
                            Icon(option['icon'] as IconData, size: 24, color: AppColors.primary),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(option['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF333333))),
                                  const SizedBox(height: 2),
                                  Text(option['subtitle'] as String, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right, size: 24, color: Color(0xFFCCCCCC)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
