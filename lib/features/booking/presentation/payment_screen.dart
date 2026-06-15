import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_spacing.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/navigation/app_routes.dart';
import 'booking_success_screen.dart';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const PaymentScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();
  final _cardHolderController = TextEditingController();

  String _selectedMethod = 'card';
  bool _processing = false;
  Map<String, dynamic> _hotel = {};
  Map<String, dynamic> _room = {};
  Map<String, dynamic> _dates = {};

  @override
  void initState() {
    super.initState();
    if (widget.arguments != null) {
      _hotel = widget.arguments!['hotel'] ?? {};
      _room = widget.arguments!['room'] ?? {};
      _dates = widget.arguments!['dates'] ?? {};
      if (widget.arguments!['guestDetails'] != null) {
        final guest = widget.arguments!['guestDetails'];
        _cardHolderController.text = '${guest['firstName'] ?? ''} ${guest['lastName'] ?? ''}'.trim();
      }
    }
  }

  Future<void> _handlePayment() async {
    if (_selectedMethod == 'card' && !_formKey.currentState!.validate()) return;

    setState(() => _processing = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      // Build booking payload
      final bookingData = <String, dynamic>{
        'hotel_id': _hotel['id']?.toString() ?? _hotel['hotel_id']?.toString() ?? '',
        'room_type_id': _room['id']?.toString() ?? _room['room_type_id']?.toString() ?? '',
        'check_in_date': _dates['checkIn'] ?? _dates['check_in'] ?? '',
        'check_out_date': _dates['checkOut'] ?? _dates['check_out'] ?? '',
        'adults': _dates['adults'] ?? _dates['guests'] ?? 1,
        'children': _dates['children'] ?? 0,
        'room_count': _dates['rooms'] ?? 1,
        'payment_method': _selectedMethod,
        'total_amount': _totalAmount,
        'status': 'confirmed',
      };

      // Add guest info if available
      final guest = widget.arguments?['guestDetails'];
      if (guest != null) {
        bookingData['guest_name'] = '${guest['firstName'] ?? ''} ${guest['lastName'] ?? ''}'.trim();
        bookingData['guest_email'] = guest['email'] ?? '';
        bookingData['guest_phone'] = guest['phone'] ?? '';
        bookingData['special_requests'] = guest['specialRequests'] ?? '';
      }

      // Call the actual booking API
      final bookingService = BookingService();
      final result = await bookingService.createBooking(bookingData);

      if (!mounted) return;
      setState(() => _processing = false);

      if (result['success'] == true) {
        // Extract booking response data
        final responseData = result['data'] ?? {};
        final raw = responseData is Map ? responseData : {};

        // Build arguments for success screen — cover all possible API field names
        final successArgs = <String, dynamic>{
          'booking_id':          raw['booking_id']?.toString() ?? raw['id']?.toString() ?? '',
          'confirmation_number': raw['confirmation_number']?.toString() ?? raw['confirmationNumber']?.toString() ?? '',
          'hotel_name':          _hotel['name']?.toString() ?? _hotel['hotel_name']?.toString() ?? 'Hotel',
          'room_type':           _room['type']?.toString() ?? _room['name']?.toString() ?? _room['room_type']?.toString() ?? 'Room',
          'check_in':            _dates['checkIn'] ?? _dates['check_in'] ?? raw['check_in_date'] ?? '',
          'check_out':           _dates['checkOut'] ?? _dates['check_out'] ?? raw['check_out_date'] ?? '',
          'nights':              _dates['nights']?.toString() ?? raw['nights']?.toString() ?? '1',
          'guests':              (_dates['adults'] ?? 1).toString(),
          'total_amount':        _totalAmount.toString(),
          'payment_method':      _selectedMethod,
          'guest_name':          guest?['firstName'] != null
              ? '${guest['firstName']} ${guest['lastName'] ?? ''}'.trim()
              : (prefs.getString('userName') ?? 'Guest'),
        };

        if (mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (_) => BookingSuccessScreen(arguments: successArgs),
            ),
            (route) => false,
          );
        }
      } else {
        // Show error
        final msg = result['message'] ?? 'Payment failed. Please try again.';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _processing = false);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Payment failed. Please check your connection.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  int get _totalAmount {
    final price = (_room['price'] as num?)?.toInt() ?? (_room['base_price'] as num?)?.toInt() ?? 0;
    final nights = (_dates['nights'] as num?)?.toInt() ?? 1;
    return ((price * nights) * 1.18).round();
  }

  @override
  void dispose() {
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    _cardHolderController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final total = _totalAmount;

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
          'Payment',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Amount Summary
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.darkGray,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.elevatedShadow,
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Total Payable Amount',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'NPR $total',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.security_rounded, color: AppColors.success, size: 14),
                              const SizedBox(width: 6),
                              const Text(
                                'Secure SSL Encryption',
                                style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    'Select Payment Method',
                    style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                  ),
                  const SizedBox(height: 16),

                  _buildMethodItem(
                    id: 'card',
                    name: 'Credit / Debit Card',
                    icon: Icons.credit_card_rounded,
                    subtitle: 'Visa, Mastercard, RuPay',
                  ),
                  _buildMethodItem(
                    id: 'khalti',
                    name: 'Khalti Wallet',
                    icon: Icons.account_balance_wallet_rounded,
                    subtitle: 'Pay via Khalti app or web',
                  ),
                  _buildMethodItem(
                    id: 'esewa',
                    name: 'eSewa',
                    icon: Icons.account_balance_rounded,
                    subtitle: 'Direct payment from eSewa',
                  ),

                  if (_selectedMethod == 'card') ...[
                    const SizedBox(height: 24),
                    const Text(
                      'Card Information',
                      style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AppColors.darkGray),
                    ),
                    const SizedBox(height: 16),
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildField(
                            label: 'Card Holder Name',
                            controller: _cardHolderController,
                            hint: 'Enter name on card',
                            validator: (v) => v!.isEmpty ? 'Required' : null,
                          ),
                          const SizedBox(height: 16),
                          _buildField(
                            label: 'Card Number',
                            controller: _cardNumberController,
                            hint: '0000 0000 0000 0000',
                            keyboardType: TextInputType.number,
                            validator: (v) => v!.replaceAll(' ', '').length < 16 ? 'Invalid card number' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: _buildField(
                                  label: 'Expiry Date',
                                  controller: _expiryController,
                                  hint: 'MM/YY',
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v!.length < 5 ? 'Invalid' : null,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: _buildField(
                                  label: 'CVV',
                                  controller: _cvvController,
                                  hint: '000',
                                  keyboardType: TextInputType.number,
                                  validator: (v) => v!.length < 3 ? 'Invalid' : null,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
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
                onPressed: _processing ? null : _handlePayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _processing
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        'Pay NPR $total',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMethodItem({
    required String id,
    required String name,
    required IconData icon,
    required String subtitle,
  }) {
    final selected = _selectedMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.lightGray,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(
                color: selected ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: selected ? AppColors.primary : AppColors.gray),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selected ? AppColors.primary : AppColors.darkGray,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.gray),
                  ),
                ],
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 24)
            else
              const Icon(Icons.circle_outlined, color: AppColors.lightGray, size: 24),
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
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.lightGray),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            errorStyle: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }
}
