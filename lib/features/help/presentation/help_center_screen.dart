import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  State<HelpCenterScreen> createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'all';
  String? _expandedFAQ;
  bool _loadingFaqs = true;

  List<Map<String, dynamic>> _faqs = [];

  static const List<Map<String, dynamic>> _fallbackFaqs = [
    {'id': '1', 'category': 'booking', 'question': 'How do I cancel my booking?', 'answer': 'Go to My Trips, select the booking, and tap "Cancel Booking". Free cancellation is available up to 24 hours before check-in.'},
    {'id': '2', 'category': 'payment', 'question': 'Which payment methods are accepted?', 'answer': 'We accept eSewa, Khalti, ConnectIPS, credit/debit cards, and wallet balance.'},
    {'id': '3', 'category': 'booking', 'question': 'Can I modify my booking dates?', 'answer': 'Yes, visit My Trips → Booking Details → Modify. Date changes are subject to availability and may incur additional charges.'},
    {'id': '4', 'category': 'cancellation', 'question': 'When will I get my refund?', 'answer': 'Refunds are processed within 5–7 business days after cancellation. The amount is credited to your original payment method.'},
    {'id': '5', 'category': 'account', 'question': 'How do I update my profile?', 'answer': 'Go to Profile → Personal Information and tap Edit.'},
    {'id': '6', 'category': 'booking', 'question': 'What if I arrive late for check-in?', 'answer': 'Please contact the hotel directly. Most hotels accommodate late check-ins, but it\'s best to notify them in advance via the in-app chat.'},
    {'id': '7', 'category': 'payment', 'question': 'Is my payment information secure?', 'answer': 'Yes. We use SSL encryption and never store raw card details. Payments are processed through certified payment gateways.'},
    {'id': '8', 'category': 'account', 'question': 'How do I earn loyalty points?', 'answer': 'You earn 10 points per NPR 100 spent on bookings. Additional points for referrals (500 pts), reviews (50 pts), and daily login (5 pts).'},
  ];

  final List<Map<String, dynamic>> _categories = [
    {'id': 'all', 'title': 'All Topics', 'icon': Icons.help_outline_rounded, 'color': AppColors.primary},
    {'id': 'booking', 'title': 'Booking Help', 'icon': Icons.event_rounded, 'color': const Color(0xFF1890FF)},
    {'id': 'payment', 'title': 'Payments', 'icon': Icons.payment_rounded, 'color': const Color(0xFF52C41A)},
    {'id': 'cancellation', 'title': 'Cancellation', 'icon': Icons.cancel_rounded, 'color': const Color(0xFFFA8C16)},
    {'id': 'account', 'title': 'Account', 'icon': Icons.person_rounded, 'color': const Color(0xFF722ED1)},
  ];

  @override
  void initState() {
    super.initState();
    _loadFaqs();
    _searchCtrl.addListener(() => setState(() => _searchQuery = _searchCtrl.text));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadFaqs() async {
    setState(() => _loadingFaqs = true);
    try {
      final response = await ApiService.get(ApiConfig.faqEndpoint);
      if (mounted) {
        final raw = response['data'];
        final list = raw is List ? raw : (raw is Map ? (raw['faqs'] ?? raw['data'] ?? []) : []);
        if (list.isNotEmpty) {
          setState(() {
            _faqs = list.map<Map<String, dynamic>>((f) => {
              'id': f['id']?.toString() ?? '',
              'category': (f['category'] ?? 'booking').toString().toLowerCase(),
              'question': f['question'] ?? f['title'] ?? '',
              'answer': f['answer'] ?? f['content'] ?? '',
            }).toList();
            _loadingFaqs = false;
          });
          return;
        }
      }
    } catch (_) {}
    if (mounted) {
      setState(() { _faqs = List.from(_fallbackFaqs); _loadingFaqs = false; });
    }
  }

  List<Map<String, dynamic>> get _filteredFaqs {
    return _faqs.where((faq) {
      final matchesCat = _selectedCategory == 'all' || faq['category'] == _selectedCategory;
      final q = _searchQuery.toLowerCase();
      final matchesSearch = q.isEmpty ||
          (faq['question'] as String).toLowerCase().contains(q) ||
          (faq['answer'] as String).toLowerCase().contains(q);
      return matchesCat && matchesSearch;
    }).toList();
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchPhone(String phone) => _launchUrl('tel:$phone');
  Future<void> _launchEmail(String email) => _launchUrl('mailto:$email');

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
        title: const Text('Help Center', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.confirmation_number_outlined, color: AppColors.primary),
            tooltip: 'My Support Tickets',
            onPressed: () => context.push('/support-ticket'),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Search bar
            TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search help topics...',
                hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray, size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.gray), onPressed: () => _searchCtrl.clear())
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),

            // Categories
            const Text('Browse by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 3.2,
              children: _categories.map((cat) {
                final sel = _selectedCategory == cat['id'];
                return GestureDetector(
                  onTap: () => setState(() { _selectedCategory = cat['id'] as String; _expandedFAQ = null; }),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: sel ? (cat['color'] as Color).withOpacity(0.12) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: sel ? cat['color'] as Color : AppColors.lightGray, width: sel ? 1.5 : 1),
                      boxShadow: sel ? [] : AppColors.cardShadow,
                    ),
                    child: Row(
                      children: [
                        Icon(cat['icon'] as IconData, size: 18, color: cat['color'] as Color),
                        const SizedBox(width: 8),
                        Flexible(child: Text(cat['title'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? cat['color'] as Color : AppColors.darkGray), overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ).animate().fadeIn(delay: 80.ms),
            const SizedBox(height: 24),

            // FAQs
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Frequently Asked Questions', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                if (_loadingFaqs) const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 12),
            if (_filteredFaqs.isEmpty)
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                child: const Center(child: Text('No results found. Try a different search.', style: TextStyle(color: AppColors.gray))),
              )
            else
              Container(
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                child: Column(
                  children: _filteredFaqs.asMap().entries.map((entry) {
                    final i = entry.key;
                    final faq = entry.value;
                    final isExpanded = _expandedFAQ == faq['id'];
                    final isLast = i == _filteredFaqs.length - 1;
                    return Column(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _expandedFAQ = isExpanded ? null : faq['id'] as String),
                          borderRadius: BorderRadius.vertical(
                            top: i == 0 ? const Radius.circular(16) : Radius.zero,
                            bottom: isLast ? const Radius.circular(16) : Radius.zero,
                          ),
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(child: Text(faq['question'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isExpanded ? AppColors.primary : AppColors.darkGray))),
                                    const SizedBox(width: 8),
                                    AnimatedRotation(
                                      turns: isExpanded ? 0.5 : 0,
                                      duration: const Duration(milliseconds: 200),
                                      child: Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: isExpanded ? AppColors.primary : AppColors.gray),
                                    ),
                                  ],
                                ),
                                if (isExpanded) ...[
                                  const SizedBox(height: 10),
                                  Text(faq['answer'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray, height: 1.5)),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, color: AppColors.lightGray, indent: 16, endIndent: 16),
                      ],
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 140.ms),
            const SizedBox(height: 24),

            // Contact Support
            const Text('Contact Support', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
              child: Column(
                children: [
                  _contactRow(
                    icon: Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                    title: 'Live Chat',
                    subtitle: 'Chat with our support team',
                    onTap: () => context.push('/chat'),
                  ),
                  const Divider(height: 1, color: AppColors.lightGray, indent: 16, endIndent: 16),
                  _contactRow(
                    icon: Icons.phone_outlined,
                    color: AppColors.success,
                    title: 'Call Us',
                    subtitle: '+977-1-4701234',
                    onTap: () => _launchPhone('+97714701234'),
                  ),
                  const Divider(height: 1, color: AppColors.lightGray, indent: 16, endIndent: 16),
                  _contactRow(
                    icon: Icons.email_outlined,
                    color: AppColors.info,
                    title: 'Email Support',
                    subtitle: 'support@hotelsewa.com',
                    onTap: () => _launchEmail('support@hotelsewa.com'),
                  ),
                  const Divider(height: 1, color: AppColors.lightGray, indent: 16, endIndent: 16),
                  _contactRow(
                    icon: Icons.confirmation_number_outlined,
                    color: AppColors.warning,
                    title: 'Submit a Ticket',
                    subtitle: 'Track your support request',
                    onTap: () => context.push('/support-ticket'),
                    isLast: true,
                  ),
                ],
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _contactRow({required IconData icon, required Color color, required String title, required String subtitle, required VoidCallback onTap, bool isLast = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
            ])),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.placeholder),
          ],
        ),
      ),
    );
  }
}
