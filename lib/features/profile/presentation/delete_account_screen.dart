import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/auth_service.dart';

class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({Key? key}) : super(key: key);

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final AuthService _authService = AuthService();
  String? _selectedReason;
  final _pwController = TextEditingController();
  bool _confirmed = false;
  bool _loading = false;
  bool _showPw = false;

  final _reasons = [
    'I no longer use this service',
    'Privacy concerns',
    'Too many emails/notifications',
    'Found a better alternative',
    'Account security issues',
    'Other',
  ];

  @override
  void dispose() {
    _pwController.dispose();
    super.dispose();
  }

  Future<void> _deleteAccount() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a reason'), behavior: SnackBarBehavior.floating));
      return;
    }
    if (_pwController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter your password'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    final result = await _authService.deleteAccount(password: _pwController.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (r) => false);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to delete account'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
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
        title: const Text('Delete Account', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: AppColors.errorLight, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.error.withOpacity(0.2))),
                    child: Column(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 40),
                        const SizedBox(height: 12),
                        const Text('This action is permanent', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.error)),
                        const SizedBox(height: 8),
                        const Text('Deleting your account will permanently remove all your data including bookings, reviews, wallet balance, and loyalty points. This cannot be undone.',
                            style: TextStyle(fontSize: 13, color: AppColors.error, height: 1.5), textAlign: TextAlign.center),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),

                  const Text('What will be deleted:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  const SizedBox(height: 10),
                  ...[
                    'Your profile and personal information',
                    'All booking history',
                    'Wallet balance and transactions',
                    'Loyalty points and tier status',
                    'Saved hotels and preferences',
                    'Reviews and ratings',
                  ].map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_circle_outline_rounded, size: 16, color: AppColors.error),
                        const SizedBox(width: 10),
                        Text(item, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
                      ],
                    ),
                  )),
                  const SizedBox(height: 20),

                  const Text('Reason for leaving', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  const SizedBox(height: 10),
                  ..._reasons.asMap().entries.map((e) {
                    final selected = _selectedReason == e.value;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedReason = e.value),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.errorLight : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: selected ? AppColors.error : AppColors.lightGray, width: selected ? 1.5 : 1),
                        ),
                        child: Row(
                          children: [
                            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: selected ? AppColors.error : AppColors.placeholder, size: 18),
                            const SizedBox(width: 10),
                            Text(e.value, style: TextStyle(fontSize: 13, color: selected ? AppColors.error : AppColors.darkGray, fontWeight: selected ? FontWeight.w600 : FontWeight.w400)),
                          ],
                        ),
                      ).animate(delay: (e.key * 30).ms).fadeIn(),
                    );
                  }),
                  const SizedBox(height: 20),

                  const Text('Confirm with password', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pwController,
                    obscureText: !_showPw,
                    decoration: InputDecoration(
                      hintText: 'Enter your password',
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.error, width: 1.5)),
                      suffixIcon: IconButton(icon: Icon(_showPw ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: AppColors.gray), onPressed: () => setState(() => _showPw = !_showPw)),
                    ),
                  ),
                  const SizedBox(height: 16),

                  GestureDetector(
                    onTap: () => setState(() => _confirmed = !_confirmed),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Checkbox(value: _confirmed, onChanged: (v) => setState(() => _confirmed = v!), activeColor: AppColors.error, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
                        const Expanded(child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text('I understand that this action is permanent and cannot be undone.',
                              style: TextStyle(fontSize: 13, color: AppColors.darkGray, height: 1.4)),
                        )),
                      ],
                    ),
                  ),
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
                onPressed: (_confirmed && !_loading) ? _deleteAccount : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.error,
                  disabledBackgroundColor: AppColors.lightGray,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Delete My Account', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

