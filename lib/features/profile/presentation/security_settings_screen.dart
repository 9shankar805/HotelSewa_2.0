import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';
import '../../../core/services/two_factor_service.dart';

class SecuritySettingsScreen extends StatefulWidget {
  const SecuritySettingsScreen({Key? key}) : super(key: key);

  @override
  State<SecuritySettingsScreen> createState() => _SecuritySettingsScreenState();
}

class _SecuritySettingsScreenState extends State<SecuritySettingsScreen> {
  final _twoFactorService = TwoFactorService();

  bool _biometricEnabled = false;
  bool _twoFactorEnabled = false;
  bool _loginAlerts = true;
  bool _loadingStatus = true;
  bool _togglingBiometric = false;
  bool _toggling2FA = false;

  // Change password
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;
  bool _changingPw = false;

  @override
  void initState() {
    super.initState();
    _loadSecurityStatus();
  }

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  Future<void> _loadSecurityStatus() async {
    setState(() => _loadingStatus = true);
    try {
      final result = await _twoFactorService.getTwoFactorStatus();
      if (result['success'] == true && mounted) {
        final status = result['status'] ?? {};
        setState(() {
          _twoFactorEnabled = status['enabled'] == true || status['is_enabled'] == true;
          _biometricEnabled = status['biometric_enabled'] == true || status['biometric'] == true;
          _loginAlerts = status['login_alerts'] ?? status['login_notifications'] ?? true;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingStatus = false);
  }

  Future<void> _toggleBiometric(bool enabled) async {
    setState(() => _togglingBiometric = true);
    final result = await _twoFactorService.toggleBiometricAuth(enabled: enabled);
    if (mounted) {
      if (result['success'] == true) {
        setState(() => _biometricEnabled = enabled);
        _showSnack(enabled ? 'Biometric login enabled' : 'Biometric login disabled');
      } else {
        _showSnack(result['message'] ?? 'Failed to update biometric setting', isError: true);
      }
      setState(() => _togglingBiometric = false);
    }
  }

  Future<void> _toggle2FA(bool enabled) async {
    if (enabled) {
      // Show setup dialog
      await _show2FASetupDialog();
    } else {
      // Require password to disable
      await _show2FADisableDialog();
    }
  }

  Future<void> _show2FASetupDialog() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Enable Two-Factor Auth', style: TextStyle(fontWeight: FontWeight.w700)),
        content: const Text('A verification code will be sent to your phone or email each time you log in.\n\nChoose your preferred method:', style: TextStyle(color: AppColors.gray, height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Enable via SMS', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _toggling2FA = true);
    final result = await _twoFactorService.setupTwoFactor(method: 'sms');
    if (mounted) {
      if (result['success'] == true) {
        setState(() => _twoFactorEnabled = true);
        _showSnack('Two-factor authentication enabled');
      } else {
        _showSnack(result['message'] ?? 'Failed to enable 2FA', isError: true);
      }
      setState(() => _toggling2FA = false);
    }
  }

  Future<void> _show2FADisableDialog() async {
    final pwCtrl = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Disable Two-Factor Auth', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Enter your password to disable 2FA:', style: TextStyle(color: AppColors.gray)),
            const SizedBox(height: 12),
            TextField(
              controller: pwCtrl,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Current password',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Disable', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _toggling2FA = true);
    final result = await _twoFactorService.disableTwoFactor(password: pwCtrl.text);
    pwCtrl.dispose();
    if (mounted) {
      if (result['success'] == true) {
        setState(() => _twoFactorEnabled = false);
        _showSnack('Two-factor authentication disabled');
      } else {
        _showSnack(result['message'] ?? 'Failed to disable 2FA', isError: true);
      }
      setState(() => _toggling2FA = false);
    }
  }

  Future<void> _changePassword() async {
    if (_currentPwController.text.isEmpty) {
      _showSnack('Enter your current password', isError: true);
      return;
    }
    if (_newPwController.text != _confirmPwController.text) {
      _showSnack('Passwords do not match', isError: true);
      return;
    }
    if (_newPwController.text.length < 8) {
      _showSnack('Password must be at least 8 characters', isError: true);
      return;
    }
    setState(() => _changingPw = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(
        ApiConfig.updateProfileEndpoint,
        token: token,
        data: {
          'current_password': _currentPwController.text,
          'password': _newPwController.text,
          'password_confirmation': _confirmPwController.text,
        },
      );
      if (!mounted) return;
      if (response['success'] == true) {
        _currentPwController.clear();
        _newPwController.clear();
        _confirmPwController.clear();
        _showSnack('Password changed successfully');
      } else {
        _showSnack(response['message'] ?? 'Failed to change password', isError: true);
      }
    } catch (e) {
      _showSnack('Failed to change password', isError: true);
    } finally {
      if (mounted) setState(() => _changingPw = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
      behavior: SnackBarBehavior.floating,
    ));
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
        title: const Text('Security Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Security toggles
            _sectionLabel('Authentication'),
            const SizedBox(height: 10),
            _card(child: Column(
              children: [
                _toggleRow(Icons.fingerprint_rounded, AppColors.primary, 'Biometric Login', 'Use fingerprint or Face ID',
                    _biometricEnabled, _togglingBiometric ? null : _toggleBiometric),
                const Divider(color: AppColors.lightGray, height: 1),
                _toggleRow(Icons.security_rounded, AppColors.success, 'Two-Factor Authentication', 'Extra security via SMS/email',
                    _twoFactorEnabled, _toggling2FA ? null : _toggle2FA),
                const Divider(color: AppColors.lightGray, height: 1),
                _toggleRow(Icons.notifications_active_outlined, AppColors.warning, 'Login Alerts', 'Get notified of new sign-ins',
                    _loginAlerts, (v) => setState(() => _loginAlerts = v)),
              ],
            )).animate().fadeIn().slideY(begin: 0.1),
            const SizedBox(height: 20),

            _sectionLabel('Change Password'),
            const SizedBox(height: 10),
            _card(child: Column(
              children: [
                _pwField('Current Password', _currentPwController, _showCurrent, () => setState(() => _showCurrent = !_showCurrent)),
                const SizedBox(height: 14),
                _pwField('New Password', _newPwController, _showNew, () => setState(() => _showNew = !_showNew)),
                const SizedBox(height: 14),
                _pwField('Confirm New Password', _confirmPwController, _showConfirm, () => setState(() => _showConfirm = !_showConfirm)),
                const SizedBox(height: 6),
                _passwordStrength(_newPwController.text),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _changingPw ? null : _changePassword,
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    child: _changingPw
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                        : const Text('Update Password', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            )).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
            const SizedBox(height: 20),

            _sectionLabel('Danger Zone'),
            const SizedBox(height: 10),
            _card(child: Column(
              children: [
                _actionRow(Icons.devices_outlined, AppColors.info, 'Active Sessions', 'Manage logged-in devices', () {}),
                const Divider(color: AppColors.lightGray, height: 1),
                _actionRow(Icons.delete_forever_outlined, AppColors.error, 'Delete Account', 'Permanently remove your account', () => Navigator.pushNamed(context, '/delete-account')),
              ],
            )).animate().fadeIn(delay: 160.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray, letterSpacing: 0.5));

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
    child: child,
  );

  Widget _toggleRow(IconData icon, Color color, String title, String sub, bool value, ValueChanged<bool>? onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(
        children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 19, color: color)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
            Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
          ])),
          onChanged == null
              ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
              : Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }

  Widget _actionRow(IconData icon, Color color, String title, String sub, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(width: 38, height: 38, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, size: 19, color: color)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color == AppColors.error ? AppColors.error : AppColors.darkGray)),
              Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
            ])),
            const Icon(Icons.chevron_right_rounded, size: 20, color: AppColors.placeholder),
          ],
        ),
      ),
    );
  }

  Widget _pwField(String label, TextEditingController ctrl, bool show, VoidCallback toggle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          obscureText: !show,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: '••••••••',
            filled: true, fillColor: AppColors.background,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            suffixIcon: IconButton(icon: Icon(show ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.gray), onPressed: toggle),
          ),
        ),
      ],
    );
  }

  Widget _passwordStrength(String pw) {
    if (pw.isEmpty) return const SizedBox();
    int strength = 0;
    if (pw.length >= 8) strength++;
    if (pw.contains(RegExp(r'[A-Z]'))) strength++;
    if (pw.contains(RegExp(r'[0-9]'))) strength++;
    if (pw.contains(RegExp(r'[!@#\$%^&*]'))) strength++;

    final colors = [AppColors.error, AppColors.warning, AppColors.warning, AppColors.success, AppColors.success];
    final labels = ['', 'Weak', 'Fair', 'Good', 'Strong'];

    return Row(
      children: [
        ...List.generate(4, (i) => Expanded(
          child: Container(
            height: 4, margin: const EdgeInsets.only(right: 4),
            decoration: BoxDecoration(
              color: i < strength ? colors[strength] : AppColors.lightGray,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        )),
        const SizedBox(width: 8),
        Text(labels[strength], style: TextStyle(fontSize: 11, color: colors[strength], fontWeight: FontWeight.w600)),
      ],
    );
  }
}
