import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';

class NearbyAttractionsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const NearbyAttractionsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<NearbyAttractionsScreen> createState() => _NearbyAttractionsScreenState();
}

class _NearbyAttractionsScreenState extends State<NearbyAttractionsScreen> {
  String _selectedCategory = 'All';
  List<Map<String, dynamic>> _attractions = [];
  bool _loading = true;

  final _categories = ['All', 'Attractions', 'Restaurants', 'Transport', 'Shopping', 'Hospitals'];

  /// Kathmandu Valley POIs — used as fallback if API returns nothing
  static const List<Map<String, dynamic>> _kathmanduFallback = [
    {
      'name': 'Pashupatinath Temple',
      'category': 'Attractions',
      'distance': '1.2 km',
      'rating': 4.9,
      'type': 'Hindu Temple',
      'icon': 'temple',
      'open': true,
      'description': 'One of the most sacred Hindu temples in the world, located on the banks of the Bagmati River.',
    },
    {
      'name': 'Boudhanath Stupa',
      'category': 'Attractions',
      'distance': '2.0 km',
      'rating': 4.8,
      'type': 'Buddhist Stupa',
      'icon': 'stupa',
      'open': true,
      'description': 'UNESCO World Heritage Site — one of the largest Buddhist stupas in the world.',
    },
    {
      'name': 'Swayambhunath (Monkey Temple)',
      'category': 'Attractions',
      'distance': '3.5 km',
      'rating': 4.7,
      'type': 'Buddhist Shrine',
      'icon': 'temple',
      'open': true,
      'description': 'Ancient religious complex atop a hill with panoramic views of Kathmandu valley.',
    },
    {
      'name': 'Kathmandu Durbar Square',
      'category': 'Attractions',
      'distance': '2.8 km',
      'rating': 4.6,
      'type': 'UNESCO Heritage',
      'icon': 'heritage',
      'open': true,
      'description': 'Historic royal palace square with ancient temples, courtyards and traditional architecture.',
    },
    {
      'name': 'Thamel District',
      'category': 'Shopping',
      'distance': '1.5 km',
      'rating': 4.5,
      'type': 'Shopping & Dining',
      'icon': 'shopping',
      'open': true,
      'description': 'Kathmandu\'s tourist hub — trekking gear, handicrafts, restaurants and nightlife.',
    },
    {
      'name': 'Ason Bazaar',
      'category': 'Shopping',
      'distance': '2.2 km',
      'rating': 4.3,
      'type': 'Traditional Market',
      'icon': 'shopping',
      'open': true,
      'description': 'One of the oldest and busiest markets in Kathmandu selling spices, handicrafts and everyday goods.',
    },
    {
      'name': 'Dwarika\'s Restaurant',
      'category': 'Restaurants',
      'distance': '0.8 km',
      'rating': 4.7,
      'type': 'Nepali Fine Dining',
      'icon': 'restaurant',
      'open': true,
      'description': 'Award-winning restaurant serving authentic Nepali cuisine in a heritage setting.',
    },
    {
      'name': 'OR2K Restaurant',
      'category': 'Restaurants',
      'distance': '1.4 km',
      'rating': 4.4,
      'type': 'International Cuisine',
      'icon': 'restaurant',
      'open': true,
      'description': 'Popular restaurant in Thamel with vegetarian options and rooftop seating.',
    },
    {
      'name': 'Tribhuvan International Airport',
      'category': 'Transport',
      'distance': '4.2 km',
      'rating': 3.9,
      'type': 'Airport',
      'icon': 'transport',
      'open': true,
      'description': 'Nepal\'s only international airport, connecting Kathmandu to major cities worldwide.',
    },
    {
      'name': 'New Bus Park (Gongabu)',
      'category': 'Transport',
      'distance': '3.1 km',
      'rating': 3.7,
      'type': 'Bus Terminal',
      'icon': 'transport',
      'open': true,
      'description': 'Main inter-city bus terminal for connections to all major cities across Nepal.',
    },
    {
      'name': 'Bir Hospital',
      'category': 'Hospitals',
      'distance': '2.5 km',
      'rating': 4.1,
      'type': 'Government Hospital',
      'icon': 'hospital',
      'open': true,
      'description': 'One of the largest and oldest government hospitals in Nepal.',
    },
    {
      'name': 'Norvic International Hospital',
      'category': 'Hospitals',
      'distance': '3.8 km',
      'rating': 4.5,
      'type': 'Private Hospital',
      'icon': 'hospital',
      'open': true,
      'description': 'Leading private hospital providing comprehensive healthcare services in Kathmandu.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    final hotelId = widget.arguments?['hotelId']?.toString() ?? widget.arguments?['id']?.toString();
    final lat = widget.arguments?['latitude']?.toString() ?? widget.arguments?['lat']?.toString();
    final lng = widget.arguments?['longitude']?.toString() ?? widget.arguments?['lng']?.toString();

    if (hotelId != null || (lat != null && lng != null)) {
      try {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken');
        final queryParams = <String, String>{};
        if (hotelId != null) queryParams['hotel_id'] = hotelId;
        if (lat != null) queryParams['lat'] = lat;
        if (lng != null) queryParams['lng'] = lng;
        queryParams['radius'] = '5'; // 5 km radius

        final response = await ApiService.get(
          '${ApiConfig.hotelsNearbyEndpoint}/attractions',
          token: token,
          queryParams: queryParams,
        );

        if (mounted) {
          final raw = response['data'];
          final list = raw is List ? raw : (raw is Map ? (raw['attractions'] ?? raw['data'] ?? []) : []);
          if (list.isNotEmpty) {
            setState(() {
              _attractions = list.map<Map<String, dynamic>>((a) => Map<String, dynamic>.from(a)).toList();
              _loading = false;
            });
            return;
          }
        }
      } catch (_) {
        // API not available — fall through to Kathmandu defaults
      }
    }

    // Use Kathmandu fallback data
    if (mounted) {
      setState(() {
        _attractions = List<Map<String, dynamic>>.from(_kathmanduFallback);
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered => _selectedCategory == 'All'
      ? _attractions
      : _attractions.where((a) => (a['category'] ?? '') == _selectedCategory).toList();

  IconData _iconFor(Map attraction) {
    final iconKey = (attraction['icon'] ?? attraction['type'] ?? '').toString().toLowerCase();
    if (iconKey.contains('temple') || iconKey.contains('stupa') || iconKey.contains('shrine') || iconKey.contains('heritage')) {
      return Icons.account_balance_rounded;
    }
    if (iconKey.contains('restaurant') || iconKey.contains('dining') || iconKey.contains('cafe') || iconKey.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (iconKey.contains('airport') || iconKey.contains('bus') || iconKey.contains('transport') || iconKey.contains('railway') || iconKey.contains('station')) {
      return iconKey.contains('airport') ? Icons.flight_rounded : Icons.directions_bus_rounded;
    }
    if (iconKey.contains('shopping') || iconKey.contains('market') || iconKey.contains('mall') || iconKey.contains('bazaar')) {
      return Icons.shopping_bag_rounded;
    }
    if (iconKey.contains('hospital') || iconKey.contains('clinic') || iconKey.contains('medical')) {
      return Icons.local_hospital_rounded;
    }
    if (iconKey.contains('park') || iconKey.contains('garden') || iconKey.contains('nature')) {
      return Icons.park_rounded;
    }
    if (iconKey.contains('museum') || iconKey.contains('gallery')) {
      return Icons.museum_rounded;
    }
    return Icons.place_rounded;
  }

  Color _colorFor(Map attraction) {
    final cat = (attraction['category'] ?? '').toString().toLowerCase();
    if (cat.contains('attraction')) return AppColors.teal;
    if (cat.contains('restaurant') || cat.contains('food')) return AppColors.warning;
    if (cat.contains('transport')) return AppColors.info;
    if (cat.contains('shopping')) return AppColors.success;
    if (cat.contains('hospital') || cat.contains('medical')) return AppColors.error;
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final hotel = widget.arguments ?? {};
    final hotelName = hotel['hotelName'] ?? hotel['name'] ?? 'Nearby Attractions';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(hotelName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkGray), overflow: TextOverflow.ellipsis),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Map placeholder
                Container(
                  height: 160,
                  color: const Color(0xFFE8F4FD),
                  child: Stack(
                    children: [
                      // Simulated map grid lines
                      CustomPaint(painter: _MapGridPainter(), size: const Size(double.infinity, 160)),
                      Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52, height: 52,
                              decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: AppColors.primaryShadow),
                              child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 26),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: AppColors.cardShadow),
                              child: Text(
                                hotelName.length > 20 ? '${hotelName.substring(0, 20)}...' : hotelName,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Positioned(
                        bottom: 10, right: 10,
                        child: GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/map-search', arguments: hotel),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.map_outlined, size: 13, color: AppColors.primary),
                                SizedBox(width: 5),
                                Text('Open Map', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary)),
                              ],
                            ),
                          ),
                        ),
                      ),
                      // Location label
                      const Positioned(
                        top: 10, left: 12,
                        child: Row(
                          children: [
                            Icon(Icons.location_on_rounded, size: 13, color: AppColors.primary),
                            SizedBox(width: 4),
                            Text('Kathmandu Valley', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                // Category filter
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final sel = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : AppColors.background,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray),
                            ),
                            child: Center(
                              child: Text(cat, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.gray)),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // List
                Expanded(
                  child: _filtered.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _load,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.all(14),
                            itemCount: _filtered.length,
                            itemBuilder: (_, i) => _buildAttractionCard(_filtered[i], i),
                          ),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildAttractionCard(Map attraction, int index) {
    final color = _colorFor(attraction);
    final icon = _iconFor(attraction);
    final isOpen = attraction['open'] ?? true;
    final rating = (attraction['rating'] as num?)?.toDouble() ?? 0.0;
    final description = attraction['description'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attraction['name'] ?? '', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const SizedBox(height: 2),
                Text(attraction['type'] ?? '', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(description, style: const TextStyle(fontSize: 11, color: AppColors.placeholder, height: 1.3), maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  if (rating > 0) ...[
                    const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                    const SizedBox(width: 3),
                    Text(rating.toStringAsFixed(1), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, decoration: const BoxDecoration(color: AppColors.placeholder, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                  ],
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: isOpen ? AppColors.successLight : AppColors.errorLight,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(isOpen ? 'Open' : 'Closed', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isOpen ? AppColors.success : AppColors.error)),
                  ),
                ]),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if ((attraction['distance'] ?? '').toString().isNotEmpty)
                Text(attraction['distance'].toString(), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(height: 6),
              const Icon(Icons.directions_outlined, size: 18, color: AppColors.gray),
            ],
          ),
        ],
      ),
    ).animate(delay: Duration(milliseconds: index * 40)).fadeIn().slideX(begin: 0.05);
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.place_outlined, size: 56, color: AppColors.placeholder),
          const SizedBox(height: 12),
          Text('No $_selectedCategory found nearby', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 6),
          const Text('Try a different category', style: TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 16),
          TextButton(
            onPressed: () => setState(() => _selectedCategory = 'All'),
            child: const Text('Show All', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

/// Paints a subtle grid on the map placeholder to make it look more map-like
class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFB8D9F0).withOpacity(0.5)
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 40) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 40) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    // Draw a few fake road lines
    final roadPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 3;
    canvas.drawLine(Offset(0, size.height * 0.4), Offset(size.width, size.height * 0.4), roadPaint);
    canvas.drawLine(Offset(size.width * 0.35, 0), Offset(size.width * 0.35, size.height), roadPaint);
  }

  @override
  bool shouldRepaint(_) => false;
}
