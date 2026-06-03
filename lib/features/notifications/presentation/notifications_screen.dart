import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final NotificationService _service = NotificationService();
  List<Map<String, dynamic>> _notifications = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getNotifications();
    if (result['success'] && mounted) {
      final raw = result['notifications'];
      List items = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['items'] ?? []) : []);
      setState(() {
        _notifications = items.map<Map<String, dynamic>>((n) => {
          'id': n['id']?.toString() ?? '',
          'title': n['title'] ?? n['subject'] ?? 'Notification',
          'message': n['message'] ?? n['body'] ?? '',
          'type': n['type'] ?? 'general',
          'time': _formatTime(n['created_at']),
          'read': n['read_at'] != null,
        }).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  Future<void> _markRead(String id, int index) async {
    await _service.markAsRead(id);
    setState(() => _notifications[index]['read'] = true);
  }

  Future<void> _markAllRead() async {
    await _service.markAllAsRead();
    setState(() {
      for (final n in _notifications) n['read'] = true;
    });
  }

  String _formatTime(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inSeconds < 60) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      return raw.toString();
    }
  }

  IconData _iconFor(String type) {
    switch (type) {
      case 'booking': return Icons.hotel_rounded;
      case 'payment': return Icons.payment_rounded;
      case 'offer': return Icons.local_offer_rounded;
      case 'review': return Icons.star_rounded;
      case 'loyalty': return Icons.diamond_rounded;
      default: return Icons.notifications_rounded;
    }
  }

  Color _colorFor(String type) {
    switch (type) {
      case 'booking': return AppColors.primary;
      case 'payment': return AppColors.success;
      case 'offer': return AppColors.warning;
      case 'review': return AppColors.gold;
      case 'loyalty': return AppColors.purple;
      default: return AppColors.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final unread = _notifications.where((n) => n['read'] == false).length;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            if (unread > 0) Text('$unread unread', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ],
        ),
        actions: [
          if (unread > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: AppColors.darkGray, size: 20),
            onPressed: () => Navigator.pushNamed(context, '/notification-settings'),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _notifications.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.builder(
                    itemCount: _notifications.length,
                    itemBuilder: (_, i) => _buildItem(_notifications[i], i),
                  ),
                ),
    );
  }

  Future<void> _delete(String id, int index) async {
    // Assuming service has deleteNotification
    // await _service.deleteNotification(id);
    setState(() => _notifications.removeAt(index));
  }

  Widget _buildItem(Map<String, dynamic> n, int i) {
    final unread = n['read'] == false;
    final color = _colorFor(n['type'] as String);
    return Dismissible(
      key: Key(n['id']),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppColors.error,
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) => _delete(n['id'], i),
      child: InkWell(
        onTap: () {
          _markRead(n['id'] as String, i);
          // Navigate based on type
          if (n['type'] == 'booking') {
            context.push('/my-trips');
          } else if (n['type'] == 'payment') {
            context.push('/wallet');
          } else if (n['type'] == 'offer') {
            context.push('/deals');
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: unread ? AppColors.primary.withOpacity(0.04) : Colors.white,
            border: const Border(bottom: BorderSide(color: Color(0xFFF5F5F5), width: 1)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
                child: Icon(_iconFor(n['type'] as String), color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text(n['title'] as String, style: TextStyle(fontSize: 14, fontWeight: unread ? FontWeight.w700 : FontWeight.w500, color: AppColors.darkGray))),
                      if (unread) Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
                    ]),
                    const SizedBox(height: 3),
                    Text(n['message'] as String, style: const TextStyle(fontSize: 13, color: AppColors.gray, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text(n['time'] as String, style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ).animate(delay: (i * 30).ms).fadeIn();
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.notifications_off_outlined, size: 40, color: AppColors.placeholder)),
          const SizedBox(height: 16),
          const Text('No notifications yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          const Text('We\'ll notify you about bookings, deals and more', style: TextStyle(fontSize: 14, color: AppColors.gray), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
