import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_colors.dart';

/// Debug screen to check authentication status
/// Navigate to this screen to see if you have a valid token saved
class AuthDebugScreen extends StatefulWidget {
  const AuthDebugScreen({Key? key}) : super(key: key);

  @override
  State<AuthDebugScreen> createState() => _AuthDebugScreenState();
}

class _AuthDebugScreenState extends State<AuthDebugScreen> {
  String _tokenStatus = 'Checking...';
  String _tokenPreview = '';
  String _userEmail = '';
  String _userName = '';
  String _userPhone = '';
  String _loginMethod = '';
  bool _hasToken = false;

  @override
  void initState() {
    super.initState();
    _checkAuthStatus();
  }

  Future<void> _checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final email = prefs.getString('userEmail') ?? 'Not set';
    final name = prefs.getString('userName') ?? 'Not set';
    final phone = prefs.getString('userPhone') ?? 'Not set';
    final method = prefs.getString('loginMethod') ?? 'Not set';

    setState(() {
      if (token != null && token.isNotEmpty) {
        _hasToken = true;
        _tokenStatus = '✅ Token exists';
        _tokenPreview = token.length > 50 
            ? '${token.substring(0, 50)}...' 
            : token;
      } else {
        _hasToken = false;
        _tokenStatus = '❌ No token found';
        _tokenPreview = 'You need to log in';
      }
      _userEmail = email;
      _userName = name;
      _userPhone = phone;
      _loginMethod = method;
    });
  }

  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
    await prefs.remove('loginMethod');
    _checkAuthStatus();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All auth data cleared. Please log in again.')),
      );
    }
  }

  void _copyToken() {
    if (_hasToken) {
      Clipboard.setData(ClipboardData(text: _tokenPreview));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Token copied to clipboard')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 2,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Auth Debug',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.darkGray,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _hasToken ? AppColors.success.shade50 : AppColors.error.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _hasToken ? AppColors.success : AppColors.error,
                  width: 2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        _hasToken ? Icons.check_circle : Icons.error,
                        color: _hasToken ? AppColors.success : AppColors.error,
                        size: 32,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _tokenStatus,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: _hasToken ? AppColors.success.shade900 : AppColors.error.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!_hasToken) ...[
                    const SizedBox(height: 12),
                    Text(
                      'You need to log in to use booking features',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.error.shade700,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // User Info
            _buildInfoCard('User Information', [
              _buildInfoRow('Name', _userName),
              _buildInfoRow('Email', _userEmail),
              _buildInfoRow('Phone', _userPhone),
              _buildInfoRow('Login Method', _loginMethod),
            ]),
            const SizedBox(height: 16),

            // Token Info
            _buildInfoCard('Token Information', [
              _buildInfoRow('Status', _hasToken ? 'Valid' : 'Missing'),
              if (_hasToken) ...[
                const SizedBox(height: 8),
                const Text(
                  'Token Preview:',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkGray,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.gray.shade100,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _tokenPreview,
                    style: const TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: AppColors.darkGray,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  onPressed: _copyToken,
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copy Token'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ]),
            const SizedBox(height: 24),

            // Instructions
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.info.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.info.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info, color: AppColors.info.shade700),
                      const SizedBox(width: 8),
                      const Text(
                        'What to do?',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkGray,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (!_hasToken) ...[
                    const Text(
                      '1. Go back and log in\n'
                      '2. Use Email/Password or OTP\n'
                      '3. Come back here to verify token is saved\n'
                      '4. Try booking again',
                      style: TextStyle(fontSize: 14, color: AppColors.darkGray),
                    ),
                  ] else ...[
                    const Text(
                      '✅ You have a token saved!\n\n'
                      'If booking still fails with 302 error:\n'
                      '1. Your token might be expired\n'
                      '2. Clear token below and log in again\n'
                      '3. Make sure API server is running',
                      style: TextStyle(fontSize: 14, color: AppColors.darkGray),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Actions
            if (_hasToken) ...[
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _clearToken,
                  icon: const Icon(Icons.logout),
                  label: const Text('Clear Token & Log Out'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _checkAuthStatus,
                icon: const Icon(Icons.refresh),
                label: const Text('Refresh Status'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.darkGray,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.gray,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.darkGray,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
