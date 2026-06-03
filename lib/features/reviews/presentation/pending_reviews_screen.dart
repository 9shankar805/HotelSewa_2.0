import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';
import 'review_submission_screen.dart';

class PendingReviewsScreen extends StatefulWidget {
  const PendingReviewsScreen({Key? key}) : super(key: key);

  @override
  State<PendingReviewsScreen> createState() => _PendingReviewsScreenState();
}

class _PendingReviewsScreenState extends State<PendingReviewsScreen> {
  List<Map<String, dynamic>> _pending = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.myPendingReviewsEndpoint, token: token);
      if (response['success'] == true) {
        final raw = response['data'];
        List items = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['bookings'] ?? raw['reviews'] ?? []) : []);
        setState(() {
          _pending = items.map<Map<String, dynamic>>((b) => {
            'bookingId': b['id']?.toString() ?? b['booking_id']?.toString() ?? '',
            'hotelName': b['hotel']?['name'] ?? b['hotel_name'] ?? 'Hotel',
            'hotelImage': _parseImage(b['hotel']?['image'] ?? b['hotel']?['images']),
            'city': b['hotel']?['city'] ?? b['city'] ?? '',
            'roomType': b['room_type']?['name'] ?? b['room_name'] ?? 'Room',
            'checkIn': b['check_in_date']?.toString().split('T')[0] ?? '',
            'checkOut': b['check_out_date']?.toString().split('T')[0] ?? '',
            'amount': (b['total_price'] ?? b['total_amount'] ?? 0) as num,
            'hotelId': b['hotel']?['id']?.toString() ?? b['hotel_id']?.toString() ?? '',
          }).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load pending reviews'; _loading = false; });
    }
  }

  String _parseImage(dynamic images) {
    if (images is String && images.startsWith('http')) return images;
    if (images is List && images.isNotEmpty) {
      final first = images[0];
      return first is Map ? (first['url']?.toString() ?? '') : first.toString();
    }
    return '';
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
        title: const Text('Pending Reviews', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.placeholder),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.gray)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
                ]))
              : _pending.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(40),
                        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
                            child: const Icon(Icons.check_circle_outline_rounded, size: 40, color: AppColors.success)),
                          const SizedBox(height: 16),
                          const Text('All caught up!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                          const SizedBox(height: 8),
                          const Text('You have no pending reviews. All your recent stays have been reviewed.',
                              style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.4), textAlign: TextAlign.center),
                        ]),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _load,
                      color: AppColors.primary,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _pending.length,
                        itemBuilder: (_, i) => _buildCard(_pending[i], i),
                      ),
                    ),
    );
  }

  Widget _buildCard(Map<String, dynamic> item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: InkWell(
        onTap: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ReviewSubmissionScreen(arguments: {
            'hotel': {
              'id': item['hotelId'],
              'name': item['hotelName'],
              'image': item['hotelImage'],
              'city': item['city'],
            },
            'booking': {
              'id': item['bookingId'],
              'check_in_date': item['checkIn'],
              'check_out_date': item['checkOut'],
            }
          }),
        )).then((_) => _load()),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item['hotelImage']?.isNotEmpty == true
                    ? Image.network(item['hotelImage'], width: 70, height: 70, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder())
                    : _imagePlaceholder(),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item['hotelName'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (item['city']?.isNotEmpty == true)
                    Text(item['city'], style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                  const SizedBox(height: 4),
                  Text('${item['roomType']} · ${item['checkIn']} – ${item['checkOut']}',
                      style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
                  const SizedBox(height: 6),
                  Row(children: [
                    ...List.generate(5, (i) => const Icon(Icons.star_outline_rounded, size: 16, color: AppColors.gold)),
                    const SizedBox(width: 6),
                    const Text('Tap to review', style: TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ),
              const Icon(Icons.chevron_right_rounded, color: AppColors.placeholder),
            ],
          ),
        ),
      ),
    ).animate(delay: (index * 60).ms).fadeIn().slideY(begin: 0.05);
  }

  Widget _imagePlaceholder() => Container(
    width: 70, height: 70, color: AppColors.surfaceVariant,
    child: const Icon(Icons.hotel_rounded, color: AppColors.placeholder, size: 28),
  );
}
