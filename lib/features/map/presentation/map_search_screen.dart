import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';
import '../../../core/services/location_service.dart';
import '../../hotel/presentation/hotel_details_screen.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({Key? key}) : super(key: key);

  @override
  State<MapSearchScreen> createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  String _selectedFilter = 'all';
  List<Map<String, dynamic>> _hotels = [];
  Map<String, dynamic>? _selectedHotel;
  bool _loading = false;
  bool _detectingGps = false;
  double? _lat;
  double? _lng;

  final _filters = ['all', 'budget', 'luxury', 'business', 'resort'];

  @override
  void initState() {
    super.initState();
    _loadFromSavedLocation();
  }

  Future<void> _loadFromSavedLocation() async {
    final coords = await LocationService.getSavedCoords();
    if (coords != null && coords['lat'] != null && coords['lng'] != null) {
      _lat = coords['lat'];
      _lng = coords['lng'];
      await _loadNearbyHotels();
    } else {
      await _loadAllHotels();
    }
  }

  Future<void> _loadNearbyHotels() async {
    if (_lat == null || _lng == null) return;
    setState(() => _loading = true);
    try {
      final response = await ApiService.get(ApiConfig.hotelsNearbyEndpoint, queryParams: {
        'latitude': _lat,
        'longitude': _lng,
        'radius': 50,
        if (_selectedFilter != 'all') 'type': _selectedFilter,
      });
      if (response['success'] == true) {
        final raw = response['data'];
        List hotels = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['hotels'] ?? []) : []);
        setState(() => _hotels = hotels.map<Map<String, dynamic>>((h) => _mapHotel(h)).toList());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _loadAllHotels() async {
    setState(() => _loading = true);
    try {
      final filters = <String, dynamic>{};
      if (_selectedFilter != 'all') filters['type'] = _selectedFilter;
      final response = await ApiService.get(ApiConfig.hotelsEndpoint, queryParams: filters.isNotEmpty ? filters : null);
      if (response['success'] == true) {
        final raw = response['data'];
        List hotels = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['hotels'] ?? []) : []);
        setState(() => _hotels = hotels.take(20).map<Map<String, dynamic>>((h) => _mapHotel(h)).toList());
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Map<String, dynamic> _mapHotel(Map h) => {
    'id': h['id']?.toString() ?? '',
    'name': h['name'] ?? 'Hotel',
    'city': h['city'] ?? '',
    'rating': (h['rating'] as num?)?.toDouble() ?? 4.0,
    'price': (h['min_price'] ?? h['price'] ?? 2500) as num,
    'distance': h['distance'],
    'image': _parseImage(h['image'] ?? h['images']),
  };

  String _parseImage(dynamic images) {
    if (images is String && images.startsWith('http')) return images;
    return 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400';
  }

  Future<void> _detectLocation() async {
    setState(() => _detectingGps = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enable GPS'), behavior: SnackBarBehavior.floating));
        return;
      }
      _lat = position.latitude;
      _lng = position.longitude;
      await LocationService.saveCity('Near Me', lat: _lat, lng: _lng);
      await _loadNearbyHotels();
    } finally {
      if (mounted) setState(() => _detectingGps = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              children: [
                // Search bar
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)),
                              child: Row(
                                children: [
                                  const Icon(Icons.search_rounded, size: 18, color: AppColors.gray),
                                  const SizedBox(width: 8),
                                  Text(_lat != null ? 'Hotels near you' : 'Search on map', style: const TextStyle(fontSize: 14, color: AppColors.gray)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _detectingGps ? null : _detectLocation,
                            child: Container(
                              width: 40, height: 40,
                              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                              child: _detectingGps
                                  ? const Padding(padding: EdgeInsets.all(10), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                                  : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: _filters.length,
                          itemBuilder: (_, i) {
                            final f = _filters[i];
                            final sel = _selectedFilter == f;
                            return GestureDetector(
                              onTap: () { setState(() => _selectedFilter = f); _lat != null ? _loadNearbyHotels() : _loadAllHotels(); },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.primary : AppColors.background,
                                  borderRadius: BorderRadius.circular(18),
                                  border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray),
                                ),
                                child: Center(child: Text(f[0].toUpperCase() + f.substring(1), style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.gray))),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // Map placeholder with hotel pins
                Expanded(
                  child: Stack(
                    children: [
                      Container(
                        color: const Color(0xFFE8F4FD),
                        child: _loading
                            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                            : Stack(
                                children: [
                                  // Map background
                                  Center(
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        const Icon(Icons.map_rounded, size: 64, color: AppColors.placeholder),
                                        const SizedBox(height: 8),
                                        Text('${_hotels.length} hotels found', style: const TextStyle(fontSize: 14, color: AppColors.gray)),
                                        if (_lat == null) ...[
                                          const SizedBox(height: 8),
                                          GestureDetector(
                                            onTap: _detectLocation,
                                            child: Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                                              child: const Text('Enable GPS for map view', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                  // Hotel pins (simulated)
                                  ..._hotels.take(5).toList().asMap().entries.map((e) {
                                    final h = e.value;
                                    final offset = Offset(
                                      50.0 + (e.key * 60.0) % (MediaQuery.of(context).size.width - 100),
                                      100.0 + (e.key * 80.0) % 200,
                                    );
                                    return Positioned(
                                      left: offset.dx,
                                      top: offset.dy,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _selectedHotel = h),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                          decoration: BoxDecoration(
                                            color: _selectedHotel?['id'] == h['id'] ? AppColors.primary : Colors.white,
                                            borderRadius: BorderRadius.circular(20),
                                            boxShadow: AppColors.cardShadow,
                                          ),
                                          child: Text(
                                            'Rs.${h['price']}',
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                                              color: _selectedHotel?['id'] == h['id'] ? Colors.white : AppColors.darkGray),
                                          ),
                                        ),
                                      ).animate(delay: (e.key * 100).ms).fadeIn().scale(),
                                    );
                                  }),
                                ],
                              ),
                      ),
                    ],
                  ),
                ),

                // Hotel list at bottom
                if (_hotels.isNotEmpty)
                  Container(
                    height: 140,
                    color: Colors.white,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.all(12),
                      itemCount: _hotels.length,
                      itemBuilder: (_, i) {
                        final h = _hotels[i];
                        final isSelected = _selectedHotel?['id'] == h['id'];
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedHotel = h);
                            Navigator.push(context, MaterialPageRoute(builder: (_) => HotelDetailsScreen(arguments: {'hotelId': h['id']})));
                          },
                          child: Container(
                            width: 220,
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isSelected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: isSelected ? AppColors.primary : AppColors.lightGray, width: isSelected ? 1.5 : 1),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: Row(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(h['image'], width: 60, height: 60, fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(width: 60, height: 60, color: AppColors.surfaceVariant, child: const Icon(Icons.hotel_rounded, color: AppColors.placeholder))),
                                ),
                                const SizedBox(width: 10),
                                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                  Text(h['name'], style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                                  Text(h['city'], style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                                  const SizedBox(height: 4),
                                  Row(children: [
                                    const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                                    const SizedBox(width: 2),
                                    Text('${h['rating']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                                    const Spacer(),
                                    Text('Rs.${h['price']}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary)),
                                  ]),
                                  if (h['distance'] != null)
                                    Text('${(h['distance'] as num).toStringAsFixed(1)} km', style: const TextStyle(fontSize: 10, color: AppColors.gray)),
                                ])),
                              ],
                            ),
                          ).animate(delay: (i * 50).ms).fadeIn().slideX(begin: 0.1),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
