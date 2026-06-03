import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/hotel_registration_data.dart';
import '../../../../core/constants/nepal_locations.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import '../../../../../../../core/constants/app_colors.dart';

class HotelRegistrationStep2 extends StatefulWidget {
  final HotelRegistrationData registrationData;

  const HotelRegistrationStep2({
    super.key,
    required this.registrationData,
  });

  @override
  State<HotelRegistrationStep2> createState() => _HotelRegistrationStep2State();
}

class _HotelRegistrationStep2State extends State<HotelRegistrationStep2> {
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _districtController;
  late TextEditingController _wardNumberController;
  late TextEditingController _landmarkController;
  late TextEditingController _phoneController;
  late TextEditingController _latitudeController;
  late TextEditingController _longitudeController;

  String _selectedCountry = 'Nepal';
  String _selectedState = '';
  String _selectedDistrict = '';
  String _selectedMunicipality = '';

  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _addressController =
        TextEditingController(text: widget.registrationData.hotelAddress);
    _cityController = TextEditingController(text: widget.registrationData.city);
    _districtController =
        TextEditingController(text: widget.registrationData.district);
    _wardNumberController =
        TextEditingController(text: widget.registrationData.wardNumber);
    _landmarkController =
        TextEditingController(text: widget.registrationData.landmark);
    _phoneController =
        TextEditingController(text: widget.registrationData.hotelPhone);
    _latitudeController = TextEditingController(
      text: widget.registrationData.latitude?.toString() ?? '',
    );
    _longitudeController = TextEditingController(
      text: widget.registrationData.longitude?.toString() ?? '',
    );
    _selectedCountry = widget.registrationData.country;
    _selectedState = widget.registrationData.state;
    _selectedDistrict = widget.registrationData.district;
    _latitude = widget.registrationData.latitude;
    _longitude = widget.registrationData.longitude;
  }

  @override
  void dispose() {
    _addressController.dispose();
    _cityController.dispose();
    _districtController.dispose();
    _wardNumberController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _goToNextStep() {
    final updatedData = widget.registrationData.copyWith(
      country: _selectedCountry,
      state: _selectedState,
      district: _selectedDistrict,
      city: _cityController.text.trim(),
      wardNumber: _wardNumberController.text.trim(),
      hotelAddress: _addressController.text.trim(),
      landmark: _landmarkController.text.trim(),
      hotelPhone: _phoneController.text.trim(),
      latitude: _latitude,
      longitude: _longitude,
    );

    context.push('/hotel-registration/step-3', extra: updatedData);
  }

  Future<void> _getCurrentLocation() async {
    try {
      // Request location permission
      LocationPermission permission = await Geolocator.requestPermission();

      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission denied'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission permanently denied'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Get current location
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (mounted) {
        setState(() {
          _latitude = position.latitude;
          _longitude = position.longitude;
          _latitudeController.text = position.latitude.toString();
          _longitudeController.text = position.longitude.toString();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location captured successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error getting location: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _goToPreviousStep() {
    context.push('/hotel-registration/step-1', extra: widget.registrationData);
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
                _buildProgressStep(1, 'Basic Info', false),
                _buildProgressLine(true),
                _buildProgressStep(2, 'Location', true),
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
                    'Location Information',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Where is your hotel located?',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Country
                  _buildRequiredFieldLabel('Country'),
                  const SizedBox(height: 8),
                  _buildCountryDropdown(),
                  const SizedBox(height: 24),

                  // State/Province
                  _buildRequiredFieldLabel('State/Province'),
                  const SizedBox(height: 8),
                  _buildStateDropdown(),
                  const SizedBox(height: 24),

                  // District
                  _buildRequiredFieldLabel('District'),
                  const SizedBox(height: 8),
                  _buildDistrictDropdown(),
                  const SizedBox(height: 24),

                  // City/Municipality
                  _buildRequiredFieldLabel('City/Municipality'),
                  const SizedBox(height: 8),
                  _buildCityDropdown(),
                  const SizedBox(height: 24),

                  // Hotel Address
                  _buildRequiredFieldLabel('Hotel Address'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _addressController,
                    hintText: 'Enter complete hotel address',
                    icon: Icons.location_on,
                    maxLines: 2,
                  ),
                  const SizedBox(height: 24),

                  // Ward Number
                  _buildOptionalFieldLabel('Ward Number'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _wardNumberController,
                    hintText: 'Ward number (if applicable)',
                    icon: Icons.numbers,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 24),

                  // Landmark
                  _buildOptionalFieldLabel('Landmark'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _landmarkController,
                    hintText: 'Nearby landmark for easy identification',
                    icon: Icons.local_activity,
                  ),
                  const SizedBox(height: 24),

                  // Phone Number
                  _buildRequiredFieldLabel('Contact Phone Number'),
                  const SizedBox(height: 8),
                  _buildTextField(
                    controller: _phoneController,
                    hintText: 'Hotel contact number',
                    icon: Icons.phone,
                    keyboardType: TextInputType.phone,
                  ),
                  const SizedBox(height: 16),

                  // Pin on Map Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final result = await context.push<LatLng>('/hotel-location-map', extra: {
                          'hotelName': widget.registrationData.hotelName,
                        });
                        
                        if (result != null) {
                          setState(() {
                            _latitude = result.latitude;
                            _longitude = result.longitude;
                            _latitudeController.text = result.latitude.toString();
                            _longitudeController.text = result.longitude.toString();
                          });
                          
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Location pinned successfully!'),
                              backgroundColor: AppColors.success,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.map),
                      label: const Text('Pin on Map'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.error.shade50,
                        foregroundColor: AppColors.error.shade600,
                        side: BorderSide(color: AppColors.error.shade600),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // GPS Coordinates (Optional)
                  _buildOptionalFieldLabel('GPS Coordinates (Optional)'),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTextField(
                          controller: _latitudeController,
                          hintText: 'Latitude',
                          icon: Icons.gps_fixed,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _latitude = double.tryParse(value);
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTextField(
                          controller: _longitudeController,
                          hintText: 'Longitude',
                          icon: Icons.gps_fixed,
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            _longitude = double.tryParse(value);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Get Location from Maps Button
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.location_on),
                      label: const Text('Get Current Location'),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.error.shade50,
                        foregroundColor: AppColors.error.shade600,
                        side: BorderSide(color: AppColors.error.shade600),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Navigation Buttons
                  SizedBox(
                    width: double.infinity,
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _goToPreviousStep,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: BorderSide(color: AppColors.error.shade600),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.arrow_back,
                                    color: AppColors.error.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  'Previous',
                                  style: TextStyle(
                                    color: AppColors.error.shade600,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _addressController.text
                                        .trim()
                                        .isNotEmpty &&
                                    _cityController.text.trim().isNotEmpty &&
                                    _phoneController.text.trim().isNotEmpty
                                ? _goToNextStep
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.error.shade600,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            child: const Text(
                              'Continue to Photos',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
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
          backgroundColor:
              isActive ? AppColors.error.shade600 : AppColors.gray.shade300,
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
    Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hintText,
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

  Widget _buildCountryDropdown() {
    return DropdownButtonFormField<String>(
      value: _selectedCountry,
      items: const [
        DropdownMenuItem(value: 'Nepal', child: Text('Nepal')),
        DropdownMenuItem(value: 'India', child: Text('India')),
        DropdownMenuItem(value: 'China', child: Text('China')),
        DropdownMenuItem(value: 'Other', child: Text('Other')),
      ],
      onChanged: (value) {
        setState(() {
          _selectedCountry = value!;
          _selectedState = '';
          _selectedDistrict = '';
          _selectedMunicipality = '';
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.flag, color: AppColors.gray),
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

  Widget _buildStateDropdown() {
    List<String> states = [];
    if (_selectedCountry == 'Nepal') {
      states = NepalLocationData.provinces.keys.toList();
    } else if (_selectedCountry == 'India') {
      states = [
        'Maharashtra',
        'Delhi',
        'Karnataka',
        'Tamil Nadu',
        'Uttar Pradesh'
      ];
    }

    return DropdownButtonFormField<String>(
      value: _selectedState.isEmpty ? null : _selectedState,
      items: states.map((state) {
        return DropdownMenuItem(value: state, child: Text(state));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedState = value!;
          _selectedDistrict = '';
          _selectedMunicipality = '';
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.location_city, color: AppColors.gray),
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

  Widget _buildDistrictDropdown() {
    List<String> districts = [];
    if (_selectedCountry == 'Nepal' && _selectedState.isNotEmpty) {
      final province = NepalLocationData.provinces[_selectedState];
      if (province != null) {
        districts =
            province.districts.map((district) => district.name).toList();
      }
    }

    return DropdownButtonFormField<String>(
      value: _selectedDistrict.isEmpty ? null : _selectedDistrict,
      items: districts.map((district) {
        return DropdownMenuItem(value: district, child: Text(district));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedDistrict = value!;
          _selectedMunicipality = '';
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.map, color: AppColors.gray),
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

  Widget _buildCityDropdown() {
    List<String> cities = [];
    if (_selectedCountry == 'Nepal' &&
        _selectedState.isNotEmpty &&
        _selectedDistrict.isNotEmpty) {
      final province = NepalLocationData.provinces[_selectedState];
      if (province != null) {
        final district = province.districts.firstWhere(
          (d) => d.name == _selectedDistrict,
          orElse: () => District(name: '', municipalities: []),
        );
        cities = district.municipalities;
      }
    }

    return DropdownButtonFormField<String>(
      value: _selectedMunicipality.isEmpty ? null : _selectedMunicipality,
      items: cities.map((city) {
        return DropdownMenuItem(value: city, child: Text(city));
      }).toList(),
      onChanged: (value) {
        setState(() {
          _selectedMunicipality = value!;
          _cityController.text = value;
        });
      },
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.location_city, color: AppColors.gray),
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
