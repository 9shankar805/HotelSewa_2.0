import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/loyalty_service.dart';

class LoyaltyProgramScreen extends StatefulWidget {
  const LoyaltyProgramScreen({Key? key}) : super(key: key);

  @override
  State<LoyaltyProgramScreen> createState() => _LoyaltyProgramScreenState();
}

class _LoyaltyProgramScreenState extends State<LoyaltyProgramScreen> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final _loyaltyService = LoyaltyService();

  Map _dashboard = {};
  bool _loading = true;

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
    setState(() => _loading = true);
    final result = await _loyaltyService.getLoyaltyDashboard();
    if (mounted) {
      setState(() {
        _dashboard = result['success'] == true ? (result['dashboard'] ?? {}) : {};
        _loading = false;
      });
    }
  }

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
        title: const Text('Loyalty Program', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'History'),
            Tab(text: 'Rewards'),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildHistoryTab(),
                _buildRewardsTab(),
              ],
            ),
    );
  }

  Widget _buildOverviewTab() {
    final balance = _dashboard['balance'];
    final points = (balance?['points'] ?? balance?['total_points'] ?? 0) as num;
    final tier = _dashboard['tier'];
    final tierName = tier?['name'] ?? 'Silver';
    final tierColor = _tierColor(tierName);
    final referralStats = _dashboard['referral_stats'];
    final referralCount = (referralStats?['total_referrals'] ?? referralStats?['count'] ?? 0) as num;

    return RefreshIndicator(
      onRefresh: _load,
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Points card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [tierColor, tierColor.withOpacity(0.7)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [BoxShadow(color: tierColor.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.star_rounded, size: 14, color: Colors.white),
                            const SizedBox(width: 4),
                            Text(tierName, style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.workspace_premium_rounded, color: Colors.white70, size: 28),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('${points.toInt()}', style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: Colors.white)),
                  const Text('Loyalty Points', style: TextStyle(fontSize: 14, color: Colors.white70, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(child: _statPill('NPR ${(points * 0.1).toStringAsFixed(0)}', 'Value')),
                      const SizedBox(width: 12),
                      Expanded(child: _statPill('$referralCount', 'Referrals')),
                    ],
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 20),
            // Tier progress
            _buildTierProgress(tier, tierName, points.toInt()),
            const SizedBox(height: 16),
            // Earn points section
            _buildSection(
              title: 'How to Earn Points',
              index: 2,
              child: Column(
                children: [
                  _earnRow(Icons.hotel_rounded, AppColors.primary, 'Hotel Booking', 'Earn 10 points per NPR 100 spent'),
                  _earnRow(Icons.people_alt_rounded, AppColors.purple, 'Refer a Friend', 'Earn 500 points per referral'),
                  _earnRow(Icons.star_rate_rounded, AppColors.gold, 'Write a Review', 'Earn 50 points per review'),
                  _earnRow(Icons.login_rounded, AppColors.success, 'Daily Login', 'Earn 5 points per day'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Redeem section
            _buildSection(
              title: 'How to Redeem',
              index: 3,
              child: Column(
                children: [
                  _earnRow(Icons.discount_rounded, AppColors.error, 'Booking Discount', '100 points = NPR 10 off'),
                  _earnRow(Icons.account_balance_wallet_rounded, AppColors.teal, 'Wallet Cashback', '500 points = NPR 50 cashback'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryTab() {
    final history = _dashboard['recent_history'];
    final list = history is List ? history : [];

    return list.isEmpty
        ? const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history_rounded, size: 56, color: AppColors.placeholder),
                SizedBox(height: 12),
                Text('No points history yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                SizedBox(height: 6),
                Text('Start booking to earn points', style: TextStyle(fontSize: 13, color: AppColors.gray)),
              ],
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (ctx, i) {
              final item = list[i];
              final isEarn = (item['type'] ?? 'earned') == 'earned';
              final pts = item['points'] ?? 0;
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
                child: Row(
                  children: [
                    Container(
                      width: 40, height: 40,
                      decoration: BoxDecoration(
                        color: (isEarn ? AppColors.success : AppColors.error).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(isEarn ? Icons.add_rounded : Icons.remove_rounded, color: isEarn ? AppColors.success : AppColors.error),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item['description'] ?? (isEarn ? 'Points Earned' : 'Points Redeemed'),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                          if ((item['date'] ?? '').isNotEmpty)
                            Text(item['date'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                        ],
                      ),
                    ),
                    Text(
                      '${isEarn ? '+' : '-'}$pts pts',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isEarn ? AppColors.success : AppColors.error),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: i * 60));
            },
          );
  }

  Widget _buildRewardsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: AppColors.goldLight, borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.emoji_events_rounded, color: AppColors.gold, size: 28),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Referral Program', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                      Text('Invite friends and earn 500 points each', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pushNamed(context, '/invite-earn'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Invite', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                ),
              ],
            ),
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          ...[
            {'title': 'NPR 50 Off Next Booking', 'points': 500, 'icon': Icons.hotel_rounded, 'color': AppColors.primary},
            {'title': 'Free Room Upgrade', 'points': 1000, 'icon': Icons.upgrade_rounded, 'color': AppColors.purple},
            {'title': 'Free Breakfast', 'points': 750, 'icon': Icons.free_breakfast_rounded, 'color': AppColors.gold},
            {'title': 'Late Check-out', 'points': 300, 'icon': Icons.access_time_rounded, 'color': AppColors.teal},
            {'title': 'NPR 200 Wallet Credit', 'points': 2000, 'icon': Icons.account_balance_wallet_rounded, 'color': AppColors.success},
          ].asMap().entries.map((entry) {
            final i = entry.key;
            final reward = entry.value;
            final color = reward['color'] as Color;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
              child: Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Icon(reward['icon'] as IconData, color: color, size: 22),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(reward['title'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                        Row(children: [
                          const Icon(Icons.stars_rounded, size: 12, color: AppColors.gold),
                          const SizedBox(width: 3),
                          Text('${reward['points']} points', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                        ]),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _showRedeemDialog(reward['title'] as String, reward['points'] as int),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    child: const Text('Redeem', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: Duration(milliseconds: i * 80)).slideY(begin: 0.1);
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildTierProgress(Map? tier, String tierName, int points) {
    final nextTier = _nextTierName(tierName);
    final progress = _tierProgress(tierName, points);
    final pointsNeeded = _pointsToNextTier(tierName, points);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(tierName, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _tierColor(tierName))),
              if (nextTier != null)
                Text(nextTier, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _tierColor(nextTier))),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: AppColors.lightGray,
              valueColor: AlwaysStoppedAnimation(_tierColor(tierName)),
              minHeight: 10,
            ),
          ),
          const SizedBox(height: 8),
          if (nextTier != null)
            Text(
              pointsNeeded > 0 ? '$pointsNeeded more points to reach $nextTier' : 'You have reached $tierName tier!',
              style: const TextStyle(fontSize: 12, color: AppColors.gray),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms);
  }

  Widget _buildSection({required String title, required int index, required Widget child}) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
            child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          ),
          const Divider(height: 1, color: AppColors.lightGray),
          Padding(padding: const EdgeInsets.all(16), child: child),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: index * 80)).slideY(begin: 0.1);
  }

  Widget _earnRow(IconData icon, Color color, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _statPill(String value, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
        ],
      ),
    );
  }

  Color _tierColor(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze': return const Color(0xFFCD7F32);
      case 'silver': return const Color(0xFF9E9E9E);
      case 'gold': return AppColors.gold;
      case 'platinum': return AppColors.purple;
      default: return AppColors.primary;
    }
  }

  String? _nextTierName(String tier) {
    switch (tier.toLowerCase()) {
      case 'bronze': return 'Silver';
      case 'silver': return 'Gold';
      case 'gold': return 'Platinum';
      default: return null;
    }
  }

  double _tierProgress(String tier, int points) {
    switch (tier.toLowerCase()) {
      case 'bronze': return (points / 1000).clamp(0.0, 1.0);
      case 'silver': return ((points - 1000) / 4000).clamp(0.0, 1.0);
      case 'gold': return ((points - 5000) / 10000).clamp(0.0, 1.0);
      default: return 1.0;
    }
  }

  int _pointsToNextTier(String tier, int points) {
    switch (tier.toLowerCase()) {
      case 'bronze': return (1000 - points).clamp(0, 1000);
      case 'silver': return (5000 - points).clamp(0, 5000);
      case 'gold': return (15000 - points).clamp(0, 15000);
      default: return 0;
    }
  }

  Future<void> _showRedeemDialog(String title, int points) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Redeem Reward', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Redeem "$title" for $points points?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await _loyaltyService.redeemPoints(points: points, redeemType: 'discount');
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(result['success'] == true ? 'Reward redeemed successfully!' : (result['message'] ?? 'Could not redeem points')),
                  behavior: SnackBarBehavior.floating,
                ));
                if (result['success'] == true) _load();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Redeem', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
