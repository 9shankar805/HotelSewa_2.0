import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class IdVerificationScreen extends StatefulWidget {
  const IdVerificationScreen({Key? key}) : super(key: key);

  @override
  State<IdVerificationScreen> createState() => _IdVerificationScreenState();
}

class _IdVerificationScreenState extends State<IdVerificationScreen> {
  bool _loading = true;
  bool _submitting = false;
  String? _status;
  String _idType = 'national_id';
  final _idNumberCtrl = TextEditingController();
  File? _frontImage;
  File? _backImage;
  File? _selfie;

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _idNumberCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.idVerificationStatusEndpoint, token: token);
      if (response['success'] == true) {
        final data = response['data'];
        _status = data is Map ? data['status']?.toString() : null;
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _pickImage(String field) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1200, imageQuality: 85);
    if (picked != null) {
      setState(() {
        if (field == 'front') _frontImage = File(picked.path);
        if (field == 'back') _backImage = File(picked.path);
        if (field == 'selfie') _selfie = File(picked.path);
      });
    }
  }

  Future<void> _submit() async {
    if (_frontImage == null || _idNumberCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields'), backgroundColor: AppColors.error),
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}${ApiConfig.idVerificationSubmitEndpoint}'),
      );
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';
      request.fields['id_type'] = _idType;
      request.fields['id_number'] = _idNumberCtrl.text;
      request.files.add(await http.MultipartFile.fromPath('front_image', _frontImage!.path));
      if (_backImage != null) {
        request.files.add(await http.MultipartFile.fromPath('back_image', _backImage!.path));
      }
      if (_selfie != null) {
        request.files.add(await http.MultipartFile.fromPath('selfie', _selfie!.path));
      }

      final streamed = await request.send();
      final httpResponse = await http.Response.fromStream(streamed);

      Map<String, dynamic> response;
      try {
        final decoded = jsonDecode(httpResponse.body) as Map<String, dynamic>;
        if (!decoded.containsKey('success')) {
          decoded['success'] = httpResponse.statusCode >= 200 && httpResponse.statusCode < 300;
        }
        response = decoded;
      } catch (_) {
        response = {'success': httpResponse.statusCode >= 200 && httpResponse.statusCode < 300};
      }

      if (response['success'] == true) {
        setState(() => _status = 'pending');
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ID submitted for verification'), backgroundColor: AppColors.success),
        );
      } else {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response['message']?.toString() ?? 'Submission failed'), backgroundColor: AppColors.error),
        );
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Submission failed'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  Map<String, dynamic> _parseJson(String body) {
    try {
      // dart:convert is available via http package transitively
      final decoded = body.trim();
      if (decoded.startsWith('{')) {
        // Basic success check from status code already handled above
        return {'success': true};
      }
      return {'success': false};
    } catch (_) {
      return {};
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
        title: const Text('ID Verification', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _status == 'verified'
              ? _buildVerified()
              : _status == 'pending'
                  ? _buildPending()
                  : _buildForm(),
    );
  }

  Widget _buildVerified() {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.verified_rounded, size: 40, color: AppColors.success)),
      const SizedBox(height: 20),
      const Text('Identity Verified', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 8),
      const Text('Your identity has been successfully verified. You can now access all features.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
    ])));
  }

  Widget _buildPending() {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.hourglass_top_rounded, size: 40, color: AppColors.warning)),
      const SizedBox(height: 20),
      const Text('Verification Pending', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 8),
      const Text('Your documents are under review. This usually takes 1-2 business days.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
    ])));
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(14)),
                  child: const Icon(Icons.badge_rounded, color: Colors.white, size: 26)),
                const SizedBox(width: 16),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Verify Your Identity', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                  SizedBox(height: 4),
                  Text('Required for certain bookings and features.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                ])),
              ],
            ),
          ),
          const SizedBox(height: 24),

          const Text('Document Type', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: [
              {'value': 'national_id', 'label': 'National ID'},
              {'value': 'passport', 'label': 'Passport'},
              {'value': 'driving_license', 'label': 'Driving License'},
            ].map((item) {
              final selected = _idType == item['value'];
              return ChoiceChip(
                label: Text(item['label']!),
                selected: selected,
                onSelected: (_) => setState(() => _idType = item['value']!),
                selectedColor: AppColors.infoLight,
                labelStyle: TextStyle(color: selected ? AppColors.info : AppColors.gray, fontWeight: selected ? FontWeight.w600 : FontWeight.normal),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),

          const Text('Document Number *', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          TextField(
            controller: _idNumberCtrl,
            decoration: InputDecoration(
              hintText: 'Enter document number',
              prefixIcon: const Icon(Icons.numbers_rounded, color: AppColors.gray),
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
            ),
          ),
          const SizedBox(height: 20),

          _imageUploadTile('Front of Document *', _frontImage, () => _pickImage('front'), Icons.credit_card_rounded),
          const SizedBox(height: 12),
          _imageUploadTile('Back of Document', _backImage, () => _pickImage('back'), Icons.credit_card_rounded),
          const SizedBox(height: 12),
          _imageUploadTile('Selfie with Document', _selfie, () => _pickImage('selfie'), Icons.face_rounded),
          const SizedBox(height: 32),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _submitting
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit for Verification', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _imageUploadTile(String label, File? file, VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow,
          border: file != null ? Border.all(color: AppColors.success, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: file != null ? AppColors.successLight : AppColors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: file != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(file, fit: BoxFit.cover))
                  : Icon(icon, color: AppColors.gray, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
              Text(file != null ? 'Uploaded ✓' : 'Tap to upload', style: TextStyle(fontSize: 12, color: file != null ? AppColors.success : AppColors.gray)),
            ])),
            Icon(file != null ? Icons.check_circle_rounded : Icons.upload_rounded, color: file != null ? AppColors.success : AppColors.gray),
          ],
        ),
      ),
    );
  }
}
