import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_constants.dart';

class Biometric2FAScreen extends StatefulWidget {
  const Biometric2FAScreen({super.key});
  @override
  State<Biometric2FAScreen> createState() => _Biometric2FAScreenState();
}

class _Biometric2FAScreenState extends State<Biometric2FAScreen> {
  bool _biometricEnabled = false;
  bool _twoFAEnabled = false;
  String _twoFAMethod = 'sms'; // 'sms' | 'totp'
  bool _sessionAlerts = true;
  final _otpCtrl = TextEditingController();
  bool _verifying = false;

  @override
  void dispose() {
    _otpCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      appBar: AppBar(title: const Text('Security & 2FA')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Security score banner
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: (_biometricEnabled && _twoFAEnabled)
                    ? [const Color(0xFF1A6B3C), const Color(0xFF2E9E5B)]
                    : _twoFAEnabled
                        ? [const Color(0xFF1A4A6B), const Color(0xFF2E7AB5)]
                        : [const Color(0xFF6B1A1A), const Color(0xFFB52E2E)],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: Icon(
                    (_biometricEnabled && _twoFAEnabled) ? Icons.security : _twoFAEnabled ? Icons.lock : Icons.lock_open,
                    color: Colors.white, size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        (_biometricEnabled && _twoFAEnabled) ? 'Strong Security' : _twoFAEnabled ? 'Good Security' : 'Weak Security',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      Text(
                        (_biometricEnabled && _twoFAEnabled) ? 'All security features enabled' : 'Enable more features to improve',
                        style: const TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${(_biometricEnabled ? 40 : 0) + (_twoFAEnabled ? 50 : 0) + (_sessionAlerts ? 10 : 0)}%',
                  style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _sectionHeader('Biometric Login', isDark),
          _card(card, border, child: Column(
            children: [
              _switchRow(
                icon: Icons.fingerprint_rounded,
                iconColor: const Color(AppConstants.primaryRed),
                title: 'Fingerprint / Face ID',
                subtitle: 'Use biometrics to unlock the app',
                value: _biometricEnabled,
                onChanged: (v) async {
                  if (v) {
                    final ok = await _promptBiometric();
                    if (ok) setState(() => _biometricEnabled = true);
                  } else {
                    setState(() => _biometricEnabled = false);
                  }
                },
              ),
              if (_biometricEnabled) ...[
                const Divider(height: 1),
                _infoRow(Icons.info_outline, 'Biometric data stays on your device and is never sent to our servers.', isDark),
              ],
            ],
          )),
          const SizedBox(height: 16),

          _sectionHeader('Two-Factor Authentication (2FA)', isDark),
          _card(card, border, child: Column(
            children: [
              _switchRow(
                icon: Icons.verified_user_outlined,
                iconColor: const Color(AppConstants.successGreen),
                title: 'Enable 2FA',
                subtitle: 'Require a code on every login',
                value: _twoFAEnabled,
                onChanged: (v) {
                  if (v) {
                    _show2FASetup();
                  } else {
                    _confirm2FADisable();
                  }
                },
              ),
              if (_twoFAEnabled) ...[
                const Divider(height: 1),
                const SizedBox(height: 12),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('2FA Method', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(AppConstants.mediumGray))),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _methodChip('sms', Icons.sms_outlined, 'SMS OTP'),
                          const SizedBox(width: 8),
                          _methodChip('totp', Icons.qr_code_rounded, 'Authenticator App'),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          )),
          const SizedBox(height: 16),

          _sectionHeader('Session Security', isDark),
          _card(card, border, child: Column(
            children: [
              _switchRow(
                icon: Icons.notifications_active_outlined,
                iconColor: const Color(AppConstants.warningOrange),
                title: 'New Login Alerts',
                subtitle: 'Get notified when a new device logs in',
                value: _sessionAlerts,
                onChanged: (v) => setState(() => _sessionAlerts = v),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(0xFF722ED1).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.devices_rounded, color: Color(0xFF722ED1), size: 18),
                ),
                title: const Text('Active Sessions', style: TextStyle(fontWeight: FontWeight.w500)),
                subtitle: const Text('2 devices logged in'),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(AppConstants.mediumGray), size: 18),
                onTap: _showActiveSessions,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
              const Divider(height: 1),
              ListTile(
                leading: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(color: const Color(AppConstants.errorRed).withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.logout_rounded, color: Color(AppConstants.errorRed), size: 18),
                ),
                title: const Text('Sign Out All Devices', style: TextStyle(fontWeight: FontWeight.w500, color: Color(AppConstants.errorRed))),
                trailing: const Icon(Icons.chevron_right_rounded, color: Color(AppConstants.mediumGray), size: 18),
                onTap: _confirmSignOutAll,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              ),
            ],
          )),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title.toUpperCase(), style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(AppConstants.mediumGray), letterSpacing: 0.8)),
  );

  Widget _card(Color bg, Color border, {required Widget child}) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
    child: child,
  );

  Widget _switchRow({required IconData icon, required Color iconColor, required String title, required String subtitle, required bool value, required ValueChanged<bool> onChanged}) {
    return ListTile(
      leading: Container(width: 36, height: 36, decoration: BoxDecoration(color: iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: iconColor, size: 18)),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(AppConstants.mediumGray))),
      trailing: Switch.adaptive(value: value, onChanged: onChanged, activeColor: const Color(AppConstants.primaryRed)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
    );
  }

  Widget _infoRow(IconData icon, String text, bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
    child: Row(
      children: [
        Icon(icon, size: 14, color: const Color(AppConstants.mediumGray)),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray)))),
      ],
    ),
  );

  Widget _methodChip(String id, IconData icon, String label) {
    final selected = _twoFAMethod == id;
    return GestureDetector(
      onTap: () => setState(() => _twoFAMethod = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? const Color(AppConstants.primaryRed).withOpacity(0.1) : const Color(AppConstants.lightGray),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? const Color(AppConstants.primaryRed) : Colors.transparent, width: 1.5),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? const Color(AppConstants.primaryRed) : const Color(AppConstants.mediumGray)),
            const SizedBox(width: 6),
            Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? const Color(AppConstants.primaryRed) : const Color(AppConstants.mediumGray))),
          ],
        ),
      ),
    );
  }

  Future<bool> _promptBiometric() async {
    // In production: use local_auth package
    // final auth = LocalAuthentication();
    // return await auth.authenticate(localizedReason: 'Confirm your identity');
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Enable Biometrics'),
        content: const Text('Use your fingerprint or face to log in quickly and securely.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Enable')),
        ],
      ),
    );
    return result ?? false;
  }

  void _show2FASetup() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Set Up 2FA', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            const Text('Enter the 6-digit code sent to your phone to verify.', style: TextStyle(color: Color(AppConstants.mediumGray))),
            const SizedBox(height: 20),
            TextField(
              controller: _otpCtrl,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 12),
              decoration: InputDecoration(
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(AppConstants.primaryRed), width: 2)),
                hintText: '000000',
                hintStyle: const TextStyle(color: Color(AppConstants.mediumGray), letterSpacing: 12),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _verifying ? null : () async {
                  setState(() => _verifying = true);
                  await Future.delayed(const Duration(seconds: 1));
                  setState(() { _verifying = false; _twoFAEnabled = true; });
                  Navigator.pop(context);
                  _snack('2FA enabled successfully');
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryRed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: _verifying ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Verify & Enable', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirm2FADisable() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Disable 2FA?'),
        content: const Text('This will make your account less secure. Are you sure?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); setState(() => _twoFAEnabled = false); _snack('2FA disabled'); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.errorRed)),
            child: const Text('Disable'),
          ),
        ],
      ),
    );
  }

  void _showActiveSessions() {
    final sessions = [
      {'device': 'iPhone 14 Pro', 'location': 'Kathmandu, Nepal', 'time': 'Active now', 'current': true},
      {'device': 'Chrome on Windows', 'location': 'Pokhara, Nepal', 'time': '2 hours ago', 'current': false},
    ];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Active Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            ...sessions.map((s) => ListTile(
              leading: Icon(s['device'].toString().contains('iPhone') ? Icons.phone_iphone : Icons.computer_rounded, color: const Color(AppConstants.primaryRed)),
              title: Text(s['device'] as String, style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: Text('${s['location']} • ${s['time']}'),
              trailing: s['current'] == true
                  ? Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3), decoration: BoxDecoration(color: const Color(AppConstants.successGreen).withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Text('This device', style: TextStyle(fontSize: 11, color: Color(AppConstants.successGreen), fontWeight: FontWeight.w600)))
                  : TextButton(onPressed: () { Navigator.pop(context); _snack('Session revoked'); }, child: const Text('Revoke', style: TextStyle(color: Color(AppConstants.errorRed)))),
            )),
          ],
        ),
      ),
    );
  }

  void _confirmSignOutAll() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out All Devices?'),
        content: const Text('You will be logged out from all devices except this one.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); _snack('Signed out from all other devices'); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.errorRed)),
            child: const Text('Sign Out All'),
          ),
        ],
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: const Color(AppConstants.successGreen),
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
