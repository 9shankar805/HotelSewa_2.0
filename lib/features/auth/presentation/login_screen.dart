import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/models/user_role.dart';
import '../../../core/services/shared/auth_service.dart';
import 'providers/auth_provider.dart';
import 'otp_verification_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _localAuth = LocalAuthentication();
  bool _loading = false;
  UserRole _selectedRole = UserRole.customer;
  bool _biometricAvailable = false;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: AppColors.white,
      statusBarIconBrightness: Brightness.dark,
    ));
    _loadSavedRole();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    try {
      final canCheck = await _localAuth.canCheckBiometrics;
      final isDeviceSupported = await _localAuth.isDeviceSupported();
      if (mounted) {
        setState(() => _biometricAvailable = canCheck && isDeviceSupported);
      }
    } catch (_) {
      // biometrics not available
    }
  }

  Future<void> _handleBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString('authToken') ?? '';
    if (savedToken.isEmpty) {
      _showError('No saved session. Please sign in with email first.');
      return;
    }
    setState(() => _loading = true);
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Authenticate to sign in to HotelSewa',
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
      if (authenticated && mounted) {
        await _navigateAfterLogin();
      }
    } on PlatformException catch (e) {
      _showError('Biometric error: ${e.message}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString('user_role') ?? '';
    if (mounted) {
      setState(() => _selectedRole = UserRoleHelper.stringToRole(roleStr));
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    setState(() => _loading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', UserRoleHelper.roleToString(_selectedRole));
      if (!mounted) return;
      await _navigateAfterLogin();
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGmailLogin() async {
    setState(() => _loading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.signInWithGoogle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', UserRoleHelper.roleToString(_selectedRole));
      if (!mounted) return;
      await _navigateAfterLogin();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      // Don't show error for user-cancelled sign-in
      if (!msg.contains('cancelled')) _showError(msg);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
    ));
  }

  Future<void> _navigateAfterLogin() async {
    if (!mounted) return;
    context.go(_selectedRole == UserRole.hotelOwner ? '/owner/dashboard' : '/home');
  }

  void _showOtpLoginSheet() {
    final phoneCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Login with Phone', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 6),
              const Text('We\'ll send a 6-digit OTP to your phone number.', style: TextStyle(fontSize: 14, color: AppColors.gray)),
              const SizedBox(height: 20),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: InputDecoration(
                  hintText: '+977 98XXXXXXXX',
                  prefixIcon: const Icon(Icons.phone_outlined, color: AppColors.primary, size: 20),
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
              StatefulBuilder(builder: (ctx, setS) {
                bool sending = false;
                return SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: sending ? null : () async {
                      final phone = phoneCtrl.text.trim();
                      if (phone.isEmpty) return;
                      setS(() => sending = true);
                      final authService = AuthService();
                      final result = await authService.requestOtp(phone);
                      setS(() => sending = false);
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (result['success'] == true) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => OTPVerificationScreen(arguments: {'phoneNumber': phone}),
                        ));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result['message'] ?? 'Failed to send OTP'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: sending
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Send OTP', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _RoleTab(
                    label: 'Customer',
                    icon: Icons.person_outline,
                    selected: _selectedRole == UserRole.customer,
                    onTap: () => setState(() => _selectedRole = UserRole.customer),
                  ),
                  _RoleTab(
                    label: 'Owner',
                    icon: Icons.business_outlined,
                    selected: _selectedRole == UserRole.hotelOwner,
                    onTap: () => setState(() => _selectedRole = UserRole.hotelOwner),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: size.height - padding.top - padding.bottom),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.1, vertical: 40),
                    child: Column(
                      children: [
                        Image.asset('assets/logo.png', width: 100, height: 100,
                          errorBuilder: (_, __, ___) => const Text('HOTELSEWA',
                            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold,
                              color: AppColors.primary, letterSpacing: 2)),
                        ),
                        const SizedBox(height: 40),
                        const Text('Welcome Back',
                          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: Color(0xFF1F2937))),
                        const SizedBox(height: 8),
                        const Text('Sign in to continue to your account',
                          style: TextStyle(fontSize: 16, color: Color(0xFF6B7280), height: 1.5),
                          textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: size.width * 0.1),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Email', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: _inputDecoration('Enter your email'),
                        ),
                        const SizedBox(height: 20),
                        const Text('Password', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          decoration: _inputDecoration('Enter your password'),
                        ),
                        const SizedBox(height: 20),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () => Navigator.pushNamed(context, '/forgot-password'),
                            child: const Text('Forgot Password?',
                              style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _handleLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              disabledBackgroundColor: AppColors.primary.withOpacity(0.6),
                            ),
                            child: _loading
                                ? const SizedBox(height: 20, width: 20,
                                    child: CircularProgressIndicator(color: AppColors.white, strokeWidth: 2))
                                : const Text('Sign In',
                                    style: TextStyle(color: AppColors.white, fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                        ),
                        const SizedBox(height: 20),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: _loading ? null : _handleGmailLogin,
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: AppColors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset('assets/google.png', width: 24, height: 24),
                                const SizedBox(width: 16),
                                const Text('Continue with Gmail',
                                  style: TextStyle(fontSize: 16, color: Color(0xFF374151), fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_biometricAvailable)
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _loading ? null : _handleBiometricLogin,
                              icon: const Icon(Icons.fingerprint, size: 22, color: AppColors.primary),
                              label: const Text('Use Biometrics',
                                style: TextStyle(fontSize: 16, color: AppColors.primary, fontWeight: FontWeight.w600)),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                side: const BorderSide(color: AppColors.primary),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                backgroundColor: AppColors.white,
                              ),
                            ),
                          ),
                        const SizedBox(height: 20),
                        const Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lock_outline_rounded, size: 14, color: Color(0xFF9CA3AF)),
                              SizedBox(width: 6),
                              Text('Secured with 256-bit encryption',
                                style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        // OTP Login option
                        Center(
                          child: GestureDetector(
                            onTap: () => _showOtpLoginSheet(),
                            child: RichText(
                              text: const TextSpan(
                                text: 'Login with ',
                                style: TextStyle(fontSize: 15, color: Color(0xFF6B7280)),
                                children: [
                                  TextSpan(
                                    text: 'Phone OTP',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Center(
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => const SignupScreen())),
                            child: RichText(
                              text: const TextSpan(
                                text: "Don't have an account? ",
                                style: TextStyle(fontSize: 16, color: Color(0xFF6B7280)),
                                children: [
                                  TextSpan(text: 'Sign Up',
                                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: EdgeInsets.fromLTRB(size.width * 0.1, 0, size.width * 0.1, 40),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: const TextSpan(
                        text: 'By continuing, you agree to our ',
                        style: TextStyle(fontSize: 12, color: Color(0xFF999999), height: 1.5),
                        children: [
                          TextSpan(text: 'Terms of Service',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                          TextSpan(text: ' and '),
                          TextSpan(text: 'Privacy Policy',
                            style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }
}

class _RoleTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _RoleTab({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? Colors.white : const Color(0xFF6B7280)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: selected ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

