import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/loyalty_service.dart';
/// Loyalty screen — redirects to profile loyalty program page.
/// Used by the owner navigation as a re-export.
class LoyaltyScreen extends StatefulWidget {
  const LoyaltyScreen({super.key});
  @override
  State<LoyaltyScreen> createState() => _LoyaltyScreenState();
}

class _LoyaltyScreenState extends State<LoyaltyScreen> {
  final LoyaltyService _service = LoyaltyService();
  bool _loading = true;
  Map<String, dynamic> _dashboard = {};

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getLoyaltyDashboard();
    if (result['success'] == true && mounted) {
      setState(() { _dashboard = Map<String, dynamic>.from(result['dashboard'] ?? {}); _loading = false; });
    } else {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = _dashboard['balance'];
    final points = (balance?['points'] ?? 0) as num;
    final tier = _dashboard['tier'];
    final tierName = tier?['name']?.toString() ?? 'Bronze';
    final history = _dashboard['recent_history'];
    final historyList = history is List ? history : [];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray), onPressed: () => Navigator.pop(context)),
        title: const Text('Loyalty Program', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load)],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load, color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(children: [
                  // Points card
                  Container(
                    width: double.infinity, padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(gradient: AppColors.premiumGradient, borderRadius: BorderRadius.circular(24)),
                    child: Column(children: [
                      const Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 40),
                      const SizedBox(height: 12),
                      Text('$points', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900)),
                      const Text('Loyalty Points', style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                        child: Text(tierName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                      ),
                    ]),
                  ),
                  const SizedBox(height: 20),
                  // Recent history
                  if (historyList.isNotEmpty) ...[
                    const Row(children: [
                      Text('Recent Activity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                    ]),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                      child: Column(
                        children: historyList.take(5).toList().asMap().entries.map((e) {
                          final item = e.value as Map<String, dynamic>;
                          final type = item['type']?.toString() ?? 'earned';
                          final pts = (item['points'] ?? 0) as num;
                          final isEarned = type == 'earned' || pts >= 0;
                          return ListTile(
                            leading: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: (isEarned ? AppColors.success : AppColors.error).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: Icon(isEarned ? Icons.add_rounded : Icons.remove_rounded, color: isEarned ? AppColors.success : AppColors.error),
                            ),
                            title: Text(item['description']?.toString() ?? type, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGray)),
                            subtitle: Text(item['created_at']?.toString().split('T')[0] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                            trailing: Text('${isEarned ? '+' : ''}$pts pts', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isEarned ? AppColors.success : AppColors.error)),
                          );
                        }).toList(),
                      ),
                    ),
                  ] else
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                      child: const Column(children: [
                        Icon(Icons.workspace_premium_outlined, size: 48, color: AppColors.placeholder),
                        SizedBox(height: 12),
                        Text('No activity yet', style: TextStyle(fontSize: 15, color: AppColors.gray, fontWeight: FontWeight.w600)),
                        SizedBox(height: 6),
                        Text('Earn points with every booking', style: TextStyle(fontSize: 12, color: AppColors.placeholder)),
                      ]),
                    ),
                ]),
              ),
            ),
    );
  }
}
