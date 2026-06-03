import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class NearbyAttractionsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const NearbyAttractionsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<NearbyAttractionsScreen> createState() => _NearbyAttractionsScreenState();
}

class _NearbyAttractionsScreenState extends State<NearbyAttractionsScreen> {
  String _selectedCategory = 'All';

  final _categories = ['All', 'Restaurants', 'Transport', 'Attractions', 'Shopping', 'Hospitals'];

  final _attractions = [
    {'name': 'Marine Drive', 'category': 'Attractions', 'distance': '0.2 km', 'rating': 4.8, 'type': 'Landmark', 'icon': Icons.landscape_rounded, 'color': AppColors.teal, 'open': true},
    {'name': 'Trident Hotel Restaurant', 'category': 'Restaurants', 'distance': '0.3 km', 'rating': 4.5, 'type': 'Fine Dining', 'icon': Icons.restaurant_rounded, 'color': AppColors.warning, 'open': true},
    {'name': 'Churchgate Station', 'category': 'Transport', 'distance': '0.5 km', 'rating': 4.2, 'type': 'Railway Station', 'icon': Icons.train_rounded, 'color': AppColors.info, 'open': true},
    {'name': 'Nariman Point', 'category': 'Attractions', 'distance': '0.8 km', 'rating': 4.6, 'type': 'Business District', 'icon': Icons.business_rounded, 'color': AppColors.purple, 'open': true},
    {'name': 'Café Mondegar', 'category': 'Restaurants', 'distance': '1.1 km', 'rating': 4.4, 'type': 'Café', 'icon': Icons.local_cafe_rounded, 'color': AppColors.warning, 'open': true},
    {'name': 'Colaba Causeway', 'category': 'Shopping', 'distance': '1.5 km', 'rating': 4.3, 'type': 'Street Market', 'icon': Icons.shopping_bag_rounded, 'color': AppColors.success, 'open': true},
    {'name': 'Gateway of India', 'category': 'Attractions', 'distance': '1.8 km', 'rating': 4.9, 'type': 'Monument', 'icon': Icons.account_balance_rounded, 'color': AppColors.gold, 'open': true},
    {'name': 'Breach Candy Hospital', 'category': 'Hospitals', 'distance': '2.1 km', 'rating': 4.7, 'type': 'Hospital', 'icon': Icons.local_hospital_rounded, 'color': AppColors.error, 'open': true},
    {'name': 'CSMT Bus Stop', 'category': 'Transport', 'distance': '2.3 km', 'rating': 3.8, 'type': 'Bus Stop', 'icon': Icons.directions_bus_rounded, 'color': AppColors.info, 'open': true},
    {'name': 'Palladium Mall', 'category': 'Shopping', 'distance': '3.0 km', 'rating': 4.5, 'type': 'Shopping Mall', 'icon': Icons.local_mall_rounded, 'color': AppColors.success, 'open': false},
  ];

  List<Map<String, dynamic>> get _filtered => _selectedCategory == 'All'
      ? _attractions
      : _attractions.where((a) => a['category'] == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    final hotel = widget.arguments ?? {};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(hotel['hotelName'] ?? 'Nearby Attractions', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Map placeholder
          Container(
            height: 180,
            color: const Color(0xFFE8F4FD),
            child: Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 56, height: 56,
                        decoration: BoxDecoration(color: AppColors.primary, shape: BoxShape.circle, boxShadow: AppColors.primaryShadow),
                        child: const Icon(Icons.hotel_rounded, color: Colors.white, size: 28),
                      ),
                      const SizedBox(height: 8),
                      const Text('Hotel Location', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                    ],
                  ),
                ),
                Positioned(
                  bottom: 12, right: 12,
                  child: GestureDetector(
                    onTap: () => Navigator.pushNamed(context, '/map-search'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                      child: const Row(children: [
                        Icon(Icons.map_outlined, size: 14, color: AppColors.primary),
                        SizedBox(width: 6),
                        Text('Open Map', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ]),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Category filter
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              height: 36,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (_, i) {
                  final cat = _categories[i];
                  final sel = _selectedCategory == cat;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray),
                      ),
                      child: Center(child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.gray))),
                    ),
                  );
                },
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              itemBuilder: (_, i) {
                final place = _filtered[i];
                final color = place['color'] as Color;
                return Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                  child: Row(
                    children: [
                      Container(
                        width: 46, height: 46,
                        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
                        child: Icon(place['icon'] as IconData, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(place['name'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                            const SizedBox(height: 2),
                            Text(place['type'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.star_rounded, size: 12, color: AppColors.gold),
                              const SizedBox(width: 3),
                              Text('${place['rating']}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                              const SizedBox(width: 8),
                              Container(width: 4, height: 4, decoration: const BoxDecoration(color: AppColors.placeholder, shape: BoxShape.circle)),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: (place['open'] as bool) ? AppColors.successLight : AppColors.errorLight,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text((place['open'] as bool) ? 'Open' : 'Closed',
                                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: (place['open'] as bool) ? AppColors.success : AppColors.error)),
                              ),
                            ]),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(place['distance'] as String, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.primary)),
                          const SizedBox(height: 4),
                          const Icon(Icons.directions_outlined, size: 18, color: AppColors.gray),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: (i * 40).ms).fadeIn().slideX(begin: 0.05);
              },
            ),
          ),
        ],
      ),
    );
  }
}
