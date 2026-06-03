import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class SplitPaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const SplitPaymentScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<SplitPaymentScreen> createState() => _SplitPaymentScreenState();
}

class _SplitPaymentScreenState extends State<SplitPaymentScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _mySplits = [];
  bool _creating = false;

  final _bookingIdCtrl = TextEditingController();
  final List<Map<String, TextEditingController>> _participants = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _addParticipant();
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _bookingIdCtrl.dispose();
    for (final p in _participants) {
      p['email']?.dispose();
      p['amount']?.dispose();
    }
    super.dispose();
  }

  void _addParticipant() {
    _participants.add({'email': TextEditingController(), 'amount': TextEditingController()});
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.splitPaymentMySplitsEndpoint, token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['splits'] ?? []) : []);
        setState(() => _mySplits = List<Map<String, dynamic>>.from(raw));
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _create() async {
    setState(() => _creating = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final participants = _participants
          .where((p) => (p['email']?.text ?? '').isNotEmpty)
          .map((p) => {'email': p['email']!.text, 'amount': double.tryParse(p['amount']!.text) ?? 0})
          .toList();
      final response = await ApiService.post(
        ApiConfig.splitPaymentCreateEndpoint,
        data: {'booking_id': int.tryParse(_bookingIdCtrl.text) ?? 0, 'participants': participants},
        token: token,
      );
      if (response['success'] == true) {
        final splitToken = response['data']?['split_token'] ?? '';
        _load();
        if (mounted) {
          _tabController.animateTo(1);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Split created! Token: $splitToken'), backgroundColor: AppColors.success),
          );
        }
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message'] ?? 'Failed to create split'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _creating = false);
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
        title: const Text('Split Payment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Create Split'), Tab(text: 'My Splits')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildCreateTab(), _buildMySplitsTab()],
      ),
    );
  }

  Widget _buildCreateTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.call_split_rounded, color: Colors.white, size: 26)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Split the Bill', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Invite friends to pay their share directly.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Booking ID', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          TextField(
            controller: _bookingIdCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Enter booking ID',
              prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.gray),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Participants', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              TextButton.icon(
                onPressed: () => setState(() => _addParticipant()),
                icon: const Icon(Icons.add_rounded, size: 18, color: AppColors.primary),
                label: const Text('Add', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 8),

          ..._participants.asMap().entries.map((entry) {
            final i = entry.key;
            final p = entry.value;
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
              child: Column(
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppColors.purpleLight,
                        child: Text('${i + 1}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.purple)),
                      ),
                      const SizedBox(width: 10),
                      const Text('Participant', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                      const Spacer(),
                      if (_participants.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline_rounded, color: AppColors.error, size: 20),
                          onPressed: () => setState(() => _participants.removeAt(i)),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: p['email'],
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gray, size: 18),
                      filled: true, fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: p['amount'],
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Amount (NPR)',
                      prefixIcon: const Icon(Icons.attach_money_rounded, color: AppColors.gray, size: 18),
                      filled: true, fillColor: AppColors.surfaceVariant,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                  ),
                ],
              ),
            );
          }),

          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _creating ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _creating
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Create Split', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildMySplitsTab() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_mySplits.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.call_split_rounded, size: 40, color: AppColors.purple)),
        const SizedBox(height: 20),
        const Text('No Splits Yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        const Text('Create a split payment to share booking costs with friends.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
      ])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _mySplits.length,
      itemBuilder: (_, i) {
        final s = _mySplits[i];
        final token = s['split_token'] ?? s['token'] ?? '';
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(12)),
                    child: const Icon(Icons.call_split_rounded, color: AppColors.purple, size: 22)),
                  const SizedBox(width: 12),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Booking #${s['booking_id'] ?? ''}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                    Text('${(s['participants'] as List?)?.length ?? 0} participants', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                  ])),
                  IconButton(
                    icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.gray),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: token));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Token copied'), backgroundColor: AppColors.success));
                    },
                  ),
                ],
              ),
              if (token.isNotEmpty) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(8)),
                  child: Text('Token: $token', style: const TextStyle(fontSize: 11, fontFamily: 'monospace', color: AppColors.gray)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
