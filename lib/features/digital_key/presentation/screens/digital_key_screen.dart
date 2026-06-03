import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class DigitalKeyScreen extends StatefulWidget {
  const DigitalKeyScreen({Key? key}) : super(key: key);

  @override
  State<DigitalKeyScreen> createState() => _DigitalKeyScreenState();
}

class _DigitalKeyScreenState extends State<DigitalKeyScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _keys = [];
  bool _unlocking = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.digitalKeyMyEndpoint, token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['keys'] ?? []) : []);
        setState(() { _keys = List<Map<String, dynamic>>.from(raw); _loading = false; });
      } else {
        setState(() { _error = response['message'] ?? 'Failed to load keys'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load digital keys'; _loading = false; });
    }
  }

  Future<void> _unlock(String keyToken, int roomId) async {
    setState(() => _unlocking = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.post(
        ApiConfig.digitalKeyUnlockEndpoint,
        data: {'key_token': keyToken, 'room_id': roomId},
        token: token,
      );
      if (mounted) {
        if (response['success'] == true) {
          HapticFeedback.heavyImpact();
          _showUnlockSuccess();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Unlock failed'), backgroundColor: AppColors.error),
          );
        }
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unlock failed'), backgroundColor: AppColors.error),
      );
    } finally {
      if (mounted) setState(() => _unlocking = false);
    }
  }

  Future<void> _revoke(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    final response = await ApiService.delete('${ApiConfig.digitalKeyRevokeEndpoint}/$id', token: token);
    if (response['success'] == true) {
      setState(() => _keys.removeWhere((k) => k['id'] == id));
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Key revoked'), backgroundColor: AppColors.success),
      );
    }
  }

  void _showUnlockSuccess() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(20)),
              child: const Icon(Icons.lock_open_rounded, size: 36, color: AppColors.success),
            ),
            const SizedBox(height: 16),
            const Text('Door Unlocked!', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            const Text('Your room door has been unlocked. Please enter within 30 seconds.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: const Text('Got it', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
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
        title: const Text('Digital Room Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _keys.isEmpty ? _buildEmpty() : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _keys.length,
                    itemBuilder: (_, i) => _buildKeyCard(_keys[i]),
                  ),
                ),
    );
  }

  Widget _buildKeyCard(Map<String, dynamic> key) {
    final isActive = key['is_active'] == true || key['status'] == 'active';
    final validUntil = key['valid_until'] ?? key['expires_at'] ?? '';
    final keyToken = key['key_token'] ?? key['token'] ?? '';
    final roomId = key['room_id'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isActive
            ? const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: isActive ? null : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withOpacity(0.15) : AppColors.infoLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(Icons.key_rounded, color: isActive ? Colors.white : AppColors.info, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        key['hotel_name'] ?? key['hotel']?['name'] ?? 'Hotel',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isActive ? Colors.white : AppColors.darkGray),
                      ),
                      Text(
                        'Room ${key['room_number'] ?? key['room']?['room_number'] ?? ''}',
                        style: TextStyle(fontSize: 13, color: isActive ? Colors.white70 : AppColors.gray),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: isActive ? Colors.white.withOpacity(0.2) : AppColors.lightGray,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    isActive ? 'Active' : 'Expired',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isActive ? Colors.white : AppColors.gray),
                  ),
                ),
              ],
            ),
            if (validUntil.isNotEmpty) ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  Icon(Icons.access_time_rounded, size: 14, color: isActive ? Colors.white60 : AppColors.gray),
                  const SizedBox(width: 6),
                  Text('Valid until $validUntil', style: TextStyle(fontSize: 12, color: isActive ? Colors.white60 : AppColors.gray)),
                ],
              ),
            ],
            if (isActive) ...[
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _unlocking ? null : () => _unlock(keyToken, roomId),
                      icon: _unlocking
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.lock_open_rounded, size: 18),
                      label: Text(_unlocking ? 'Unlocking...' : 'Unlock Room'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _showShareDialog(key['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.share_rounded, size: 18),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton(
                    onPressed: () => _revoke(key['id']),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white30),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Icon(Icons.delete_outline_rounded, size: 18),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showShareDialog(int id) {
    final emailController = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Share Digital Key', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  hintText: 'Guest email address',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.gray),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.isEmpty) return;
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post('${ApiConfig.digitalKeyShareEndpoint}/$id/share', data: {'email': emailController.text}, token: token);
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Key shared successfully'), backgroundColor: AppColors.success),
                    );
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Share Key', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry', style: TextStyle(color: Colors.white))),
    ])));
  }

  Widget _buildEmpty() {
    return Center(child: Padding(padding: const EdgeInsets.all(40), child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(24)),
        child: const Icon(Icons.key_off_rounded, size: 40, color: AppColors.info)),
      const SizedBox(height: 20),
      const Text('No Digital Keys', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 8),
      const Text('Digital keys are generated after check-in is confirmed. They allow you to unlock your room directly from the app.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
    ])));
  }
}
