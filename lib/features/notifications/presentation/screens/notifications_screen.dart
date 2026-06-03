import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/notification_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        NotificationService.setToken(token);
        final data = await NotificationService().fetchNotifications();
        _notifications = data.map((n) => _mapNotification(n)).toList();
      }
    } catch (_) {
      // keep empty list on error
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Map<String, dynamic> _mapNotification(Map<String, dynamic> n) {
    final type = (n['type'] ?? 'general').toString().toLowerCase();
    IconData icon;
    Color color;
    switch (type) {
      case 'booking': icon = Icons.calendar_today_rounded; color = const Color(0xFF1890FF); break;
      case 'payment': icon = Icons.currency_rupee_rounded; color = Color(AppConstants.successGreen); break;
      case 'message': icon = Icons.chat_bubble_outline_rounded; color = Color(AppConstants.warningOrange); break;
      case 'review': icon = Icons.star_rounded; color = const Color(0xFFFFBF00); break;
      case 'cancellation': icon = Icons.cancel_outlined; color = Color(AppConstants.errorRed); break;
      default: icon = Icons.notifications_rounded; color = Color(AppConstants.primaryRed);
    }
    return {
      'id': n['id']?.toString() ?? '',
      'title': n['title'] ?? n['subject'] ?? 'Notification',
      'message': n['message'] ?? n['body'] ?? '',
      'time': n['createdAt'] ?? n['time'] ?? '',
      'type': type,
      'read': n['read'] ?? n['isRead'] ?? false,
      'icon': icon,
      'color': color,
    };
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _unread => _notifications.where((n) => n['read'] == false).toList();
  List<Map<String, dynamic>> get _all => _notifications;

  void _markAllRead() {
    setState(() {
      for (final n in _notifications) {
        n['read'] = true;
      }
    });
  }

  void _markRead(String id) {
    setState(() {
      final n = _notifications.firstWhere((n) => n['id'] == id, orElse: () => {});
      if (n.isNotEmpty) n['read'] = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    final unreadCount = _unread.length;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            const Text('Notifications'),
            if (unreadCount > 0) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(AppConstants.primaryRed),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$unreadCount',
                  style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (unreadCount > 0)
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read', style: TextStyle(color: Color(AppConstants.primaryRed), fontSize: 13)),
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(AppConstants.primaryRed),
          labelColor: const Color(AppConstants.primaryRed),
          unselectedLabelColor: const Color(AppConstants.mediumGray),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: [
            Tab(text: 'Unread${unreadCount > 0 ? ' ($unreadCount)' : ''}'),
            const Tab(text: 'All'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildSkeleton()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildList(_unread, emptyMessage: 'All caught up!', emptyIcon: Icons.check_circle_outline_rounded),
                _buildList(_all),
              ],
            ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: List.generate(5, (_) => const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: SkeletonListItem(),
      )),
    );
  }

  Widget _buildList(List<Map<String, dynamic>> items, {String emptyMessage = 'No notifications', IconData emptyIcon = Icons.notifications_none_rounded}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, size: 64, color: AppColors.lightGray),
            const SizedBox(height: 16),
            Text(emptyMessage, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.gray[400])),
            if (emptyMessage == 'All caught up!') ...[
              const SizedBox(height: 8),
              Text('No unread notifications', style: Theme.of(context).textTheme.bodySmall),
            ],
          ],
        ),
      );
    }

    // Group by date
    final today = <Map<String, dynamic>>[];
    final earlier = <Map<String, dynamic>>[];
    for (final n in items) {
      final time = n['time'] as String;
      if (time.contains('min') || time.contains('hour')) {
        today.add(n);
      } else {
        earlier.add(n);
      }
    }

    return RefreshIndicator(
      onRefresh: () async => setState(() {}),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          if (today.isNotEmpty) ...[
            _buildGroupHeader('Today'),
            ...today.map((n) => _buildNotificationItem(n)),
          ],
          if (earlier.isNotEmpty) ...[
            _buildGroupHeader('Earlier'),
            ...earlier.map((n) => _buildNotificationItem(n)),
          ],
        ],
      ),
    );
  }

  Widget _buildGroupHeader(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: const Color(AppConstants.mediumGray),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> n) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isUnread = n['read'] == false;
    final color = n['color'] as Color;

    return GestureDetector(
      onTap: () => _markRead(n['id'] as String),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isUnread
              ? (isDark ? color.withOpacity(0.08) : color.withOpacity(0.04))
              : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isUnread ? color.withOpacity(0.2) : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(n['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          n['title'] as String,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: isUnread ? FontWeight.w700 : FontWeight.w600,
                          ),
                        ),
                      ),
                      if (isUnread)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                        ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    n['message'] as String,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.4),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    n['time'] as String,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
