import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/hotel_service.dart';
import '../../../../core/constants/app_colors.dart';

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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token != null) {
        HotelService.setToken(token);
        final hotelService = HotelService();
        final response = await hotelService.getHotelStatus();
        
        debugPrint('Hotel details response: $response');
        
        if (response['success'] == true && response['data'] != null) {
          setState(() {
            _hotelData = response['data'];
            _isLoading = false;
          });
        } else {
          setState(() {
            _hotelData = null;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      debugPrint('Hotel details error: $e');
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFFE60023)))
          : _hotelData == null
              ? _buildEmptyState()
              : CustomScrollView(
                  slivers: [
                    _buildSliverAppBar(),
                    SliverToBoxAdapter(
                      child: RefreshIndicator(
                        onRefresh: _loadHotelData,
                        color: const Color(0xFFE60023),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildStatusCard(),
                              const SizedBox(height: 24),
                              _buildInfoSection('Basic Information', [
                                _buildDetailRow(Icons.hotel_rounded, 'Hotel Name', _hotelData!['name']),
                                _buildDetailRow(Icons.description_rounded, 'Description', _hotelData!['description']),
                                _buildDetailRow(Icons.stars_rounded, 'Star Rating', '${_hotelData!['star_rating']} Stars'),
                              ]),
                              const SizedBox(height: 24),
                              _buildInfoSection('Location Details', [
                                _buildDetailRow(Icons.location_on_rounded, 'Address', _hotelData!['address']),
                                _buildDetailRow(Icons.location_city_rounded, 'City', _hotelData!['city']),
                                _buildDetailRow(Icons.map_rounded, 'State', _hotelData!['state']),
                                _buildDetailRow(Icons.public_rounded, 'Country', _hotelData!['country']),
                                _buildDetailRow(Icons.pin_drop_rounded, 'Pincode', _hotelData!['pincode']),
                              ]),
                              const SizedBox(height: 24),
                              _buildInfoSection('Contact Info', [
                                _buildDetailRow(Icons.phone_rounded, 'Phone', _hotelData!['contact_number'] ?? _hotelData!['phone']),
                                _buildDetailRow(Icons.email_rounded, 'Email', _hotelData!['email']),
                              ]),
                              const SizedBox(height: 24),
                              _buildInfoSection('Policies', [
                                _buildDetailRow(Icons.access_time_filled_rounded, 'Check-in', _hotelData!['check_in_time']),
                                _buildDetailRow(Icons.access_time_rounded, 'Check-out', _hotelData!['check_out_time']),
                                _buildDetailRow(Icons.nightlight_round, 'Min Stay', '${_hotelData!['minimum_stay_nights']} nights'),
                              ]),
                              if (_hotelData!['amenities'] != null) ...[
                                const SizedBox(height: 24),
                                _buildAmenitiesSection(),
                              ],
                              if (_hotelData!['images'] != null) ...[
                                const SizedBox(height: 24),
                                _buildImagesSection(),
                              ],
                              const SizedBox(height: 24),
                              _buildInfoSection('Management', [
                                _buildDetailRow(Icons.currency_exchange_rounded, 'Currency', _hotelData!['currency']),
                                _buildDetailRow(Icons.calendar_today_rounded, 'Registered', _formatDate(_hotelData!['created_at'])),
                                _buildDetailRow(Icons.update_rounded, 'Last Update', _formatDate(_hotelData!['updated_at'])),
                              ]),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildSliverAppBar() {
    final images = _hotelData!['images'];
    String? firstImage;
    if (images is String && images.isNotEmpty) {
      final match = RegExp(r'https?://[^\s",]+').firstMatch(images);
      if (match != null) firstImage = match.group(0);
    }

    return SliverAppBar(
      expandedHeight: 250,
      pinned: true,
      backgroundColor: const Color(0xFFE60023),
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: firstImage != null
            ? Image.network(firstImage, fit: BoxFit.cover)
            : Container(color: const Color(0xFFE60023)),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _loadHotelData,
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.hotel_rounded, size: 80, color: Color(0xFFADB5BD)),
          const SizedBox(height: 16),
          const Text(
            'No Hotel Found',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 8),
          const Text('You haven\'t added any hotel yet.'),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE60023),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Go Back', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final status = (_hotelData!['status'] ?? 'PENDING').toString().toUpperCase();
    Color statusColor;
    IconData statusIcon;

    switch (status) {
      case 'APPROVED':
        statusColor = const Color(0xFF10B981);
        statusIcon = Icons.check_circle_rounded;
        break;
      case 'PENDING':
        statusColor = const Color(0xFFF59E0B);
        statusIcon = Icons.pending_actions_rounded;
        break;
      case 'REJECTED':
        statusColor = const Color(0xFFEF4444);
        statusIcon = Icons.cancel_rounded;
        break;
      default:
        statusColor = AppColors.gray;
        statusIcon = Icons.info_rounded;
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: statusColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor,
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Application Status',
                  style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                ),
                Text(
                  status,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
          ),
          const SizedBox(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, dynamic value) {
    if (value == null || value.toString().isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: const Color(0xFFE60023)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A2E),
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

  Widget _buildAmenitiesSection() {
    final amenities = _hotelData!['amenities'];
    List<String> amenitiesList = [];

    if (amenities is String) {
      amenitiesList = amenities.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    } else if (amenities is List) {
      amenitiesList = amenities.map((e) => e.toString()).toList();
    }

    if (amenitiesList.isEmpty) return const SizedBox.shrink();

    return _buildInfoSection('Amenities', [
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: amenitiesList.map((amenity) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF0F2F5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            amenity,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF1A1A2E)),
          ),
        )).toList(),
      ),
    ]);
  }

  Widget _buildImagesSection() {
    final images = _hotelData!['images'];
    List<String> imagesList = [];

    if (images is String && images.isNotEmpty) {
      final matches = RegExp(r'https?://[^\s",]+').allMatches(images);
      imagesList = matches.map((m) => m.group(0)!).toList();
    } else if (images is List) {
      imagesList = images.map((e) => e.toString()).where((e) => e.startsWith('http')).toList();
    }

    if (imagesList.isEmpty) return const SizedBox.shrink();

    return _buildInfoSection('Property Photos', [
      SizedBox(
        height: 150,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: imagesList.length,
          itemBuilder: (context, index) => Padding(
            padding: const EdgeInsets.only(right: 12),
            child: GestureDetector(
              onTap: () => _showImagePreview(imagesList[index], index),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  imagesList[index],
                  width: 200,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 200,
                    height: 150,
                    color: const Color(0xFFF0F2F5),
                    child: const Icon(Icons.image_not_supported_rounded),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  void _showImagePreview(String imageUrl, int index) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppBar(
              title: Text('Image ${index + 1}'),
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Image.network(imageUrl, fit: BoxFit.contain),
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
