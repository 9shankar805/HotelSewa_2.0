import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/shared/auth_service.dart';
import 'payment_screen.dart';

class BookingFormScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const BookingFormScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<BookingFormScreen> createState() => _BookingFormScreenState();
}

class _BookingFormScreenState extends State<BookingFormScreen> {
  final AuthService _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idNumberController = TextEditingController();
  final _specialRequestsController = TextEditingController();

  Map<String, dynamic> _hotel = {};
  Map<String, dynamic> _room = {};
  Map<String, dynamic> _dates = {};
  int _guests = 1;
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _extractArguments();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() => _loading = true);
    
    // Get cached user data
    final userData = await _authService.getCachedUser();
    
    if (userData['name']?.isNotEmpty ?? false) {
      final nameParts = userData['name']!.split(' ');
      _firstNameController.text = nameParts.first;
      if (nameParts.length > 1) {
        _lastNameController.text = nameParts.sublist(1).join(' ');
      }
    }
    
    if (userData['email']?.isNotEmpty ?? false) {
      _emailController.text = userData['email']!;
    }
    
    if (userData['phone']?.isNotEmpty ?? false) {
      _phoneController.text = userData['phone']!;
    }
    
    setState(() => _loading = false);
  }

  void _extractArguments() {
    if (widget.arguments != null) {
      _hotel = widget.arguments!['hotel'] ?? {'name': 'Hotel Paradise'};
      _room = widget.arguments!['room'] ?? {'price': 1299, 'type': 'Standard Room'};
      _dates = widget.arguments!['dates'] ?? {'checkIn': 'Today', 'checkOut': 'Tomorrow', 'nights': 1};
      _guests = widget.arguments!['guests'] ?? 1;
    } else {
      _hotel = {'name': 'Hotel Paradise'};
      _room = {'price': 1299, 'type': 'Standard Room'};
      _dates = {'checkIn': 'Today', 'checkOut': 'Tomorrow', 'nights': 1};
      _guests = 1;
    }
  }

  Future<void> _handleBooking() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    // Check if user is logged in before proceeding
    final isLoggedIn = await _authService.isLoggedIn();
    
    if (!isLoggedIn) {
      setState(() => _submitting = false);
      if (mounted) {
        final shouldLogin = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Login Required'),
            content: const Text(
              'You need to be logged in to complete the booking. Would you like to login now?',
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Login'),
              ),
            ],
          ),
        );

        if (shouldLogin == true && mounted) {
          Navigator.pushNamed(context, '/login');
        }
      }
      return;
    }

    final guestDetails = {
      'firstName': _firstNameController.text.trim(),
      'lastName': _lastNameController.text.trim(),
      'email': _emailController.text.trim(),
      'phone': _phoneController.text.trim(),
      'idType': 'passport',
      'idNumber': _idNumberController.text.trim(),
    };

    setState(() => _submitting = false);

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          arguments: {
            'hotel': _hotel,
            'room': _room,
            'dates': _dates,
            'guests': _guests,
            'guestDetails': guestDetails,
            'specialRequests': _specialRequestsController.text,
          },
        ),
      ),
    );
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idNumberController.dispose();
    _specialRequestsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final totalAmount = (_room['price'] ?? 1299) * (_dates['nights'] ?? 1);
    final taxAmount = (totalAmount * 0.18).round();
    final finalAmount = totalAmount + taxAmount;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Booking Details',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.darkGray,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          // Booking Summary
                          Container(
                            width: double.infinity,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              boxShadow: AppColors.cardShadow,
                            ),
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _hotel['name'] ?? 'Hotel Paradise',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w800,
                                              color: AppColors.darkGray,
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            _room['type'] ?? 'Standard Room',
                                            style: const TextStyle(fontSize: 15, color: AppColors.gray, fontWeight: FontWeight.w500),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        '${_dates['nights']} Nights',
                                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700, fontSize: 13),
                                      ),
                                    ),
                                  ],
                                ),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.gray),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${_dates['checkIn']} - ${_dates['checkOut']}',
                                      style: const TextStyle(fontSize: 14, color: AppColors.darkGray, fontWeight: FontWeight.w600),
                                    ),
                                    const Spacer(),
                                    const Icon(Icons.person_outline_rounded, size: 18, color: AppColors.gray),
                                    const SizedBox(width: 6),
                                    Text(
                                      '$_guests Guest${_guests > 1 ? 's' : ''}',
                                      style: const TextStyle(fontSize: 14, color: AppColors.darkGray, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Guest Details Section
                          Container(
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Guest Details',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildField(
                                        label: 'First Name',
                                        controller: _firstNameController,
                                        hint: 'Enter first name',
                                        validator: (v) => v!.isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                    const SizedBox(width: 16),
                                    Expanded(
                                      child: _buildField(
                                        label: 'Last Name',
                                        controller: _lastNameController,
                                        hint: 'Enter last name',
                                        validator: (v) => v!.isEmpty ? 'Required' : null,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                _buildField(
                                  label: 'Email Address',
                                  controller: _emailController,
                                  hint: 'Enter email address',
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v!.isEmpty) return 'Email is required';
                                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(v)) return 'Invalid email format';
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),

                                _buildField(
                                  label: 'Phone Number',
                                  controller: _phoneController,
                                  hint: 'Enter phone number',
                                  keyboardType: TextInputType.phone,
                                  validator: (v) => v!.isEmpty ? 'Phone number is required' : null,
                                ),
                                const SizedBox(height: 16),

                                _buildField(
                                  label: 'ID / Document Number',
                                  controller: _idNumberController,
                                  hint: 'Passport or ID number',
                                  textInputAction: TextInputAction.done,
                                ),
                              ],
                            ),
                          ),

                          // Special Requests Section
                          Container(
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Special Requests',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                TextFormField(
                                  controller: _specialRequestsController,
                                  maxLines: 3,
                                  decoration: InputDecoration(
                                    hintText: 'Any special requests (optional)',
                                    hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
                                    filled: true,
                                    fillColor: AppColors.background,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                      borderSide: BorderSide.none,
                                    ),
                                    contentPadding: const EdgeInsets.all(16),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Price Breakdown Section
                          Container(
                            width: double.infinity,
                            color: Colors.white,
                            padding: const EdgeInsets.all(20),
                            margin: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Price Summary',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.darkGray,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                _buildPriceRow('Room charges (${_dates['nights']} nights)', 'NPR $totalAmount'),
                                const SizedBox(height: 10),
                                _buildPriceRow('Taxes & service fees (18%)', 'NPR $taxAmount'),
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  child: Divider(height: 1),
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Total Amount',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.darkGray,
                                      ),
                                    ),
                                    Text(
                                      'NPR $finalAmount',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Bottom Button
                  Container(
                    padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _handleBooking,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _submitting
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Text(
                                'Continue to Payment',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    TextInputAction textInputAction = TextInputAction.next,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
            filled: true,
            fillColor: AppColors.background,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, color: AppColors.gray, fontWeight: FontWeight.w500)),
        Text(value, style: const TextStyle(fontSize: 14, color: AppColors.darkGray, fontWeight: FontWeight.w600)),
      ],
    );
  }
}
