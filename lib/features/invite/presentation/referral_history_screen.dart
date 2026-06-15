import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/loyalty_service.dart';

class ReferralHistoryScreen extends StatefulWidget {
  const ReferralHistoryScreen({Key? key}) : super(key: key);

  @override
  State<ReferralHistoryScreen> createState() => _ReferralHistoryScreenState();
}

class _ReferralHistoryScreenState extends State<ReferralHistoryScreen> {
  final _loyaltyService = LoyaltyService();
  List _history = [];
  Map _stats = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final results = await Future.wait([
      _loyaltyService.getReferralStats(),
      _loyaltyService.getLoyaltyHistory(type: 'earned'),
    ]);
    if (mounted) {
      final statsResult = results[0];
      final historyResult = results[1];
      final raw = historyResult['history'];
      final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? []) : []);
      // Filter for referral-type entries
      final referrals = list.where((item) {
        final type = (item['type'] ?? '').toString().toLowerCase();
        final desc = (item['description'] ?? '').toString().toLowerCase();
        return type.contains('referral') || desc.contains('referral') || desc.contains('refer');
      }).toList();
      setState(() {
        _stats = statsResult['success'] == true ? (statsResult['stats'] ?? {}) : {};
        _history = referrals.isNotEmpty ? referrals : list;
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
        title: const Text('Referral History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            onPressed: () => Navigator.pushNamed(context, '/invite-earn'),
            tooltip: 'Invite Friends',
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _buildStatsRow(),
                    const SizedBox(height: 20),
                    _buildInviteCard(),
                    const SizedBox(height: 20),
                    _buildHistoryList(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildStatsRow() {
    final total = (_stats['total_referrals'] ?? _stats['count'] ?? 0) as num;
    final totalPoints = (_stats['total_points_earned'] ?? _stats['points'] ?? 0) as num;
    final pending = (_stats['pending_referrals'] ?? 0) as num;
    final completed = (_stats['completed_referrals'] ?? 0) as num;

    return Row(
      children: [
        Expanded(child: _statCard('${total.toInt()}', 'Total\nReferrals', Icons.people_alt_rounded, AppColors.primary)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('${totalPoints.toInt()}', 'Points\nEarned', Icons.stars_rounded, AppColors.gold)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('${completed.toInt()}', 'Completed', Icons.check_circle_rounded, AppColors.success)),
        const SizedBox(width: 10),
        Expanded(child: _statCard('${pending.toInt()}', 'Pending', Icons.hourglass_top_rounded, AppColors.warning)),
      ],
    ).animate().fadeIn().slideY(begin: 0.1);
  }

  Widget _statCard(String value, String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color)),
          Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildInviteCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.primaryShadow,
      ),
      child: Row(
        children: [
          const Icon(Icons.card_giftcard_rounded, color: Colors.white, size: 36),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text('Earn 500 Points per Referral', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                SizedBox(height: 2),
                Text('Invite friends and earn when they book!', style: TextStyle(fontSize: 12, color: Colors.white70)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/invite-earn'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: AppColors.primary,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Invite', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1);
  }

  Widget _buildHistoryList() {
    if (_history.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
        child: Column(
          children: [
            const Icon(Icons.person_add_outlined, size: 52, color: AppColors.placeholder),
            const SizedBox(height: 12),
            const Text('No referrals yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
            const SizedBox(height: 6),
            const Text('Share your referral code and start earning', style: TextStyle(fontSize: 13, color: AppColors.gray), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/invite-earn'),
              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
              label: const Text('Invite Friends', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Points History', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        const SizedBox(height: 12),
        ..._history.asMap().entries.map((entry) {
          final i = entry.key;
          final item = entry.value;
          final pts = item['points'] ?? 0;
          final isEarned = (item['type'] ?? 'earned') != 'redeemed';
          final description = item['description'] ?? 'Points earned';
          final date = item['date'] ?? item['created_at'] ?? '';
          final friendName = item['friend_name'] ?? item['referred_user'] ?? '';

          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
            child: Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.success.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_rounded, color: AppColors.success, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(friendName.isNotEmpty ? friendName : description,
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                      if (friendName.isNotEmpty)
                        Text(description, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                      if (date.isNotEmpty)
                        Text(date, style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('+$pts pts', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.success)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)),
                      child: const Text('Earned', style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: i * 60)).slideX(begin: 0.1);
        }).toList(),
      ],
    );
  }
}
