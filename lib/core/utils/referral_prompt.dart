import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import '../constants/app_colors.dart';
import '../services/shared/api_service.dart';

/// Shows a one-time referral code prompt after social/OTP login for new users.
///
/// Usage:
///   await ReferralPrompt.showIfNeeded(context, token: token);
///   // then navigate to home
class ReferralPrompt {
  static const _key = 'referral_prompted';

  /// Returns true if this user has never been prompted before.
  static Future<bool> _shouldShow() async {
    final prefs = await SharedPreferences.getInstance();
    return !(prefs.getBool(_key) ?? false);
  }

  static Future<void> _markShown() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, true);
  }

  /// Call after Google / Apple / OTP login.
  /// Shows a bottom sheet asking for a referral code if the user hasn't
  /// been prompted yet. Always resolves (never blocks navigation).
  static Future<void> showIfNeeded(
    BuildContext context, {
    required String token,
  }) async {
    if (!await _shouldShow()) return;
    await _markShown();

    if (!context.mounted) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: true,
      builder: (_) => _ReferralSheet(token: token),
    );
  }
}

class _ReferralSheet extends StatefulWidget {
  final String token;
  const _ReferralSheet({required this.token});

  @override
  State<_ReferralSheet> createState() => _ReferralSheetState();
}

class _ReferralSheetState extends State<_ReferralSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  String? _resultMsg;
  bool _success = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _apply() async {
    final code = _ctrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      Navigator.pop(context);
      return;
    }
    setState(() { _loading = true; _resultMsg = null; });
    try {
      final resp = await ApiService.post(
        ApiConfig.loyaltyApplyReferralEndpoint,
        token: widget.token,
        data: {'referral_code': code},
      );
      if (resp['success'] == true) {
        setState(() {
          _success = true;
          _resultMsg = '🎉 Rs.500 reward applied to your account!';
          _loading = false;
        });
        await Future.delayed(const Duration(seconds: 2));
        if (mounted) Navigator.pop(context);
      } else {
        setState(() {
          _success = false;
          _resultMsg = resp['message'] ?? 'Invalid referral code';
          _loading = false;
        });
      }
    } catch (_) {
      setState(() { _loading = false; _resultMsg = 'Could not apply code. Try later.'; _success = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Center(
              child: Container(width: 40, height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 20),

            // Icon + title
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.card_giftcard_rounded,
                color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: 14),
            const Text('Have a referral code?',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800,
                color: Color(0xFF111827))),
            const SizedBox(height: 6),
            const Text(
              'Enter a friend\'s code and get Rs.500 off\nyour first booking.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5),
            ),
            const SizedBox(height: 20),

            // Input
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFFFF5F5),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  const Icon(Icons.confirmation_number_outlined,
                    color: AppColors.primary, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      textCapitalization: TextCapitalization.characters,
                      autofocus: true,
                      style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800,
                        letterSpacing: 3, color: AppColors.primary,
                      ),
                      onChanged: (_) => setState(() { _resultMsg = null; }),
                      decoration: const InputDecoration(
                        hintText: 'e.g. PDQ2YXAZ',
                        hintStyle: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w400,
                          letterSpacing: 1, color: Color(0xFFADB5BD)),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Result message
            if (_resultMsg != null) ...[
              const SizedBox(height: 10),
              Text(_resultMsg!,
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600,
                  color: _success ? AppColors.success : AppColors.error),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 20),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _apply,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _loading
                    ? const SizedBox(width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white))
                    : const Text('Apply & Claim Reward',
                        style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 10),

            // Skip
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text("I don't have a code",
                  style: TextStyle(fontSize: 14, color: Color(0xFF9CA3AF),
                    fontWeight: FontWeight.w500)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
