import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class LinkedAccountsScreen extends StatefulWidget {
  const LinkedAccountsScreen({Key? key}) : super(key: key);

  @override
  State<LinkedAccountsScreen> createState() => _LinkedAccountsScreenState();
}

class _LinkedAccountsScreenState extends State<LinkedAccountsScreen> {
  List<Map<String, dynamic>> _accounts = [
    {'id': 'google', 'name': 'Google', 'email': null, 'icon': 'G', 'color': const Color(0xFF4285F4), 'linked': false},
    {'id': 'apple', 'name': 'Apple', 'email': null, 'icon': '', 'color': Colors.black, 'linked': false},
    {'id': 'phone', 'name': 'Phone Number', 'email': null, 'icon': '#', 'color': AppColors.success, 'linked': false},
  ];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final loginMethod = prefs.getString('loginMethod') ?? '';
      final userEmail = prefs.getString('userEmail') ?? '';

      // Mark Google as linked if user logged in with Google
      setState(() {
        for (final a in _accounts) {
          if (a['id'] == 'google' && loginMethod == 'google') {
            a['linked'] = true;
            a['email'] = userEmail;
          }
          if (a['id'] == 'phone') {
            final phone = prefs.getString('userPhone') ?? '';
            if (phone.isNotEmpty) { a['linked'] = true; a['email'] = phone; }
          }
        }
      });

      // Try to get linked accounts from API
      final response = await ApiService.get(ApiConfig.linkedAccountsEndpoint, token: token);
      if (response['success'] == true && response['data'] is List) {
        final linked = response['data'] as List;
        setState(() {
          for (final a in _accounts) {
            final matches = linked.where((l) => l['provider'] == a['id']);
            final match = matches.isNotEmpty ? matches.first : null;
            if (match != null) { a['linked'] = true; a['email'] = match['email'] ?? match['identifier']; }
          }
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _toggleLink(Map<String, dynamic> account) async {
    if (account['linked'] == true) {
      // Unlink
      showDialog(context: context, builder: (_) => AlertDialog(
        title: Text('Unlink ${account['name']}'),
        content: Text('Are you sure you want to unlink your ${account['name']} account?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final prefs = await SharedPreferences.getInstance();
                final token = prefs.getString('authToken');
                await ApiService.delete(
                  ApiConfig.buildPath(ApiConfig.linkedAccountsEndpoint, account['id']),
                  token: token,
                );
                if (account['id'] == 'google') await GoogleSignIn().signOut();
                setState(() { account['linked'] = false; account['email'] = null; });
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${account['name']} unlinked'), behavior: SnackBarBehavior.floating));
              } catch (_) {
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to unlink'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
              }
            },
            child: const Text('Unlink', style: TextStyle(color: AppColors.error)),
          ),
        ],
      ));
    } else {
      // Link Google
      if (account['id'] == 'google') {
        try {
          final googleUser = await GoogleSignIn(
            serverClientId: '664870792174-akgpqfbgcddbfn936e531lnjo52fqc61.apps.googleusercontent.com',
            scopes: ['email', 'profile'],
          ).signIn();
          if (googleUser == null) return;
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('authToken');
          final googleAuth = await googleUser.authentication;
          await ApiService.post(ApiConfig.linkedAccountsEndpoint, token: token, data: {
            'provider': 'google',
            'email': googleUser.email,
            'firebase_id': googleAuth.idToken ?? googleAuth.accessToken ?? '',
          });
          setState(() { account['linked'] = true; account['email'] = googleUser.email; });
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${account['name']} linked successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
        } catch (e) {
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to link: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${account['name']} linking coming soon'), behavior: SnackBarBehavior.floating));
      }
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
        title: const Text('Linked Accounts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                  SizedBox(width: 10),
                  Expanded(child: Text('Linking accounts lets you sign in faster and keeps your data in sync across platforms.',
                      style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
                ],
              ),
            ).animate().fadeIn(),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
              child: Column(
                children: _accounts.asMap().entries.map((e) {
                  final account = e.value;
                  final linked = account['linked'] as bool;
                  final color = account['color'] as Color;
                  return Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                              child: account['id'] == 'apple'
                                  ? Icon(Icons.apple_rounded, color: color, size: 24)
                                  : Center(child: Text(account['icon'] as String, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: color))),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(account['name'] as String, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                                  if (linked && account['email'] != null)
                                    Text(account['email'].toString(), style: const TextStyle(fontSize: 12, color: AppColors.gray))
                                  else
                                    const Text('Not linked', style: TextStyle(fontSize: 12, color: AppColors.placeholder)),
                                ],
                              ),
                            ),
                            GestureDetector(
                              onTap: () => _toggleLink(account),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                decoration: BoxDecoration(
                                  color: linked ? AppColors.errorLight : AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  linked ? 'Unlink' : 'Link',
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: linked ? AppColors.error : AppColors.primary),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (e.key < _accounts.length - 1) const Divider(color: AppColors.lightGray, height: 1, indent: 16, endIndent: 16),
                    ],
                  );
                }).toList(),
              ),
            ).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
