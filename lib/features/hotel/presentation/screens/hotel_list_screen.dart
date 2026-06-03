import 'package:flutter/material.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';

class HotelListScreen extends StatefulWidget {
  const HotelListScreen({super.key});

  @override
  State<HotelListScreen> createState() => _HotelListScreenState();
}

class _HotelListScreenState extends State<HotelListScreen> {
  List<Map<String, dynamic>> _hotels = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHotels();
  }

  Future<void> _loadHotels() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final dynamic response = await ApiService.get(ApiConfig.myHotelsEndpoint);
      debugPrint('🏨 Hotels response: $response');

      List<dynamic> hotelsList = [];
      
      if (response is List) {
        hotelsList = response;
      } else if (response is Map) {
        final data = response['data'] ?? response['hotels'] ?? [];
        hotelsList = data is List ? data : [];
      }

      setState(() {
        _hotels = hotelsList.map((h) => Map<String, dynamic>.from(h as Map)).toList();
      });
      
      debugPrint('✅ Loaded ${_hotels.length} hotels');
    } catch (e) {
      debugPrint('❌ Error loading hotels: $e');
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteHotel(String hotelId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Hotel'),
        content: const Text('Are you sure you want to delete this hotel? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      final response = await ApiService.delete('${ApiConfig.deleteHotelEndpoint}/$hotelId',
          token: null); 

      if (response['success'] == true) {
        setState(() {
          _hotels.removeWhere((hotel) => hotel['id'] == hotelId);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hotel deleted successfully'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message'] ?? 'Failed to delete hotel'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Network error: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _navigateToHotelDetails(Map<String, dynamic> hotel) {
    Navigator.pushNamed(context, '/hotel-details', arguments: hotel);
  }

  void _navigateToCreateHotel() async {
    final result = await Navigator.pushNamed(context, '/create-hotel');
    if (result == true) {
      _loadHotels(); // Refresh list if hotel was created
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'My Hotels',
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _loadHotels,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFFE60023)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadHotels,
        color: const Color(0xFFE60023),
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateHotel,
        backgroundColor: const Color(0xFFE60023),
        label: const Text('Add Hotel', style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        elevation: 4,
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFE60023)));
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: AppColors.gray[400]),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: TextStyle(color: AppColors.gray[600]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadHotels,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_hotels.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.hotel_outlined, size: 64, color: AppColors.gray[400]),
            const SizedBox(height: 16),
            Text(
              'No hotels found',
              style: TextStyle(color: AppColors.gray[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Create your first hotel to get started',
              style: TextStyle(color: AppColors.gray),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _navigateToCreateHotel,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFE60023),
              ),
              child: const Text('Create Hotel'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _hotels.length,
      itemBuilder: (context, index) {
        final hotel = _hotels[index];
        return _buildHotelCard(hotel);
      },
    );
  }

  Widget _buildHotelCard(Map<String, dynamic> hotel) {
    final status = hotel['status']?.toString().toLowerCase() ?? 'pending';
    final statusColor = _getStatusColor(status);
    final roomCount = hotel['_count']?['rooms'] ?? 0;
    final bookingCount = hotel['_count']?['bookings'] ?? 0;
    final imageUrl = hotel['image'] ?? hotel['images'];
    String? firstImage;
    
    if (imageUrl is String && imageUrl.isNotEmpty) {
      if (imageUrl.startsWith('http')) {
        firstImage = imageUrl;
      } else {
        try {
          final decoded = (imageUrl as String).replaceAll('\\"', '"');
          final parsed = decoded.startsWith('[') ? decoded : '[$decoded]';
          // Simple extraction if it looks like a list
          final match = RegExp(r'https?://[^\s",]+').firstMatch(imageUrl);
          if (match != null) firstImage = match.group(0);
        } catch (_) {}
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _navigateToHotelDetails(hotel),
        borderRadius: BorderRadius.circular(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image and Status
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  child: firstImage != null
                      ? Image.network(
                          firstImage,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                        )
                      : _buildPlaceholderImage(),
                ),
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: statusColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w900,
                            color: statusColor,
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          hotel['name'] ?? 'Unnamed Hotel',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.gray),
                        padding: EdgeInsets.zero,
                        onSelected: (value) {
                          if (value == 'delete') {
                            _deleteHotel(hotel['id']);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(Icons.delete_outline_rounded, color: AppColors.error, size: 20),
                                SizedBox(width: 12),
                                Text('Delete Hotel', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 16, color: Color(0xFFE60023)),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${hotel['city'] ?? ''}, ${hotel['state'] ?? ''}',
                          style: const TextStyle(
                            color: Color(0xFF6B7280),
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFF0F2F5)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatItem(Icons.king_bed_rounded, '$roomCount', 'Rooms'),
                      const SizedBox(width: 24),
                      _buildStatItem(Icons.bookmark_rounded, '$bookingCount', 'Bookings'),
                      const Spacer(),
                      const Text(
                        'Manage',
                        style: TextStyle(
                          color: Color(0xFFE60023),
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(Icons.arrow_forward_ios_rounded, size: 12, color: Color(0xFFE60023)),
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

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
      color: const Color(0xFFF0F2F5),
      child: const Icon(Icons.hotel_rounded, size: 64, color: Color(0xFFADB5BD)),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: const Color(0xFF1A1A2E)),
            const SizedBox(width: 6),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF1A1A2E),
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'pending':
        return AppColors.warning;
      case 'rejected':
        return AppColors.error;
      default:
        return AppColors.gray;
    }
  }
}

