import 'package:flutter/material.dart';
import '../services/hotel_service.dart';
import '../../../../../../../core/constants/app_colors.dart';

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
      appBar: AppBar(
        title: const Text('Create New Hotel'),
        backgroundColor: const Color(0xFFE60023),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_errorMessage != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.shade50,
                    border: Border.all(color: AppColors.error.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(color: AppColors.error.shade800),
                  ),
                ),
              
              _buildTextField(
                controller: _nameController,
                label: 'Hotel Name *',
                hint: 'Enter hotel name',
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              
              _buildTextField(
                controller: _descriptionController,
                label: 'Description',
                hint: 'Describe your hotel',
                maxLines: 3,
              ),
              
              _buildTextField(
                controller: _addressController,
                label: 'Address *',
                hint: 'Complete address',
                maxLines: 2,
                validator: (value) => value?.isEmpty == true ? 'Required' : null,
              ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _cityController,
                      label: 'City *',
                      hint: 'City',
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _stateController,
                      label: 'State *',
                      hint: 'State',
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _pincodeController,
                      label: 'Pincode *',
                      hint: 'Pincode',
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                ],
              ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _phoneController,
                      label: 'Phone *',
                      hint: 'Phone number',
                      keyboardType: TextInputType.phone,
                      validator: (value) => value?.isEmpty == true ? 'Required' : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _emailController,
                      label: 'Email *',
                      hint: 'Email address',
                      keyboardType: TextInputType.emailAddress,
                      validator: (value) {
                        if (value?.isEmpty == true) return 'Required';
                        if (!value!.contains('@')) return 'Invalid email';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _checkInController,
                      label: 'Check-in Time',
                      hint: '14:00',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildTextField(
                      controller: _checkOutController,
                      label: 'Check-out Time',
                      hint: '11:00',
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createHotel,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE60023),
                    padding: const EdgeInsets.all(16),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Create Hotel',
                          style: TextStyle(fontSize: 18, color: Colors.white),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            decoration: InputDecoration(
              border: const OutlineInputBorder(),
              hintText: hint,
            ),
            maxLines: maxLines,
            keyboardType: keyboardType,
            validator: validator,
          ),
        ],
      ),
    );
  }
}

