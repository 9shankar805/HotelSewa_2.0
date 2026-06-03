import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/hotel_registration_data.dart';
import '../../../../../../../core/constants/app_colors.dart';

class HotelRegistrationStep1 extends StatefulWidget {
  final HotelRegistrationData registrationData;
  
  const HotelRegistrationStep1({
    super.key,
    required this.registrationData,
  });

  @override
  State<HotelRegistrationStep1> createState() => _HotelRegistrationStep1State();
}

class _HotelRegistrationStep1State extends State<HotelRegistrationStep1> {
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _totalRoomsController;
  late TextEditingController _yearEstablishedController;
  late TextEditingController _priceMinController;
  late TextEditingController _priceMaxController;
  
  String _selectedPropertyType = 'Hotel';
  
  final List<String> _propertyTypes = [
    'Hotel',
    'Lodge',
    'Guest House',
    'Resort',
    'Homestay'
  ];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.registrationData.hotelName);
    _descriptionController = TextEditingController(text: widget.registrationData.hotelDescription);
    _totalRoomsController = TextEditingController(text: widget.registrationData.totalRooms);
    _yearEstablishedController = TextEditingController(text: widget.registrationData.yearOfEstablishment);
    _priceMinController = TextEditingController(text: widget.registrationData.priceRangeMin);
    _priceMaxController = TextEditingController(text: widget.registrationData.priceRangeMax);
    _selectedPropertyType = widget.registrationData.propertyType;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalRoomsController.dispose();
    _yearEstablishedController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    final updatedData = widget.registrationData.copyWith(
      hotelName: _nameController.text.trim(),
      hotelDescription: _descriptionController.text.trim(),
      totalRooms: _totalRoomsController.text.trim(),
      yearOfEstablishment: _yearEstablishedController.text.trim(),
      priceRangeMin: _priceMinController.text.trim(),
      priceRangeMax: _priceMaxController.text.trim(),
      propertyType: _selectedPropertyType,
    );

    context.push('/hotel-registration/step-2', extra: updatedData);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Registration'),
        backgroundColor: AppColors.error.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Progress Indicator
          Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildProgressStep(1, 'Basic Info', true),
                _buildProgressLine(false),
                _buildProgressStep(2, 'Location', false),
                _buildProgressLine(false),
                _buildProgressStep(3, 'Photos', false),
                _buildProgressLine(false),
                _buildProgressStep(4, 'Agreements', false),
              ],
            ),
          ),
          
          // Form Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Basic Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Tell us about your hotel property',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Hotel Name
                  _buildRequiredFieldLabel('Hotel Name'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _nameController,
                    hintText: 'Enter your hotel name',
                    icon: Icons.hotel,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),

                  // Property Type
                  _buildRequiredFieldLabel('Property Type'),
                  const SizedBox(height: 8),
                  _buildDropdownField(
                    value: _selectedPropertyType,
                    items: _propertyTypes,
                    onChanged: (value) {
                      setState(() {
                        _selectedPropertyType = value!;
                      });
                    },
                    icon: Icons.apartment,
                  ),
                  const SizedBox(height: 24),

                  // Total Rooms
                  _buildRequiredFieldLabel('Total Rooms'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _totalRoomsController,
                    hintText: 'Number of rooms',
                    icon: Icons.meeting_room,
                    keyboardType: TextInputType.number,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 24),

                  // Year of Establishment
                  _buildOptionalFieldLabel('Year of Establishment'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _yearEstablishedController,
                    hintText: 'e.g., 2020',
                    icon: Icons.calendar_today,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Price Range
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOptionalFieldLabel('Min Price (per night)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _priceMinController,
                              hintText: 'Min price',
                              icon: Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildOptionalFieldLabel('Max Price (per night)'),
                            const SizedBox(height: 8),
                            _buildTextField(
                              controller: _priceMaxController,
                              hintText: 'Max price',
                              icon: Icons.currency_rupee,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Hotel Description
                  _buildRequiredFieldLabel('Hotel Description'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _descriptionController,
                    hintText: 'Describe your hotel, amenities, and unique features...',
                    icon: Icons.description,
                    maxLines: 4,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 40),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _nameController.text.trim().isNotEmpty &&
                                 _totalRoomsController.text.trim().isNotEmpty &&
                                 _descriptionController.text.trim().isNotEmpty
                          ? _goToNextStep
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Continue to Location',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStep(int step, String title, bool isActive) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: isActive ? AppColors.error.shade600 : AppColors.gray.shade300,
          child: Text(
            step.toString(),
            style: TextStyle(
              color: isActive ? Colors.white : AppColors.gray.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? AppColors.error.shade600 : AppColors.gray.shade600,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildProgressLine(bool isActive) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: isActive ? AppColors.error.shade600 : AppColors.gray.shade300,
      ),
    );
  }

  Widget _buildRequiredFieldLabel(String label) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.darkGray,
          ),
        ),
        const Text(
          ' *',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.error,
          ),
        ),
      ],
    );
  }

  Widget _buildOptionalFieldLabel(String label) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: AppColors.darkGray,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    VoidCallback? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: (value) {
        if (onChanged != null) {
          onChanged!();
        }
      },
      decoration: InputDecoration(
        hintText: hintText,
        prefixIcon: Icon(icon, color: AppColors.gray.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.error.shade600, width: 2),
        ),
        filled: true,
        fillColor: AppColors.gray.shade50,
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
    required IconData icon,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        prefixIcon: Icon(icon, color: AppColors.gray.shade600),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.gray.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppColors.info.shade600, width: 2),
        ),
        filled: true,
        fillColor: AppColors.gray.shade50,
      ),
    );
  }
}
