import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';\nimport 'package:shared_preferences/shared_preferences.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/hotel_service.dart';
import '../../../../core/services/api_service.dart';
import '../../../../../../../core/constants/app_colors.dart';

class HotelRegistrationReviewScreen extends StatefulWidget {
  // Section 1: Property Basic Info
  final String hotelName;
  final String propertyType;
  final String totalRooms;
  final String yearOfEstablishment;
  final String priceRangeMin;
  final String priceRangeMax;
  final String hotelDescription;

  // Section 2: Location
  final String country;
  final String state;
  final String district;
  final String city;
  final String wardNumber;
  final String hotelAddress;
  final String landmark;
  final double? latitude;
  final double? longitude;

  // Section 3: Contact
  final String hotelPhone;

  // Section 4: Agreements
  final bool termsAccepted;
  final bool commissionAccepted;
  final bool cancellationPolicyAccepted;

  // Section 5: Photos
  final File? exteriorPhoto;
  final File? receptionPhoto;
  final List<File> galleryPhotos;

  const HotelRegistrationReviewScreen({
    super.key,
    // Section 1
    required this.hotelName,
    required this.propertyType,
    required this.totalRooms,
    required this.yearOfEstablishment,
    required this.priceRangeMin,
    required this.priceRangeMax,
    required this.hotelDescription,
    // Section 2
    required this.country,
    required this.state,
    required this.district,
    required this.city,
    required this.wardNumber,
    required this.hotelAddress,
    required this.landmark,
    this.latitude,
    this.longitude,
    // Section 3
    required this.hotelPhone,
    // Section 4
    required this.termsAccepted,
    required this.commissionAccepted,
    required this.cancellationPolicyAccepted,
    // Section 5
    this.exteriorPhoto,
    this.receptionPhoto,
    required this.galleryPhotos,
  });

  @override
  State<HotelRegistrationReviewScreen> createState() =>
      _HotelRegistrationReviewScreenState();
}

class _HotelRegistrationReviewScreenState
    extends State<HotelRegistrationReviewScreen> with TickerProviderStateMixin {
  // Animation Controllers
  late AnimationController _checkmarkController;
  late AnimationController _contentController;
  late AnimationController _buttonController;

  // Checkmark Animations
  late Animation<double> _checkmarkScaleAnimation;
  late Animation<double> _checkmarkOpacityAnimation;

  // Content Animations
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Button Animation
  late Animation<double> _buttonScaleAnimation;
  late Animation<double> _buttonOpacityAnimation;

  // Staggered card animations
  late Animation<double> _card1Animation;
  late Animation<double> _card2Animation;
  late Animation<double> _card3Animation;
  late Animation<double> _card4Animation;
  late Animation<double> _card5Animation;
  late Animation<double> _card6Animation;

  bool _isConfirming = false;

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _startAnimations();
  }

  void _initAnimations() {
    // Checkmark controller
    _checkmarkController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _checkmarkScaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: Curves.elasticOut,
    ));

    _checkmarkOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _checkmarkController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeIn),
    ));

    // Content controller
    _contentController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _contentController,
      curve: const Interval(0.2, 0.7, curve: Curves.easeOutCubic),
    ));

    // Staggered card animations
    _card1Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.3, 0.5, curve: Curves.easeOut)),
    );
    _card2Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.35, 0.55, curve: Curves.easeOut)),
    );
    _card3Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.4, 0.6, curve: Curves.easeOut)),
    );
    _card4Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.45, 0.65, curve: Curves.easeOut)),
    );
    _card5Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.5, 0.7, curve: Curves.easeOut)),
    );
    _card6Animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
          parent: _contentController,
          curve: const Interval(0.55, 0.75, curve: Curves.easeOut)),
    );

    // Button controller
    _buttonController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _buttonScaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: Curves.elasticOut,
    ));

    _buttonOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _buttonController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    ));
  }

  void _startAnimations() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) {
        _checkmarkController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        _contentController.forward();
      }
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        _buttonController.forward();
      }
    });
  }

  Future<void> _confirmRegistration() async {
    setState(() => _isConfirming = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Step 1: Create hotel (JSON, no images)
      final hotelData = {
        'name': widget.hotelName,
        'description': widget.hotelDescription,
        'star_rating': 3,
        'check_in_time': '14:00',
        'check_out_time': '11:00',
        'cancellation_policy': 'Free cancellation 24h before',
        'address': widget.hotelAddress.isNotEmpty
            ? widget.hotelAddress
            : '${widget.landmark}, ${widget.city}',
        'city': widget.city,
        'state': widget.state,
        'country': widget.country,
        if (widget.latitude != null) 'latitude': widget.latitude,
        if (widget.longitude != null) 'longitude': widget.longitude,
        'contact_number': widget.hotelPhone,
        'email': authProvider.user?.email ?? 'owner@hotel.com',
      };

      HotelService.setToken(authProvider.token ?? '');
      final hotelService = HotelService();
      final response = await hotelService.createHotel(hotelData);

      if (!mounted) return;

      if (response['success'] != true) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ));
        return;
      }

      // Step 2: Upload images using the returned hotel ID
      final hotelId = response['data']?['id']?.toString() ?? '';
      if (hotelId.isNotEmpty) {
        final imagesToUpload = [
          if (widget.exteriorPhoto != null) widget.exteriorPhoto!,
          if (widget.receptionPhoto != null) widget.receptionPhoto!,
          ...widget.galleryPhotos,
        ];
        if (imagesToUpload.isNotEmpty) {
          await _uploadImages(imagesToUpload, hotelId);
        }
      }

      // Step 3: Update local state and navigate
      await authProvider.updateHotelStatus(true);
      await authProvider.setHotelApproved(false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(response['message'] ?? 'Hotel submitted for approval!'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ));
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.go('/hotel-pending-approval');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
      }
    } finally {
      if (mounted) setState(() => _isConfirming = false);
    }
  }

  // Upload images to /hotel-owner/media/images using images[] field
  Future<List<String>> _uploadImages(List<File> files, String hotelId) async {
    final List<String> urls = [];
    if (files.isEmpty) return urls;
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/hotel-owner/media/images'),
      );
      request.headers['Authorization'] = 'Bearer ${authProvider.token}';
      request.headers['Accept'] = 'application/json';
      request.fields['hotel_id'] = hotelId;
      for (final file in files) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      final data = jsonDecode(body);
      // Normalize error/success
      if (data['error'] == false && data['data'] is List) {
        for (final item in data['data'] as List) {
          if (item['url'] != null) urls.add(item['url'].toString());
        }
      }
    } catch (e) {
      debugPrint('Image upload error: $e');
    }
    return urls;
  }

  void _editDetails() {
    // Go back to registration screen
    context.pop();
  }

  @override
  void dispose() {
    _checkmarkController.dispose();
    _contentController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray.shade50,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),

              // Animated Success Checkmark
              AnimatedBuilder(
                animation: _checkmarkController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _checkmarkOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _checkmarkScaleAnimation.value,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.success.shade100,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.success.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 70,
                          color: AppColors.success.shade600,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Title
              AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: Column(
                        children: [
                          Text(
                            'Registration Submitted!',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success.shade700,
                                ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please review your hotel details below',
                            style: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.copyWith(
                                  color: AppColors.gray.shade600,
                                ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // ==================== SECTION 1: PROPERTY BASIC INFO ====================
              _buildSectionTitle('Section 1: Property Basic Info'),

              _buildAnimatedCard(
                animation: _card1Animation,
                icon: Icons.hotel_rounded,
                iconColor: AppColors.info,
                title: 'Hotel Name',
                value: widget.hotelName,
              ),

              _buildAnimatedCard(
                animation: _card2Animation,
                icon: Icons.business_rounded,
                iconColor: Colors.purple,
                title: 'Property Type',
                value: widget.propertyType,
              ),

              _buildAnimatedCard(
                animation: _card3Animation,
                icon: Icons.meeting_room_rounded,
                iconColor: Colors.teal,
                title: 'Total Rooms',
                value: widget.totalRooms,
              ),

              if (widget.yearOfEstablishment.isNotEmpty)
                _buildAnimatedCard(
                  animation: _card3Animation,
                  icon: Icons.calendar_today_rounded,
                  iconColor: AppColors.warning,
                  title: 'Year of Establishment',
                  value: widget.yearOfEstablishment,
                ),

              if (widget.priceRangeMin.isNotEmpty ||
                  widget.priceRangeMax.isNotEmpty)
                _buildAnimatedCard(
                  animation: _card3Animation,
                  icon: Icons.attach_money_rounded,
                  iconColor: AppColors.success,
                  title: 'Price Range (per night)',
                  value:
                      'Rs. ${widget.priceRangeMin} - Rs. ${widget.priceRangeMax}',
                ),

              if (widget.hotelDescription.isNotEmpty)
                _buildAnimatedCard(
                  animation: _card4Animation,
                  icon: Icons.description_rounded,
                  iconColor: Colors.indigo,
                  title: 'Description',
                  value: widget.hotelDescription,
                ),

              const SizedBox(height: 24),

              // ==================== SECTION 2: LOCATION ====================
              _buildSectionTitle('Section 2: Location'),

              _buildAnimatedCard(
                animation: _card4Animation,
                icon: Icons.public_rounded,
                iconColor: AppColors.info,
                title: 'Country',
                value: widget.country,
              ),

              _buildAnimatedCard(
                animation: _card4Animation,
                icon: Icons.location_city_rounded,
                iconColor: Colors.purple,
                title: 'Province / State',
                value: widget.state,
              ),

              _buildAnimatedCard(
                animation: _card4Animation,
                icon: Icons.map_rounded,
                iconColor: AppColors.warning,
                title: 'District',
                value: widget.district,
              ),

              _buildAnimatedCard(
                animation: _card4Animation,
                icon: Icons.location_on_rounded,
                iconColor: AppColors.error,
                title: 'City / Municipality',
                value: widget.city,
              ),

              if (widget.wardNumber.isNotEmpty)
                _buildAnimatedCard(
                  animation: _card4Animation,
                  icon: Icons.markunread_mailbox_rounded,
                  iconColor: Colors.teal,
                  title: 'Ward Number',
                  value: widget.wardNumber,
                ),

              _buildAnimatedCard(
                animation: _card5Animation,
                icon: Icons.home_rounded,
                iconColor: Colors.brown,
                title: 'Full Address',
                value: widget.hotelAddress,
              ),

              if (widget.landmark.isNotEmpty)
                _buildAnimatedCard(
                  animation: _card5Animation,
                  icon: Icons.place_rounded,
                  iconColor: Colors.pink,
                  title: 'Landmark',
                  value: widget.landmark,
                ),

              if (widget.latitude != null && widget.longitude != null)
                _buildAnimatedCard(
                  animation: _card5Animation,
                  icon: Icons.gps_fixed_rounded,
                  iconColor: AppColors.success,
                  title: 'GPS Location',
                  value:
                      '${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)}',
                ),

              const SizedBox(height: 24),

              // ==================== SECTION 3: CONTACT ====================
              _buildSectionTitle('Section 3: Contact'),

              _buildAnimatedCard(
                animation: _card5Animation,
                icon: Icons.phone_rounded,
                iconColor: Colors.teal,
                title: 'Contact Phone',
                value: widget.hotelPhone,
              ),

              const SizedBox(height: 24),

              // ==================== SECTION 4: AGREEMENTS ====================
              _buildSectionTitle('Section 4: Agreements'),

              _buildAgreementCard(
                animation: _card6Animation,
                icon: Icons.description_rounded,
                iconColor: AppColors.info,
                title: 'Terms & Conditions',
                accepted: widget.termsAccepted,
              ),

              _buildAgreementCard(
                animation: _card6Animation,
                icon: Icons.handshake_rounded,
                iconColor: AppColors.success,
                title: 'Commission Agreement',
                accepted: widget.commissionAccepted,
              ),

              _buildAgreementCard(
                animation: _card6Animation,
                icon: Icons.cancel_rounded,
                iconColor: AppColors.warning,
                title: 'Cancellation Policy',
                accepted: widget.cancellationPolicyAccepted,
              ),

              const SizedBox(height: 32),

              // Action Buttons
              AnimatedBuilder(
                animation: _buttonController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _buttonOpacityAnimation.value,
                    child: Transform.scale(
                      scale: _buttonScaleAnimation.value,
                      child: Column(
                        children: [
                          // Confirm Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed:
                                  _isConfirming ? null : _confirmRegistration,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFE60023),
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 4,
                              ),
                              child: _isConfirming
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.check_circle_rounded,
                                            color: Colors.white),
                                        SizedBox(width: 8),
                                        Text(
                                          'Looks Good!',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Edit Button
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: _isConfirming ? null : _editDetails,
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.all(16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                side: BorderSide(color: AppColors.gray.shade400),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.edit_rounded,
                                      color: AppColors.gray.shade600),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Edit Details',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.gray.shade700,
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
                },
              ),

              const SizedBox(height: 24),

              // Info message
              AnimatedBuilder(
                animation: _contentController,
                builder: (context, child) {
                  return FadeTransition(
                    opacity: _fadeAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              color: AppColors.info.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Your registration will be reviewed within 24-48 hours. You\'ll receive a notification once approved.',
                              style: TextStyle(
                                color: AppColors.info.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE60023).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE60023),
        ),
      ),
    );
  }

  Widget _buildAnimatedCard({
    required Animation<double> animation,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: AppColors.gray.shade600,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.darkGray,
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

  Widget _buildAgreementCard({
    required Animation<double> animation,
    required IconData icon,
    required Color iconColor,
    required String title,
    required bool accepted,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - animation.value)),
          child: Opacity(
            opacity: animation.value,
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: accepted ? AppColors.success.shade50 : AppColors.gray.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: accepted ? AppColors.success.shade200 : AppColors.gray.shade300,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: accepted
                    ? AppColors.success.withOpacity(0.1)
                    : AppColors.gray.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                accepted ? Icons.check_circle : Icons.cancel,
                color: accepted ? AppColors.success : AppColors.gray,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: accepted
                          ? AppColors.success.shade700
                          : AppColors.gray.shade600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    accepted ? 'Accepted' : 'Not Accepted',
                    style: TextStyle(
                      fontSize: 12,
                      color: accepted
                          ? AppColors.success.shade600
                          : AppColors.gray.shade500,
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
}
