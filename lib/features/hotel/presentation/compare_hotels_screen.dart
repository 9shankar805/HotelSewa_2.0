import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';

class CompareHotelsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const CompareHotelsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<CompareHotelsScreen> createState() => _CompareHotelsScreenState();
}

class _CompareHotelsScreenState extends State<CompareHotelsScreen> {
  List<Map<String, dynamic>> _hotels = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    // Try to get hotel IDs from arguments
    final ids = widget.arguments?['hotelIds'];
    if (ids is List && ids.isNotEmpty) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken');
        final idsParam = ids.join(',');
        final response = await ApiService.get(ApiConfig.hotelsCompareEndpoint, token: token, queryParams: {'ids': idsParam});
        if (mounted) {
          final raw = response['data'];
          final list = raw is List ? raw.cast<Map<String, dynamic>>() : <Map<String, dynamic>>[];
          setState(() { _hotels = list; _loading = false; });
          return;
        }
      } catch (_) {}
    }
    // Fallback: use hotel maps passed directly
    final hotelList = widget.arguments?['hotels'];
    if (hotelList is List) {
      setState(() { _hotels = hotelList.cast<Map<String, dynamic>>(); _loading = false; });
    } else {
      setState(() { _hotels = []; _loading = false; });
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
        title: const Text('Compare Hotels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _hotels.isEmpty
              ? _buildEmpty()
              : _hotels.length == 1
                  ? _buildNeedMoreHotels()
                  : _buildComparison(),
    );
  }

  Widget _buildComparison() {
    final rows = [
      {'label': 'Rating', 'icon': Icons.star_rounded, 'key': 'rating'},
      {'label': 'Price/Night', 'icon': Icons.payments_outlined, 'key': 'price'},
      {'label': 'Location', 'icon': Icons.location_on_rounded, 'key': 'city'},
      {'label': 'Rooms', 'icon': Icons.meeting_room_outlined, 'key': 'total_rooms'},
      {'label': 'WiFi', 'icon': Icons.wifi_rounded, 'key': 'wifi'},
      {'label': 'Parking', 'icon': Icons.local_parking_rounded, 'key': 'parking'},
      {'label': 'Pool', 'icon': Icons.pool_rounded, 'key': 'pool'},
      {'label': 'Gym', 'icon': Icons.fitness_center_rounded, 'key': 'gym'},
      {'label': 'Restaurant', 'icon': Icons.restaurant_rounded, 'key': 'restaurant'},
      {'label': 'Spa', 'icon': Icons.spa_rounded, 'key': 'spa'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Hotel header cards
          Row(
            children: [
              const SizedBox(width: 100),
              ..._hotels.take(3).map((h) => Expanded(child: _buildHotelHeader(h))).toList(),
            ],
          ).animate().fadeIn().slideY(begin: 0.1),
          const SizedBox(height: 16),
          // Comparison rows
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
            child: Column(
              children: rows.asMap().entries.map((entry) {
                final i = entry.key;
                final row = entry.value;
                return _buildComparisonRow(
                  row['label'] as String,
                  row['icon'] as IconData,
                  row['key'] as String,
                  isLast: i == rows.length - 1,
                );
              }).toList(),
            ),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
          const SizedBox(height: 24),
          // Book buttons
          Row(
            children: [
              const SizedBox(width: 100),
              ..._hotels.take(3).map((h) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pushNamed(context, '/hotel-details', arguments: {'hotelId': h['id']?.toString(), 'hotel': h}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Book', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
                  ),
                ),
              )).toList(),
            ],
          ).animate().fadeIn(delay: 400.ms),
        ],
      ),
    );
  }

  Widget _buildHotelHeader(Map hotel) {
    final name = hotel['name'] ?? 'Hotel';
    final imageUrl = _resolveImage(hotel);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: imageUrl.isNotEmpty
                ? Image.network(imageUrl, height: 80, width: double.infinity, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
          ),
          const SizedBox(height: 6),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.darkGray), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String label, IconData icon, String key, {bool isLast = false}) {
    return Container(
      decoration: BoxDecoration(
        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.lightGray, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(icon, size: 14, color: AppColors.gray),
                  const SizedBox(width: 6),
                  Flexible(child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500))),
                ],
              ),
            ),
          ),
          ..._hotels.take(3).map((h) {
            final value = _getValue(h, key);
            final highlight = key == 'rating' && _isBestRating(h, key);
            final priceHighlight = key == 'price' && _isBestPrice(h, key);
            return Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                color: (highlight || priceHighlight) ? AppColors.success.withOpacity(0.06) : null,
                child: Center(
                  child: _buildValueWidget(value, key, highlight || priceHighlight),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildValueWidget(String value, String key, bool highlight) {
    if (value == 'true') return Icon(Icons.check_circle_rounded, color: AppColors.success, size: 18);
    if (value == 'false') return Icon(Icons.cancel_rounded, color: AppColors.placeholder, size: 18);
    return Text(
      value,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: highlight ? AppColors.success : AppColors.darkGray),
      textAlign: TextAlign.center,
    );
  }

  String _getValue(Map hotel, String key) {
    if (key == 'price') {
      final p = hotel['price_per_night'] ?? hotel['min_price'] ?? hotel['price'] ?? '—';
      return p != '—' ? 'NPR $p' : '—';
    }
    if (key == 'rating') return (hotel['rating'] ?? '—').toString();
    if (['wifi', 'parking', 'pool', 'gym', 'restaurant', 'spa'].contains(key)) {
      final amenities = hotel['amenities'];
      if (amenities is List) {
        final has = amenities.any((a) => a.toString().toLowerCase().contains(key));
        return has ? 'true' : 'false';
      }
      final val = hotel[key];
      if (val is bool) return val.toString();
      return 'false';
    }
    return (hotel[key] ?? '—').toString();
  }

  bool _isBestRating(Map hotel, String key) {
    if (_hotels.isEmpty) return false;
    final maxRating = _hotels.map((h) => (h['rating'] as num?)?.toDouble() ?? 0.0).reduce((a, b) => a > b ? a : b);
    return (hotel['rating'] as num?)?.toDouble() == maxRating && maxRating > 0;
  }

  bool _isBestPrice(Map hotel, String key) {
    if (_hotels.isEmpty) return false;
    final prices = _hotels.map((h) => (h['price_per_night'] ?? h['min_price'] ?? h['price'] ?? 999999) as num).toList();
    final minPrice = prices.reduce((a, b) => a < b ? a : b);
    return ((hotel['price_per_night'] ?? hotel['min_price'] ?? hotel['price']) as num?) == minPrice;
  }

  String _resolveImage(Map hotel) {
    final img = hotel['image'] ?? hotel['cover_image'] ?? hotel['thumbnail'] ?? '';
    if (img is String && img.isNotEmpty) {
      if (img.startsWith('http')) return img;
      return '${ApiConfig.baseUrl.replaceAll('/api', '')}/$img';
    }
    return '';
  }

  Widget _placeholder() {
    return Container(height: 80, color: AppColors.surfaceVariant, child: const Icon(Icons.hotel_rounded, color: AppColors.placeholder));
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.compare_arrows_rounded, size: 64, color: AppColors.placeholder),
          const SizedBox(height: 16),
          const Text('No hotels to compare', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          const Text('Select at least 2 hotels to compare', style: TextStyle(fontSize: 14, color: AppColors.gray)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildNeedMoreHotels() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.add_business_rounded, size: 64, color: AppColors.placeholder),
          const SizedBox(height: 16),
          const Text('Add another hotel', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          const Text('You need at least 2 hotels to compare', style: TextStyle(fontSize: 14, color: AppColors.gray)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Browse Hotels', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
