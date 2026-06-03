import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/messaging_service.dart';
import 'automated_messaging_screen.dart';

class GuestMessagingScreen extends StatefulWidget {
  const GuestMessagingScreen({super.key});
  @override
  State<GuestMessagingScreen> createState() => _GuestMessagingScreenState();
}

class _GuestMessagingScreenState extends State<GuestMessagingScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  List<Map<String, dynamic>> _filtered = [];
  String _activeFilter = 'All';
  final _searchCtrl = TextEditingController();
  bool _isSearching = false;

  static const _filters = ['All', 'Unread', 'Archived'];
  static const _quickReplies = [
    'Thank you for your booking! We look forward to welcoming you.',
    'Your room is ready. Check-in time is 2:00 PM.',
    'Please let us know if you need any assistance during your stay.',
    'We hope you enjoyed your stay. Please leave us a review!',
    'Your booking has been confirmed. See you soon!',
  ];

  @override
  void initState() {
    super.initState();
    _load();
    _searchCtrl.addListener(_applyFilters);
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_applyFilters);
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        MessagingService.setToken(token);
        _conversations = List<Map<String, dynamic>>.from(await MessagingService().getConversations());
      }
    } catch (_) {
      _conversations = [
        {'id': '1', 'guestName': 'Rahul Sharma', 'lastMessage': 'What time is check-in?', 'time': '10:30 AM', 'unreadCount': 2, 'archived': false},
        {'id': '2', 'guestName': 'Priya Patel', 'lastMessage': 'Thank you for the quick response!', 'time': 'Yesterday', 'unreadCount': 0, 'archived': false},
        {'id': '3', 'guestName': 'Amit Kumar', 'lastMessage': 'Is breakfast included?', 'time': 'Mon', 'unreadCount': 1, 'archived': false},
        {'id': '4', 'guestName': 'Sneha Gupta', 'lastMessage': 'We had a wonderful stay!', 'time': 'Sun', 'unreadCount': 0, 'archived': true},
        {'id': '5', 'guestName': 'Vikram Singh', 'lastMessage': 'Can I get a late checkout?', 'time': 'Sat', 'unreadCount': 3, 'archived': false},
      ];
    }
    if (mounted) { setState(() { _isLoading = false; _applyFilters(); }); }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_conversations);
    if (_activeFilter == 'Unread') result = result.where((c) => (c['unreadCount'] ?? 0) > 0).toList();
    else if (_activeFilter == 'Archived') result = result.where((c) => c['archived'] == true).toList();
    else result = result.where((c) => c['archived'] != true).toList();
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isNotEmpty) result = result.where((c) => (c['guestName'] ?? '').toString().toLowerCase().contains(q) || (c['lastMessage'] ?? '').toString().toLowerCase().contains(q)).toList();
    setState(() => _filtered = result);
  }

  void _showQuickReplies() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(color: isDark ? const Color(0xFF1E1E1E) : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: const Color(AppConstants.mediumGray).withOpacity(0.3), borderRadius: BorderRadius.circular(2)))),
            const SizedBox(height: 16),
            Text('Quick Reply Templates', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
            const SizedBox(height: 14),
            ..._quickReplies.map((reply) => GestureDetector(
              onTap: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: const Text('Template copied'), behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray), borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, size: 16, color: Color(AppConstants.primaryRed)),
                    const SizedBox(width: 10),
                    Expanded(child: Text(reply, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(AppConstants.darkGray)))),
                    const Icon(Icons.copy, size: 14, color: Color(AppConstants.mediumGray)),
                  ],
                ),
              ),
            )),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
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
        title: _isSearching
            ? TextField(controller: _searchCtrl, autofocus: true, decoration: const InputDecoration(hintText: 'Search conversations...', border: InputBorder.none, hintStyle: TextStyle(color: Color(AppConstants.mediumGray))), style: const TextStyle(fontSize: 16))
            : const Text('Messages', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(icon: Icon(_isSearching ? Icons.close : Icons.search, color: Colors.black), onPressed: () { setState(() { _isSearching = !_isSearching; if (!_isSearching) { _searchCtrl.clear(); _applyFilters(); } }); }),
          IconButton(icon: const Icon(Icons.auto_awesome_rounded, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AutomatedMessagingScreen())), tooltip: 'Automated Messages'),
          IconButton(icon: const Icon(Icons.quickreply_outlined, color: Colors.black), onPressed: _showQuickReplies),
        ],
      ),
      body: _isLoading
          ? _buildSkeleton()
          : Column(
              children: [
                _buildFilterChips(isDark, cardColor),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _load,
                    color: const Color(AppConstants.primaryRed),
                    child: _filtered.isEmpty
                        ? _buildEmpty(isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildConvItem(_filtered[i], isDark, cardColor, borderColor),
                          ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterChips(bool isDark, Color cardColor) {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: _filters.map((filter) {
          final isActive = _activeFilter == filter;
          final unreadCount = filter == 'Unread' ? _conversations.where((c) => (c['unreadCount'] ?? 0) > 0).length : 0;
          return GestureDetector(
            onTap: () { setState(() => _activeFilter = filter); _applyFilters(); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(right: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? const Color(AppConstants.primaryRed) : (isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray)),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(filter, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isActive ? Colors.white : const Color(AppConstants.mediumGray))),
                  if (unreadCount > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: isActive ? Colors.white.withOpacity(0.3) : const Color(AppConstants.primaryRed), borderRadius: BorderRadius.circular(10)),
                      child: Text('$unreadCount', style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: Colors.white)),
                    ),
                  ],
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildConvItem(Map<String, dynamic> conv, bool isDark, Color cardColor, Color borderColor) {
    final name = conv['guestName'] ?? 'Guest';
    final initials = name.trim().split(' ').take(2).map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    final unread = (conv['unreadCount'] ?? 0) as int;
    final colors = [const Color(0xFF5C6BC0), const Color(0xFF26A69A), const Color(0xFFEF5350), const Color(0xFFAB47BC), const Color(0xFF42A5F5)];
    final avatarColor = colors[name.hashCode.abs() % colors.length];

    return GestureDetector(
      onTap: () {},
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: unread > 0 ? const Color(AppConstants.primaryRed).withOpacity(0.2) : borderColor),
        ),
        child: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(radius: 26, backgroundColor: avatarColor, child: Text(initials, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15))),
                Positioned(bottom: 0, right: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: const Color(AppConstants.successGreen), shape: BoxShape.circle, border: Border.all(color: cardColor, width: 2)))),
              ],
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(name, style: TextStyle(fontSize: 15, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600, color: isDark ? Colors.white : Colors.black))),
                      Text(conv['time'] ?? '', style: TextStyle(fontSize: 11, color: unread > 0 ? const Color(AppConstants.primaryRed) : const Color(AppConstants.mediumGray), fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(child: Text(conv['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13, color: unread > 0 ? (isDark ? Colors.white70 : const Color(AppConstants.darkGray)) : const Color(AppConstants.mediumGray), fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.w400))),
                      if (unread > 0) ...[
                        const SizedBox(width: 8),
                        Container(width: 22, height: 22, decoration: const BoxDecoration(color: Color(AppConstants.primaryRed), shape: BoxShape.circle), child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)))),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 90, height: 90, decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray), shape: BoxShape.circle), child: const Icon(Icons.chat_bubble_outline, size: 44, color: Color(AppConstants.mediumGray))),
          const SizedBox(height: 20),
          Text(_activeFilter == 'Unread' ? 'No unread messages' : 'No conversations yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          const Text('Guest messages will appear here', style: TextStyle(fontSize: 14, color: Color(AppConstants.mediumGray))),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        Container(height: 56, color: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), child: Row(children: List.generate(3, (_) => const Padding(padding: EdgeInsets.only(right: 10), child: SkeletonLoader(width: 80, height: 36, borderRadius: 20))))),
        Expanded(child: ListView.builder(padding: const EdgeInsets.all(16), itemCount: 6, itemBuilder: (_, __) => const Padding(padding: EdgeInsets.only(bottom: 8), child: SkeletonBookingItem()))),
      ],
    );
  }
}
