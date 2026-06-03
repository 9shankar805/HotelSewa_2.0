import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../models/hotel_registration_data.dart';
import '../../../../core/constants/app_colors.dart';

class HotelRegistrationStep3 extends StatefulWidget {
  final HotelRegistrationData registrationData;

  const HotelRegistrationStep3({
    super.key,
    required this.registrationData,
  });

  @override
  State<HotelRegistrationStep3> createState() => _HotelRegistrationStep3State();
}

class _HotelRegistrationStep3State extends State<HotelRegistrationStep3> {
  File? _exteriorPhoto;
  File? _receptionPhoto;
  List<File> _galleryPhotos = [];

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _exteriorPhoto = widget.registrationData.exteriorPhoto;
    _receptionPhoto = widget.registrationData.receptionPhoto;
    _galleryPhotos = List.from(widget.registrationData.galleryPhotos);
  }

  Future<void> _pickExteriorPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _exteriorPhoto = File(image.path);
      });
    }
  }

  Future<void> _pickReceptionPhoto() async {
    final XFile? image = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 600,
      imageQuality: 80,
    );
    if (image != null) {
      setState(() {
        _receptionPhoto = File(image.path);
      });
    }
  }

  Future<void> _pickGalleryPhotos() async {
    for (int i = 0; i < 5 - _galleryPhotos.length; i++) {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() {
          _galleryPhotos.add(File(image.path));
        });
      } else {
        break;
      }
    }
  }

  void _removeGalleryPhoto(int index) {
    setState(() {
      _galleryPhotos.removeAt(index);
    });
  }

  void _goToNextStep() {
    final updatedData = widget.registrationData.copyWith(
      exteriorPhoto: _exteriorPhoto,
      receptionPhoto: _receptionPhoto,
      galleryPhotos: _galleryPhotos,
    );

    context.push('/hotel-registration/step-4', extra: updatedData);
  }

  void _goToPreviousStep() {
    final updatedData = widget.registrationData.copyWith(
      exteriorPhoto: _exteriorPhoto,
      receptionPhoto: _receptionPhoto,
      galleryPhotos: _galleryPhotos,
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
                _buildProgressStep(1, 'Basic Info', false),
                _buildProgressLine(true),
                _buildProgressStep(2, 'Location', false),
                _buildProgressLine(true),
                _buildProgressStep(3, 'Photos', true),
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
                    'Hotel Photos',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Add photos to showcase your hotel',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Exterior Photo (Required)
                  _buildRequiredFieldLabel('Hotel Exterior Photo'),
                  const SizedBox(height: 8),
                  Text(
                    'Show the exterior view of your hotel',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoUpload(
                    photo: _exteriorPhoto,
                    onPick: _pickExteriorPhoto,
                    onRemove: () => setState(() => _exteriorPhoto = null),
                    label: 'Tap to upload exterior photo',
                    isRequired: true,
                  ),
                  const SizedBox(height: 32),

                  // Reception Photo (Optional)
                  _buildOptionalFieldLabel('Reception Photo'),
                  const SizedBox(height: 8),
                  Text(
                    'Show your hotel reception area',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildPhotoUpload(
                    photo: _receptionPhoto,
                    onPick: _pickReceptionPhoto,
                    onRemove: () => setState(() => _receptionPhoto = null),
                    label: 'Tap to upload reception photo',
                    isRequired: false,
                  ),
                  const SizedBox(height: 32),

                  // Gallery Photos (Optional)
                  _buildOptionalFieldLabel('Hotel Gallery'),
                  const SizedBox(height: 8),
                  Text(
                    'Add multiple photos of rooms, amenities, and facilities',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.gray.shade600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMultiPhotoUpload(),
                  const SizedBox(height: 40),

                  // Navigation Buttons
                  Row(
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
                          onPressed:
                              _exteriorPhoto != null ? _goToNextStep : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: Flexible(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    'Continue to Agreements',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                const Icon(Icons.arrow_forward),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
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
              isActive ? AppColors.info.shade600 : AppColors.gray.shade300,
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
            color: isActive ? AppColors.info.shade600 : AppColors.gray.shade600,
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
        decoration: BoxDecoration(
          color: isActive ? AppColors.error.shade600 : AppColors.gray.shade300,
        ),
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

  Widget _buildPhotoUpload({
    required File? photo,
    required VoidCallback onPick,
    required VoidCallback onRemove,
    required String label,
    required bool isRequired,
  }) {
    return Container(
      height: 200,
      width: double.infinity,
      decoration: BoxDecoration(
        border: Border.all(
          color: photo != null ? AppColors.info.shade600 : AppColors.gray.shade300,
          width: photo != null ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: AppColors.gray.shade50,
      ),
      child: photo != null
          ? Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    photo,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.gray,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, color: Colors.white),
                    ),
                  ),
                ),
              ],
            )
          : InkWell(
              onTap: onPick,
              borderRadius: BorderRadius.circular(12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.add_photo_alternate,
                    size: 48,
                    color: isRequired
                        ? AppColors.info.shade600
                        : AppColors.gray.shade400,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isRequired
                          ? AppColors.info.shade600
                          : AppColors.gray.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  if (isRequired)
                    Text(
                      'Required',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.error.shade600,
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Widget _buildMultiPhotoUpload() {
    return Column(
      children: [
        // Gallery Photos Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount:
              _galleryPhotos.length + (_galleryPhotos.length < 5 ? 1 : 0),
          itemBuilder: (context, index) {
            if (index == _galleryPhotos.length && _galleryPhotos.length < 5) {
              // Add Photo Button
              return InkWell(
                onTap: _pickGalleryPhotos,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.gray.shade300),
                    borderRadius: BorderRadius.circular(12),
                    color: AppColors.gray.shade50,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add, color: AppColors.gray, size: 32),
                      SizedBox(height: 4),
                      Text(
                        'Add Photo',
                        style: TextStyle(
                          color: AppColors.gray,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            } else if (index < _galleryPhotos.length) {
              // Existing Photo
              return Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.file(
                      _galleryPhotos[index],
                      width: double.infinity,
                      height: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.gray,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: IconButton(
                        onPressed: () => _removeGalleryPhoto(index),
                        icon: const Icon(Icons.close,
                            color: Colors.white, size: 16),
                        constraints: const BoxConstraints(
                          minWidth: 32,
                          minHeight: 32,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
        const SizedBox(height: 12),
        Text(
          '${_galleryPhotos.length}/5 photos added',
          style: TextStyle(
            color: AppColors.gray.shade600,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}
