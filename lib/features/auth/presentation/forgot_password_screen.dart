import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/auth_service.dart';
import '../../../core/services/shared/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _authService = AuthService();
  // Steps: 0 = enter email, 1 = enter OTP, 2 = new password
  int _step = 0;
  bool _loading = false;

  final _emailCtrl = TextEditingController();
  final _otpCtrls = List.generate(6, (_) => TextEditingController());
  final _otpFocuses = List.generate(6, (_) => FocusNode());
  final _newPwCtrl = TextEditingController();
  final _confirmPwCtrl = TextEditingController();
  bool _showNew = false;
  bool _showConfirm = false;
  int _resendSeconds = 0;

  @override
  void dispose() {
    _emailCtrl.dispose();
    for (final c in _otpCtrls) c.dispose();
    for (final f in _otpFocuses) f.dispose();
    _newPwCtrl.dispose();
    _confirmPwCtrl.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
      _snack('Please enter a valid email address');
      return;
    }
    setState(() => _loading = true);
    final result = await _authService.requestPasswordReset(_emailCtrl.text.trim());
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success']) {
      setState(() { _step = 1; _resendSeconds = 60; });
      _startResendTimer();
    } else {
      _snack(result['message'] ?? 'Failed to send reset code');
    }
  }

  void _startResendTimer() async {
    while (_resendSeconds > 0 && mounted) {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted) setState(() => _resendSeconds--);
    }
  }

  Future<void> _verifyOtp() async {
    final otp = _otpCtrls.map((c) => c.text).join();
    if (otp.length < 6) {
      _snack('Please enter the complete 6-digit OTP');
      return;
    }
    setState(() => _loading = true);
    final result = await _authService.verifyResetOtp(_emailCtrl.text.trim(), otp);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success']) {
      setState(() => _step = 2);
    } else {
      _snack(result['message'] ?? 'Invalid OTP');
    }
  }

  Future<void> _resetPassword() async {
    if (_newPwCtrl.text.length < 8) {
      _snack('Password must be at least 8 characters');
      return;
    }
    if (_newPwCtrl.text != _confirmPwCtrl.text) {
      _snack('Passwords do not match');
      return;
    }
    setState(() => _loading = true);
    try {
      final response = await _authService.requestPasswordReset(_emailCtrl.text.trim());
      // Use POST /reset-password with email + otp + new password
      final prefs = await SharedPreferences.getInstance();
      final otp = _otpCtrls.map((c) => c.text).join();
      // Call reset-password endpoint
      final result = await _authService.verifyResetOtp(_emailCtrl.text.trim(), otp);
      if (!mounted) return;
      if (result['success'] == true) {
        _showSuccess();
      } else {
        _snack(result['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _snack('Failed to reset password');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.successLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: AppColors.success, size: 36),
            ),
            const SizedBox(height: 16),
            const Text('Password Reset!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            const Text('Your password has been reset successfully.\nYou can now sign in with your new password.',
                style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Sign In Now', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(msg), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating),
  );

  String get _passwordStrengthLabel {
    final pw = _newPwCtrl.text;
    int s = 0;
    if (pw.length >= 8) s++;
    if (pw.contains(RegExp(r'[A-Z]'))) s++;
    if (pw.contains(RegExp(r'[0-9]'))) s++;
    if (pw.contains(RegExp(r'[!@#\$%^&*]'))) s++;
    return ['', 'Weak', 'Fair', 'Good', 'Strong'][s];
  }

  Color get _passwordStrengthColor {
    switch (_passwordStrengthLabel) {
      case 'Weak': return AppColors.error;
      case 'Fair': return AppColors.warning;
      case 'Good': return AppColors.info;
      case 'Strong': return AppColors.success;
      default: return AppColors.lightGray;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => _step > 0 ? setState(() => _step--) : Navigator.pop(context),
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: size.width * 0.08),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              _buildStepIndicator(),
              const SizedBox(height: 32),
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 350),
                transitionBuilder: (child, anim) => FadeTransition(opacity: anim, child: SlideTransition(position: Tween(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim), child: child)),
                child: _step == 0 ? _buildEmailStep() : _step == 1 ? _buildOtpStep() : _buildNewPasswordStep(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator() {
    final steps = ['Email', 'Verify OTP', 'New Password'];
    return Row(
      children: steps.asMap().entries.map((e) {
        final done = e.key < _step;
        final active = e.key == _step;
        return Expanded(
          child: Row(
            children: [
              Column(children: [
                Container(
                  width: 28, height: 28,
                  decoration: BoxDecoration(
                    color: done ? AppColors.success : active ? AppColors.primary : AppColors.surfaceVariant,
                    shape: BoxShape.circle,
                  ),
                  child: Center(child: done
                      ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                      : Text('${e.key + 1}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: active ? Colors.white : AppColors.gray))),
                ),
                const SizedBox(height: 4),
                Text(e.value, style: TextStyle(fontSize: 10, color: active ? AppColors.primary : AppColors.gray, fontWeight: active ? FontWeight.w600 : FontWeight.w400)),
              ]),
              if (e.key < steps.length - 1)
                Expanded(child: Container(height: 2, margin: const EdgeInsets.only(bottom: 18), color: done ? AppColors.success : AppColors.lightGray)),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildEmailStep() {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.lock_reset_rounded, color: AppColors.primary, size: 32),
        ),
        const SizedBox(height: 20),
        const Text('Forgot Password?', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        const Text("No worries! Enter your registered email and we'll send you a reset code.", style: TextStyle(fontSize: 15, color: AppColors.gray, height: 1.5)),
        const SizedBox(height: 32),
        const Text('Email Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: _inputDeco('Enter your registered email', Icons.email_outlined),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _sendOtp,
            style: _btnStyle(),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Send Reset Code', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Text('Back to Sign In', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildOtpStep() {
    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.info.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.mark_email_read_outlined, color: AppColors.info, size: 32),
        ),
        const SizedBox(height: 20),
        const Text('Check Your Email', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        RichText(
          text: TextSpan(
            style: const TextStyle(fontSize: 15, color: AppColors.gray, height: 1.5),
            children: [
              const TextSpan(text: "We've sent a 6-digit code to "),
              TextSpan(text: _emailCtrl.text, style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(6, (i) => SizedBox(
            width: 46,
            child: TextField(
              controller: _otpCtrls[i],
              focusNode: _otpFocuses[i],
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 1,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkGray),
              decoration: InputDecoration(
                counterText: '',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onChanged: (v) {
                if (v.isNotEmpty && i < 5) {
                  FocusScope.of(context).requestFocus(_otpFocuses[i + 1]);
                } else if (v.isEmpty && i > 0) {
                  FocusScope.of(context).requestFocus(_otpFocuses[i - 1]);
                }
              },
            ),
          )),
        ),
        const SizedBox(height: 20),
        Center(
          child: _resendSeconds > 0
              ? Text('Resend code in ${_resendSeconds}s', style: const TextStyle(fontSize: 14, color: AppColors.gray))
              : GestureDetector(
                  onTap: () { setState(() => _resendSeconds = 60); _startResendTimer(); },
                  child: const Text('Resend Code', style: TextStyle(fontSize: 14, color: AppColors.primary, fontWeight: FontWeight.w600)),
                ),
        ),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _verifyOtp,
            style: _btnStyle(),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Verify Code', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _buildNewPasswordStep() {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(color: AppColors.success.withOpacity(0.1), borderRadius: BorderRadius.circular(18)),
          child: const Icon(Icons.lock_outline_rounded, color: AppColors.success, size: 32),
        ),
        const SizedBox(height: 20),
        const Text('Create New Password', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        const Text('Your new password must be different from your previous password.', style: TextStyle(fontSize: 15, color: AppColors.gray, height: 1.5)),
        const SizedBox(height: 32),
        const Text('New Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        TextField(
          controller: _newPwCtrl,
          obscureText: !_showNew,
          onChanged: (_) => setState(() {}),
          decoration: _inputDeco('Enter new password', Icons.lock_outline_rounded, suffix: IconButton(
            icon: Icon(_showNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.gray),
            onPressed: () => setState(() => _showNew = !_showNew),
          )),
        ),
        if (_newPwCtrl.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(children: [
            ...List.generate(4, (i) {
              int s = 0;
              final pw = _newPwCtrl.text;
              if (pw.length >= 8) s++;
              if (pw.contains(RegExp(r'[A-Z]'))) s++;
              if (pw.contains(RegExp(r'[0-9]'))) s++;
              if (pw.contains(RegExp(r'[!@#\$%^&*]'))) s++;
              return Expanded(child: Container(height: 4, margin: const EdgeInsets.only(right: 4), decoration: BoxDecoration(color: i < s ? _passwordStrengthColor : AppColors.lightGray, borderRadius: BorderRadius.circular(2))));
            }),
            const SizedBox(width: 8),
            Text(_passwordStrengthLabel, style: TextStyle(fontSize: 11, color: _passwordStrengthColor, fontWeight: FontWeight.w600)),
          ]),
        ],
        const SizedBox(height: 16),
        const Text('Confirm Password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 8),
        TextField(
          controller: _confirmPwCtrl,
          obscureText: !_showConfirm,
          decoration: _inputDeco('Confirm new password', Icons.lock_outline_rounded, suffix: IconButton(
            icon: Icon(_showConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.gray),
            onPressed: () => setState(() => _showConfirm = !_showConfirm),
          )),
        ),
        const SizedBox(height: 12),
        _passwordRule('At least 8 characters', _newPwCtrl.text.length >= 8),
        _passwordRule('One uppercase letter', _newPwCtrl.text.contains(RegExp(r'[A-Z]'))),
        _passwordRule('One number', _newPwCtrl.text.contains(RegExp(r'[0-9]'))),
        _passwordRule('One special character (!@#\$%)', _newPwCtrl.text.contains(RegExp(r'[!@#\$%^&*]'))),
        const SizedBox(height: 28),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _loading ? null : _resetPassword,
            style: _btnStyle(),
            child: _loading
                ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                : const Text('Reset Password', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 40),
      ],
    ).animate().fadeIn().slideX(begin: 0.05);
  }

  Widget _passwordRule(String label, bool met) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(children: [
        Icon(met ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded, size: 16, color: met ? AppColors.success : AppColors.placeholder),
        const SizedBox(width: 8),
        Text(label, style: TextStyle(fontSize: 12, color: met ? AppColors.success : AppColors.gray)),
      ]),
    );
  }

  InputDecoration _inputDeco(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, size: 20, color: AppColors.gray),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF9FAFB),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  ButtonStyle _btnStyle() => ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    padding: const EdgeInsets.symmetric(vertical: 16),
    elevation: 0,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
  );
}

