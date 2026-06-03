import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class AddCardScreen extends StatefulWidget {
  const AddCardScreen({Key? key}) : super(key: key);

  @override
  State<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends State<AddCardScreen> {
  final _formKey = GlobalKey<FormState>();
  final _cardNumberCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  bool _saveCard = true;
  bool _setAsDefault = false;
  bool _loading = false;
  bool _showCvv = false;

  String get _cardType {
    final n = _cardNumberCtrl.text.replaceAll(' ', '');
    if (n.startsWith('4')) return 'Visa';
    if (n.startsWith('5') || n.startsWith('2')) return 'Mastercard';
    if (n.startsWith('37') || n.startsWith('34')) return 'Amex';
    if (n.startsWith('6')) return 'RuPay';
    return '';
  }

  Color get _cardColor {
    switch (_cardType) {
      case 'Visa': return const Color(0xFF1A1F71);
      case 'Mastercard': return const Color(0xFFEB001B);
      case 'Amex': return const Color(0xFF007BC1);
      case 'RuPay': return const Color(0xFF006A4E);
      default: return AppColors.darkGray;
    }
  }

  String _formatCardNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    final buffer = StringBuffer();
    for (int i = 0; i < digits.length && i < 16; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }

  String _formatExpiry(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 2) return '${digits.substring(0, 2)}/${digits.substring(2).padRight(0)}';
    return digits;
  }

  Future<void> _addCard() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      
      // PCI Compliance: In a real app, use Stripe/Razorpay SDK to get a token.
      // Here we simulate by sending only the last 4 digits and a mock token if not saving.
      final cardNumber = _cardNumberCtrl.text.replaceAll(' ', '');
      final last4 = cardNumber.substring(cardNumber.length - 4);
      
      final response = await ApiService.post(ApiConfig.paymentMethodsEndpoint, token: token, data: {
        'type': 'card',
        'card_number_last4': last4,
        'card_holder': _nameCtrl.text.trim(),
        'expiry': _expiryCtrl.text.trim(),
        'save_card': _saveCard,
        'set_default': _setAsDefault,
        'mock_token': 'tok_test_${DateTime.now().millisecondsSinceEpoch}',
      });
      
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Card added successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to add card'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to add card'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
  );

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _nameCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Add New Card', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _buildCardPreview().animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 24),
                  Form(
                    key: _formKey,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Card Number'),
                          _field(
                            controller: _cardNumberCtrl,
                            hint: '0000 0000 0000 0000',
                            keyboardType: TextInputType.number,
                            maxLength: 19,
                            validator: (v) => (v?.replaceAll(' ', '').length ?? 0) < 16 ? 'Invalid card number' : null,
                            suffix: _cardType.isNotEmpty
                                ? Text(_cardType, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _cardColor))
                                : null,
                            onChanged: (v) {
                              final formatted = _formatCardNumber(v);
                              if (formatted != v) {
                                _cardNumberCtrl.value = TextEditingValue(
                                  text: formatted,
                                  selection: TextSelection.collapsed(offset: formatted.length),
                                );
                              }
                              setState(() {});
                            },
                          ),
                          const SizedBox(height: 16),
                          _label('Cardholder Name'),
                          _field(
                            controller: _nameCtrl, 
                            hint: 'Name as on card', 
                            textCapitalization: TextCapitalization.characters,
                            validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label('Expiry Date'),
                                _field(
                                  controller: _expiryCtrl,
                                  hint: 'MM/YY',
                                  keyboardType: TextInputType.number,
                                  maxLength: 5,
                                  validator: (v) => (v?.length ?? 0) < 5 ? 'Invalid' : null,
                                  onChanged: (v) {
                                    final formatted = _formatExpiry(v);
                                    if (formatted != v) {
                                      _expiryCtrl.value = TextEditingValue(
                                        text: formatted,
                                        selection: TextSelection.collapsed(offset: formatted.length),
                                      );
                                    }
                                  },
                                ),
                              ])),
                              const SizedBox(width: 16),
                              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                _label('CVV'),
                                _field(
                                  controller: _cvvCtrl,
                                  hint: '...',
                                  keyboardType: TextInputType.number,
                                  maxLength: 4,
                                  obscure: !_showCvv,
                                  validator: (v) => (v?.length ?? 0) < 3 ? 'Invalid' : null,
                                  suffix: GestureDetector(
                                    onTap: () => setState(() => _showCvv = !_showCvv),
                                    child: Icon(_showCvv ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 16, color: AppColors.gray),
                                  ),
                                ),
                              ])),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _toggleRow('Save card for future payments', _saveCard, (v) => setState(() => _saveCard = v)),
                          const SizedBox(height: 8),
                          _toggleRow('Set as default payment method', _setAsDefault, (v) => setState(() => _setAsDefault = v)),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      children: [
                        Icon(Icons.lock_rounded, color: AppColors.success, size: 16),
                        SizedBox(width: 8),
                        Expanded(child: Text('Your card details are encrypted with 256-bit SSL security.',
                            style: TextStyle(fontSize: 12, color: AppColors.success, height: 1.4))),
                      ],
                    ),
                  ).animate().fadeIn(delay: 160.ms),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _addCard,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Add Card', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardPreview() {
    final number = _cardNumberCtrl.text.isEmpty ? '.... .... .... ....' : _cardNumberCtrl.text.padRight(19, '.');
    final name = _nameCtrl.text.isEmpty ? 'CARDHOLDER NAME' : _nameCtrl.text.toUpperCase();
    final expiry = _expiryCtrl.text.isEmpty ? 'MM/YY' : _expiryCtrl.text;

    return Container(
      height: 190,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _cardType.isNotEmpty ? [_cardColor, _cardColor.withOpacity(0.7)] : [AppColors.darkGray, const Color(0xFF2D3748)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.elevatedShadow,
      ),
      child: Stack(
        children: [
          Positioned(top: -20, right: -20, child: Container(width: 120, height: 120, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
          Positioned(bottom: -30, left: -10, child: Container(width: 150, height: 150, decoration: BoxDecoration(color: Colors.white.withOpacity(0.05), shape: BoxShape.circle))),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  const Icon(Icons.wifi_rounded, color: Colors.white54, size: 28),
                  if (_cardType.isNotEmpty) Text(_cardType, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white)),
                ]),
                const Spacer(),
                Text(number, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.white, letterSpacing: 2)),
                const SizedBox(height: 16),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('CARD HOLDER', style: TextStyle(fontSize: 9, color: Colors.white54, letterSpacing: 1)),
                    Text(name, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                  Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Text('EXPIRES', style: TextStyle(fontSize: 9, color: Colors.white54, letterSpacing: 1)),
                    Text(expiry, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                  ]),
                ]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
  );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    int? maxLength,
    bool obscure = false,
    Widget? suffix,
    ValueChanged<String>? onChanged,
    TextCapitalization textCapitalization = TextCapitalization.none,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscure,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        filled: true,
        fillColor: AppColors.background,
        suffixIcon: suffix != null ? Padding(padding: const EdgeInsets.only(right: 12), child: suffix) : null,
        suffixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _toggleRow(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      children: [
        Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkGray))),
        Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
      ],
    );
  }
}