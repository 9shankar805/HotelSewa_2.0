import 'package:flutter/foundation.dart';
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
import '../../../core/utils/referral_prompt.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _localAuth = LocalAuthentication();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _loading = false;
  bool _obscurePassword = true;
  bool _biometricAvailable = false;
  UserRole _selectedRole = UserRole.customer;
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ));
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
    _loadSavedRole();
    _checkBiometric();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _loadSavedRole() async {
    final prefs = await SharedPreferences.getInstance();
    final roleStr = prefs.getString('user_role') ?? '';
    if (mounted) setState(() => _selectedRole = UserRoleHelper.stringToRole(roleStr));
  }

  Future<void> _checkBiometric() async {
    try {
      final can = await _localAuth.canCheckBiometrics;
      final supported = await _localAuth.isDeviceSupported();
      if (mounted) setState(() => _biometricAvailable = can && supported);
    } catch (_) {}
  }

  Future<void> _handleLogin() async {
    if (_emailCtrl.text.isEmpty || _passwordCtrl.text.isEmpty) {
      _showError('Please fill in all fields');
      return;
    }
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.login(email: _emailCtrl.text.trim(), password: _passwordCtrl.text);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', UserRoleHelper.roleToString(_selectedRole));
      if (!mounted) return;
      context.go(_selectedRole == UserRole.hotelOwner ? '/owner/dashboard' : '/home');
    } catch (e) {
      _showError(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _handleGoogleLogin() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signInWithGoogle();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', UserRoleHelper.roleToString(_selectedRole));
      if (!mounted) return;
      // Show referral prompt for new users before going home
      await ReferralPrompt.showIfNeeded(context, token: auth.token ?? '');
      if (!mounted) return;
      context.go(_selectedRole == UserRole.hotelOwner ? '/owner/dashboard' : '/home');
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('cancelled')) _showError(msg);
    }
  }

  Future<void> _handleAppleLogin() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.signInWithApple();
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_role', UserRoleHelper.roleToString(_selectedRole));
      if (!mounted) return;
      // Show referral prompt for new users before going home
      await ReferralPrompt.showIfNeeded(context, token: auth.token ?? '');
      if (!mounted) return;
      context.go(_selectedRole == UserRole.hotelOwner ? '/owner/dashboard' : '/home');
    } catch (e) {
      if (mounted) setState(() => _loading = false);
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('cancelled')) _showError(msg);
    }
  }

  Future<void> _handleBiometricLogin() async {
    final prefs = await SharedPreferences.getInstance();
    if ((prefs.getString('authToken') ?? '').isEmpty) {
      _showError('No saved session. Please sign in first.');
      return;
    }
    setState(() => _loading = true);
    try {
      final ok = await _localAuth.authenticate(
        localizedReason: 'Authenticate to sign in to HotelSewa',
        options: const AuthenticationOptions(biometricOnly: false, stickyAuth: true),
      );
      if (ok && mounted) {
        context.go(_selectedRole == UserRole.hotelOwner ? '/owner/dashboard' : '/home');
      }
    } on PlatformException catch (e) {
      _showError('Biometric error: ${e.message}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  void _showOtpSheet() {
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
              Center(child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 20),
              const Text('Phone OTP Login', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              const Text("We'll send a 6-digit OTP to your number.",
                style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
              const SizedBox(height: 20),
              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                autofocus: true,
                decoration: _inputDecoration('e.g. +977 98XXXXXXXX', Icons.phone_outlined),
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
                      final result = await AuthService().requestOtp(phone);
                      setS(() => sending = false);
                      if (!mounted) return;
                      Navigator.pop(context);
                      if (result['success'] == true) {
                        Navigator.push(context, MaterialPageRoute(
                          builder: (_) => OTPVerificationScreen(arguments: {'phoneNumber': phone})));
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                          content: Text(result['message'] ?? 'Failed to send OTP'),
                          backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: sending
                        ? const SizedBox(width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
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
    final isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    return Scaffold(
      backgroundColor: AppColors.white,
      resizeToAvoidBottomInset: false,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: size.width * 0.07),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Top bar: logo + role toggle ──────────────────────────
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Image.asset('assets/logo.png', width: 44, height: 44,
                      errorBuilder: (_, __, ___) => Container(
                        width: 44, height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.hotel, color: Colors.white, size: 24),
                      ),
                    ),
                    _RoleToggle(
                      selected: _selectedRole,
                      onChanged: (r) => setState(() => _selectedRole = r),
                    ),
                  ],
                ),

                // ── Headline ─────────────────────────────────────────────
                const SizedBox(height: 28),
                const Text('Welcome back',
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800,
                    color: Color(0xFF111827), letterSpacing: -0.5)),
                const SizedBox(height: 4),
                Text(
                  _selectedRole == UserRole.hotelOwner
                      ? 'Sign in to manage your property'
                      : 'Sign in to find your perfect stay',
                  style: const TextStyle(fontSize: 15, color: Color(0xFF6B7280), height: 1.4),
                ),

                // ── Email field ───────────────────────────────────────────
                const SizedBox(height: 24),
                TextField(
                  controller: _emailCtrl,
                  focusNode: _emailFocus,
                  keyboardType: TextInputType.emailAddress,
                  textInputAction: TextInputAction.next,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                  decoration: _inputDecoration('Email address', Icons.mail_outline_rounded),
                ),

                // ── Password field ────────────────────────────────────────
                const SizedBox(height: 12),
                TextField(
                  controller: _passwordCtrl,
                  focusNode: _passwordFocus,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _handleLogin(),
                  style: const TextStyle(fontSize: 15, color: Color(0xFF111827)),
                  decoration: _inputDecoration('Password', Icons.lock_outline_rounded,
                    suffix: GestureDetector(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20, color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ),
                ),

                // ── Forgot password ───────────────────────────────────────
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => context.push('/forgot-password'),
                    child: const Text('Forgot password?',
                      style: TextStyle(fontSize: 13, color: AppColors.primary,
                        fontWeight: FontWeight.w600)),
                  ),
                ),

                // ── Sign in button ────────────────────────────────────────
                const SizedBox(height: 20),
                _PrimaryButton(
                  label: 'Sign In',
                  loading: _loading,
                  onTap: _handleLogin,
                ),

                // ── Divider ───────────────────────────────────────────────
                const SizedBox(height: 20),
                const _Divider(),
                const SizedBox(height: 16),

                // ── Social buttons row ────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: _SocialButton(
                        onTap: _loading ? null : _handleGoogleLogin,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Image.asset('assets/google.png', width: 20, height: 20,
                              errorBuilder: (_, __, ___) =>
                                const Icon(Icons.g_mobiledata, size: 20, color: Color(0xFF4285F4))),
                            const SizedBox(width: 8),
                            const Text('Google', style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                          ],
                        ),
                      ),
                    ),
                    if (isApple) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _SocialButton(
                          dark: true,
                          onTap: _loading ? null : _handleAppleLogin,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.apple, size: 20, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Apple', style: TextStyle(fontSize: 14,
                                fontWeight: FontWeight.w600, color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(width: 12),
                    Expanded(
                      child: _SocialButton(
                        onTap: _loading ? null : _showOtpSheet,
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.phone_outlined, size: 20, color: Color(0xFF374151)),
                            SizedBox(width: 8),
                            Text('OTP', style: TextStyle(fontSize: 14,
                              fontWeight: FontWeight.w600, color: Color(0xFF374151))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // ── Biometric ─────────────────────────────────────────────
                if (_biometricAvailable) ...[
                  const SizedBox(height: 12),
                  _SocialButton(
                    onTap: _loading ? null : _handleBiometricLogin,
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.fingerprint, size: 20, color: AppColors.primary),
                        SizedBox(width: 8),
                        Text('Use Biometrics', style: TextStyle(fontSize: 14,
                          fontWeight: FontWeight.w600, color: AppColors.primary)),
                      ],
                    ),
                  ),
                ],

                const Spacer(),

                // ── Bottom: sign up + terms ───────────────────────────────
                Center(
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SignupScreen())),
                    child: RichText(
                      text: const TextSpan(
                        text: "Don't have an account? ",
                        style: TextStyle(fontSize: 14, color: Color(0xFF6B7280)),
                        children: [
                          TextSpan(text: 'Sign Up',
                            style: TextStyle(color: AppColors.primary,
                              fontWeight: FontWeight.w700)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text(
                    'By continuing you agree to our Terms & Privacy Policy',
                    style: TextStyle(fontSize: 11, color: Colors.grey[400]),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 15, color: Color(0xFFADB5BD)),
      prefixIcon: Icon(icon, size: 20, color: const Color(0xFFADB5BD)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF7F8FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.8)),
    );
  }
}

// ─── Role Toggle ──────────────────────────────────────────────────────────────
class _RoleToggle extends StatelessWidget {
  final UserRole selected;
  final ValueChanged<UserRole> onChanged;
  const _RoleToggle({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Tab(label: 'Customer', icon: Icons.person_outline_rounded,
            selected: selected == UserRole.customer,
            onTap: () => onChanged(UserRole.customer)),
          _Tab(label: 'Owner', icon: Icons.business_outlined,
            selected: selected == UserRole.hotelOwner,
            onTap: () => onChanged(UserRole.hotelOwner)),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  const _Tab({required this.label, required this.icon,
    required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          boxShadow: selected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3),
            blurRadius: 8, offset: const Offset(0, 3))] : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: selected ? Colors.white : const Color(0xFF9CA3AF)),
            const SizedBox(width: 5),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: selected ? Colors.white : const Color(0xFF9CA3AF))),
          ],
        ),
      ),
    );
  }
}

// ─── Primary Button ───────────────────────────────────────────────────────────
class _PrimaryButton extends StatelessWidget {
  final String label;
  final bool loading;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          gradient: loading
              ? const LinearGradient(colors: [Color(0xFFE60023), Color(0xFFFF4D6A)])
              : const LinearGradient(colors: [Color(0xFFE60023), Color(0xFFFF3651)],
                  begin: Alignment.topLeft, end: Alignment.bottomRight),
          borderRadius: BorderRadius.circular(14),
          boxShadow: loading ? [] : [
            BoxShadow(color: AppColors.primary.withOpacity(0.4),
              blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        child: Center(
          child: loading
              ? const SizedBox(width: 22, height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(label, style: const TextStyle(color: Colors.white,
                  fontSize: 16, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
        ),
      ),
    );
  }
}

// ─── Divider ──────────────────────────────────────────────────────────────────
class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
      const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12),
        child: Text('or continue with', style: TextStyle(fontSize: 12,
          color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
      ),
      Expanded(child: Container(height: 1, color: const Color(0xFFE5E7EB))),
    ]);
  }
}

// ─── Social Button ────────────────────────────────────────────────────────────
class _SocialButton extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool dark;
  const _SocialButton({required this.child, this.onTap, this.dark = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: dark ? Colors.black : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: dark ? null : Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: dark ? null : [
            BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: child,
      ),
    );
  }
}
