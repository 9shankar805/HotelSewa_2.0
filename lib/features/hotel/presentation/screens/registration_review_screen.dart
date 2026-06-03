import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/hotel_service.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/app_colors.dart';

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
      final token = authProvider.token;
      
      if (token == null || token.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Authentication required. Please login again.'),
          backgroundColor: AppColors.error,
        ));
        setState(() => _isConfirming = false);
        return;
      }

      debugPrint('🔑 Using auth token: ${token.substring(0, 20)}...');

      // Create hotel with images in single request using /store-hotel endpoint
      final response = await _createHotelWithImages(token);

      if (!mounted) return;

      debugPrint('📥 Registration response: $response');

      // Check response format (API uses 'error' field, not 'success')
      final bool isSuccess = response['error'] == false || response['success'] == true;
      
      if (!isSuccess) {
        final errorMessage = response['message'] ?? response['error'] ?? 'Registration failed';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
        ));
        setState(() => _isConfirming = false);
        return;
      }

      // Update local state
      await authProvider.updateHotelStatus(true);
      await authProvider.setHotelApproved(false);

      if (mounted) {
        final imageCount = response['data']?['gallery_images']?.length ?? 0;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Hotel registered with $imageCount image(s)! Pending approval.'),
          backgroundColor: AppColors.success,
          duration: const Duration(seconds: 2),
        ));
        
        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.go('/hotel-pending-approval');
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Registration failed: ${e.toString()}'),
          backgroundColor: AppColors.error,
        ));
        setState(() => _isConfirming = false);
      }
    }
  }

  // Create hotel with images using /store-hotel endpoint (single request)
  Future<Map<String, dynamic>> _createHotelWithImages(String token) async {
    try {
      debugPrint('📤 Creating hotel with images using /store-hotel endpoint');
      debugPrint('📋 Hotel Name: ${widget.hotelName}');
      debugPrint('📋 Address: ${widget.hotelAddress}');
      debugPrint('📋 City: ${widget.city}');
      debugPrint('📋 Phone: ${widget.hotelPhone}');
      debugPrint('📸 Exterior Photo: ${widget.exteriorPhoto?.path ?? "NULL"}');
      debugPrint('📸 Reception Photo: ${widget.receptionPhoto?.path ?? "NULL"}');
      debugPrint('📸 Gallery Photos: ${widget.galleryPhotos.length}');
      
      if (token.isEmpty) {
        throw Exception('Authentication token is required');
      }
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/store-hotel'),
      );
      
      // Headers
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      
      // Required fields validation
      if (widget.hotelName.isEmpty) {
        throw Exception('Hotel name is required');
      }
      if (widget.city.isEmpty) {
        throw Exception('City is required');
      }
      if (widget.hotelPhone.isEmpty) {
        throw Exception('Phone number is required');
      }
      
      // Required fields
      request.fields['name'] = widget.hotelName;
      request.fields['address'] = widget.hotelAddress.isNotEmpty
          ? widget.hotelAddress
          : '${widget.landmark}, ${widget.city}';
      request.fields['city'] = widget.city;
      request.fields['country'] = widget.country;
      request.fields['contact_number'] = widget.hotelPhone;
      
      // Optional fields
      if (widget.hotelDescription.isNotEmpty) {
        request.fields['description'] = widget.hotelDescription;
      }
      if (widget.state.isNotEmpty) {
        request.fields['state'] = widget.state;
      }
      if (widget.latitude != null) {
        request.fields['latitude'] = widget.latitude.toString();
      }
      if (widget.longitude != null) {
        request.fields['longitude'] = widget.longitude.toString();
      }
      request.fields['currency'] = 'NPR';
      
      // REQUIRED: Exterior Photo
      if (widget.exteriorPhoto != null) {
        final fileSize = await widget.exteriorPhoto!.length();
        debugPrint('📎 Adding exterior_photo: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        request.files.add(
          await http.MultipartFile.fromPath(
            'exterior_photo',  // API expects this field name
            widget.exteriorPhoto!.path,
          ),
        );
      } else {
        debugPrint('⚠️ Warning: No exterior photo provided');
      }
      
      // OPTIONAL: Reception Photo
      if (widget.receptionPhoto != null) {
        final fileSize = await widget.receptionPhoto!.length();
        debugPrint('📎 Adding reception_photo: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        request.files.add(
          await http.MultipartFile.fromPath(
            'reception_photo',  // API expects this field name
            widget.receptionPhoto!.path,
          ),
        );
      }
      
      // OPTIONAL: Gallery Photos (max 5)
      for (int i = 0; i < widget.galleryPhotos.length && i < 5; i++) {
        final file = widget.galleryPhotos[i];
        final fileSize = await file.length();
        debugPrint('📎 Adding gallery_images[$i]: ${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB');
        request.files.add(
          await http.MultipartFile.fromPath(
            'gallery_images[]',  // API expects array notation
            file.path,
          ),
        );
      }
      
      debugPrint('🚀 Sending registration request with ${request.files.length} images...');
      debugPrint('📋 Request fields: ${request.fields}');
      
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      
      debugPrint('📥 Response status: ${streamed.statusCode}');
      debugPrint('📥 Response body: $body');
      
      if (streamed.statusCode != 200 && streamed.statusCode != 201) {
        throw Exception('HTTP ${streamed.statusCode}: Registration failed');
      }
      
      final data = jsonDecode(body);
      return data;
    } catch (e) {
      debugPrint('❌ Hotel registration error: $e');
      return {'error': true, 'message': 'Registration failed: ${e.toString()}'};
    }
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

