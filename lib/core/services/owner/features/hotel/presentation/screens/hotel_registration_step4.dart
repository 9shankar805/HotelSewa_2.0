import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/hotel_registration_data.dart';
import '../../../../../../../core/constants/app_colors.dart';

class HotelRegistrationStep4 extends StatefulWidget {
  final HotelRegistrationData registrationData;
  
  const HotelRegistrationStep4({
    super.key,
    required this.registrationData,
  });

  @override
  State<HotelRegistrationStep4> createState() => _HotelRegistrationStep4State();
}

class _HotelRegistrationStep4State extends State<HotelRegistrationStep4> {
  bool _termsAccepted = false;
  bool _commissionAccepted = false;
  bool _cancellationPolicyAccepted = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _termsAccepted = widget.registrationData.termsAccepted;
    _commissionAccepted = widget.registrationData.commissionAccepted;
    _cancellationPolicyAccepted = widget.registrationData.cancellationPolicyAccepted;
  }

  void _goToPreviousStep() {
    final updatedData = widget.registrationData.copyWith(
      termsAccepted: _termsAccepted,
      commissionAccepted: _commissionAccepted,
      cancellationPolicyAccepted: _cancellationPolicyAccepted,
    );

    context.push('/hotel-registration/step-3', extra: updatedData);
  }

  void _submitRegistration() {
    if (!_termsAccepted || !_commissionAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please accept all required agreements to continue'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final updatedData = widget.registrationData.copyWith(
      termsAccepted: _termsAccepted,
      commissionAccepted: _commissionAccepted,
      cancellationPolicyAccepted: _cancellationPolicyAccepted,
    );

    // Navigate to review screen with all data
    context.push('/registration-review', extra: updatedData);
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
                _buildProgressStep(3, 'Photos', false),
                _buildProgressLine(true),
                _buildProgressStep(4, 'Agreements', true),
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
                    'Terms & Agreements',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppColors.darkGray,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please review and accept the following agreements',
                    style: TextStyle(
                      fontSize: 16,
                      color: AppColors.gray,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Terms and Conditions
                  _buildAgreementCard(
                    title: 'Terms and Conditions',
                    subtitle: 'Hotel registration terms and conditions',
                    isRequired: true,
                    isChecked: _termsAccepted,
                    onChanged: (value) {
                      setState(() {
                        _termsAccepted = value!;
                      });
                    },
                    content: [
                      '• I certify that I am the legal owner or authorized representative of this property',
                      '• All information provided is accurate and truthful',
                      '• I agree to comply with HotelSewa\'s quality standards and policies',
                      '• I understand that false information may lead to account termination',
                      '• I agree to regular quality inspections and audits',
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Commission Agreement
                  _buildAgreementCard(
                    title: 'Commission Agreement',
                    subtitle: 'HotelSewa commission and payment terms',
                    isRequired: true,
                    isChecked: _commissionAccepted,
                    onChanged: (value) {
                      setState(() {
                        _commissionAccepted = value!;
                      });
                    },
                    content: [
                      '• I agree to pay HotelSewa commission on all bookings through the platform',
                      '• Commission rate: 22% of total booking amount',
                      '• Payments will be settled within 7 business days',
                      '• I agree to the payment schedule and refund policy',
                      '• Commission rates may be reviewed annually with 30-day notice',
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Cancellation Policy
                  _buildAgreementCard(
                    title: 'Cancellation Policy',
                    subtitle: 'Hotel booking cancellation terms',
                    isRequired: false,
                    isChecked: _cancellationPolicyAccepted,
                    onChanged: (value) {
                      setState(() {
                        _cancellationPolicyAccepted = value!;
                      });
                    },
                    content: [
                      '• Free cancellation up to 24 hours before check-in',
                      '• 50% refund for cancellations within 24 hours',
                      '• No refund for no-shows',
                      '• I agree to follow HotelSewa\'s standard cancellation policy',
                      '• Special cancellation terms may apply during peak seasons',
                    ],
                  ),
                  const SizedBox(height: 32),

                  // Summary Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.info.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.info.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: AppColors.info.shade600),
                            const SizedBox(width: 8),
                            Text(
                              'Registration Summary',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: AppColors.info.shade600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildSummaryRow('Hotel Name', widget.registrationData.hotelName),
                        _buildSummaryRow('Property Type', widget.registrationData.propertyType),
                        _buildSummaryRow('Location', '${widget.registrationData.city}, ${widget.registrationData.state}'),
                        _buildSummaryRow('Photos', '${(widget.registrationData.exteriorPhoto != null ? 1 : 0) + widget.registrationData.galleryPhotos.length} photos uploaded'),
                        const SizedBox(height: 8),
                        const Divider(),
                        const SizedBox(height: 8),
                        Text(
                          'By clicking "Submit Registration", you confirm that all information is accurate and you agree to the terms above.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.gray.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
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
                            side: BorderSide(color: AppColors.info.shade600),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.arrow_back, color: AppColors.info.shade600),
                              const SizedBox(width: 8),
                              Text(
                                'Previous',
                                style: TextStyle(
                                  color: AppColors.info.shade600,
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
                          onPressed: (_termsAccepted && _commissionAccepted) ? _submitRegistration : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Flexible(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'Submit Registration',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      const Icon(Icons.check_circle),
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

  Widget _buildAgreementCard({
    required String title,
    required String subtitle,
    required bool isRequired,
    required bool isChecked,
    required Function(bool?) onChanged,
    required List<String> content,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isRequired ? AppColors.error.shade600 : AppColors.gray.shade600,
          width: isChecked ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(12),
        color: isChecked ? AppColors.info.shade50 : Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Checkbox(
                  value: isChecked,
                  onChanged: onChanged,
                  activeColor: AppColors.info.shade600,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: isChecked ? AppColors.info.shade600 : AppColors.darkGray,
                            ),
                          ),
                          if (isRequired)
                            const Text(
                              ' *',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: AppColors.error,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.gray.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (isChecked)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: content.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    item,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.gray.shade700,
                      height: 1.4,
                    ),
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
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
              ),
            ),
          ),
          const Text(': '),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
