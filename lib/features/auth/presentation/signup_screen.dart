import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';
import '../../../core/services/shared/auth_service.dart';
import '../../../core/navigation/main_navigation.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final AuthService _authService = AuthService();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  bool _loading = false;
  bool _showPassword = false;
  bool _showConfirmPassword = false;
  bool _showReferralField = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.white,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (_nameController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _confirmPasswordController.text.isEmpty) {
      _showError('Missing Information', 'Please fill in all fields to continue');
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showError('Password Mismatch', 'Passwords do not match. Please try again.');
      return;
    }

    if (_passwordController.text.length < 6) {
      _showError('Weak Password', 'Password must be at least 6 characters long');
      return;
    }

    if (!_emailController.text.contains('@') ||
        !_emailController.text.contains('.')) {
      _showError('Invalid Email', 'Please enter a valid email address');
      return;
    }

    setState(() => _loading = true);

    final result = await _authService.signup(
      _nameController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text,
      '',
    );

    setState(() => _loading = false);

    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      final token = result['data']['token'] ?? '';
      await prefs.setString('authToken', token);
      await prefs.setString('userEmail', _emailController.text);
      await prefs.setString('userName', _nameController.text);

      // Apply referral code if entered
      final referralCode = _referralController.text.trim().toUpperCase();
      if (referralCode.isNotEmpty && token.isNotEmpty) {
        try {
          await ApiService.post(
            ApiConfig.loyaltyApplyReferralEndpoint,
            token: token,
            data: {'referral_code': referralCode},
          );
        } catch (_) {
          // Non-fatal — continue even if referral apply fails
        }
      }

      if (!mounted) return;

      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Welcome to HotelSewa! 🎉'),
          content: Text(referralCode.isNotEmpty
              ? 'Account created! Your referral code "$referralCode" has been applied. Enjoy your Rs.500 reward!'
              : 'Your account has been created successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => const MainNavigation()),
                );
              },
              child: const Text('Get Started'),
            ),
          ],
        ),
      );
    } else {
      _showError('Signup Failed', result['message'] ?? 'Something went wrong');
    }
  }

  Map<String, dynamic>? _getPasswordStrength() {
    if (_passwordController.text.isEmpty) return null;
    if (_passwordController.text.length < 6) {
      return {'text': 'Weak', 'color': const Color(0xFFEF4444), 'width': 0.3};
    }
    if (_passwordController.text.length < 8) {
      return {'text': 'Good', 'color': const Color(0xFFF59E0B), 'width': 0.6};
    }
    return {'text': 'Strong', 'color': const Color(0xFF10B981), 'width': 1.0};
  }

  void _showError(String title, String message) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final passwordStrength = _getPasswordStrength();

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Stack(
          children: [
            SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  children: [
                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(30, 80, 30, 30),
                      child: Column(
                        children: [
                          // Logo
                          Image.asset(
                            'assets/logo.png',
                            width: 80,
                            height: 80,
                            errorBuilder: (context, error, stackTrace) {
                              return const Text(
                                'HOTELSEWA',
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                  letterSpacing: 2,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                          const Text(
                            'Join HOTELSEWA',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1F2937),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Create your account and discover amazing hotels',
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF6B7280),
                              height: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),

                    // Form
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 30),
                      child: Column(
                        children: [
                          // Name input
                          _buildInputField(
                            label: 'Full Name',
                            controller: _nameController,
                            hint: 'Enter your full name',
                            prefixIcon: Icons.person_outline_rounded,
                            textCapitalization: TextCapitalization.words,
                            suffixIcon: _nameController.text.isNotEmpty
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF10B981))
                                : null,
                          ),

                          // Email input
                          _buildInputField(
                            label: 'Email Address',
                            controller: _emailController,
                            hint: 'Enter your email address',
                            prefixIcon: Icons.email_outlined,
                            keyboardType: TextInputType.emailAddress,
                            suffixIcon: _emailController.text.contains('@') &&
                                    _emailController.text.contains('.')
                                ? const Icon(Icons.check_circle,
                                    color: Color(0xFF10B981))
                                : null,
                          ),

                          // Password input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                label: 'Password',
                                controller: _passwordController,
                                hint: 'Create a strong password',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: !_showPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  onPressed: () {
                                    setState(() => _showPassword = !_showPassword);
                                  },
                                ),
                              ),
                              if (passwordStrength != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          height: 4,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFE5E7EB),
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                          child: FractionallySizedBox(
                                            alignment: Alignment.centerLeft,
                                            widthFactor: passwordStrength['width'],
                                            child: Container(
                                              decoration: BoxDecoration(
                                                color: passwordStrength['color'],
                                                borderRadius:
                                                    BorderRadius.circular(2),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        passwordStrength['text'],
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: passwordStrength['color'],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),

                          // Confirm Password input
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildInputField(
                                label: 'Confirm Password',
                                controller: _confirmPasswordController,
                                hint: 'Confirm your password',
                                prefixIcon: Icons.lock_outline_rounded,
                                obscureText: !_showConfirmPassword,
                                suffixIcon: IconButton(
                                  icon: Icon(
                                    _showConfirmPassword
                                        ? Icons.visibility_off
                                        : Icons.visibility,
                                    color: const Color(0xFF6B7280),
                                  ),
                                  onPressed: () {
                                    setState(() => _showConfirmPassword =
                                        !_showConfirmPassword);
                                  },
                                ),
                              ),
                              if (_confirmPasswordController.text.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text(
                                    _passwordController.text ==
                                            _confirmPasswordController.text
                                        ? '✓ Passwords match'
                                        : '✗ Passwords do not match',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: _passwordController.text ==
                                              _confirmPasswordController.text
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFEF4444),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(height: 10),

                          // Optional referral code
                          GestureDetector(
                            onTap: () => setState(() => _showReferralField = !_showReferralField),
                            child: Row(
                              children: [
                                Icon(
                                  _showReferralField
                                      ? Icons.keyboard_arrow_up_rounded
                                      : Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: AppColors.primary,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _showReferralField
                                      ? 'Remove referral code'
                                      : 'Have a referral code? (Optional)',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          if (_showReferralField) ...[
                            const SizedBox(height: 12),
                            Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFF5F5),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                              child: Row(
                                children: [
                                  const Icon(Icons.card_giftcard_rounded,
                                      color: AppColors.primary, size: 20),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: TextField(
                                      controller: _referralController,
                                      textCapitalization: TextCapitalization.characters,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 2,
                                        color: AppColors.primary,
                                      ),
                                      decoration: const InputDecoration(
                                        hintText: 'Enter referral code',
                                        hintStyle: TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          letterSpacing: 0,
                                          color: Color(0xFFADB5BD),
                                        ),
                                        border: InputBorder.none,
                                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                                      ),
                                    ),
                                  ),
                                  if (_referralController.text.isNotEmpty)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppColors.primary, size: 18),
                                ],
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Padding(
                              padding: EdgeInsets.only(left: 4),
                              child: Text(
                                'You\'ll get Rs.500 off your first booking!',
                                style: TextStyle(fontSize: 12, color: AppColors.primary),
                              ),
                            ),
                          ],

                          const SizedBox(height: 16),

                          // Signup button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _loading ? null : _handleSignup,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 18),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                elevation: 3,
                                shadowColor: AppColors.primary.withOpacity(0.3),
                                disabledBackgroundColor:
                                    AppColors.primary.withOpacity(0.6),
                              ),
                              child: _loading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: AppColors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: const [
                                        Text(
                                          'Create My Account',
                                          style: TextStyle(
                                            color: AppColors.white,
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Icon(Icons.arrow_forward,
                                            color: AppColors.white, size: 20),
                                      ],
                                    ),
                            ),
                          ),

                          const SizedBox(height: 30),

                          // Benefits
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFEF7F7),
                              borderRadius: BorderRadius.circular(12),
                              border: const Border(
                                left: BorderSide(
                                  color: AppColors.primary,
                                  width: 4,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'What you\'ll get:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF374151),
                                  ),
                                ),
                                const SizedBox(height: 12),
                                _buildBenefitItem(
                                  Icons.hotel,
                                  'Access to 1000+ premium hotels',
                                ),
                                _buildBenefitItem(
                                  Icons.local_offer,
                                  'Exclusive deals and discounts',
                                ),
                                _buildBenefitItem(
                                  Icons.support_agent,
                                  '24/7 customer support',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Back button
            Positioned(
              top: 20,
              left: 20,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.arrow_back,
                    color: Color(0xFF666666),
                    size: 20,
                  ),
                ),
              ),
            ),

            // Footer
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 30),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  border: Border(
                    top: BorderSide(color: Color(0xFFF3F4F6)),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(
                        fontSize: 16,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: const Size(0, 0),
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 16,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
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

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    IconData? prefixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            textCapitalization: textCapitalization,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Color(0xFF9CA3AF)),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: const Color(0xFF9CA3AF), size: 20)
                  : null,
              filled: true,
              fillColor: const Color(0xFFFAFAFA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
              contentPadding: const EdgeInsets.all(16),
              suffixIcon: suffixIcon,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

