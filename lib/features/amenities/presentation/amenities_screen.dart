import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class AmenitiesScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  
  const AmenitiesScreen({Key? key, this.arguments}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amenities = arguments?['amenities'] ?? [
      {'id': '1', 'name': 'Free WiFi', 'icon': Icons.wifi, 'available': true},
      {'id': '2', 'name': 'Air Conditioning', 'icon': Icons.ac_unit, 'available': true},
      {'id': '3', 'name': 'Free Parking', 'icon': Icons.local_parking, 'available': true},
      {'id': '4', 'name': 'Swimming Pool', 'icon': Icons.pool, 'available': false},
      {'id': '5', 'name': 'Gym/Fitness Center', 'icon': Icons.fitness_center, 'available': true},
      {'id': '6', 'name': '24/7 Front Desk', 'icon': Icons.schedule, 'available': true},
      {'id': '7', 'name': 'Room Service', 'icon': Icons.room_service, 'available': true},
      {'id': '8', 'name': 'Laundry Service', 'icon': Icons.local_laundry_service, 'available': false},
      {'id': '9', 'name': 'Restaurant', 'icon': Icons.restaurant, 'available': true},
      {'id': '10', 'name': 'Bar/Lounge', 'icon': Icons.local_bar, 'available': false},
      {'id': '11', 'name': 'Business Center', 'icon': Icons.business_center, 'available': true},
      {'id': '12', 'name': 'Pet Friendly', 'icon': Icons.pets, 'available': false},
      {'id': '13', 'name': 'Elevator', 'icon': Icons.elevator, 'available': true},
      {'id': '14', 'name': 'Wheelchair Accessible', 'icon': Icons.accessible, 'available': true},
      {'id': '15', 'name': 'Complimentary Breakfast', 'icon': Icons.free_breakfast, 'available': false},
      {'id': '16', 'name': 'Airport Shuttle', 'icon': Icons.airport_shuttle, 'available': false},
    ];

    final available = amenities.where((a) => a['available'] == true).toList();
    final unavailable = amenities.where((a) => a['available'] == false).toList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Available Amenities', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 4),
                  Text('${available.length} amenities included', style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                  const SizedBox(height: 16),
                  ...available.map((amenity) => _buildAmenityItem(amenity, true)).toList(),
                ],
              ),
            ),
            if (unavailable.isNotEmpty)
              Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Not Available', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                    const SizedBox(height: 4),
                    Text('${unavailable.length} amenities not included', style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                    const SizedBox(height: 16),
                    ...unavailable.map((amenity) => _buildAmenityItem(amenity, false)).toList(),
                  ],
                ),
              ),
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE6F7FF), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info, size: 24, color: Color(0xFF1890FF)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Amenities may vary by room type. Contact the hotel directly for specific details about your reservation.',
                      style: TextStyle(fontSize: 14, color: Color(0xFF1890FF), height: 1.4),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAmenityItem(Map<String, dynamic> amenity, bool available) {
    return Opacity(
      opacity: available ? 1.0 : 0.6,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Icon(amenity['icon'] as IconData, size: 24, color: available ? const Color(0xFF52C41A) : const Color(0xFFCCCCCC)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                amenity['name'] as String,
                style: TextStyle(
                  fontSize: 16,
                  color: available ? const Color(0xFF333333) : const Color(0xFF999999),
                  decoration: available ? TextDecoration.none : TextDecoration.lineThrough,
                ),
              ),
            ),
            Icon(
              available ? Icons.check_circle : Icons.cancel,
              size: 20,
              color: available ? const Color(0xFF52C41A) : const Color(0xFFFF4D4F),
            ),
          ],
        ),
      ),
    );
  }
}
