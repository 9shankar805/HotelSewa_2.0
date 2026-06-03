import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/hotel_service.dart';
import '../../../../../../../core/constants/app_colors.dart';

class HotelDetailsScreen extends StatefulWidget {
  const HotelDetailsScreen({super.key});

  @override
  State<HotelDetailsScreen> createState() => _HotelDetailsScreenState();
}

class _HotelDetailsScreenState extends State<HotelDetailsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _hotelData;

  @override
  void initState() {
    super.initState();
    _loadHotelData();
  }

  Future<void> _loadHotelData() async {
    try {
      debugPrint('🏨 Owner Hotel Details: Loading hotel data...');
      
      // Try to get AuthProvider, but handle if it's not available
      AuthProvider? authProvider;
      try {
        authProvider = Provider.of<AuthProvider>(context, listen: false);
      } catch (e) {
        debugPrint('🏨 Owner Hotel Details: AuthProvider not available: $e');
        // Try to get token from SharedPreferences as fallback
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('authToken');
        
        if (token != null) {
          debugPrint('🏨 Owner Hotel Details: Using token from SharedPreferences');
          await _loadHotelDataWithToken(token);
          return;
        } else {
          debugPrint('🏨 Owner Hotel Details: No token available');
          setState(() {
            _hotelData = null;
            _isLoading = false;
          });
          return;
        }
      }
      
      final token = authProvider?.token;
      debugPrint('🏨 Owner Hotel Details: Token available: ${token != null}');
      debugPrint('🏨 Owner Hotel Details: Token preview: ${token?.substring(0, 20)}...');
      
      if (token != null) {
        await _loadHotelDataWithToken(token);
      } else {
        debugPrint('🏨 Owner Hotel Details: No authentication token available');
        setState(() {
          _hotelData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('🏨 Owner Hotel Details: Exception occurred: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _loadHotelDataWithToken(String token) async {
    HotelService.setToken(token);
    final hotelService = HotelService();
    final response = await hotelService.getHotelStatus();
    
    debugPrint('🏨 Owner Hotel Details: API response: $response');
    
    if (response['success'] == true && response['data'] != null) {
      debugPrint('🏨 Owner Hotel Details: Hotel data received: ${response['data'].keys}');
      debugPrint('🏨 Owner Hotel Details: Hotel name: ${response['data']['name']}');
      debugPrint('🏨 Owner Hotel Details: Hotel status: ${response['data']['status']}');
      
      setState(() {
        _hotelData = response['data'];
        _isLoading = false;
      });
    } else {
      debugPrint('🏨 Owner Hotel Details: No hotel data - Success: ${response['success']}, Data: ${response['data']}');
      debugPrint('🏨 Owner Hotel Details: Error message: ${response['message']}');
      
      setState(() {
        _hotelData = null;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60023)))
          : _hotelData == null
              ? _buildEmptyState()
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatusCard().animate().fadeIn(duration: 400.ms),
                            const SizedBox(height: 20),
                            _buildInfoCard('Basic Information', [
                              _buildInfoRow('Hotel Name', _hotelData!['name'], Icons.hotel_rounded),
                              if (_hotelData!['description'] != null)
                                _buildInfoRow('Description', _hotelData!['description'], Icons.description_rounded),
                              _buildInfoRow('Status', _hotelData!['status'], Icons.info_rounded),
                            ]).animate().fadeIn(duration: 400.ms, delay: 100.ms),
                            const SizedBox(height: 20),
                            _buildInfoCard('Location', [
                              _buildInfoRow('Address', _hotelData!['address'], Icons.location_on_rounded),
                              _buildInfoRow('City', _hotelData!['city'], Icons.location_city_rounded),
                              if (_hotelData!['state'] != null)
                                _buildInfoRow('State', _hotelData!['state'], Icons.map_rounded),
                              _buildInfoRow('Country', _hotelData!['country'], Icons.flag_rounded),
                              if (_hotelData!['pincode'] != null)
                                _buildInfoRow('Pincode', _hotelData!['pincode'], Icons.pin_drop_rounded),
                            ]).animate().fadeIn(duration: 400.ms, delay: 200.ms),
                            const SizedBox(height: 20),
                            _buildInfoCard('Contact', [
                              _buildInfoRow('Phone', _hotelData!['contact_number'] ?? _hotelData!['phone'], Icons.phone_rounded),
                              _buildInfoRow('Email', _hotelData!['email'], Icons.email_rounded),
                            ]).animate().fadeIn(duration: 400.ms, delay: 300.ms),
                            const SizedBox(height: 20),
                            _buildInfoCard('Property Details', [
                              _buildInfoRow('Property Type', _hotelData!['property_type'], Icons.business_rounded),
                              _buildInfoRow('Star Rating', _hotelData!['star_rating']?.toString(), Icons.star_rounded),
                              if (_hotelData!['check_in_time'] != null)
                                _buildInfoRow('Check-in Time', _hotelData!['check_in_time'], Icons.login_rounded),
                              if (_hotelData!['check_out_time'] != null)
                                _buildInfoRow('Check-out Time', _hotelData!['check_out_time'], Icons.logout_rounded),
                              if (_hotelData!['minimum_stay_nights'] != null)
                                _buildInfoRow('Minimum Stay', '${_hotelData!['minimum_stay_nights']} nights', Icons.nights_stay_rounded),
                            ]).animate().fadeIn(duration: 400.ms, delay: 400.ms),
                            if (_hotelData!['amenities'] != null) ...[
                              const SizedBox(height: 20),
                              _buildAmenitiesCard().animate().fadeIn(duration: 400.ms, delay: 500.ms),
                            ],
                            if (_hotelData!['images'] != null) ...[
                              const SizedBox(height: 20),
                              _buildImagesCard().animate().fadeIn(duration: 400.ms, delay: 600.ms),
                            ],
                            const SizedBox(height: 20),
                            _buildInfoCard('Registration Details', [
                              _buildInfoRow('User ID', _hotelData!['user_id']?.toString(), Icons.person_rounded),
                              _buildInfoRow('Currency', _hotelData!['currency'], Icons.currency_rupee_rounded),
                              _buildInfoRow('Total Bookings', _hotelData!['total_bookings']?.toString(), Icons.book_rounded),
                              _buildInfoRow('Created', _formatDate(_hotelData!['created_at']), Icons.calendar_today_rounded),
                              _buildInfoRow('Updated', _formatDate(_hotelData!['updated_at']), Icons.update_rounded),
                            ]).animate().fadeIn(duration: 400.ms, delay: 700.ms),
                            const SizedBox(height: 100), // Bottom padding for FAB
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
      floatingActionButton: _hotelData != null ? FloatingActionButton.extended(
        onPressed: () {
          setState(() => _isLoading = true);
          _loadHotelData();
        },
        backgroundColor: const Color(0xFFE60023),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.refresh_rounded),
        label: const Text('Refresh'),
      ).animate().scale(delay: 800.ms) : null,
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      stretch: true,
      backgroundColor: const Color(0xFFE60023),
      flexibleSpace: FlexibleSpaceBar(
        title: Text(
          _hotelData!['name'] ?? 'My Hotel',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                const Color(0xFFE60023),
                const Color(0xFFE60023).withOpacity(0.8),
              ],
            ),
          ),
          child: Stack(
            children: [
              // Background pattern
              Positioned.fill(
                child: Opacity(
                  opacity: 0.1,
                  child: Container(
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1566073771259-6a8506099945?w=800'),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
              // Hotel icon
              const Center(
                child: Icon(
                  Icons.hotel_rounded,
                  size: 80,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('My Hotel'),
        backgroundColor: const Color(0xFFE60023),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60023).withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.hotel_outlined,
                  size: 64,
                  color: Color(0xFFE60023),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'No Hotel Found',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'You haven\'t registered a hotel yet or your hotel is not approved.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 16,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() => _isLoading = true);
                        _loadHotelData();
                      },
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('Retry'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE60023),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () => context.push('/hotel-registration'),
                icon: const Icon(Icons.add_business_rounded),
                label: const Text('Register Hotel'),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE60023),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
            ],
          ),
        ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = _hotelData!['status'] ?? 'PENDING';
    Color statusColor;
    IconData statusIcon;
    String statusMessage;
    
    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        statusMessage = 'Your hotel is approved and live!';
        break;
      case 'PENDING':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending_rounded;
        statusMessage = 'Your hotel is under review';
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        statusMessage = 'Your hotel application was rejected';
        break;
      default:
        statusColor = const Color(0xFF6B7280);
        statusIcon = Icons.info_rounded;
        statusMessage = 'Status unknown';
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            statusColor.withOpacity(0.1),
            statusColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hotel Status',
                  style: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusMessage,
                  style: TextStyle(
                    color: statusColor.withOpacity(0.8),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60023).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _getIconForTitle(title),
                  color: const Color(0xFFE60023),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  IconData _getIconForTitle(String title) {
    switch (title.toLowerCase()) {
      case 'basic information':
        return Icons.info_rounded;
      case 'location':
        return Icons.location_on_rounded;
      case 'contact':
        return Icons.contact_phone_rounded;
      case 'property details':
        return Icons.business_rounded;
      case 'registration details':
        return Icons.app_registration_rounded;
      default:
        return Icons.info_rounded;
    }
  }

  Widget _buildInfoRow(String label, dynamic value, IconData icon) {
    if (value == null) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: const Color(0xFF6B7280).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 16, color: const Color(0xFF6B7280)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF6B7280),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesCard() {
    final amenities = _hotelData!['amenities'];
    List<String> amenitiesList = [];
    
    if (amenities is String) {
      try {
        amenitiesList = (amenities as String).split(',').map((e) => e.trim()).toList();
      } catch (e) {
        amenitiesList = [amenities];
      }
    } else if (amenities is List) {
      amenitiesList = amenities.map((e) => e.toString()).toList();
    }

    final amenityIcons = {
      'wifi': Icons.wifi_rounded,
      'pool': Icons.pool_rounded,
      'spa': Icons.spa_rounded,
      'restaurant': Icons.restaurant_rounded,
      'parking': Icons.local_parking_rounded,
      'gym': Icons.fitness_center_rounded,
      'room service': Icons.room_service_rounded,
      'ac': Icons.ac_unit_rounded,
      'bar': Icons.local_bar_rounded,
      'elevator': Icons.elevator_rounded,
      'concierge': Icons.room_service_rounded,
      'business center': Icons.business_center_rounded,
    };

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60023).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.star_rounded,
                  color: Color(0xFFE60023),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Amenities',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: amenitiesList.length,
            itemBuilder: (context, index) {
              final amenity = amenitiesList[index].toLowerCase();
              final icon = amenityIcons[amenity] ?? Icons.check_circle_rounded;
              
              return Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      const Color(0xFFE60023).withOpacity(0.1),
                      const Color(0xFFE60023).withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFE60023).withOpacity(0.2),
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      icon,
                      color: const Color(0xFFE60023),
                      size: 24,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      amenitiesList[index],
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF2D3748),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(duration: 300.ms, delay: (index * 50).ms).scale(begin: const Offset(0.8, 0.8));
            },
          ),
        ],
      ),
    );
  }

  Widget _buildImagesCard() {
    final images = _hotelData!['images'];
    List<String> imagesList = [];
    
    if (images is String && images.isNotEmpty) {
      try {
        final decoded = images.replaceAll('\\"', '"');
        final parsed = decoded.startsWith('[') ? decoded : '[$decoded]';
        final dynamic jsonData = parsed;
        if (jsonData is String) {
          imagesList = (jsonData as String)
              .replaceAll('[', '')
              .replaceAll(']', '')
              .replaceAll('"', '')
              .split(',')
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty && e.startsWith('http'))
              .toList();
        }
      } catch (e) {
        debugPrint('Image parsing error: $e');
      }
    } else if (images is List) {
      imagesList = images.map((e) => e.toString()).where((e) => e.startsWith('http')).toList();
    }

    if (imagesList.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE60023).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.photo_library_rounded,
                  color: Color(0xFFE60023),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Hotel Images (${imagesList.length})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2D3748),
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: imagesList.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.only(right: index == imagesList.length - 1 ? 0 : 16),
                child: GestureDetector(
                  onTap: () => _showImagePreview(imagesList[index], index),
                  child: Hero(
                    tag: 'hotel-image-$index',
                    child: Container(
                      width: 280,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imagesList[index],
                              width: 280,
                              height: 200,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                width: 280,
                                height: 200,
                                color: AppColors.lightGray,
                                child: const Icon(Icons.image, size: 40),
                              ),
                            ),
                            // Overlay with image number
                            Positioned(
                              top: 12,
                              right: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.7),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${index + 1}/${imagesList.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            // Tap to view overlay
                            Positioned(
                              bottom: 12,
                              left: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.zoom_in_rounded, size: 14, color: Color(0xFFE60023)),
                                    SizedBox(width: 4),
                                    Text(
                                      'Tap to view',
                                      style: TextStyle(
                                        color: Color(0xFFE60023),
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
                      ),
                    ),
                  ),
                ),
              ).animate().fadeIn(duration: 400.ms, delay: (index * 100).ms).slideX(begin: 0.2),
            ),
          ),
        ],
      ),
    );
  }

  void _showImagePreview(String imageUrl, int index) {
    showDialog(
      context: context,
      barrierColor: AppColors.darkGray,
      builder: (context) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Center(
              child: Hero(
                tag: 'hotel-image-$index',
                child: InteractiveViewer(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Container(
                      color: AppColors.gray[800],
                      child: const Icon(Icons.image, size: 100, color: Colors.white),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              left: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Image ${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.day}/${dt.month}/${dt.year}';
    } catch (e) {
      return date.toString();
    }
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          TextField(controller: controller, decoration: const InputDecoration(border: OutlineInputBorder()), maxLines: maxLines),
        ],
      ),
    );
  }
}
