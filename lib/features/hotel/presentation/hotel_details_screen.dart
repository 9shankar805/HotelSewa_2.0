import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/hotel_service.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../../core/widgets/live_chat.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../booking/presentation/booking_form_screen.dart';
import '../../booking/presentation/hourly_booking_screen.dart';
import '../../reviews/presentation/hotel_reviews_screen.dart';
import 'room_details_screen.dart';
import 'photo_gallery_screen.dart';

// ---------------------------------------------------------------------------
// HotelDetailsScreen
// ---------------------------------------------------------------------------
class HotelDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const HotelDetailsScreen({super.key, this.arguments});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen>
    with TickerProviderStateMixin {
  // Services
  final HotelService _hotelService = HotelService();
  final FavoriteService _favoriteService = FavoriteService();

  // State
  bool _loading = true;
  bool _loadError = false;
  bool _isFavorite = false;
  bool _descriptionExpanded = false;
  Map<String, dynamic> _hotel = {};
  List<Map<String, dynamic>> _rooms = [];
  List<Map<String, dynamic>> _amenities = [];
  List<Map<String, dynamic>> _reviews = [];

  // Controllers
  late TabController _tabController;
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _imagePageController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    final hotelId = widget.arguments?['hotelId']?.toString();
    
    debugPrint('?? HotelDetailsScreen: Loading data for hotelId: $hotelId');
    debugPrint('?? HotelDetailsScreen: Full arguments: ${widget.arguments}');

    if (hotelId != null) {
      // Record the view
      await _hotelService.recordHotelView(hotelId);
      
      try {
        debugPrint('?? HotelDetailsScreen: Calling getHotelDetails...');
        final hotelResult = await _hotelService.getHotelDetails(hotelId);
        debugPrint('?? HotelDetailsScreen: Hotel result: $hotelResult');
        
        final isFav = await _favoriteService.isFavorite(hotelId);
        debugPrint('?? HotelDetailsScreen: Is favorite: $isFav');

        final rawData = hotelResult['data'];
        final data = rawData is Map<String, dynamic> ? rawData : null;
        
        debugPrint('?? HotelDetailsScreen: Processed data: ${data?.keys}');

        if (mounted && data != null) {

          // Map room_types from API
          final rawRooms = data['room_types'] as List? ?? [];
          debugPrint('?? HotelDetailsScreen: Raw rooms count: ${rawRooms.length}');
          
          final rooms = rawRooms.map<Map<String, dynamic>>((r) {
            // Fix all room images using centralized helper
            final fixedImages = ImageUrlHelper.fixList(r['images']);
            
            // Calculate availability properly
            final availableRooms = r['available_rooms'] as num? ?? 0;
            final totalRooms = r['total_rooms'] as num? ?? 0;
            final isAvailable = availableRooms > 0 || totalRooms > 0;
            
            return {
              'id': r['id']?.toString() ?? '',
              'type': r['name'] ?? 'Room',
              'image': ImageUrlHelper.firstOrFallback(r['images']),
              'images': fixedImages.isNotEmpty
                  ? fixedImages
                  : ['https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800'],
              'price': r['effective_price'] ?? r['base_price'] ?? 0,
              'original_price': r['weekend_price'] ?? r['base_price'] ?? 0,
              'discount': 0,
              'available': isAvailable,
              'max_guests': (r['max_adults'] ?? 2) + (r['max_children'] ?? 0),
              'size': '${r['room_size_sqft'] ?? '?'} sqft',
              'bed': r['bed_type'] ?? 'Standard',
              'features': (r['amenities'] as List?)?.map((a) => a.toString()).toList() ?? [],
              // Additional room details
              'description': r['description'] ?? '',
              'view_type': r['view_type'],
              'is_smoking': r['is_smoking'] ?? false,
              'extra_bed_available': r['extra_bed_available'] ?? false,
              'extra_bed_price': r['extra_bed_price'],
              'total_rooms': totalRooms,
              'available_rooms': availableRooms,
              'weekend_price': r['weekend_price'] ?? r['base_price'] ?? 0,
              // Hourly booking fields
              'hourly_available': r['hourly_available'] ?? false,
              'hourly_price': r['hourly_price'],
              'min_hours': r['min_hours'] ?? 1,
              'max_hours': r['max_hours'] ?? 12,
              'currency': r['currency'] ?? 'NPR',
              // Video and floor information
              'video_url': r['video_url'],
              'video_urls': r['video_urls'] ?? [],
              'videos': r['videos'] ?? [],
              'floor': r['floor'],
              'floor_number': r['floor_number'],
              'room_number': r['room_number'],
              // Additional media
              'media': r['media'] ?? [],
              'gallery': r['gallery'] ?? [],
            };
          }).toList();

          // Map reviews from API
          final rawReviews = data['reviews'] as List? ?? [];
          final reviews = rawReviews.map<Map<String, dynamic>>((r) => {
            'id': r['id']?.toString() ?? '',
            'user': {
              'name': r['guest_name'] ?? 'Guest',
              'avatar': r['guest_avatar'] ?? '',
            },
            'rating': r['rating'] ?? 5,
            'comment': r['review'] ?? '',
            'stayDate': r['created_at'] ?? '',
            'createdAt': r['created_at'] ?? '',
          }).toList();

          // Map amenities
          final rawAmenities = data['amenities'] as List? ?? [];
          final amenityIconMap = {
            'wifi': Icons.wifi, 'pool': Icons.pool, 'spa': Icons.spa,
            'restaurant': Icons.restaurant, 'parking': Icons.local_parking,
            'gym': Icons.fitness_center, 'room_service': Icons.room_service,
            'ac': Icons.ac_unit, 'bar': Icons.local_bar,
            'elevator': Icons.elevator, 'concierge': Icons.room_service,
            'business_center': Icons.business_center,
          };
          final amenities = rawAmenities.map<Map<String, dynamic>>((a) {
            final key = a.toString().toLowerCase();
            return {
              'icon': amenityIconMap[key] ?? Icons.check_circle_outline,
              'label': key[0].toUpperCase() + key.substring(1).replaceAll('_', ' '),
            };
          }).toList();

          // Build images list: main image + gallery items
          final List<String> images = [];
          if (data['image'] is String && (data['image'] as String).isNotEmpty) {
            images.add(ImageUrlHelper.fix(data['image'] as String));
          }
          final gallery = data['gallery'] as List? ?? [];
          for (final cat in gallery) {
            final items = cat['items'] as List? ?? [];
            for (final item in items) {
              final url = ImageUrlHelper.fix(item['url']?.toString());
              if (url.isNotEmpty && !images.contains(url)) images.add(url);
            }
          }

          debugPrint('?? HotelDetailsScreen: Final hotel name: ${data['name']}');
          debugPrint('?? HotelDetailsScreen: Final rooms count: ${rooms.length}');
          debugPrint('?? HotelDetailsScreen: Final images count: ${images.length}');

          setState(() {
            _hotel = {
              ...data,
              'images': images.isNotEmpty ? images : <String>[],
              'starting_price': data['min_price'],
              'review_count': data['total_reviews'],
              'location': '${data['city']}, ${data['state']}',
              'check_in': data['check_in_time'],
              'check_out': data['check_out_time'],
            };
            _rooms = rooms;
            _reviews = reviews;
            _amenities = amenities;
            _isFavorite = isFav;
            _loading = false;
          });
          return;
        } else {
          debugPrint('?? HotelDetailsScreen: Data is null or component unmounted');
        }
      } catch (e) {
        debugPrint('[HotelDetails] Error loading hotel $hotelId: $e');
      }
    } else {
      debugPrint('?? HotelDetailsScreen: No hotelId provided in arguments');
    }

    // No fallback � show error state
    if (mounted) {
      setState(() {
        _loadError = true;
        _loading = false;
      });
    }
  }

  Future<void> _toggleFavorite() async {
    final hotelId = (_hotel['id'] ?? 'default').toString();
    setState(() => _isFavorite = !_isFavorite);
    await _favoriteService.toggleFavorite(hotelId);
  }

  void _shareHotel() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing ${_hotel['name'] ?? 'hotel'}...'),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _openLiveChat() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LiveChat(hotelName: _hotel['name'] ?? 'Hotel'),
      ),
    );
  }

  Future<void> _bookNow({Map<String, dynamic>? room}) async {
    // Show date picker for check-in
    final checkInDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (checkInDate == null) return;

    // Show date picker for check-out
    final checkOutDate = await showDatePicker(
      context: context,
      initialDate: checkInDate.add(const Duration(days: 1)),
      firstDate: checkInDate.add(const Duration(days: 1)),
      lastDate: checkInDate.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(primary: AppColors.primary),
          ),
          child: child!,
        );
      },
    );

    if (checkOutDate == null) return;

    final nights = checkOutDate.difference(checkInDate).inDays;
    final checkInStr = '${checkInDate.year}-${checkInDate.month.toString().padLeft(2, '0')}-${checkInDate.day.toString().padLeft(2, '0')}';
    final checkOutStr = '${checkOutDate.year}-${checkOutDate.month.toString().padLeft(2, '0')}-${checkOutDate.day.toString().padLeft(2, '0')}';

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookingFormScreen(
          arguments: {
            'hotel': _hotel,
            'room': room ?? (_rooms.isNotEmpty ? _rooms.first : {'price': _hotel['starting_price'] ?? 3499, 'type': 'Standard Room'}),
            'dates': {'checkIn': checkInStr, 'checkOut': checkOutStr, 'nights': nights},
            'guests': 2,
          },
        ),
      ),
    );
  }

  void _bookHourly({Map<String, dynamic>? room}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HourlyBookingScreen(
          arguments: {
            'hotel': _hotel,
            'room': room ?? (_rooms.isNotEmpty ? _rooms.first : {}),
            'guests': 2,
          },
        ),
      ),
    );
  }

  void _viewAllReviews() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HotelReviewsScreen(arguments: {'hotel': _hotel}),
      ),
    );
  }

  List<String> get _images {
    final raw = _hotel['images'];
    if (raw is List && raw.isNotEmpty) {
      return raw.map((e) => e.toString()).toList();
    }
    return [];
  }

  double get _averageRating {
    if (_reviews.isEmpty) return (_hotel['rating'] as num?)?.toDouble() ?? 0.0;
    final sum = _reviews.fold<double>(0, (s, r) => s + ((r['rating'] as num?)?.toDouble() ?? 0));
    return sum / _reviews.length;
  }

  Map<int, int> get _ratingDistribution {
    final dist = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    for (final r in _reviews) {
      final rating = (r['rating'] as num?)?.toInt() ?? 0;
      if (rating >= 1 && rating <= 5) dist[rating] = (dist[rating] ?? 0) + 1;
    }
    return dist;
  }

  // ---------------------------------------------------------------------------
  // Build
  // ---------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.background,
        body: const HotelListShimmer(count: 3),
      );
    }

    if (_loadError || _hotel.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(backgroundColor: AppColors.white, elevation: 0, foregroundColor: AppColors.darkGray),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.hotel_outlined, size: 64, color: AppColors.gray),
              const SizedBox(height: 16),
              const Text('Could not load hotel details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              const SizedBox(height: 8),
              const Text('Please check your connection and try again', style: TextStyle(fontSize: 14, color: AppColors.gray)),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadData,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: AppColors.white),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              _buildSliverAppBar(),
              _buildHotelInfoSliver(),
              _buildTabBarSliver(),
            ],
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildRoomsTab(),
                _buildAmenitiesTab(),
                _buildReviewsTab(),
              ],
            ),
          ),
          _buildStickyBottomBar(),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sliver AppBar with image carousel
  // ---------------------------------------------------------------------------
  SliverAppBar _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: AppColors.primary,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.white.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(
                _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                size: 20,
                color: _isFavorite ? AppColors.error : AppColors.darkGray,
              ),
              onPressed: _toggleFavorite,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, top: 8, bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share_rounded, size: 20, color: AppColors.darkGray),
              onPressed: _shareHotel,
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            // Image carousel with hero animation
            _images.isEmpty
                ? Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          AppColors.primary.withOpacity(0.3),
                          AppColors.primary.withOpacity(0.7),
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.hotel_outlined, size: 80, color: AppColors.white),
                          SizedBox(height: 12),
                          Text(
                            'No Images Available',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : Hero(
                    tag: 'hotel-image-${_hotel['id']}',
                    child: GestureDetector(
                      onTap: () {
                        if (_images.isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PhotoGalleryScreen(
                                images: _images,
                                initialIndex: _currentImageIndex,
                                title: _hotel['name'] as String?,
                              ),
                            ),
                          );
                        }
                      },
                      child: PageView.builder(
                        controller: _imagePageController,
                        itemCount: _images.length,
                        onPageChanged: (i) => setState(() => _currentImageIndex = i),
                        itemBuilder: (_, i) => Stack(
                          fit: StackFit.expand,
                          children: [
                            AppCachedImage(
                              url: _images[i],
                              fit: BoxFit.cover,
                            ),
                            // Subtle overlay for better text readability
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    AppColors.black.withOpacity(0.1),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
            // Enhanced gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.black.withOpacity(0.2),
                  ],
                ),
              ),
            ),
            // Page indicator with enhanced styling
            if (_images.isNotEmpty) Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: SmoothPageIndicator(
                    controller: _imagePageController,
                    count: _images.length,
                    effect: ExpandingDotsEffect(
                      dotHeight: 8,
                      dotWidth: 8,
                      expansionFactor: 3,
                      spacing: 6,
                      activeDotColor: AppColors.white,
                      dotColor: AppColors.white.withOpacity(0.5),
                    ),
                  ),
                ),
              ),
            ),
            // Enhanced image counter badge
            if (_images.isNotEmpty) Positioned(
              bottom: 20,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.white.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_rounded, color: AppColors.white, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentImageIndex + 1}/${_images.length}',
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Tap to view gallery hint
            if (_images.isNotEmpty) Positioned(
              top: 100,
              right: 20,
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PhotoGalleryScreen(
                      images: _images,
                      initialIndex: _currentImageIndex,
                    ),
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primary),
                      SizedBox(width: 4),
                      Text(
                        'Tap to view gallery',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 800.ms, delay: 1000.ms).slideX(begin: 0.3),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Hotel info section
  // ---------------------------------------------------------------------------
  SliverToBoxAdapter _buildHotelInfoSliver() {
    final rating = (_hotel['rating'] as num?)?.toDouble() ?? _averageRating;
    final reviewCount = (_hotel['review_count'] as num?)?.toInt() ?? _reviews.length;

    return SliverToBoxAdapter(
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + rating badge row with enhanced styling
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _hotel['name'] ?? 'Hotel',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w900,
                          color: AppColors.darkGray,
                          height: 1.1,
                          letterSpacing: -0.5,
                        ),
                      ).animate().fadeIn(duration: 500.ms).slideX(begin: -0.1),
                      const SizedBox(height: 8),
                      // Enhanced location with better icon
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.location_on_rounded, color: AppColors.primary, size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _hotel['location'] ?? '',
                              style: const TextStyle(
                                color: AppColors.gray,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 500.ms, delay: 100.ms),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Enhanced rating badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.gold.withOpacity(0.15),
                        AppColors.gold.withOpacity(0.25),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.gold.withOpacity(0.4)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.gold.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, color: AppColors.gold, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.darkGray,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rating >= 4.5 ? 'Excellent' : rating >= 4.0 ? 'Very Good' : rating >= 3.5 ? 'Good' : 'Average',
                        style: const TextStyle(
                          color: AppColors.gray,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 150.ms).scale(begin: const Offset(0.8, 0.8)),
              ],
            ),
            const SizedBox(height: 12),
            // Enhanced review count with tap gesture
            GestureDetector(
              onTap: _viewAllReviews,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.reviews_rounded, size: 14, color: AppColors.info),
                    const SizedBox(width: 6),
                    Text(
                      '$reviewCount reviews',
                      style: const TextStyle(
                        color: AppColors.info,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.info),
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 200.ms),
            const SizedBox(height: 12),
            // ── HotelSewa Trust Badge ─────────────────────────────────
            _buildTrustBadge(),
            const SizedBox(height: 20),
            // Enhanced Check-in / Check-out card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.infoLight,
                    AppColors.infoLight.withOpacity(0.7),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.info.withOpacity(0.2)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.info.withOpacity(0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCheckTime(
                      icon: Icons.login_rounded,
                      label: 'Check-in',
                      time: _hotel['check_in'] ?? '2:00 PM',
                    ),
                  ),
                  Container(
                    width: 2,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(1),
                    ),
                  ),
                  Expanded(
                    child: _buildCheckTime(
                      icon: Icons.logout_rounded,
                      label: 'Check-out',
                      time: _hotel['check_out'] ?? '11:00 AM',
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 250.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),
            // Enhanced View All Photos button
            if (_images.isNotEmpty)
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PhotoGalleryScreen(
                        images: _images,
                        initialIndex: 0,
                        title: _hotel['name'] as String?,
                      ),
                    ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary.withOpacity(0.08),
                        AppColors.primary.withOpacity(0.12),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.photo_library_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'View All ${_images.length} Photos',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_ios_rounded, color: AppColors.primary, size: 14),
                    ],
                  ),
                ),
              ).animate().fadeIn(duration: 500.ms, delay: 300.ms).scale(begin: const Offset(0.95, 0.95)),
            const SizedBox(height: 20),
            // Enhanced Description
            _buildDescription(),
            const SizedBox(height: 16),
            // Enhanced live chat button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.success.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.chat_bubble_outline_rounded, size: 16, color: AppColors.success),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Need help? Chat with hotel staff',
                      style: TextStyle(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _openLiveChat,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.success,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Chat Now',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 350.ms),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckTime({required IconData icon, required String label, required String time}) {
    return Column(
      children: [
        Icon(icon, color: AppColors.info, size: 20),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: AppColors.gray, fontSize: 11)),
        const SizedBox(height: 2),
        Text(time, style: const TextStyle(color: AppColors.darkGray, fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  /// HotelSewa trust badge — verified, secure booking assurance strip.
  Widget _buildTrustBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.success.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: AppColors.success.withOpacity(0.15), shape: BoxShape.circle),
            child: const Icon(Icons.verified_rounded, color: AppColors.success, size: 20),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('HotelSewa Verified', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.success)),
                Text('Secure booking · Instant confirmation · Best price', style: TextStyle(fontSize: 11, color: AppColors.gray)),
              ],
            ),
          ),
          const Icon(Icons.shield_rounded, color: AppColors.success, size: 18),
        ],
      ),
    );
  }

  Widget _buildDescription() {
    final desc = _hotel['description'] as String? ?? '';
    const maxLines = 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          desc,
          maxLines: _descriptionExpanded ? null : maxLines,
          overflow: _descriptionExpanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: const TextStyle(color: AppColors.gray, fontSize: 14, height: 1.6),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => setState(() => _descriptionExpanded = !_descriptionExpanded),
          child: Text(
            _descriptionExpanded ? 'Show less' : 'Read more',
            style: const TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Tab bar
  // ---------------------------------------------------------------------------
  SliverPersistentHeader _buildTabBarSliver() {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _TabBarDelegate(
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
          tabs: const [
            Tab(text: 'Rooms'),
            Tab(text: 'Amenities'),
            Tab(text: 'Reviews'),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Rooms tab
  // ---------------------------------------------------------------------------
  Widget _buildRoomsTab() {
    if (_rooms.isEmpty) {
      return const Center(
        child: Text('No rooms available', style: TextStyle(color: AppColors.gray)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      itemCount: _rooms.length,
      itemBuilder: (_, i) => _buildRoomCard(_rooms[i]).animate().fadeIn(
            duration: 350.ms,
            delay: (i * 80).ms,
          ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room) {
    final price = (room['price'] as num?)?.toInt() ?? 0;
    final originalPrice = (room['original_price'] as num?)?.toInt() ?? 0;
    final discount = (room['discount'] as num?)?.toInt() ?? 0;
    final available = room['available'] as bool? ?? true;
    final features = List<String>.from(room['features'] as List? ?? []);
    final roomImages = List<String>.from(room['images'] as List? ?? []);
    final mainImage = roomImages.isNotEmpty ? roomImages.first : room['image'] as String? ?? 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomDetailsScreen(
              arguments: {
                'room': room,
                'hotel': _hotel,
              },
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced room image with multiple images carousel
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: SizedBox(
                    height: 220,
                    width: double.infinity,
                    child: roomImages.length > 1
                        ? PageView.builder(
                            itemCount: roomImages.length,
                            itemBuilder: (context, index) => AppCachedImage(
                              url: roomImages[index],
                              height: 220,
                              width: double.infinity,
                            ),
                          )
                        : AppCachedImage(
                            url: mainImage,
                            height: 220,
                            width: double.infinity,
                          ),
                  ),
                ),
                // Enhanced gradient overlay
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        AppColors.black.withOpacity(0.1),
                      ],
                    ),
                  ),
                ),
                // Enhanced discount badge
                if (discount > 0)
                  Positioned(
                    top: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.error, Color(0xFFFF6B6B)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.error.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.local_offer_rounded, color: AppColors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '$discount% OFF',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Enhanced availability badge
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: available ? AppColors.success : AppColors.error,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: (available ? AppColors.success : AppColors.error).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          available ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          color: AppColors.white,
                          size: 12,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          available ? 'Available' : 'Sold Out',
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Enhanced View Details overlay
                Positioned(
                  bottom: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.visibility_rounded, size: 14, color: AppColors.primary),
                        const SizedBox(width: 6),
                        const Text(
                          'View Details',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                      ],
                    ),
                  ),
                ),
                // Image count indicator for multiple images
                if (roomImages.length > 1)
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.photo_library_rounded, color: AppColors.white, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '${roomImages.length}',
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Enhanced room type + meta
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          room['type'] as String? ?? 'Room',
                          style: const TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.darkGray,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // Enhanced meta information with better icons
                  Row(
                    children: [
                      _roomMeta(Icons.people_alt_rounded, '${room['max_guests'] ?? 2} Guests', AppColors.primary),
                      const SizedBox(width: 20),
                      _roomMeta(Icons.straighten_rounded, room['size'] as String? ?? '', AppColors.info),
                      const SizedBox(width: 20),
                      _roomMeta(Icons.bed_rounded, room['bed'] as String? ?? '', AppColors.success),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Enhanced feature chips
                  if (features.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: features.take(4).map(
                        (f) => Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                AppColors.surfaceVariant,
                                AppColors.surfaceVariant.withOpacity(0.7),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.gray.withOpacity(0.2)),
                          ),
                          child: Text(
                            f,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.gray,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ).toList(),
                    ),
                  if (features.length > 4)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        '+${features.length - 4} more amenities',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  const SizedBox(height: 18),
                  // Enhanced price row + select button
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (originalPrice > price)
                              Text(
                                'NPR $originalPrice',
                                style: const TextStyle(
                                  color: AppColors.placeholder,
                                  fontSize: 14,
                                  decoration: TextDecoration.lineThrough,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.baseline,
                              textBaseline: TextBaseline.alphabetic,
                              children: [
                                Text(
                                  'NPR $price',
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.primary,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const Text(
                                  ' /night',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.gray,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            // Enhanced hourly price badge
                            if (room['hourly_available'] == true && room['hourly_price'] != null)
                              Container(
                                margin: const EdgeInsets.only(top: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.info.withOpacity(0.1),
                                      AppColors.info.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.info.withOpacity(0.3)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.info),
                                    const SizedBox(width: 4),
                                    Text(
                                      'NPR ${room['hourly_price']}/hr � min ${room['min_hours'] ?? 1}h',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: AppColors.info,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      // Enhanced buttons
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          GestureDetector(
                            onTap: available ? () => _bookNow(room: room) : null,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                              decoration: BoxDecoration(
                                gradient: available ? AppColors.primaryGradient : null,
                                color: available ? null : AppColors.lightGray,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: available ? [
                                  BoxShadow(
                                    color: AppColors.primary.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ] : null,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    available ? Icons.hotel_rounded : Icons.block_rounded,
                                    color: available ? AppColors.white : AppColors.placeholder,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    available ? 'Book Night' : 'Unavailable',
                                    style: TextStyle(
                                      color: available ? AppColors.white : AppColors.placeholder,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 14,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          if (available && room['hourly_available'] == true && room['hourly_price'] != null) ...[
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () => _bookHourly(room: room),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      AppColors.info.withOpacity(0.1),
                                      AppColors.info.withOpacity(0.15),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: AppColors.info.withOpacity(0.4)),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: const [
                                    Icon(Icons.access_time_rounded, color: AppColors.info, size: 16),
                                    SizedBox(width: 6),
                                    Text(
                                      'Book Hour',
                                      style: TextStyle(
                                        color: AppColors.info,
                                        fontWeight: FontWeight.w800,
                                        fontSize: 14,
                                        letterSpacing: 0.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
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

  Widget _roomMeta(IconData icon, String text, Color color) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Icon(icon, size: 12, color: color),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.gray,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Amenities tab
  // ---------------------------------------------------------------------------
  Widget _buildAmenitiesTab() {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 4,
        mainAxisSpacing: 16,
        crossAxisSpacing: 12,
        childAspectRatio: 0.85,
      ),
      itemCount: _amenities.length,
      itemBuilder: (_, i) {
        final amenity = _amenities[i];
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                amenity['icon'] as IconData? ?? Icons.check_circle_outline,
                color: AppColors.primary,
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              amenity['label'] as String? ?? '',
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, color: AppColors.darkGray, fontWeight: FontWeight.w500),
            ),
          ],
        ).animate().fadeIn(duration: 300.ms, delay: (i * 40).ms).scale(begin: const Offset(0.8, 0.8));
      },
    );
  }

  // ---------------------------------------------------------------------------
  // Reviews tab
  // ---------------------------------------------------------------------------
  Widget _buildReviewsTab() {
    final avg = _averageRating;
    final dist = _ratingDistribution;
    final total = dist.values.fold(0, (a, b) => a + b);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
      children: [
        // Rating summary card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: AppColors.cardShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Big score
              Column(
                children: [
                  Text(
                    avg.toStringAsFixed(1),
                    style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: AppColors.darkGray,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RatingBarIndicator(
                    rating: avg,
                    itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.gold),
                    itemCount: 5,
                    itemSize: 16,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$total reviews',
                    style: const TextStyle(color: AppColors.gray, fontSize: 12),
                  ),
                ],
              ),
              const SizedBox(width: 24),
              // Bar chart
              Expanded(
                child: Column(
                  children: [5, 4, 3, 2, 1].map((star) {
                    final count = dist[star] ?? 0;
                    final fraction = total > 0 ? count / total : 0.0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 3),
                      child: Row(
                        children: [
                          Text('$star', style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600)),
                          const SizedBox(width: 4),
                          const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: fraction,
                                minHeight: 8,
                                backgroundColor: AppColors.lightGray,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  star >= 4 ? AppColors.success : star == 3 ? AppColors.gold : AppColors.error,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 24,
                            child: Text(
                              '$count',
                              style: const TextStyle(fontSize: 11, color: AppColors.gray),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 400.ms),
        const SizedBox(height: 16),
        // Individual review cards
        ..._reviews.asMap().entries.map((entry) {
          final i = entry.key;
          final review = entry.value;
          return _buildReviewCard(review).animate().fadeIn(
                duration: 350.ms,
                delay: (i * 80).ms,
              );
        }),
        // View all button
        if (_reviews.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: OutlinedButton(
              onPressed: _viewAllReviews,
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primary,
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('View All Reviews', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
      ],
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final user = review['user'] as Map? ?? {};
    final rating = (review['rating'] as num?)?.toDouble() ?? 0;
    final comment = review['comment'] as String? ?? '';
    final stayDate = review['stayDate'] as String? ?? '';
    final createdAt = review['createdAt'] as String? ?? '';
    final avatarUrl = user['avatar'] as String? ?? 'https://i.pravatar.cc/80';
    final userName = user['name'] as String? ?? 'Guest';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: AppCachedImage(url: avatarUrl, width: 44, height: 44),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.darkGray),
                    ),
                    if (stayDate.isNotEmpty)
                      Text(
                        'Stayed: $stayDate',
                        style: const TextStyle(fontSize: 11, color: AppColors.gray),
                      ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  RatingBarIndicator(
                    rating: rating,
                    itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.gold),
                    itemCount: 5,
                    itemSize: 14,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    createdAt,
                    style: const TextStyle(fontSize: 10, color: AppColors.placeholder),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            comment,
            style: const TextStyle(fontSize: 13, color: AppColors.gray, height: 1.5),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Sticky bottom bar
  // ---------------------------------------------------------------------------
  Widget _buildStickyBottomBar() {
    final startingPrice = (_hotel['starting_price'] as num?)?.toInt() ??
        (_rooms.isNotEmpty ? ((_rooms.first['price'] as num?)?.toInt() ?? 3499) : 3499);

    // Check if any room supports hourly
    final hourlyRoom = _rooms.where((r) => r['hourly_available'] == true && r['hourly_price'] != null).firstOrNull;
    final hourlyPrice = hourlyRoom != null ? (hourlyRoom['hourly_price'] as num?)?.toInt() : null;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.fromLTRB(16, 14, 16, MediaQuery.of(context).padding.bottom + 14),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: AppColors.darkGray.withOpacity(0.15),
              blurRadius: 32,
              offset: const Offset(0, -8),
            ),
            BoxShadow(
              color: AppColors.darkGray.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Price info — fixed width so it never crowds the buttons
            SizedBox(
              width: 130,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Starting from',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.gray,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          'NPR $startingPrice',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const Text(
                          ' /night',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.gray,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (hourlyPrice != null)
                    Text(
                      'NPR $hourlyPrice/hr',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.info[600],
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // Book Night button
            Expanded(
              child: GestureDetector(
                onTap: _bookNow,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.hotel_rounded, color: AppColors.white, size: 17),
                      SizedBox(width: 7),
                      Text(
                        'Book Night',
                        style: TextStyle(
                          color: AppColors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            // Hourly button — only if supported
            if (hourlyRoom != null) ...[
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () => _bookHourly(room: hourlyRoom),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                  decoration: BoxDecoration(
                    color: AppColors.info.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.info.withOpacity(0.4), width: 1.5),
                  ),
                  alignment: Alignment.center,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.access_time_rounded, color: AppColors.info, size: 16),
                      SizedBox(width: 5),
                      Text(
                        'Hourly',
                        style: TextStyle(
                          color: AppColors.info,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Tab bar persistent header delegate
// ---------------------------------------------------------------------------
class _TabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _TabBarDelegate(this.tabBar);

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_TabBarDelegate oldDelegate) => false;
}
