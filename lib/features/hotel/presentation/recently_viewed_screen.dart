import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';
import '../../../core/services/hotel_service.dart';

class RecentlyViewedScreen extends StatefulWidget {
  const RecentlyViewedScreen({Key? key}) : super(key: key);

  @override
  State<RecentlyViewedScreen> createState() => _RecentlyViewedScreenState();
}

class _RecentlyViewedScreenState extends State<RecentlyViewedScreen> {
  final HotelService _hotelService = HotelService();
  List _hotels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _hotelService.getRecentlyViewedHotels();
      if (mounted) {
        if (response['success']) {
          final raw = response['data'];
          final list = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['hotels'] ?? []) : []);
          setState(() { _hotels = list; _loading = false; });
        } else {
          setState(() { _hotels = []; _loading = false; });
        }
      }
    } catch (_) {
      if (mounted) setState(() { _hotels = []; _loading = false; });
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
        title: const Text('Recently Viewed', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          if (_hotels.isNotEmpty)
            TextButton(
              onPressed: _showClearDialog,
              child: const Text('Clear All', style: TextStyle(color: AppColors.primary, fontSize: 13)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _hotels.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _hotels.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (ctx, i) => _buildHotelCard(_hotels[i], i),
                  ),
                ),
    );
  }

  Widget _buildHotelCard(Map hotel, int index) {
    final name = hotel['name'] ?? 'Hotel';
    final location = hotel['city'] ?? hotel['location'] ?? 'Kathmandu';
    final rating = (hotel['rating'] as num?)?.toDouble() ?? 0.0;
    final price = hotel['price_per_night'] ?? hotel['min_price'] ?? hotel['price'] ?? 0;
    final imageUrl = _resolveImage(hotel);
    final viewedAt = hotel['viewed_at'] ?? hotel['last_viewed'] ?? '';

    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/hotel-details', arguments: {'hotelId': hotel['id']?.toString(), 'hotel': hotel}),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
              child: imageUrl.isNotEmpty
                  ? Image.network(imageUrl, width: 110, height: 110, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder())
                  : _imagePlaceholder(),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.primary),
                      const SizedBox(width: 3),
                      Expanded(child: Text(location, style: const TextStyle(fontSize: 12, color: AppColors.gray), overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    Row(children: [
                      const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                      const SizedBox(width: 3),
                      Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                    ]),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('NPR $price/night', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                        if (viewedAt.isNotEmpty)
                          Text(viewedAt, style: const TextStyle(fontSize: 10, color: AppColors.placeholder)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 60)).slideX(begin: 0.1),
    );
  }

  String _resolveImage(Map hotel) {
    final img = hotel['image'] ?? hotel['cover_image'] ?? hotel['thumbnail'] ?? '';
    if (img is String && img.isNotEmpty) {
      if (img.startsWith('http')) return img;
      return '${ApiConfig.baseUrl.replaceAll('/api', '')}/$img';
    }
    return '';
  }

  Widget _imagePlaceholder() {
    return Container(
      width: 110, height: 110,
      color: AppColors.surfaceVariant,
      child: const Icon(Icons.hotel_rounded, color: AppColors.placeholder, size: 36),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.history_rounded, size: 64, color: AppColors.placeholder),
          const SizedBox(height: 16),
          const Text('No recently viewed hotels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          const Text('Hotels you browse will appear here', style: TextStyle(fontSize: 14, color: AppColors.gray)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/hotel-list'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Explore Hotels', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showClearDialog() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Clear History', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('Remove all recently viewed hotels?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirm == true) setState(() => _hotels = []);
  }
}
