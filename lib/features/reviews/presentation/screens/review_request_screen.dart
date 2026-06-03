import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/reviews_service.dart';

class ReviewRequestScreen extends StatefulWidget {
  const ReviewRequestScreen({super.key});
  @override
  State<ReviewRequestScreen> createState() => _ReviewRequestScreenState();
}

class _ReviewRequestScreenState extends State<ReviewRequestScreen> {
  bool _autoRequestEnabled = true;
  String _sendAfter = '2h';
  String _channel = 'both';
  bool _isLoading = true;
  String? _error;

  final _messageCtrl = TextEditingController(
    text: 'Thank you for staying at {hotel_name}, {guest_name}! We hope you had a wonderful experience. Your feedback helps us improve. Please take 2 minutes to share your review: {review_link} 🙏',
  );

  List<Map<String, dynamic>> _recentCheckouts = [];
  Map<String, dynamic> _stats = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final data = await ReviewsService.getReviewRequests(token: token);
      if (mounted) {
        setState(() {
          _recentCheckouts = List<Map<String, dynamic>>.from(data['checkouts'] ?? []);
          _stats = Map<String, dynamic>.from(data['stats'] ?? {});
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  void dispose() {
    _messageCtrl.dispose();
    super.dispose();
  }

  int get _sentCount => (_stats['sent_count'] as num?)?.toInt() ?? _recentCheckouts.where((g) => g['already_requested'] == true).length;
  int get _reviewedCount => (_stats['reviewed_count'] as num?)?.toInt() ?? _recentCheckouts.where((g) => g['has_review'] == true).length;
  double get _conversionRate => _sentCount > 0 ? _reviewedCount / _sentCount : 0;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      appBar: AppBar(title: const Text('Review Requests')),
      body: _isLoading ? _skeleton() : _error != null ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.gray),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.gray)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]),
      ) : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Stats row
          Row(
            children: [
              Expanded(child: _statCard('Requests Sent', '$_sentCount', const Color(0xFF1890FF), Icons.send_rounded, isDark, card, border)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Reviews Received', '$_reviewedCount', Color(AppConstants.successGreen), Icons.star_rounded, isDark, card, border)),
              const SizedBox(width: 10),
              Expanded(child: _statCard('Conversion', '${(_conversionRate * 100).toInt()}%', Color(AppConstants.warningOrange), Icons.trending_up_rounded, isDark, card, border)),
            ],
          ),
          const SizedBox(height: 20),

          // Auto-request toggle
          Container(
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
            child: Column(
              children: [
                ListTile(
                  leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: Color(AppConstants.primaryRed).withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.auto_awesome_rounded, color: Color(AppConstants.primaryRed), size: 18)),
                  title: const Text('Auto-Request Reviews', style: TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: const Text('Automatically ask guests after checkout'),
                  trailing: Switch.adaptive(value: _autoRequestEnabled, onChanged: (v) => setState(() => _autoRequestEnabled = v), activeColor: Color(AppConstants.primaryRed)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                ),
                if (_autoRequestEnabled) ...[
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Send After Checkout', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(AppConstants.mediumGray))),
                        const SizedBox(height: 8),
                        Row(
                          children: ['30m', '1h', '2h', '6h', '24h'].map((t) {
                            final sel = _sendAfter == t;
                            return Expanded(
                              child: GestureDetector(
                                onTap: () => setState(() => _sendAfter = t),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  margin: const EdgeInsets.only(right: 6),
                                  padding: const EdgeInsets.symmetric(vertical: 8),
                                  decoration: BoxDecoration(
                                    color: sel ? Color(AppConstants.primaryRed) : (isDark ? const Color(0xFF2C2C2C) : Color(AppConstants.lightGray)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(t, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Color(AppConstants.mediumGray))),
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 14),
                        Text('Send Via', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(AppConstants.mediumGray))),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _channelChip('sms', Icons.sms_outlined, 'SMS'),
                            const SizedBox(width: 8),
                            _channelChip('email', Icons.email_outlined, 'Email'),
                            const SizedBox(width: 8),
                            _channelChip('both', Icons.all_inclusive_rounded, 'Both'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Message template
          Text('Message Template', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: TextField(
                    controller: _messageCtrl,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      hintText: 'Write your review request message...',
                    ),
                  ),
                ),
                const Divider(height: 1),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(
                    children: [
                      Text('Variables: ', style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                      ...['{guest_name}', '{hotel_name}', '{review_link}'].map((v) => Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Color(AppConstants.primaryRed).withOpacity(0.08), borderRadius: BorderRadius.circular(4)),
                        child: Text(v, style: TextStyle(fontSize: 10, color: Color(AppConstants.primaryRed), fontWeight: FontWeight.w600)),
                      )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Recent checkouts
          Row(
            children: [
              Text('Recent Checkouts', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
              const Spacer(),
              TextButton(
                onPressed: _sendToAll,
                child: const Text('Send to All', style: TextStyle(color: Color(AppConstants.primaryRed), fontWeight: FontWeight.w600, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ..._recentCheckouts.map((g) => _guestCard(g, isDark, card, border)),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon, bool isDark, Color card, Color border) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
          Text(label, style: TextStyle(fontSize: 9, color: Color(AppConstants.mediumGray)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _channelChip(String id, IconData icon, String label) {
    final sel = _channel == id;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _channel = id),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: sel ? Color(AppConstants.primaryRed).withOpacity(0.1) : Color(AppConstants.lightGray),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: sel ? Color(AppConstants.primaryRed) : Colors.transparent),
          ),
          child: Column(
            children: [
              Icon(icon, size: 16, color: sel ? Color(AppConstants.primaryRed) : Color(AppConstants.mediumGray)),
              const SizedBox(height: 2),
              Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: sel ? Color(AppConstants.primaryRed) : Color(AppConstants.mediumGray))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _guestCard(Map<String, dynamic> g, bool isDark, Color card, Color border) {
    final sent = g['already_requested'] as bool? ?? g['sent'] as bool? ?? false;
    final reviewed = g['has_review'] as bool? ?? g['reviewed'] as bool? ?? false;
    final canResend = g['can_resend'] as bool? ?? !sent;
    final initials = (g['name'] as String? ?? '?').split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: Color(AppConstants.primaryRed).withOpacity(0.1),
            child: Text(initials, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(AppConstants.primaryRed))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(g['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                Text('${g['room']} • Checked out ${g['checkout']}', style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
              ],
            ),
          ),
          if (reviewed)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: Color(AppConstants.successGreen).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFBF00)),
                  SizedBox(width: 3),
                  Text('Reviewed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(AppConstants.successGreen))),
                ],
              ),
            )
          else if (sent && !canResend)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF1890FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: const Text('Sent', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1890FF))),
            )
          else
            GestureDetector(
              onTap: () => _sendRequest(g),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(color: Color(AppConstants.primaryRed), borderRadius: BorderRadius.circular(8)),
                child: const Text('Send', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
              ),
            ),
        ],
      ),
    );
  }

  void _sendRequest(Map<String, dynamic> g) {
    setState(() { g['already_requested'] = true; g['can_resend'] = false; });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Review request sent to ${g['name']}'),
      backgroundColor: Color(AppConstants.successGreen),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _sendToAll() {
    final unsent = _recentCheckouts.where((g) {
      final sent = g['already_requested'] as bool? ?? g['sent'] as bool? ?? false;
      final reviewed = g['has_review'] as bool? ?? g['reviewed'] as bool? ?? false;
      return !sent && !reviewed;
    }).toList();
    if (unsent.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All guests already received a request'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() { for (final g in unsent) { g['already_requested'] = true; g['can_resend'] = false; } });
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('Sent to ${unsent.length} guests'),
      backgroundColor: Color(AppConstants.successGreen),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _skeleton() => ListView(padding: const EdgeInsets.all(16), children: [
    Row(children: const [Expanded(child: SkeletonLoader(height: 80, borderRadius: 12)), SizedBox(width: 10), Expanded(child: SkeletonLoader(height: 80, borderRadius: 12)), SizedBox(width: 10), Expanded(child: SkeletonLoader(height: 80, borderRadius: 12))]),
    const SizedBox(height: 16),
    const SkeletonLoader(height: 120, borderRadius: 14),
    const SizedBox(height: 16),
    const SkeletonLoader(height: 100, borderRadius: 14),
    const SizedBox(height: 16),
    ...List.generate(3, (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonLoader(height: 72, borderRadius: 14))),
  ]);
}
