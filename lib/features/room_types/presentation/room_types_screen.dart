import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';
import '../../booking/presentation/booking_form_screen.dart';

class RoomTypesScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const RoomTypesScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<RoomTypesScreen> createState() => _RoomTypesScreenState();
}

class _RoomTypesScreenState extends State<RoomTypesScreen> {
  List<Map<String, dynamic>> _rooms = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use passed rooms first
    final passedRooms = widget.arguments?['rooms'] as List?;
    if (passedRooms != null && passedRooms.isNotEmpty) {
      setState(() {
        _rooms = passedRooms.cast<Map<String, dynamic>>();
        _loading = false;
      });
      return;
    }

    // Fetch from hotel details
    final hotelId = widget.arguments?['hotelId']?.toString();
    if (hotelId != null) {
      try {
        final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelDetailsEndpoint, hotelId));
        if (response['success'] == true) {
          final data = response['data'];
          final roomTypes = data is Map ? (data['room_types'] ?? data['rooms'] ?? []) : [];
          if (roomTypes is List && roomTypes.isNotEmpty) {
            setState(() {
              _rooms = roomTypes.map<Map<String, dynamic>>((r) => {
                'id': r['id']?.toString() ?? '',
                'name': r['name'] ?? 'Room',
                'price': (r['price'] ?? r['base_price'] ?? 2500) as num,
                'originalPrice': ((r['price'] ?? 2500) * 1.2).toInt(),
                'discount': r['discount'] ?? 20,
                'size': r['size'] ?? '${r['area'] ?? 250} sq ft',
                'occupancy': '${r['max_adults'] ?? 2} Adults',
                'bedType': r['bed_type'] ?? 'Standard Bed',
                'amenities': (r['amenities'] as List?)?.map((a) => a.toString()).toList() ?? ['WiFi', 'AC'],
                'image': _parseImage(r['image'] ?? r['images']),
                'available': r['available_count'] ?? r['available'] ?? 1,
                'hourlyAvailable': r['hourly_available'] == true,
                'hourlyPrice': r['hourly_price'],
              }).toList();
              _loading = false;
            });
            return;
          }
        }
      } catch (e) {
        setState(() => _error = 'Failed to load rooms');
      }
    }
    setState(() => _loading = false);
  }

  String _parseImage(dynamic images) {
    if (images is String && images.startsWith('http')) return images;
    if (images is List && images.isNotEmpty) {
      final first = images[0];
      return first is Map ? (first['url']?.toString() ?? '') : first.toString();
    }
    return 'https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=600';
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
        title: Text(widget.arguments?['hotelName'] ?? 'Room Types', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.error_outline, size: 48, color: AppColors.placeholder),
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.gray)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry'),
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white)),
                ]))
              : _rooms.isEmpty
                  ? const Center(child: Text('No rooms available', style: TextStyle(color: AppColors.gray)))
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _rooms.length,
                      itemBuilder: (_, i) => _buildRoomCard(_rooms[i], i),
                    ),
    );
  }

  Widget _buildRoomCard(Map<String, dynamic> room, int index) {
    final available = (room['available'] as num?)?.toInt() ?? 1;
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            child: Stack(
              children: [
                CachedNetworkImage(
                  imageUrl: room['image'],
                  width: double.infinity, height: 180, fit: BoxFit.cover,
                  placeholder: (_, __) => Container(height: 180, color: AppColors.surfaceVariant),
                  errorWidget: (_, __, ___) => Container(height: 180, color: AppColors.surfaceVariant, child: const Icon(Icons.bed_rounded, size: 48, color: AppColors.placeholder)),
                ),
                if (available <= 2)
                  Positioned(top: 12, right: 12, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.error, borderRadius: BorderRadius.circular(8)),
                    child: Text('Only $available left!', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  )),
                if (room['hourlyAvailable'] == true)
                  Positioned(top: 12, left: 12, child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: AppColors.info, borderRadius: BorderRadius.circular(8)),
                    child: const Text('⏰ Hourly', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.white)),
                  )),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(room['name'], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const SizedBox(height: 8),
                Row(children: [
                  _infoChip(Icons.square_foot_rounded, room['size']),
                  const SizedBox(width: 12),
                  _infoChip(Icons.people_rounded, room['occupancy']),
                  const SizedBox(width: 12),
                  _infoChip(Icons.bed_rounded, room['bedType']),
                ]),
                const SizedBox(height: 10),
                Wrap(spacing: 6, runSpacing: 6, children: (room['amenities'] as List).take(5).map((a) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(6)),
                  child: Text(a.toString(), style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
                )).toList()),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if ((room['discount'] as num?) != null && (room['discount'] as num) > 0)
                        Text('Rs.${room['originalPrice']}', style: const TextStyle(fontSize: 12, color: AppColors.gray, decoration: TextDecoration.lineThrough)),
                      Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                        Text('Rs.${room['price']}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.primary)),
                        const Text(' /night', style: TextStyle(fontSize: 11, color: AppColors.gray)),
                      ]),
                      if (room['hourlyAvailable'] == true && room['hourlyPrice'] != null)
                        Text('Rs.${room['hourlyPrice']}/hr', style: const TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w600)),
                    ]),
                    ElevatedButton(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(
                        builder: (_) => BookingFormScreen(arguments: {
                          ...?widget.arguments,
                          'room': room,
                          'roomId': room['id'],
                          'roomName': room['name'],
                          'price': room['price'],
                        }),
                      )),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Book Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate(delay: (index * 80).ms).fadeIn().slideY(begin: 0.1);
  }

  Widget _infoChip(IconData icon, String text) => Row(mainAxisSize: MainAxisSize.min, children: [
    Icon(icon, size: 13, color: AppColors.gray),
    const SizedBox(width: 4),
    Text(text, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
  ]);
}
