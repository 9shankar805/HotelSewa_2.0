import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/favorite_service.dart';
import '../../../core/services/shared/auth_service.dart';
import '../../../core/widgets/shimmer_loading.dart';
import '../../hotel/presentation/hotel_details_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({Key? key}) : super(key: key);

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  final FavoriteService _favoriteService = FavoriteService();
  final AuthService _authService = AuthService();

  List<Map<String, dynamic>> _favorites = [];
  bool _loading = true;
  bool _isLoggedIn = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final loggedIn = await _authService.isLoggedIn();
    setState(() => _isLoggedIn = loggedIn);
    if (loggedIn) _loadFavorites();
    else setState(() => _loading = false);
  }

  Future<void> _loadFavorites() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _favoriteService.getFavorites();
      if (result['success'] == true) {
        final raw = result['favorites'];
        List items = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['hotels'] ?? []) : []);
        setState(() {
          _favorites = items.map<Map<String, dynamic>>((h) {
            final img = _parseImage(h['image'] ?? h['images']);
            return {
              'id': h['id']?.toString() ?? '',
              'name': h['name'] ?? 'Hotel',
              'address': _buildAddress(h),
              'image': img,
              'rating': (h['rating'] as num?)?.toDouble() ?? 0.0,
              'reviewCount': (h['total_reviews'] ?? h['review_count'] ?? 0) as int,
              'price': (h['min_price'] ?? h['price'] ?? 0) as num,
            };
          }).toList();
          _loading = false;
        });
      } else {
        setState(() { _error = result['message'] ?? 'Failed to load saved hotels'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load saved hotels'; _loading = false; });
    }
  }

  Future<void> _removeFavorite(String hotelId, int index) async {
    // Optimistic removal
    final removed = _favorites[index];
    setState(() => _favorites.removeAt(index));
    final result = await _favoriteService.toggleFavorite(hotelId);
    if (result['success'] != true) {
      // Revert on failure
      setState(() => _favorites.insert(index, removed));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to remove from saved'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  String _parseImage(dynamic images) {
    if (images is String && images.isNotEmpty) {
      if (images.startsWith('http')) return images;
      try {
        final d = List.from(images as dynamic);
        if (d.isNotEmpty) return d[0].toString();
      } catch (_) {}
    }
    if (images is List && images.isNotEmpty) {
      final f = images[0];
      return f is Map ? (f['url']?.toString() ?? '') : f.toString();
    }
    return 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=600';
  }

  String _buildAddress(Map h) {
    final city = h['city']?.toString() ?? '';
    final state = h['state']?.toString() ?? '';
    if (city.isEmpty && state.isEmpty) return h['address']?.toString() ?? '';
    if (state.isEmpty) return city;
    if (city.isEmpty) return state;
    return '$city, $state';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Saved Hotels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          if (_isLoggedIn && _favorites.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray),
              onPressed: _loadFavorites,
            ),
        ],
      ),
      body: !_isLoggedIn
          ? _buildLoginPrompt()
          : _loading
              ? const Padding(padding: EdgeInsets.all(16), child: HotelListShimmer(count: 4))
              : _error != null
                  ? _buildError()
                  : _favorites.isEmpty
                      ? _buildEmpty()
                      : RefreshIndicator(
                          onRefresh: _loadFavorites,
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _favorites.length,
                            itemBuilder: (_, i) => _buildCard(_favorites[i], i),
                          ),
                        ),
    );
  }

  Widget _buildCard(Map<String, dynamic> hotel, int index) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => HotelDetailsScreen(arguments: {'hotelId': hotel['id']}),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow,
        ),
        child: Row(
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(20)),
              child: Image.network(
                hotel['image'],
                width: 110,
                height: 110,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 110, height: 110,
                  color: AppColors.surfaceVariant,
                  child: const Icon(Icons.hotel_rounded, size: 36, color: AppColors.placeholder),
                ),
              ),
            ),
            // Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      hotel['name'],
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, size: 12, color: AppColors.gray),
                      const SizedBox(width: 3),
                      Expanded(child: Text(hotel['address'],
                        style: const TextStyle(fontSize: 12, color: AppColors.gray),
                        maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ]),
                    const SizedBox(height: 6),
                    if ((hotel['rating'] as double) > 0)
                      Row(children: [
                        const Icon(Icons.star_rounded, size: 13, color: AppColors.gold),
                        const SizedBox(width: 3),
                        Text('${hotel['rating']}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        if ((hotel['reviewCount'] as int) > 0)
                          Text(' (${hotel['reviewCount']})',
                            style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      ]),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'NPR ${hotel['price']}',
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.primary),
                        ),
                        GestureDetector(
                          onTap: () => _removeFavorite(hotel['id'], index),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.favorite_rounded, size: 16, color: AppColors.error),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ).animate(delay: (index * 50).ms).fadeIn().slideY(begin: 0.05, end: 0),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.favorite_border_rounded, size: 48, color: AppColors.error),
            ),
            const SizedBox(height: 24),
            const Text('No saved hotels yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 10),
            const Text(
              'Tap the heart icon on any hotel to save it here for quick access.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/search'),
              icon: const Icon(Icons.search_rounded, size: 18, color: Colors.white),
              label: const Text('Discover Hotels', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 100, height: 100,
              decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), shape: BoxShape.circle),
              child: const Icon(Icons.lock_outline_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: 24),
            const Text('Login to see saved hotels', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 10),
            const Text('Sign in to save your favourite hotels and access them anytime.',
              textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Sign In', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded, size: 56, color: AppColors.placeholder),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _loadFavorites,
              icon: const Icon(Icons.refresh_rounded, size: 18, color: Colors.white),
              label: const Text('Retry', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary, elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Reuse shimmer from shimmer_loading.dart
class _ImageErrorWidget extends StatelessWidget {
  const _ImageErrorWidget();
  @override
  Widget build(BuildContext context) => Container(
    color: AppColors.surfaceVariant,
    child: const Icon(Icons.hotel_rounded, size: 36, color: AppColors.placeholder),
  );
}
