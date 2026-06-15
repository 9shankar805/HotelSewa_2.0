import 'package:flutter/material.dart';
import '../services/hotel_service.dart';
import '../../../../core/constants/app_colors.dart';

class HotelCreationScreen extends StatefulWidget {
  const HotelCreationScreen({super.key});

  @override
  State<HotelCreationScreen> createState() => _HotelCreationScreenState();
}

class _HotelCreationScreenState extends State<HotelCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'Nepal');
  final _pincodeController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _checkInController = TextEditingController(text: '14:00');
  final _checkOutController = TextEditingController(text: '11:00');
  
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _pincodeController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _checkInController.dispose();
    _checkOutController.dispose();
    super.dispose();
  }

  final HotelService _hotelService = HotelService();
  
  Future<void> _createHotel() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _hotelService.createHotel({
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'address': _addressController.text.trim(),
        'city': _cityController.text.trim(),
        'state': _stateController.text.trim(),
        'country': _countryController.text.trim(),
        'contact_number': _phoneController.text.trim(),
        'email': _emailController.text.trim(),
        'check_in_time': _checkInController.text.trim(),
        'check_out_time': _checkOutController.text.trim(),
        'star_rating': 3,
        'cancellation_policy': 'Free cancellation 24h before',
      });

      if (response['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hotel created successfully!'),
              backgroundColor: AppColors.success,
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        setState(() {
          _errorMessage = response['message'] ?? 'Failed to create hotel';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Error: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'List Your Property',
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE60023),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_errorMessage != null) _buildErrorBanner(),
                    
                    _buildFormSection('General Information', [
                      _buildTextField(
                        controller: _nameController,
                        label: 'Hotel Name',
                        hint: 'e.g. Grand Heritage Resort',
                        icon: Icons.hotel_rounded,
                        validator: (value) => value?.isEmpty == true ? 'Hotel name is required' : null,
                      ),
                      _buildTextField(
                        controller: _descriptionController,
                        label: 'Description',
                        hint: 'Tell us what makes your hotel special...',
                        icon: Icons.description_rounded,
                        maxLines: 4,
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildFormSection('Location Details', [
                      _buildTextField(
                        controller: _addressController,
                        label: 'Street Address',
                        hint: 'Full street address',
                        icon: Icons.location_on_rounded,
                        maxLines: 2,
                        validator: (value) => value?.isEmpty == true ? 'Address is required' : null,
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              hint: 'City',
                              icon: Icons.location_city_rounded,
                              validator: (value) => value?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _stateController,
                              label: 'State',
                              hint: 'State',
                              icon: Icons.map_rounded,
                              validator: (value) => value?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _countryController,
                              label: 'Country',
                              hint: 'Country',
                              icon: Icons.public_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _pincodeController,
                              label: 'Pincode',
                              hint: 'Pincode',
                              icon: Icons.pin_drop_rounded,
                              keyboardType: TextInputType.number,
                              validator: (value) => value?.isEmpty == true ? 'Required' : null,
                            ),
                          ),
                        ],
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildFormSection('Contact Information', [
                      _buildTextField(
                        controller: _phoneController,
                        label: 'Phone Number',
                        hint: 'Primary contact number',
                        icon: Icons.phone_rounded,
                        keyboardType: TextInputType.phone,
                        validator: (value) => value?.isEmpty == true ? 'Phone number is required' : null,
                      ),
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email Address',
                        hint: 'For bookings and inquiries',
                        icon: Icons.email_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value?.isEmpty == true) return 'Email is required';
                          if (!value!.contains('@')) return 'Invalid email address';
                          return null;
                        },
                      ),
                    ]),

                    const SizedBox(height: 24),
                    _buildFormSection('Operating Hours', [
                      Row(
                        children: [
                          Expanded(
                            child: _buildTextField(
                              controller: _checkInController,
                              label: 'Check-in',
                              hint: '14:00',
                              icon: Icons.access_time_filled_rounded,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildTextField(
                              controller: _checkOutController,
                              label: 'Check-out',
                              hint: '11:00',
                              icon: Icons.access_time_rounded,
                            ),
                          ),
                        ],
                      ),
                    ]),
                    
                    const SizedBox(height: 40),
                    
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _createHotel,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE60023),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 2,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                              )
                            : const Text(
                                'Register Property',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                              ),
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

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      decoration: const BoxDecoration(
        color: Color(0xFFE60023),
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Partner with us',
            style: TextStyle(color: Colors.white70, fontSize: 16, fontWeight: FontWeight.w600),
          ),
          SizedBox(height: 8),
          Text(
            'Reach thousands of\nguests instantly.',
            style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900, height: 1.2),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBanner() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFEE2E2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_rounded, color: Color(0xFFEF4444)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Color(0xFF991B1B), fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 16),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E)),
          ),
        ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.02),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
            style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(color: AppColors.gray.shade400, fontWeight: FontWeight.w500),
              prefixIcon: Icon(icon, size: 20, color: const Color(0xFFE60023).withOpacity(0.7)),
              filled: true,
              fillColor: const Color(0xFFF9FAFB),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE60023), width: 1),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error, width: 1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

