import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/reviews_service.dart';
import 'review_request_screen.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _reviews = [];
  String? _error;
  String _sortBy = 'recent';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        ReviewsService.setToken(token);
        final data = await ReviewsService.getReviews();
        setState(() { _reviews = data; _isLoading = false; });
      } else {
        setState(() { _isLoading = false; });
      }
    } catch (e) {
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _avgRating {
    if (_reviews.isEmpty) return 0;
    return _reviews.map((r) => (r['rating'] as num).toInt()).reduce((a, b) => a + b) / _reviews.length;
  }

  Map<int, int> get _distribution {
    final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final rating = (r['rating'] as num).toInt();
      dist[rating] = (dist[rating] ?? 0) + 1;
    }
    return dist;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reviews & Ratings'),
        actions: [
          IconButton(
            icon: const Icon(Icons.send_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReviewRequestScreen())),
            tooltip: 'Request Reviews',
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded),
            onPressed: _showSortOptions,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(AppConstants.primaryRed),
          labelColor: const Color(AppConstants.primaryRed),
          unselectedLabelColor: const Color(AppConstants.mediumGray),
          indicatorSize: TabBarIndicatorSize.label,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Pending Reply'),
            Tab(text: 'Replied'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildSkeleton()
          : _error != null
              ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
              : Column(
              children: [
                _buildRatingSummary(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildReviewList(_reviews),
                      _buildReviewList(_reviews.where((r) => r['replied'] == false).toList()),
                      _buildReviewList(_reviews.where((r) => r['replied'] == true).toList()),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const SkeletonLoader(height: 160, borderRadius: 16),
        const SizedBox(height: 16),
        ...List.generate(3, (_) => const Padding(
          padding: EdgeInsets.only(bottom: 12),
          child: SkeletonLoader(height: 120, borderRadius: 14),
        )),
      ],
    );
  }

  Widget _buildRatingSummary() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avg = _avgRating;
    final dist = _distribution;
    final total = _reviews.length;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
      ),
      child: Row(
        children: [
          // Big rating number
          Column(
            children: [
              Text(
                avg.toStringAsFixed(1),
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: const Color(AppConstants.primaryRed),
                  fontWeight: FontWeight.w800,
                ),
              ),
              _buildStars(avg.round(), size: 16),
              const SizedBox(height: 4),
              Text('$total reviews', style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          const SizedBox(width: 20),
          const VerticalDivider(width: 1),
          const SizedBox(width: 20),
          // Distribution bars
          Expanded(
            child: Column(
              children: [5, 4, 3, 2, 1].map((star) {
                final count = dist[star] ?? 0;
                final fraction = total > 0 ? count / total : 0.0;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Row(
                    children: [
                      Text('$star', style: Theme.of(context).textTheme.labelSmall),
                      const SizedBox(width: 4),
                      const Icon(Icons.star_rounded, size: 10, color: Color(0xFFFFBF00)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: fraction,
                            backgroundColor: const Color(AppConstants.lightGray),
                            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFFFBF00)),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      SizedBox(
                        width: 20,
                        child: Text('$count', style: Theme.of(context).textTheme.labelSmall, textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewList(List<Map<String, dynamic>> reviews) {
    if (reviews.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.rate_review_outlined, size: 56, color: AppColors.lightGray),
            const SizedBox(height: 16),
            Text('No reviews here', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: AppColors.gray[400])),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        itemCount: reviews.length,
        itemBuilder: (context, index) => _buildReviewCard(reviews[index]),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rating = (review['rating'] as num?)?.toInt() ?? 0;
    final replied = review['replied'] == true;
    final guestName = review['guestName']?.toString() ?? review['guest_name']?.toString() ?? review['user']?['name']?.toString() ?? 'Guest';
    final initials = guestName.split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();
    final roomType = review['roomType']?.toString() ?? review['room_type']?.toString() ?? '';
    final comment = review['comment']?.toString() ?? review['review']?.toString() ?? '';
    final date = review['date']?.toString() ?? review['created_at']?.toString() ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(AppConstants.primaryRed).withOpacity(0.1),
                child: Text(initials, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(AppConstants.primaryRed))),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(review['guestName']?.toString() ?? 'Guest', style: Theme.of(context).textTheme.titleSmall),
                    Text(review['roomType']?.toString() ?? '', style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStars(rating, size: 13),
                  const SizedBox(height: 2),
                  Text(review['date']?.toString() ?? '', style: Theme.of(context).textTheme.labelSmall),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(review['comment']?.toString() ?? '', style: Theme.of(context).textTheme.bodyMedium?.copyWith(height: 1.5)),
          const SizedBox(height: 12),
          Row(
            children: [
              if (replied)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(AppConstants.successGreen).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.check_circle_rounded, size: 12, color: Color(AppConstants.successGreen)),
                      const SizedBox(width: 4),
                      Text('Replied', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(AppConstants.successGreen))),
                    ],
                  ),
                )
              else
                OutlinedButton.icon(
                  onPressed: () => _showReplyDialog(review),
                  icon: const Icon(Icons.reply_rounded, size: 14),
                  label: const Text('Reply', style: TextStyle(fontSize: 12)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    side: const BorderSide(color: Color(AppConstants.primaryRed)),
                    foregroundColor: const Color(AppConstants.primaryRed),
                  ),
                ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.thumb_up_outlined, size: 16),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: const Color(AppConstants.mediumGray),
              ),
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(Icons.flag_outlined, size: 16),
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                color: const Color(AppConstants.mediumGray),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int rating, {double size = 14}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) => Icon(
        i < rating ? Icons.star_rounded : Icons.star_outline_rounded,
        color: const Color(0xFFFFBF00),
        size: size,
      )),
    );
  }

  void _showSortOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Sort by', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),
            ...['recent', 'highest', 'lowest'].map((s) {
              final labels = {'recent': 'Most Recent', 'highest': 'Highest Rating', 'lowest': 'Lowest Rating'};
              return ListTile(
                title: Text(labels[s]!),
                leading: Radio<String>(
                  value: s,
                  groupValue: _sortBy,
                  activeColor: const Color(AppConstants.primaryRed),
                  onChanged: (v) {
                    setState(() => _sortBy = v!);
                    Navigator.pop(context);
                  },
                ),
                onTap: () {
                  setState(() => _sortBy = s);
                  Navigator.pop(context);
                },
              );
            }),
          ],
        ),
      ),
    );
  }

  void _showReplyDialog(Map<String, dynamic> review) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Reply to ${review['guestName']}'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Write your response...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final token = Provider.of<AuthProvider>(context, listen: false).token;
                if (token != null) ReviewsService.setToken(token);
                await ReviewsService().submitReply(review['id'] as String, controller.text.trim());
                setState(() => review['replied'] = true);
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reply sent successfully'), backgroundColor: Color(AppConstants.successGreen)),
                );
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to send reply: $e'), backgroundColor: Color(AppConstants.errorRed)),
                );
              }
            },
            child: const Text('Send Reply'),
          ),
        ],
      ),
    );
  }
}
