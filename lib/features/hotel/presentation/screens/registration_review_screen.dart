import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
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
    extends State<HotelRegistrationReviewScreen> {
  bool _isConfirming = false;

  /// Save hotelId to SharedPreferences after successful registration
  Future<void> _saveHotelId(dynamic hotelId) async {
    if (hotelId == null) return;
    final prefs = await SharedPreferences.getInstance();
    final idStr = hotelId.toString();
    await prefs.setString('hotelId', idStr);
    await prefs.setString('hotel_id', idStr);
    debugPrint('✅ Saved hotelId to SharedPreferences: $idStr');
  }

  /// Determine success from HTTP response - check status code first
  bool _isResponseSuccess(Map<String, dynamic> response, int statusCode) {
    // Check HTTP status first
    if (statusCode >= 200 && statusCode < 300) {
      // Check explicit success/error fields
      if (response.containsKey('error')) {
        return response['error'] == false;
      }
      if (response.containsKey('success')) {
        return response['success'] == true;
      }
      // No explicit error field and HTTP success = treat as success
      return true;
    }
    return false;
  }

  Future<void> _confirmRegistration() async {
    setState(() => _isConfirming = true);

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Authentication required. Please login again.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isConfirming = false);
        return;
      }

      debugPrint('🔑 Using auth token: ${token.substring(0, 20)}...');

      final result = await _createHotelWithImages(token);
      if (!mounted) return;

      final int statusCode = result['_statusCode'] ?? 0;
      final Map<String, dynamic> response = result;
      response.remove('_statusCode');

      debugPrint('📥 Registration response status: $statusCode');
      debugPrint('📥 Registration response body: $response');

      final bool isSuccess = _isResponseSuccess(response, statusCode);

      if (!isSuccess) {
        final errorMessage =
            response['message'] ??
            response['error'] ??
            'Registration failed. Please try again.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage.toString()),
              backgroundColor: AppColors.error,
            ),
          );
        }
        setState(() => _isConfirming = false);
        return;
      }

      // ✅ Save hotelId from response to SharedPreferences
      final responseData = response['data'] ?? response;
      dynamic hotelId =
          responseData['id'] ??
          responseData['hotelId'] ??
          responseData['hotel_id'];

      if (hotelId == null && responseData['hotel'] is Map) {
        hotelId =
            responseData['hotel']['id'] ?? responseData['hotel']['hotelId'];
      }

      if (hotelId != null) {
        await _saveHotelId(hotelId);
        debugPrint('✅ Hotel ID saved after registration: $hotelId');
      } else {
        debugPrint('⚠️ Warning: No hotel ID found in response');
        debugPrint('Response keys: ${responseData.keys.toList()}');
      }

      await authProvider.updateHotelStatus(true);
      await authProvider.setHotelApproved(false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hotel registered successfully! Pending approval.'),
            backgroundColor: AppColors.success,
            duration: Duration(seconds: 2),
          ),
        );

        await Future.delayed(const Duration(milliseconds: 1500));
        if (mounted) context.go('/hotel-pending-approval');
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Registration failed: ${e.toString()}'),
            backgroundColor: AppColors.error,
          ),
        );
        setState(() => _isConfirming = false);
      }
    }
  }

  /// Returns response map with '_statusCode' field for success evaluation
  Future<Map<String, dynamic>> _createHotelWithImages(String token) async {
    try {
      debugPrint('📤 Creating hotel with images using /store-hotel endpoint');
      if (token.isEmpty) throw Exception('Authentication token is required');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/store-hotel'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (widget.hotelName.isEmpty) throw Exception('Hotel name is required');
      if (widget.city.isEmpty) throw Exception('City is required');
      if (widget.hotelPhone.isEmpty)
        throw Exception('Phone number is required');

      request.fields['name'] = widget.hotelName;
      request.fields['address'] = widget.hotelAddress.isNotEmpty
          ? widget.hotelAddress
          : '${widget.landmark}, ${widget.city}';
      request.fields['city'] = widget.city;
      request.fields['country'] = widget.country;
      request.fields['contact_number'] = widget.hotelPhone;

      if (widget.hotelDescription.isNotEmpty)
        request.fields['description'] = widget.hotelDescription;
      if (widget.state.isNotEmpty) request.fields['state'] = widget.state;
      if (widget.latitude != null)
        request.fields['latitude'] = widget.latitude.toString();
      if (widget.longitude != null)
        request.fields['longitude'] = widget.longitude.toString();
      request.fields['currency'] = 'NPR';

      if (widget.exteriorPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'exterior_photo',
            widget.exteriorPhoto!.path,
          ),
        );
      }
      if (widget.receptionPhoto != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'reception_photo',
            widget.receptionPhoto!.path,
          ),
        );
      }
      for (int i = 0; i < widget.galleryPhotos.length && i < 5; i++) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'gallery_images[]',
            widget.galleryPhotos[i].path,
          ),
        );
      }

      debugPrint(
        '🚀 Sending registration request with ${request.files.length} images...',
      );
      final streamed = await request.send();
      final body = await streamed.stream.bytesToString();
      debugPrint('📥 Response status: ${streamed.statusCode}');
      debugPrint('📥 Response body: $body');

      Map<String, dynamic> responseData;
      try {
        responseData = jsonDecode(body) as Map<String, dynamic>;
      } catch (_) {
        responseData = {'data': body};
      }

      // Attach status code for success evaluation
      responseData['_statusCode'] = streamed.statusCode;
      return responseData;
    } catch (e) {
      debugPrint('❌ Hotel registration error: $e');
      return {
        'error': true,
        'message': 'Registration failed: ${e.toString()}',
        '_statusCode': 500,
      };
    }
  }

  void _editDetails() => context.pop();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray.shade50,
      appBar: AppBar(
        backgroundColor: const Color(0xFFE60023),
        foregroundColor: Colors.white,
        title: const Text('Review & Submit'),
        elevation: 0,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE60023), Color(0xFFB8001C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 48,
                      color: Colors.white,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      'Registration Submitted!',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Please review your hotel details before final submission',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Section 1: Basic Info
              _buildSectionTitle('Property Basic Info'),
              _buildInfoCard([
                _infoRow('Hotel Name', widget.hotelName),
                _infoRow('Property Type', widget.propertyType),
                _infoRow('Total Rooms', widget.totalRooms),
                if (widget.yearOfEstablishment.isNotEmpty)
                  _infoRow('Established', widget.yearOfEstablishment),
                if (widget.priceRangeMin.isNotEmpty ||
                    widget.priceRangeMax.isNotEmpty)
                  _infoRow(
                    'Price Range',
                    'Rs. ${widget.priceRangeMin} - Rs. ${widget.priceRangeMax}',
                  ),
                if (widget.hotelDescription.isNotEmpty)
                  _infoRow('Description', widget.hotelDescription),
              ]),

              const SizedBox(height: 20),

              // Section 2: Location
              _buildSectionTitle('Location'),
              _buildInfoCard([
                _infoRow('Country', widget.country),
                _infoRow('Province', widget.state),
                _infoRow('District', widget.district),
                _infoRow('City', widget.city),
                if (widget.wardNumber.isNotEmpty)
                  _infoRow('Ward No.', widget.wardNumber),
                _infoRow('Address', widget.hotelAddress),
                if (widget.landmark.isNotEmpty)
                  _infoRow('Landmark', widget.landmark),
                if (widget.latitude != null && widget.longitude != null)
                  _infoRow(
                    'GPS',
                    '${widget.latitude!.toStringAsFixed(4)}, ${widget.longitude!.toStringAsFixed(4)}',
                  ),
              ]),

              const SizedBox(height: 20),

              // Section 3: Contact
              _buildSectionTitle('Contact'),
              _buildInfoCard([_infoRow('Phone', widget.hotelPhone)]),

              const SizedBox(height: 20),

              // Section 4: Agreements
              _buildSectionTitle('Agreements'),
              _buildInfoCard([
                _agreementRow('Terms & Conditions', widget.termsAccepted),
                _agreementRow(
                  'Commission Agreement',
                  widget.commissionAccepted,
                ),
                _agreementRow(
                  'Cancellation Policy',
                  widget.cancellationPolicyAccepted,
                ),
              ]),

              const SizedBox(height: 32),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isConfirming ? null : _confirmRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE60023),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                  ),
                  child: _isConfirming
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_rounded, size: 22),
                            SizedBox(width: 8),
                            Text(
                              'Looks Good! Submit for Approval',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isConfirming ? null : _editDetails,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(color: AppColors.gray.shade400),
                    foregroundColor: AppColors.gray.shade700,
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.edit_rounded, size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Edit Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Info note
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.info.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.info.shade100),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.info.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your registration will be reviewed within 24-48 hours. You\'ll receive a notification once approved.',
                        style: TextStyle(
                          color: AppColors.info.shade700,
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
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
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: Color(0xFFE60023),
        ),
      ),
    );
  }

  Widget _buildInfoCard(List<Widget> rows) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: rows),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.gray.shade600,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A2E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _agreementRow(String title, bool accepted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            accepted ? Icons.check_circle : Icons.cancel,
            size: 18,
            color: accepted ? AppColors.success : AppColors.gray,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: accepted
                  ? AppColors.success.shade700
                  : AppColors.gray.shade600,
            ),
          ),
          const Spacer(),
          Text(
            accepted ? 'Accepted' : 'Not Accepted',
            style: TextStyle(
              fontSize: 11,
              color: accepted
                  ? AppColors.success.shade600
                  : AppColors.gray.shade500,
            ),
          ),
        ],
      ),
    );
  }
}
