import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class InviteEarnScreen extends StatefulWidget {
  const InviteEarnScreen({Key? key}) : super(key: key);

  @override
  State<InviteEarnScreen> createState() => _InviteEarnScreenState();
}

class _InviteEarnScreenState extends State<InviteEarnScreen> {
  String _referralCode = '';
  int _totalEarned = 0;
  int _referralCount = 0;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final codeResp = await ApiService.get(ApiConfig.loyaltyReferralCodeEndpoint, token: token);
      if (codeResp['success'] == true) {
        final data = codeResp['data'];
        if (data is Map) {
          setState(() {
            _referralCode = data['code']?.toString() ?? data['referral_code']?.toString() ?? '';
            _totalEarned = (data['total_earned'] as num?)?.toInt() ?? 0;
            _referralCount = (data['referral_count'] as num?)?.toInt() ?? 0;
          });
        }
      }

      // Fallback: generate from user data
      if (_referralCode.isEmpty) {
        final name = prefs.getString('userName') ?? '';
        final safeName = name.toUpperCase().replaceAll(' ', '');
        final prefix = safeName.isNotEmpty ? safeName.substring(0, safeName.length.clamp(0, 4)) : 'USER';
        _referralCode = 'HS$prefix${DateTime.now().year}';
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  void _copyCode() {
    Clipboard.setData(ClipboardData(text: _referralCode));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Referral code copied!'), behavior: SnackBarBehavior.floating, backgroundColor: AppColors.success),
    );
  }

  void _share() {
    final text =
        '🏨 Join HotelSewa and get Rs.500 off your first booking!\n\n'
        'Use my referral code: *$_referralCode*\n\n'
        'Download the app: https://hotelsewa.com';
    Share.share(text, subject: 'Join HotelSewa & earn rewards!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text('Invite & Earn', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _load,
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // Hero banner
                    Container(
                      margin: const EdgeInsets.all(16),
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.primaryShadow,
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.card_giftcard_rounded, size: 56, color: Colors.white),
                          const SizedBox(height: 16),
                          const Text('Invite Friends & Earn', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white)),
                          const SizedBox(height: 8),
                          const Text('Get Rs.500 for every friend who completes their first booking', style: TextStyle(fontSize: 14, color: Colors.white70), textAlign: TextAlign.center),
                          const SizedBox(height: 20),
                          // Stats row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _statChip('Rs.$_totalEarned', 'Earned'),
                              Container(width: 1, height: 36, color: Colors.white30),
                              _statChip('$_referralCount', 'Referrals'),
                              Container(width: 1, height: 36, color: Colors.white30),
                              _statChip('Rs.500', 'Per Invite'),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn().slideY(begin: 0.1),

                    // Referral code card
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('YOUR REFERRAL CODE', style: TextStyle(fontSize: 11, color: AppColors.gray, letterSpacing: 1.2, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.06),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.primary.withOpacity(0.2)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(_referralCode.isEmpty ? '...' : _referralCode,
                                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.primary, letterSpacing: 3)),
                                GestureDetector(
                                  onTap: _copyCode,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                                      Icon(Icons.copy_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text('Copy', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w700)),
                                    ]),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: _share,
                              icon: const Icon(Icons.share_rounded, size: 18, color: Colors.white),
                              label: const Text('Share with Friends', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: 80.ms).fadeIn().slideY(begin: 0.1),

                    // How it works
                    Container(
                      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('How it works', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                          const SizedBox(height: 16),
                          _step('1', Icons.share_rounded, AppColors.primary, 'Share your code', 'Send your referral code to friends'),
                          _step('2', Icons.person_add_rounded, AppColors.success, 'Friend signs up', 'They register using your code'),
                          _step('3', Icons.hotel_rounded, const Color(0xFF3B82F6), 'Friend books', 'They complete their first booking'),
                          _step('4', Icons.account_balance_wallet_rounded, const Color(0xFFFFB800), 'You earn Rs.500', 'Credited to your wallet instantly', isLast: true),
                        ],
                      ),
                    ).animate(delay: 160.ms).fadeIn().slideY(begin: 0.1),

                    // Terms
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Text(
                        '* Reward credited after friend\'s first booking is completed. Valid for new users only. HotelSewa reserves the right to modify terms.',
                        style: const TextStyle(fontSize: 11, color: AppColors.placeholder, height: 1.5),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _statChip(String value, String label) => Column(children: [
    Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
    Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
  ]);

  Widget _step(String num, IconData icon, Color color, String title, String sub, {bool isLast = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Center(child: Text(num, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color))),
          ),
          if (!isLast) Container(width: 2, height: 32, color: AppColors.lightGray),
        ]),
        const SizedBox(width: 14),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
            ]),
          ),
        ),
      ],
    );
  }
}
