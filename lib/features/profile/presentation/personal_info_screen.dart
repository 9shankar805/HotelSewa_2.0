import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class PersonalInfoScreen extends StatefulWidget {
  const PersonalInfoScreen({Key? key}) : super(key: key);

  @override
  State<PersonalInfoScreen> createState() => _PersonalInfoScreenState();
}

class _PersonalInfoScreenState extends State<PersonalInfoScreen> {
  bool _isEditing = false;
  bool _loading = true;
  bool _saving = false;
  String? _error;

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _dobController = TextEditingController();
  final _genderController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _dobController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      // First populate from local cache for instant display
      final userJson = prefs.getString('user');
      if (userJson != null) {
        final data = jsonDecode(userJson) as Map<String, dynamic>;
        _populateFields(data);
      }

      // Then fetch fresh from API
      final response = await ApiService.get(ApiConfig.getOwnerEndpoint, token: token);
      if (response['success'] == true) {
        final raw = response['data'];
        final data = raw is Map ? (raw.containsKey('owner') ? raw['owner'] : raw) : {};
        _populateFields(data as Map<String, dynamic>);
        // Update cache
        await prefs.setString('user', jsonEncode(data));
      }
    } catch (e) {
      setState(() => _error = 'Failed to load profile');
    } finally {
      setState(() => _loading = false);
    }
  }

  void _populateFields(Map<String, dynamic> data) {
    _nameController.text = data['name']?.toString() ?? '';
    _emailController.text = data['email']?.toString() ?? '';
    _phoneController.text = data['phone']?.toString() ?? data['mobile']?.toString() ?? '';
    _dobController.text = data['dob']?.toString() ?? data['date_of_birth']?.toString() ?? '';
    _genderController.text = data['gender']?.toString() ?? '';
  }

  Future<void> _handleSave() async {
    if (_nameController.text.trim().isEmpty) {
      _showSnack('Name cannot be empty', isError: true);
      return;
    }
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(
        ApiConfig.updateProfileEndpoint,
        token: token,
        data: {
          'name': _nameController.text.trim(),
          'phone': _phoneController.text.trim(),
          if (_dobController.text.isNotEmpty) 'dob': _dobController.text.trim(),
          if (_genderController.text.isNotEmpty) 'gender': _genderController.text.trim(),
        },
      );
      if (response['success'] == true) {
        // Update local cache
        final userJson = prefs.getString('user');
        final userData = userJson != null ? jsonDecode(userJson) as Map<String, dynamic> : <String, dynamic>{};
        userData['name'] = _nameController.text.trim();
        userData['phone'] = _phoneController.text.trim();
        await prefs.setString('user', jsonEncode(userData));
        await prefs.setString('userName', _nameController.text.trim());
        setState(() => _isEditing = false);
        _showSnack('Profile updated successfully');
      } else {
        _showSnack(response['message'] ?? 'Update failed', isError: true);
      }
    } catch (e) {
      _showSnack('Failed to save changes', isError: true);
    } finally {
      setState(() => _saving = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? AppColors.error : AppColors.success,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Personal Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
        centerTitle: true,
        actions: [
          if (!_loading)
            TextButton(
              onPressed: _isEditing ? (_saving ? null : _handleSave) : () => setState(() => _isEditing = true),
              child: _saving
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                  : Text(_isEditing ? 'Save' : 'Edit', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? Center(child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline, size: 48, color: AppColors.gray),
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: AppColors.gray)),
                    const SizedBox(height: 16),
                    ElevatedButton(onPressed: _loadProfile, child: const Text('Retry')),
                  ],
                ))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildField('Full Name', _nameController),
                      _buildField('Email', _emailController, keyboardType: TextInputType.emailAddress, readOnly: true),
                      _buildField('Phone Number', _phoneController, keyboardType: TextInputType.phone),
                      _buildField('Date of Birth', _dobController),
                      _buildField('Gender', _genderController),
                      if (_isEditing) ...[
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () { setState(() => _isEditing = false); _loadProfile(); },
                          child: const Text('Cancel', style: TextStyle(color: AppColors.gray)),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType? keyboardType, bool readOnly = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray)),
          const SizedBox(height: 6),
          TextField(
            controller: controller,
            enabled: _isEditing && !readOnly,
            readOnly: readOnly,
            keyboardType: keyboardType,
            style: TextStyle(fontSize: 15, color: (_isEditing && !readOnly) ? AppColors.darkGray : AppColors.gray),
            decoration: InputDecoration(
              filled: true,
              fillColor: (_isEditing && !readOnly) ? Colors.white : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.primary.withOpacity(0.4))),
              disabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              suffixIcon: readOnly ? const Icon(Icons.lock_outline, size: 16, color: AppColors.placeholder) : null,
            ),
          ),
        ],
      ),
    );
  }
}
