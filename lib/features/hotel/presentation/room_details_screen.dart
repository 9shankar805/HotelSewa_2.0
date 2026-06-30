import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/utils/image_url_helper.dart';
import '../../booking/presentation/booking_form_screen.dart';

class RoomDetailsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const RoomDetailsScreen({super.key, this.arguments});

  @override
  State<RoomDetailsScreen> createState() => _RoomDetailsScreenState();
}

class _RoomDetailsScreenState extends State<RoomDetailsScreen> {
  final PageController _imagePageController = PageController();
  int _currentImageIndex = 0;
  List<String> _selectedAmenities = [];
  final List<String> _allAmenities = [
    'Free WiFi',
    'Air Conditioning',
    'Room Service',
    'Flat-screen TV',
    'Mini Bar',
    'Safe',
    'Tea/Coffee Maker',
    'Daily Housekeeping',
    'Wake-up Service',
    'Desk',
    'Ironing Facilities',
    'Private Bathroom',
    'Free Toiletries',
    'Shower',
    'Hair Dryer',
    'Slippers',
    'Bathrobe',
    'City View',
    'Garden View',
    'Pool View',
  ];

  @override
  void dispose() {
    _imagePageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.arguments?['room'] as Map<String, dynamic>? ?? {};
    final hotel = widget.arguments?['hotel'] as Map<String, dynamic>? ?? {};
    
    final roomImages = List<String>.from(room['images'] as List? ?? []);
    final mainImage = room['image'] as String?;
    final List<String> images = [];
    
    if (mainImage != null && mainImage.isNotEmpty) {
      images.add(ImageUrlHelper.fix(mainImage));
    }
    for (final img in roomImages) {
      final fixed = ImageUrlHelper.fix(img);
      if (fixed.isNotEmpty && !images.contains(fixed)) {
        images.add(fixed);
      }
    }
    
    if (images.isEmpty) {
      images.add('https://images.unsplash.com/photo-1631049307264-da0ec9d70304?w=800');
    }
    
    final price = (room['price'] as num?)?.toInt() ?? 0;
    final originalPrice = (room['original_price'] as num?)?.toInt() ?? (price * 1.3).toInt();
    final discount = (room['discount'] as num?)?.toInt() ?? 0;
    final roomType = room['type'] as String? ?? 'Standard Room';
    final roomDescription = room['description'] as String? ?? 'Experience a comfortable stay in our well-appointed room.';
    
    // Create gallery categories for room
    final List<Map<String, dynamic>> galleryCategories = [
      {
        'name': 'All',
        'images': images,
      },
      {
        'name': 'Bedroom',
        'images': images.take(2).toList(),
      },
      {
        'name': 'Bathroom',
        'images': images.skip(1).take(2).toList(),
      },
      {
        'name': 'View',
        'images': images.take(1).toList(),
      },
      {
        'name': 'Amenities',
        'images': images.skip(2).take(2).toList(),
      },
    ];
    
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildImageGallery(images, galleryCategories),
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRoomTitle(roomType, price, originalPrice, discount),
                    _buildDivider(),
                    _buildRoomDescription(roomDescription),
                    _buildDivider(),
                    _buildAmenitiesSection(),
                    _buildDivider(),
                    _buildRoomFeatures(room),
                    _buildDivider(),
                    _buildHouseRules(),
                    const SizedBox(height: 120),
                  ],
                ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1),
              ),
            ],
          ),
          _buildStickyBottomBar(room, hotel, price),
        ],
      ),
    );
  }

  Widget _buildImageGallery(List<String> images, List<Map<String, dynamic>> galleryCategories) {
    return SliverAppBar(
      expandedHeight: 400,
      pinned: true,
      stretch: true,
      backgroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.arrow_back, size: 22, color: Colors.black),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.all(8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.95),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.share, size: 22, color: Colors.black),
              onPressed: () {},
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
        background: Stack(
          fit: StackFit.expand,
          children: [
            PageView.builder(
              controller: _imagePageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _currentImageIndex = i),
              itemBuilder: (_, i) => AppCachedImage(
                url: images[i],
                fit: BoxFit.cover,
              ),
            ),
            if (images.isNotEmpty) Positioned(
              bottom: 110,
              right: 20,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library, color: Colors.white, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      '${_currentImageIndex + 1}/${images.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.only(bottom: 16, top: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    SizedBox(
                      height: 80,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: galleryCategories.length,
                        itemBuilder: (context, index) {
                          final category = galleryCategories[index];
                          final categoryName = category['name'] as String;
                          final categoryImages = category['images'] as List<String>;
                          final isSelected = index == 0;
                          
                          return GestureDetector(
                            onTap: () {
                              if (categoryImages.isNotEmpty) {
                                final imageUrl = categoryImages.first;
                                final imageIndex = images.indexOf(imageUrl);
                                if (imageIndex != -1) {
                                  _imagePageController.jumpToPage(imageIndex);
                                }
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 10),
                              child: Column(
                                children: [
                                  Container(
                                    width: 100,
                                    height: 60,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected ? Colors.white : Colors.transparent,
                                        width: 2,
                                      ),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: categoryImages.isNotEmpty
                                          ? AppCachedImage(
                                              url: categoryImages.first,
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 60,
                                            )
                                          : Container(
                                              color: Colors.grey[300],
                                              child: const Icon(
                                                Icons.image,
                                                color: Colors.grey,
                                                size: 30,
                                              ),
                                            ),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isSelected ? Colors.white : Colors.black.withOpacity(0.5),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      categoryName,
                                      style: TextStyle(
                                        color: isSelected ? Colors.black : Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoomTitle(String roomType, int price, int originalPrice, int discount) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            roomType,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.amber, size: 20),
              const SizedBox(width: 4),
              Text(
                '4.5 (234 reviews)',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (discount > 0) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$discount% OFF',
                    style: const TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '₹$originalPrice',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          Text.rich(
            TextSpan(
              children: [
                const TextSpan(
                  text: '₹',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextSpan(
                  text: '$price',
                  style: const TextStyle(
                    fontSize: 28,
                    color: Colors.black,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const TextSpan(
                  text: ' / night',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '+ ₹${(price * 0.12).toInt()} taxes & fees',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      height: 8,
      color: Colors.grey[100],
    );
  }

  Widget _buildRoomDescription(String description) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'About the Room',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: TextStyle(
              fontSize: 15,
              color: Colors.grey[700],
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmenitiesSection() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Amenities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 1.2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemCount: _allAmenities.length,
            itemBuilder: (context, index) {
              final amenity = _allAmenities[index];
              final isSelected = _selectedAmenities.contains(amenity);
              
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (isSelected) {
                      _selectedAmenities.remove(amenity);
                    } else {
                      _selectedAmenities.add(amenity);
                    }
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.red[50] : Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? Colors.red : Colors.grey[200]!,
                      width: 1.5,
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        _getAmenityIcon(amenity),
                        size: 28,
                        color: isSelected ? Colors.red : Colors.grey[700],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        amenity,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.red : Colors.grey[700],
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  IconData _getAmenityIcon(String amenity) {
    switch (amenity.toLowerCase()) {
      case 'free wifi':
        return Icons.wifi;
      case 'air conditioning':
        return Icons.ac_unit;
      case 'room service':
        return Icons.room_service;
      case 'flat-screen tv':
        return Icons.tv;
      case 'mini bar':
        return Icons.local_bar;
      case 'safe':
        return Icons.lock;
      case 'tea/coffee maker':
        return Icons.emoji_food_beverage;
      case 'daily housekeeping':
        return Icons.cleaning_services;
      case 'wake-up service':
        return Icons.alarm;
      case 'desk':
        return Icons.desk;
      case 'ironing facilities':
        return Icons.iron;
      case 'private bathroom':
        return Icons.bathroom;
      case 'free toiletries':
        return Icons.local_hospital;
      case 'shower':
        return Icons.shower;
      case 'hair dryer':
        return Icons.air;
      case 'slippers':
        return Icons.directions_walk;
      case 'bathrobe':
        return Icons.checkroom;
      case 'city view':
        return Icons.location_city;
      case 'garden view':
        return Icons.park;
      case 'pool view':
        return Icons.pool;
      default:
        return Icons.check_circle;
    }
  }

  Widget _buildRoomFeatures(Map<String, dynamic> room) {
    final features = [
      'Room Size: 300 sq ft',
      'Bed Type: King Size',
      'Max Guests: 3 Adults',
      'Smoking: No',
      'View: City',
      'Floor: 2nd - 5th',
    ];
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Room Features',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...features.map((feature) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        feature,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildHouseRules() {
    final rules = [
      'Check-in: 2:00 PM',
      'Check-out: 12:00 PM',
      'Pets not allowed',
      'Unmarried couples allowed',
      'Valid ID required',
      'No smoking',
    ];
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'House Rules',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ...rules.map((rule) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        rule,
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildStickyBottomBar(Map<String, dynamic> room, Map<String, dynamic> hotel, int price) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        const Text(
                          '₹',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.black,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '$price',
                          style: const TextStyle(
                            fontSize: 24,
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '/ night',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+ ₹${(price * 0.12).toInt()} taxes',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => BookingFormScreen(
                          arguments: {
                            'hotel': hotel,
                            'room': room,
                          },
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Book Now',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
