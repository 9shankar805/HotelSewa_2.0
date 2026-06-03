import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class ReputationScreen extends StatefulWidget {
  const ReputationScreen({Key? key}) : super(key: key);

  @override
  State<ReputationScreen> createState() => _ReputationScreenState();
}

class _ReputationScreenState extends State<ReputationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _reviews = [];

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
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final results = await Future.wait([
        ApiService.get(ApiConfig.ownerReputationEndpoint, token: token),
        ApiService.get(ApiConfig.ownerReputationReviewsEndpoint, token: token),
      ]);
      if (results[0]['success'] == true) {
        final data = results[0]['data'];
        _summary = data is Map ? Map<String, dynamic>.from(data) : {};
      }
      if (results[1]['success'] == true) {
        final data = results[1]['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['reviews'] ?? []) : []);
        _reviews = List<Map<String, dynamic>>.from(raw);
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load reputation data'; _loading = false; });
    }
  }

  Future<void> _respond(int id, String response) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    await ApiService.post('${ApiConfig.ownerReputationReviewRespondEndpoint}/$id/respond', data: {'response': response}, token: token);
    _load();
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
        title: const Text('Reputation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Reviews')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [_buildOverviewTab(), _buildReviewsTab()],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final avgRating = (_summary['average_rating'] as num?)?.toDouble() ?? 0;
    final totalReviews = _summary['total_reviews'] ?? 0;
    final sentiment = _summary['sentiment'] ?? 'neutral';
    final sentimentColor = sentiment == 'positive' ? AppColors.success : sentiment == 'negative' ? AppColors.error : AppColors.warning;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(avgRating.toStringAsFixed(1), style: const TextStyle(fontSize: 56, fontWeight: FontWeight.w900, color: Colors.white)),
                    const Padding(padding: EdgeInsets.only(bottom: 10), child: Text('/5', style: TextStyle(fontSize: 20, color: Colors.white54))),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) => Icon(i < avgRating.round() ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.gold, size: 24)),
                ),
                const SizedBox(height: 12),
                Text('$totalReviews reviews', style: const TextStyle(fontSize: 14, color: Colors.white70)),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(color: sentimentColor.withOpacity(0.2), borderRadius: BorderRadius.circular(20), border: Border.all(color: sentimentColor.withOpacity(0.5))),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(sentiment == 'positive' ? Icons.sentiment_satisfied_rounded : sentiment == 'negative' ? Icons.sentiment_dissatisfied_rounded : Icons.sentiment_neutral_rounded, color: sentimentColor, size: 18),
                    const SizedBox(width: 6),
                    Text('${sentiment[0].toUpperCase()}${sentiment.substring(1)} Sentiment', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sentimentColor)),
                  ]),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Rating breakdown
          if (_summary['rating_breakdown'] != null)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Rating Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  const SizedBox(height: 16),
                  ...List.generate(5, (i) {
                    final star = 5 - i;
                    final count = (_summary['rating_breakdown'] as Map?)?['$star'] ?? 0;
                    final total = totalReviews > 0 ? totalReviews : 1;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(children: [
                        Text('$star', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                        const Icon(Icons.star_rounded, size: 14, color: AppColors.gold),
                        const SizedBox(width: 8),
                        Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(4), child: LinearProgressIndicator(value: count / total, backgroundColor: AppColors.lightGray, color: AppColors.gold, minHeight: 8))),
                        const SizedBox(width: 8),
                        Text('$count', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                      ]),
                    );
                  }),
                ],
              ),
            ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildReviewsTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ..._reviews.map((r) => _buildReviewCard(r)),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _showImportDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Import External Review'),
          style: OutlinedButton.styleFrom(foregroundColor: AppColors.primary, side: const BorderSide(color: AppColors.primary), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
        ),
        const SizedBox(height: 80),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = review['rating'] as int? ?? 0;
    final hasResponse = (review['response'] ?? '').isNotEmpty;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(backgroundColor: AppColors.infoLight, child: Text((review['reviewer'] ?? review['guest_name'] ?? 'G')[0].toUpperCase(), style: const TextStyle(color: AppColors.info, fontWeight: FontWeight.w700))),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(review['reviewer'] ?? review['guest_name'] ?? 'Guest', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                Text(review['platform'] ?? 'HotelSewa', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
              ])),
              Row(children: List.generate(5, (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, size: 14, color: AppColors.gold))),
            ],
          ),
          const SizedBox(height: 10),
          Text(review['review'] ?? '', style: const TextStyle(fontSize: 13, color: AppColors.darkGray, height: 1.5)),
          if (hasResponse) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(10)),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('Your Response', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.info)),
                const SizedBox(height: 4),
                Text(review['response'], style: const TextStyle(fontSize: 12, color: AppColors.darkGray)),
              ]),
            ),
          ] else ...[
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () => _showRespondDialog(review['id']),
              icon: const Icon(Icons.reply_rounded, size: 16, color: AppColors.primary),
              label: const Text('Respond', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
            ),
          ],
        ],
      ),
    );
  }

  void _showRespondDialog(int id) {
    final responseCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Respond to Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(controller: responseCtrl, maxLines: 4, decoration: InputDecoration(hintText: 'Write your response...', filled: true, fillColor: AppColors.surfaceVariant, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () { Navigator.pop(context); _respond(id, responseCtrl.text); },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Post Response', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showImportDialog() {
    final platformCtrl = TextEditingController();
    final reviewCtrl = TextEditingController();
    final reviewerCtrl = TextEditingController();
    double rating = 4;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: StatefulBuilder(builder: (ctx, setModalState) => Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Import External Review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(controller: platformCtrl, decoration: InputDecoration(hintText: 'Platform (e.g. TripAdvisor)', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 10),
              TextField(controller: reviewerCtrl, decoration: InputDecoration(hintText: 'Reviewer name', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 10),
              TextField(controller: reviewCtrl, maxLines: 3, decoration: InputDecoration(hintText: 'Review text', filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 10),
              Row(children: [
                const Text('Rating: ', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                ...List.generate(5, (i) => GestureDetector(
                  onTap: () => setModalState(() => rating = (i + 1).toDouble()),
                  child: Icon(i < rating ? Icons.star_rounded : Icons.star_outline_rounded, color: AppColors.gold, size: 28),
                )),
              ]),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.ownerReputationReviewsEndpoint, data: {'platform': platformCtrl.text, 'rating': rating.toInt(), 'review': reviewCtrl.text, 'reviewer': reviewerCtrl.text, 'date': DateTime.now().toIso8601String().substring(0, 10)}, token: token);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Import Review', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        )),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry', style: TextStyle(color: Colors.white))),
    ])));
  }
}
