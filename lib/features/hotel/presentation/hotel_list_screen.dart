import 'package:flutter/material.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/hotel_service.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/services/shared/auth_service.dart';
import '../../../core/widgets/floating_chatbot.dart';
import '../../../core/widgets/shimmer_loading.dart';
import 'hotel_details_screen.dart';

class HotelListScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const HotelListScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  final HotelService _hotelService = HotelService();
  final FavoriteService _favoriteService = FavoriteService();
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _hotels = [];
  List<Map<String, dynamic>> _filtered = [];
  bool _loading = false;
  String? _error;
  String? _location;
  String? _checkIn;
  String? _checkOut;
  int _guests = 1;
  int _rooms = 1;
  double? _latitude;
  double? _longitude;
  bool _useGps = false;
  String _sortBy = 'price_asc';
  RangeValues _priceRange = const RangeValues(0, 20000);
  double _maxPriceInData = 20000;
  List<String> _selectedAmenities = [];
  double? _minRating;
  bool _showFilters = false;
  bool _isLoggedIn = false;
  Set<String> _favoriteIds = {};

  static const _amenityOptions = ['WiFi', 'AC', 'Parking', 'Breakfast', 'Pool', 'Gym', 'Spa', 'Restaurant'];
  static const _sortOptions = [
    ('price_asc', 'Price asc'),
    ('price_desc', 'Price desc'),
    ('rating', 'Top Rated'),
    ('distance', 'Nearest'),
  ];

  @override
  void initState() {
    super.initState();
    _extractArgs();
    _loadHotels();
    _checkLoginAndFavorites();
  }

  Future<void> _checkLoginAndFavorites() async {
    final loggedIn = await _authService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
    if (loggedIn) {
      final result = await _favoriteService.getFavorites();
      if (result['success'] == true) {
        final raw = result['favorites'];
        List items = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['hotels'] ?? []) : []);
        setState(() {
          _favoriteIds = items.map<String>((h) => h['id']?.toString() ?? '').toSet();
        });
      }
    }
  }

  Future<void> _toggleFavorite(String hotelId) async {
    if (!_isLoggedIn) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please login to save hotels'), behavior: SnackBarBehavior.floating),
      );
      return;
    }
    final wasFav = _favoriteIds.contains(hotelId);
    setState(() {
      if (wasFav) _favoriteIds.remove(hotelId);
      else _favoriteIds.add(hotelId);
    });
    final result = await _favoriteService.toggleFavorite(hotelId);
    if (result['success'] != true) {
      // Revert
      setState(() {
        if (wasFav) _favoriteIds.add(hotelId);
        else _favoriteIds.remove(hotelId);
      });
    }
  }

  void _extractArgs() {
    final a = widget.arguments ?? {};
    _location = a['location'] as String?;
    _checkIn = a['checkIn'] as String?;
    _checkOut = a['checkOut'] as String?;
    _guests = (a['guests'] as int?) ?? 1;
    _rooms = (a['rooms'] as int?) ?? 1;
    _latitude = a['latitude'] as double?;
    _longitude = a['longitude'] as double?;
    _useGps = (a['useGps'] as bool?) ?? false;
  }

  Future<void> _loadHotels() async {
    setState(() { _loading = true; _error = null; });
    try {
      Map<String, dynamic> result;
      if (_useGps && _latitude != null && _longitude != null) {
        result = await _hotelService.getNearbyHotels(lat: _latitude!, lng: _longitude!, radius: 50);
      } else {
        final filters = <String, dynamic>{};
        if (_location != null && _location!.isNotEmpty && _location != 'Near Me') filters['city'] = _location;
        if (_checkIn != null) filters['check_in'] = _checkIn;
        if (_checkOut != null) filters['check_out'] = _checkOut;
        if (_guests > 1) filters['adults'] = _guests;
        if (_rooms > 1) filters['rooms'] = _rooms;
        result = await _hotelService.getHotels(filters: filters.isNotEmpty ? filters : null);
      }
      if (result['success'] != true) {
        setState(() { _error = result['message'] ?? 'Failed to load hotels'; _loading = false; });
        return;
      }
      final raw = result['data'];
      List rawList = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['hotels'] ?? raw['items'] ?? []) : []);
      final hotels = rawList.map<Map<String, dynamic>>((h) {
        final price = (h['min_price'] ?? h['starting_price'] ?? h['price'] ?? 2500) as num;
        return {
          'id': h['id'],
          'name': h['name'] ?? 'Hotel',
          'address': _buildAddress(h),
          'image': _parseImage(h['image'] ?? h['images']),
          'rating': (h['rating'] as num?)?.toDouble() ?? 0.0,
          'reviewCount': (h['total_reviews'] ?? h['review_count'] ?? 0) as int,
          'price': price.toInt(),
          'amenities': _parseAmenities(h['amenities']),
          'distance': h['distance'],
        };
      }).toList();
      if (hotels.isNotEmpty) {
        final maxP = hotels.map((h) => (h['price'] as int).toDouble()).reduce((a, b) => a > b ? a : b);
        _maxPriceInData = (maxP * 1.2).ceilToDouble();
        _priceRange = RangeValues(0, _maxPriceInData);
      }
      setState(() { _hotels = hotels; _loading = false; });
      _applyFilters();
    } catch (e) {
      setState(() { _error = 'Failed to load hotels'; _loading = false; });
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> result = List.from(_hotels);
    result = result.where((h) {
      final p = (h['price'] as int).toDouble();
      return p >= _priceRange.start && p <= _priceRange.end;
    }).toList();
    if (_selectedAmenities.isNotEmpty) {
      result = result.where((h) {
        final ams = (h['amenities'] as List).map((a) => a.toString().toLowerCase()).toList();
        return _selectedAmenities.every((a) => ams.contains(a.toLowerCase()));
      }).toList();
    }
    if (_minRating != null) {
      result = result.where((h) => (h['rating'] as double) >= _minRating!).toList();
    }
    switch (_sortBy) {
      case 'price_asc': result.sort((a, b) => (a['price'] as int).compareTo(b['price'] as int)); break;
      case 'price_desc': result.sort((a, b) => (b['price'] as int).compareTo(a['price'] as int)); break;
      case 'rating': result.sort((a, b) => (b['rating'] as double).compareTo(a['rating'] as double)); break;
      case 'distance':
        result.sort((a, b) {
          final da = (a['distance'] as num?)?.toDouble() ?? double.infinity;
          final db = (b['distance'] as num?)?.toDouble() ?? double.infinity;
          return da.compareTo(db);
        });
        break;
    }
    setState(() => _filtered = result);
  }

  String _buildAddress(Map h) {
    final city = h['city']?.toString() ?? '';
    final state = h['state']?.toString() ?? '';
    if (city.isEmpty && state.isEmpty) return h['address']?.toString() ?? '';
    if (state.isEmpty) return city;
    if (city.isEmpty) return state;
    return '$city, $state';
  }

  String _parseImage(dynamic images) {
    String url = '';
    if (images is String && images.isNotEmpty) {
      if (images.startsWith('http')) {
        url = images;
      } else {
        try {
          final d = jsonDecode(images);
          if (d is List && d.isNotEmpty) url = d[0]['url']?.toString() ?? d[0].toString();
        } catch (_) {}
      }
    } else if (images is List && images.isNotEmpty) {
      final first = images[0];
      url = first is Map ? (first['url']?.toString() ?? '') : first.toString();
    }
    final match = RegExp(r'https?://[^/]+/storage/(https?://.+)').firstMatch(url);
    if (match != null) return match.group(1)!;
    return url.isNotEmpty ? url : 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=600';
  }

  List<String> _parseAmenities(dynamic amenities) {
    if (amenities is List) return amenities.map((a) => a.toString()).toList();
    if (amenities is String) {
      try {
        final d = jsonDecode(amenities);
        if (d is List) return d.map((a) => a.toString()).toList();
      } catch (_) {}
    }
    return [];
  }

  int get _activeFilterCount {
    int c = 0;
    if (_priceRange.start > 0 || _priceRange.end < _maxPriceInData) c++;
    if (_selectedAmenities.isNotEmpty) c++;
    if (_minRating != null) c++;
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final title = _useGps ? 'Hotels Near You' : (_location ?? 'Hotels');
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            if (_checkIn != null && _checkOut != null)
              Text('$_checkIn to $_checkOut - $_guests guest${_guests > 1 ? "s" : ""}',
                  style: const TextStyle(fontSize: 11, color: AppColors.gray)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search_rounded, color: AppColors.darkGray),
            onPressed: () => Navigator.pushNamed(context, '/search')),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Container(
                color: Colors.white,
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => setState(() => _showFilters = true),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _activeFilterCount > 0 ? AppColors.primary : Colors.white,
                          border: Border.all(color: _activeFilterCount > 0 ? AppColors.primary : AppColors.lightGray),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.tune_rounded, size: 16, color: _activeFilterCount > 0 ? Colors.white : AppColors.darkGray),
                          const SizedBox(width: 5),
                          Text('Filter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                            color: _activeFilterCount > 0 ? Colors.white : AppColors.darkGray)),
                          if (_activeFilterCount > 0) ...[
                            const SizedBox(width: 5),
                            Container(width: 18, height: 18,
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: Center(child: Text('$_activeFilterCount',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: AppColors.primary)))),
                          ],
                        ]),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: _sortOptions.map((opt) {
                            final isActive = _sortBy == opt.$1;
                            return GestureDetector(
                              onTap: () { setState(() => _sortBy = opt.$1); _applyFilters(); },
                              child: Container(
                                margin: const EdgeInsets.only(right: 8),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.white,
                                  border: Border.all(color: isActive ? AppColors.primary : AppColors.lightGray),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(opt.$2, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: isActive ? AppColors.primary : AppColors.gray)),
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_loading && _error == null)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: Text(
                    '${_filtered.length} hotel${_filtered.length != 1 ? "s" : ""} found'
                    '${_useGps ? " near you" : _location != null ? " in $_location" : ""}',
                    style: const TextStyle(fontSize: 13, color: AppColors.gray, fontWeight: FontWeight.w500),
                  ),
                ),
              Expanded(
                child: _loading
                    ? const Padding(padding: EdgeInsets.all(16), child: HotelListShimmer(count: 4))
                    : _error != null ? _buildError()
                    : _filtered.isEmpty ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadHotels,
                        color: AppColors.primary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _buildCard(_filtered[i]),
                        ),
                      ),
              ),
            ],
          ),
          const FloatingChatbot(),
        ],
      ),
      bottomSheet: _showFilters ? _buildFilterSheet() : null,
    );
  }

  Widget _buildCard(Map<String, dynamic> hotel) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => HotelDetailsScreen(arguments: {'hotelId': hotel['id']}),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              child: Stack(
                children: [
                  Image.network(hotel['image'], width: double.infinity, height: 180, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(height: 180, color: AppColors.surfaceVariant,
                      child: const Icon(Icons.hotel_rounded, size: 48, color: AppColors.placeholder))),
                  if ((hotel['rating'] as double) > 0)
                    Positioned(bottom: 10, left: 12, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text('${hotel['rating']}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        if ((hotel['reviewCount'] as int) > 0)
                          Text(' (${hotel['reviewCount']})', style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      ]),
                    )),
                  // Favorite button
                  Positioned(
                    top: 10, right: 10,
                    child: GestureDetector(
                      onTap: () => _toggleFavorite(hotel['id']?.toString() ?? ''),
                      child: Container(
                        width: 36, height: 36,
                        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle,
                          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8)]),
                        child: Icon(
                          _favoriteIds.contains(hotel['id']?.toString() ?? '') ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                          size: 18,
                          color: AppColors.error,
                        ),
                      ),
                    ),
                  ),
                  if (hotel['distance'] != null)
                    Positioned(bottom: 10, right: 12, child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.gray, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.near_me_rounded, size: 12, color: Colors.white),
                        const SizedBox(width: 3),
                        Text('${(hotel['distance'] as num).toStringAsFixed(1)} km',
                          style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w600)),
                      ]),
                    )),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(hotel['name'], style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.location_on_rounded, size: 13, color: AppColors.gray),
                    const SizedBox(width: 3),
                    Expanded(child: Text(hotel['address'], style: const TextStyle(fontSize: 12, color: AppColors.gray),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                  ]),
                  if ((hotel['amenities'] as List).isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(spacing: 6, children: (hotel['amenities'] as List).take(4).map((a) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                      child: Text(a.toString(), style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
                    )).toList()),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Rs.${hotel['price']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        const Text(' /night', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                      ]),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                        decoration: BoxDecoration(gradient: AppColors.primaryGradient, borderRadius: BorderRadius.circular(12), boxShadow: AppColors.primaryShadow),
                        child: const Text('Book Now', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
      const SizedBox(height: 20),
      ElevatedButton.icon(onPressed: _loadHotels, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry'),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)))),
    ])));
  }

  Widget _buildEmpty() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.hotel_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      const Text('No hotels found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 8),
      Text(_activeFilterCount > 0 ? 'Try adjusting your filters' : 'No hotels available for this location',
        style: const TextStyle(fontSize: 14, color: AppColors.gray), textAlign: TextAlign.center),
      if (_activeFilterCount > 0) ...[
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() { _selectedAmenities.clear(); _minRating = null; _priceRange = RangeValues(0, _maxPriceInData); });
            _applyFilters();
          },
          child: const Text('Clear Filters', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600))),
      ],
    ])));
  }

  Widget _buildFilterSheet() {
    return StatefulBuilder(builder: (ctx, setS) => Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      child: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(20, 16, 8, 0), child: Row(children: [
          const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const Spacer(),
          TextButton(
            onPressed: () => setS(() { _selectedAmenities.clear(); _minRating = null; _priceRange = RangeValues(0, _maxPriceInData); }),
            child: const Text('Reset', style: TextStyle(color: AppColors.primary))),
          IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.gray), onPressed: () => setState(() => _showFilters = false)),
        ])),
        const Divider(height: 1),
        Expanded(child: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Price Range (per night)', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 4),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text('Rs.${_priceRange.start.toInt()}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
            Text('Rs.${_priceRange.end.toInt()}', style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ]),
          RangeSlider(values: _priceRange, min: 0, max: _maxPriceInData, divisions: 20,
            activeColor: AppColors.primary, inactiveColor: AppColors.lightGray,
            onChanged: (v) => setS(() => _priceRange = v)),
          const SizedBox(height: 20),
          const Text('Minimum Rating', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: [null, 3.0, 3.5, 4.0, 4.5].map((r) {
            final isSel = _minRating == r;
            return GestureDetector(onTap: () => setS(() => _minRating = r), child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSel ? AppColors.primary : Colors.white,
                border: Border.all(color: isSel ? AppColors.primary : AppColors.lightGray),
                borderRadius: BorderRadius.circular(20)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (r != null) ...[Icon(Icons.star_rounded, size: 13, color: isSel ? Colors.white : AppColors.gold), const SizedBox(width: 3)],
                Text(r == null ? 'Any' : '$r+', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isSel ? Colors.white : AppColors.darkGray)),
              ]),
            ));
          }).toList()),
          const SizedBox(height: 20),
          const Text('Amenities', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 10),
          Wrap(spacing: 8, runSpacing: 8, children: _amenityOptions.map((a) {
            final isSel = _selectedAmenities.contains(a);
            return GestureDetector(
              onTap: () => setS(() { if (isSel) _selectedAmenities.remove(a); else _selectedAmenities.add(a); }),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSel ? AppColors.primary.withOpacity(0.1) : Colors.white,
                  border: Border.all(color: isSel ? AppColors.primary : AppColors.lightGray),
                  borderRadius: BorderRadius.circular(20)),
                child: Text(a, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isSel ? AppColors.primary : AppColors.gray)),
              ),
            );
          }).toList()),
        ]))),
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), child: SizedBox(width: double.infinity,
          child: ElevatedButton(
            onPressed: () { setState(() => _showFilters = false); _applyFilters(); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16),
              elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: Text('Show ${_filtered.length} Hotels',
              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ))),
      ]),
    ));
  }
}