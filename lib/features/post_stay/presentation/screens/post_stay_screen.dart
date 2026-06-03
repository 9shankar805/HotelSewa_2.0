import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class PostStayScreen extends StatefulWidget {
  const PostStayScreen({Key? key}) : super(key: key);

  @override
  State<PostStayScreen> createState() => _PostStayScreenState();
}

class _PostStayScreenState extends State<PostStayScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _campaigns = [];
  List<Map<String, dynamic>> _logs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final results = await Future.wait([
        ApiService.get('/hotel-owner/post-stay/campaigns', token: token),
        ApiService.get('/hotel-owner/post-stay/logs', token: token),
      ]);
      if (results[0]['success'] == true) {
        final data = results[0]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['campaigns'] ?? []) : []);
        _campaigns = List<Map<String, dynamic>>.from(raw);
      }
      if (results[1]['success'] == true) {
        final data = results[1]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['logs'] ?? []) : []);
        _logs = List<Map<String, dynamic>>.from(raw);
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray), onPressed: () => Navigator.pop(context)),
        title: const Text('Post-Stay Engagement', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: _showCreateDialog),
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Campaigns'), Tab(text: 'Delivery Logs')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [_buildCampaignsTab(), _buildLogsTab()],
            ),
    );
  }

  Widget _buildCampaignsTab() {
    if (_campaigns.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.campaign_rounded, size: 40, color: AppColors.purple)),
        const SizedBox(height: 20),
        const Text('No Campaigns', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        const Text('Create post-stay email campaigns to re-engage guests after checkout.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
      ])));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _campaigns.length,
      itemBuilder: (_, i) {
        final c = _campaigns[i];
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              Container(width: 44, height: 44, decoration: BoxDecoration(color: AppColors.purpleLight, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.email_rounded, color: AppColors.purple, size: 22)),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(c['name'] ?? '', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                Text('Trigger: ${c['trigger_days_after'] ?? 0} days after checkout', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
              ])),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  if (action == 'delete') {
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.delete('/hotel-owner/post-stay/campaigns/${c['id']}', token: token);
                    _load();
                  }
                },
                itemBuilder: (_) => [const PopupMenuItem(value: 'delete', child: Text('Delete', style: TextStyle(color: AppColors.error)))],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildLogsTab() {
    if (_logs.isEmpty) {
      return const Center(child: Text('No delivery logs yet', style: TextStyle(color: AppColors.gray)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _logs.length,
      itemBuilder: (_, i) {
        final log = _logs[i];
        final status = log['status'] ?? 'sent';
        final statusColor = status == 'delivered' ? AppColors.success : status == 'failed' ? AppColors.error : AppColors.info;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(log['campaign_name'] ?? '', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                Text(log['sent_at'] ?? '', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text(status.toUpperCase(), style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: statusColor))),
            ],
          ),
        );
      },
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final subjectCtrl = TextEditingController();
    final bodyCtrl = TextEditingController();
    final daysCtrl = TextEditingController(text: '1');
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Create Campaign', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              _field('Campaign Name', nameCtrl),
              const SizedBox(height: 12),
              _field('Days After Checkout', daysCtrl, keyboardType: TextInputType.number),
              const SizedBox(height: 12),
              _field('Email Subject', subjectCtrl),
              const SizedBox(height: 12),
              _field('Email Body', bodyCtrl, maxLines: 5),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('authToken');
                  await ApiService.post('/hotel-owner/post-stay/campaigns', data: {'name': nameCtrl.text, 'trigger_days_after': int.tryParse(daysCtrl.text) ?? 1, 'subject': subjectCtrl.text, 'body': bodyCtrl.text}, token: token);
                  _load();
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Create Campaign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl, {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
      ),
    );
  }
}
