import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/support_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});
  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();
  String _selectedCategory = 'General';
  String _selectedPriority = 'Medium';
  final Set<int> _expandedFaqs = {};

  static const _faqs = [
    {'q': 'How do I update my room prices?', 'a': 'Go to the Pricing section from the main menu. Select the room type you want to update, tap "Edit Pricing", and enter the new weekday, weekend, or seasonal rates. Tap "Update" to save your changes.'},
    {'q': 'How do I handle booking cancellations?', 'a': 'Navigate to Bookings and find the booking you want to cancel. Tap on it to open details, then select "Cancel Booking". You can set your cancellation policy in Settings > Hotel Policies.'},
    {'q': 'How do I add or remove amenities?', 'a': 'Go to Amenities from the main menu. Toggle each amenity on or off to reflect what your property offers. Tap "Save Amenities" when done. These will be visible to guests searching for hotels.'},
    {'q': 'When will I receive my payout?', 'a': 'Payouts are processed within 3-5 business days after a guest checks out. You can view your pending and completed payouts in the Withdrawals section. Ensure your bank details are up to date.'},
    {'q': 'How do I upload hotel photos?', 'a': 'Go to Gallery from the main menu. Tap the "Add Photo" button to upload images from your device. You can categorize photos by Exterior, Rooms, Restaurant, Pool, or Common Areas.'},
    {'q': 'What documents do I need to verify my hotel?', 'a': 'You need to upload: Identity Proof (Aadhaar/Passport/PAN), Hotel License (Trade License), Tax Documents (GST Certificate), and Insurance documents. All documents must be valid and clearly readable.'},
    {'q': 'How do I respond to guest reviews?', 'a': 'Go to Reviews from the main menu. Find the review you want to respond to and tap "Reply". Write a professional response and tap "Submit". Responding to reviews improves your hotel\'s reputation.'},
    {'q': 'How do I set up seasonal pricing?', 'a': 'In the Pricing section, open any room card and tap "Edit Pricing". Toggle on "Seasonal Pricing" and enter the seasonal rate. This allows you to charge different rates during peak seasons like holidays.'},
    {'q': 'Can I block dates on the calendar?', 'a': 'Yes. Go to Calendar from the main menu. Tap on any date or date range you want to block. Select "Block Dates" and confirm. Blocked dates will not be available for new bookings.'},
    {'q': 'How do I contact a guest directly?', 'a': 'Go to Messages from the main menu. Find the guest\'s conversation or search by name. You can send messages, share check-in instructions, or use quick reply templates for common responses.'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black,
        title: const Text('Help & Support', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
        bottom: TabBar(
          controller: _tabController,
          labelColor: const Color(AppConstants.primaryRed),
          unselectedLabelColor: const Color(AppConstants.mediumGray),
          indicatorColor: const Color(AppConstants.primaryRed),
          indicatorWeight: 2.5,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [Tab(text: 'FAQ'), Tab(text: 'Contact'), Tab(text: 'Submit Ticket')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFAQTab(isDark, cardColor, borderColor),
          _buildContactTab(isDark, cardColor, borderColor),
          _buildTicketTab(isDark, cardColor, borderColor),
        ],
      ),
    );
  }

  Widget _buildFAQTab(bool isDark, Color cardColor, Color borderColor) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(AppConstants.primaryRed).withOpacity(0.06), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(AppConstants.primaryRed).withOpacity(0.15))),
          child: Row(
            children: [
              const Icon(Icons.search, color: Color(AppConstants.primaryRed), size: 18),
              const SizedBox(width: 10),
              Expanded(child: Text('Find answers to common questions below', style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(AppConstants.darkGray)))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...List.generate(_faqs.length, (i) => _buildFaqItem(i, isDark, cardColor, borderColor)),
      ],
    );
  }

  Widget _buildFaqItem(int index, bool isDark, Color cardColor, Color borderColor) {
    final isExpanded = _expandedFaqs.contains(index);
    return GestureDetector(
      onTap: () => setState(() { if (isExpanded) _expandedFaqs.remove(index); else _expandedFaqs.add(index); }),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(12), border: Border.all(color: isExpanded ? const Color(AppConstants.primaryRed).withOpacity(0.3) : borderColor)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(color: isExpanded ? const Color(AppConstants.primaryRed).withOpacity(0.1) : (isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray)), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.help_outline, size: 16, color: isExpanded ? const Color(AppConstants.primaryRed) : const Color(AppConstants.mediumGray)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(_faqs[index]['q']!, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black))),
                  Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: const Color(AppConstants.mediumGray), size: 20),
                ],
              ),
            ),
            if (isExpanded)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Text(_faqs[index]['a']!, style: const TextStyle(fontSize: 13, color: Color(AppConstants.mediumGray), height: 1.6)),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTab(bool isDark, Color cardColor, Color borderColor) {
    final contacts = [
      {'icon': Icons.phone, 'title': 'Call Support', 'subtitle': '+91-1800-123-4567', 'badge': '24/7', 'color': const Color(AppConstants.successGreen), 'action': 'Call Now'},
      {'icon': Icons.email_outlined, 'title': 'Email Support', 'subtitle': 'support@hotelsewa.com', 'badge': 'Replies in 2hrs', 'color': const Color(0xFF2196F3), 'action': 'Send Email'},
      {'icon': Icons.chat_bubble_outline, 'title': 'Live Chat', 'subtitle': 'Chat with our support team', 'badge': 'Online', 'color': const Color(AppConstants.warningOrange), 'action': 'Start Chat'},
      {'icon': Icons.video_call_outlined, 'title': 'Video Support', 'subtitle': 'Schedule a video call', 'badge': 'By Appointment', 'color': const Color(AppConstants.primaryRed), 'action': 'Schedule'},
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('We\'re here to help', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 4),
              const Text('Choose your preferred way to reach us', style: TextStyle(fontSize: 13, color: Color(AppConstants.mediumGray))),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...contacts.map((c) {
          final color = c['color'] as Color;
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
            child: Row(
              children: [
                Container(width: 48, height: 48, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(c['icon'] as IconData, color: color, size: 22)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(c['title'] as String, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                          const SizedBox(width: 8),
                          Container(padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Text(c['badge'] as String, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color))),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(c['subtitle'] as String, style: const TextStyle(fontSize: 12, color: Color(AppConstants.mediumGray))),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0, minimumSize: Size.zero, tapTargetSize: MaterialTapTargetSize.shrinkWrap),
                  child: Text(c['action'] as String, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTicketTab(bool isDark, Color cardColor, Color borderColor) {
    final categories = ['General', 'Booking Issue', 'Payment', 'Technical', 'Account', 'Other'];
    final priorities = ['Low', 'Medium', 'High', 'Urgent'];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Submit a Support Ticket', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                const Text('We\'ll get back to you within 24 hours', style: TextStyle(fontSize: 13, color: Color(AppConstants.mediumGray))),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Category', isDark),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(AppConstants.primaryRed))), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14)),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setState(() => _selectedCategory = v ?? 'General'),
                ),
                const SizedBox(height: 16),
                _label('Priority', isDark),
                const SizedBox(height: 8),
                Row(
                  children: priorities.map((p) {
                    final isSelected = _selectedPriority == p;
                    final color = p == 'Urgent' ? const Color(AppConstants.errorRed) : p == 'High' ? const Color(AppConstants.warningOrange) : p == 'Medium' ? const Color(0xFF2196F3) : const Color(AppConstants.successGreen);
                    return Expanded(
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedPriority = p),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: EdgeInsets.only(right: p != 'Urgent' ? 6 : 0),
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(color: isSelected ? color : color.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                          child: Text(p, textAlign: TextAlign.center, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : color)),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _label('Subject', isDark),
                const SizedBox(height: 8),
                TextField(controller: _subjectCtrl, decoration: InputDecoration(hintText: 'Brief description of your issue', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(AppConstants.primaryRed))), contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14))),
                const SizedBox(height: 16),
                _label('Message', isDark),
                const SizedBox(height: 8),
                TextField(controller: _messageCtrl, maxLines: 5, decoration: InputDecoration(hintText: 'Describe your issue in detail...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(AppConstants.primaryRed))), contentPadding: const EdgeInsets.all(14))),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _submitTicket,
                    icon: const Icon(Icons.send, size: 18),
                    label: const Text('Submit Ticket', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryRed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text, bool isDark) {
    return Text(text, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black));
  }

  void _submitTicket() async {
    if (_subjectCtrl.text.trim().isEmpty || _messageCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Please fill in all fields'), backgroundColor: const Color(AppConstants.errorRed), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) SupportService.setToken(token);
      await SupportService().createSupportTicket({
        'subject': _subjectCtrl.text.trim(),
        'message': _messageCtrl.text.trim(),
        'category': _selectedCategory,
        'priority': _selectedPriority.toLowerCase(),
      });
      _subjectCtrl.clear();
      _messageCtrl.clear();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Ticket submitted! We\'ll respond within 24 hours.'), backgroundColor: const Color(AppConstants.successGreen), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to submit: $e'), backgroundColor: const Color(AppConstants.errorRed), behavior: SnackBarBehavior.floating));
    }
  }
}
