import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../../core/constants/nepal_locations.dart';
import 'registration_review_screen.dart';
import '../../../../core/constants/app_colors.dart';

class HotelRegistrationScreenUpdated extends StatefulWidget {
  const HotelRegistrationScreenUpdated({super.key});

  @override
  State<HotelRegistrationScreenUpdated> createState() =>
      _HotelRegistrationScreenUpdatedState();
}

class _HotelRegistrationScreenUpdatedState
    extends State<HotelRegistrationScreenUpdated> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _totalRoomsController = TextEditingController();
  final _yearEstablishedController = TextEditingController();
  final _priceMinController = TextEditingController();
  final _priceMaxController = TextEditingController();

  // Location controllers
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _wardNumberController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _phoneController = TextEditingController();

  // State/Province and Country
  String _selectedCountry = 'Nepal';
  String _selectedState = '';
  String _selectedPropertyType = 'Hotel';
  String _selectedDistrict = '';
  String _selectedMunicipality = '';

  // Map location
  double? _latitude;
  double? _longitude;

  // Photo files
  File? _exteriorPhoto;
  File? _receptionPhoto;
  List<File> _galleryPhotos = [];

  // Agreements
  bool _termsAccepted = false;
  bool _commissionAccepted = false;
  bool _cancellationPolicyAccepted = false;

  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  // Dropdown options
  final List<String> _propertyTypes = [
    'Hotel',
    'Lodge',
    'Guest House',
    'Resort',
    'Homestay'
  ];

  // Nepal location data - using comprehensive data from NepalLocationData
  List<String> get _nepalProvinces => NepalLocationData.getAllProvinces();
  List<String> _nepalDistricts = [];
  List<String> _municipalities = [];

  Future<void> _pickExteriorPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _exteriorPhoto = File(image.path);
      });
    }
  }

  Future<void> _pickReceptionPhoto() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _receptionPhoto = File(image.path);
      });
    }
  }

  Future<void> _pickGalleryPhotos() async {
    for (int i = 0; i < 5; i++) {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        setState(() {
          _galleryPhotos.add(File(image.path));
        });
      } else {
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register Your Hotel'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section 1: Property Basic Info
              _buildSectionHeader(
                  'Section 1: Property Basic Info', Icons.business),
              const SizedBox(height: 16),

              // Hotel Name
              _buildRequiredFieldLabel('Hotel / Property Name'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter your hotel name',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Hotel name is required';
                  }
                  if (value.length < 3) {
                    return 'Hotel name must be at least 3 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Property Type
              _buildRequiredFieldLabel('Property Type'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedPropertyType,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: _propertyTypes.map((type) {
                  return DropdownMenuItem(value: type, child: Text(type));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedPropertyType = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Total Number of Rooms
              _buildRequiredFieldLabel('Total Number of Rooms'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _totalRoomsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter total number of rooms',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Total rooms is required';
                  }
                  final rooms = int.tryParse(value);
                  if (rooms == null || rooms <= 0) {
                    return 'Must be greater than 0';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Year of Establishment
              _buildOptionalFieldLabel('Year of Establishment'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _yearEstablishedController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., 2015',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Price Range
              _buildOptionalFieldLabel('Price Range (per night)'),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _priceMinController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Min Price',
                        prefixText: 'Rs. ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _priceMaxController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Max Price',
                        prefixText: 'Rs. ',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Section 2: Location
              _buildSectionHeader('Section 2: Location', Icons.location_on),
              const SizedBox(height: 16),

              // Country
              _buildRequiredFieldLabel('Country'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedCountry,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Nepal', child: Text('Nepal')),
                  DropdownMenuItem(value: 'India', child: Text('India')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedCountry = value!;
                  });
                },
              ),

              const SizedBox(height: 16),

              // Province
              _buildRequiredFieldLabel('Province / State'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedState.isEmpty ? null : _selectedState,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select Province',
                ),
                items: _nepalProvinces.map((province) {
                  return DropdownMenuItem(
                      value: province, child: Text(province));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedState = value ?? '';
                    _selectedDistrict = '';
                    _selectedMunicipality = '';
                    _nepalDistricts =
                        NepalLocationData.getDistricts(_selectedState);
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Province is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // District
              _buildRequiredFieldLabel('District'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedDistrict.isEmpty ? null : _selectedDistrict,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select District',
                ),
                items: _nepalDistricts.map((district) {
                  return DropdownMenuItem(
                      value: district, child: Text(district));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDistrict = value ?? '';
                    _selectedMunicipality = '';
                    _municipalities = NepalLocationData.getMunicipalities(
                        _selectedState, _selectedDistrict);
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'District is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Municipality
              _buildRequiredFieldLabel('Municipality / City'),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMunicipality.isEmpty
                    ? null
                    : _selectedMunicipality,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Select Municipality',
                ),
                items: _municipalities.map((municipality) {
                  return DropdownMenuItem(
                      value: municipality, child: Text(municipality));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMunicipality = value ?? '';
                    _cityController.text = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Municipality is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Ward Number
              _buildOptionalFieldLabel('Ward Number'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _wardNumberController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter ward number',
                ),
                keyboardType: TextInputType.number,
              ),

              const SizedBox(height: 16),

              // Full Address
              _buildRequiredFieldLabel('Full Address'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Enter complete address with street details',
                ),
                maxLines: 3,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Address is required';
                  }
                  if (value.length < 10) {
                    return 'Address must be at least 10 characters';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Landmark
              _buildOptionalFieldLabel('Landmark (Nearby place)'),
              const SizedBox(height: 8),
              TextFormField(
                controller: _landmarkController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'e.g., Near Bus Park, Opposite Temple',
                ),
              ),

              const SizedBox(height: 16),

              // Google Map Location
              _buildOptionalFieldLabel('Google Map Location'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray.shade400),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(Icons.map, color: AppColors.info.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _latitude != null && _longitude != null
                            ? 'Location set: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                            : 'Set location on map (Recommended)',
                        style: TextStyle(
                          color: _latitude != null
                              ? AppColors.success
                              : AppColors.gray.shade600,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _latitude = 27.7172;
                          _longitude = 85.3240;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Demo: Location set to Kathmandu')),
                        );
                      },
                      child: const Text('Set Location'),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Section 3: Property Photos
              _buildSectionHeader(
                  'Section 3: Property Photos', Icons.photo_library),
              const SizedBox(height: 16),

              // Hotel Exterior Photo
              _buildRequiredFieldLabel('Hotel Exterior Photo'),
              const SizedBox(height: 8),
              _buildPhotoUpload(
                photo: _exteriorPhoto,
                onPick: _pickExteriorPhoto,
                label: 'Tap to upload exterior photo',
              ),

              const SizedBox(height: 16),

              // Reception Photo
              _buildOptionalFieldLabel('Reception Photo'),
              const SizedBox(height: 8),
              _buildPhotoUpload(
                photo: _receptionPhoto,
                onPick: _pickReceptionPhoto,
                label: 'Tap to upload reception photo',
              ),

              const SizedBox(height: 16),

              // Hotel Gallery
              _buildOptionalFieldLabel('Hotel Gallery (Multiple photos)'),
              const SizedBox(height: 8),
              _buildMultiPhotoUpload(
                photos: _galleryPhotos,
                onPick: _pickGalleryPhotos,
                label: 'Tap to add gallery photos',
              ),

              const SizedBox(height: 32),

              // Section 4: Agreements
              _buildSectionHeader('Section 4: Agreements', Icons.description),
              const SizedBox(height: 16),

              // Terms & Conditions
              _buildAgreementCheckbox(
                value: _termsAccepted,
                onChanged: (value) {
                  setState(() {
                    _termsAccepted = value ?? false;
                  });
                },
                label: 'Terms & Conditions *',
              ),

              const SizedBox(height: 12),

              // Commission Agreement
              _buildAgreementCheckbox(
                value: _commissionAccepted,
                onChanged: (value) {
                  setState(() {
                    _commissionAccepted = value ?? false;
                  });
                },
                label: 'Commission Agreement *',
              ),

              const SizedBox(height: 12),

              // Cancellation Policy
              _buildAgreementCheckbox(
                value: _cancellationPolicyAccepted,
                onChanged: (value) {
                  setState(() {
                    _cancellationPolicyAccepted = value ?? false;
                  });
                },
                label: 'Cancellation Policy Acceptance (Recommended)',
              ),

              const SizedBox(height: 32),

              // Contact Phone
              const Text('Contact Phone *',
                  style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextFormField(
                controller: _phoneController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Hotel contact number',
                ),
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Phone number is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 24),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitHotelRegistration,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE60023),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Submit for Approval',
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w600),
                        ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFE60023).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFFE60023)),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFFE60023),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRequiredFieldLabel(String label) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Text(' *', style: TextStyle(color: AppColors.error)),
      ],
    );
  }

  Widget _buildOptionalFieldLabel(String label) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const Text(' ⭐', style: TextStyle(color: Colors.amber)),
      ],
    );
  }

  Widget _buildPhotoUpload({
    File? photo,
    required VoidCallback onPick,
    required String label,
  }) {
    return InkWell(
      onTap: onPick,
      child: Container(
        height: 150,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray.shade400),
          borderRadius: BorderRadius.circular(8),
          color: photo != null ? null : AppColors.gray.shade100,
        ),
        child: photo != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(photo,
                    width: double.infinity, fit: BoxFit.cover),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_a_photo,
                      size: 40, color: AppColors.gray.shade600),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: AppColors.gray.shade600)),
                ],
              ),
      ),
    );
  }

  Widget _buildMultiPhotoUpload({
    required List<File> photos,
    required VoidCallback onPick,
    required String label,
  }) {
    return InkWell(
      onTap: onPick,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.gray.shade400),
          borderRadius: BorderRadius.circular(8),
          color: photos.isEmpty ? AppColors.gray.shade100 : null,
        ),
        child: photos.isEmpty
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_photo_alternate,
                      size: 40, color: AppColors.gray.shade600),
                  const SizedBox(height: 8),
                  Text(label, style: TextStyle(color: AppColors.gray.shade600)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${photos.length} photos selected',
                      style: TextStyle(
                          color: AppColors.success.shade700,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(photos[index],
                                width: 80, height: 80, fit: BoxFit.cover),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildAgreementCheckbox({
    required bool value,
    required ValueChanged<bool?> onChanged,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gray.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFFE60023),
          ),
          Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _submitHotelRegistration() async {
    if (!_termsAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Terms & Conditions'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_commissionAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept Commission Agreement'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      await Future.delayed(const Duration(seconds: 1));

      if (mounted) {
        context.push(
          '/registration-review',
          extra: {
            'hotelName': _nameController.text.trim(),
            'propertyType': _selectedPropertyType,
            'totalRooms': _totalRoomsController.text.trim(),
            'yearOfEstablishment': _yearEstablishedController.text.trim(),
            'priceRangeMin': _priceMinController.text.trim(),
            'priceRangeMax': _priceMaxController.text.trim(),
            'hotelDescription': _descriptionController.text.trim(),
            'country': _selectedCountry,
            'state': _selectedState,
            'district': _selectedDistrict,
            'city': _selectedMunicipality,
            'wardNumber': _wardNumberController.text.trim(),
            'hotelAddress': _addressController.text.trim(),
            'landmark': _landmarkController.text.trim(),
            'latitude': _latitude,
            'longitude': _longitude,
            'hotelPhone': _phoneController.text.trim(),
            'termsAccepted': _termsAccepted,
            'commissionAccepted': _commissionAccepted,
            'cancellationPolicyAccepted': _cancellationPolicyAccepted,
            'exteriorPhoto': _exteriorPhoto,
            'receptionPhoto': _receptionPhoto,
            'galleryPhotos': _galleryPhotos,
          },
        );
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Registration failed: ${e.toString()}'),
              backgroundColor: AppColors.error),
        );
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _totalRoomsController.dispose();
    _yearEstablishedController.dispose();
    _priceMinController.dispose();
    _priceMaxController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _wardNumberController.dispose();
    _landmarkController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}
