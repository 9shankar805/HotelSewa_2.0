import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../../../../core/constants/app_colors.dart';

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
      final dynamic response = await ApiService.get('/hotels/mine');
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
      final response = await ApiService.delete('/delete-user',
          token: null); // hotel delete maps to delete-user or update-profile

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
      appBar: AppBar(
        title: const Text('My Hotels'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadHotels,
        child: _buildBody(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateHotel,
        backgroundColor: const Color(0xFFE60023),
        child: const Icon(Icons.add),
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

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () => _navigateToHotelDetails(hotel),
        child: Padding(
          padding: const EdgeInsets.all(16),
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
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                hotel['address'] ?? 'No address',
                style: TextStyle(color: AppColors.gray[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '${hotel['city'] ?? ''}, ${hotel['state'] ?? ''}',
                style: TextStyle(color: AppColors.gray),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _buildStatItem(Icons.hotel, '$roomCount', 'Rooms'),
                  const SizedBox(width: 16),
                  _buildStatItem(Icons.book, '$bookingCount', 'Bookings'),
                  const Spacer(),
                  PopupMenuButton<String>(
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
                            Icon(Icons.delete, color: AppColors.error),
                            SizedBox(width: 8),
                            Text('Delete'),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gray[600]),
        const SizedBox(width: 4),
        Text(
          '$value $label',
          style: TextStyle(color: AppColors.gray[600], fontSize: 12),
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
