import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';
import '../../../auth/presentation/providers/auth_provider.dart'
    show AuthProvider;

class AddRoomScreen extends StatefulWidget {
  const AddRoomScreen({super.key});
  @override
  State<AddRoomScreen> createState() => _AddRoomScreenState();
}

class _AddRoomScreenState extends State<AddRoomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController(text: '2');
  final _sizeCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl, _descCtrl, _priceCtrl, _capacityCtrl, _sizeCtrl])
      c.dispose();
    super.dispose();
  }

  /// Resolve hotelId with three fallback strategies (same as ManageRoomsScreen).
  Future<String?> _resolveHotelId(String token) async {
    final prefs = await SharedPreferences.getInstance();

    // 1. SharedPreferences
    final stored = prefs.getString('hotelId') ?? prefs.getString('hotel_id');
    if (stored != null && stored.isNotEmpty) return stored;

    // 2. AuthProvider
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final dynamic hid = (auth.user as dynamic)?.hotelId;
      if (hid != null && hid.toString().isNotEmpty) {
        await prefs.setString('hotelId', hid.toString());
        return hid.toString();
      }
    } catch (_) {}

    // 3. Live API
    try {
      final response = await ApiService.get('/my-hotels', token: token);
      if (response['success'] == true) {
        final data = response['data'];
        String? id;
        if (data is List && data.isNotEmpty) {
          id = data.first['id']?.toString();
        } else if (data is Map) {
          id = data['id']?.toString();
        }
        if (id != null && id.isNotEmpty) {
          await prefs.setString('hotelId', id);
          await prefs.setString('hotel_id', id);
          return id;
        }
      }
    } catch (_) {}

    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (token == null || token.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Session expired. Please log in again.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _submitting = false);
        return;
      }

      final hotelId = await _resolveHotelId(token);

      if (hotelId == null || hotelId.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No hotel found. Please register a hotel first.'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        setState(() => _submitting = false);
        return;
      }

      // Use snake_case field names to match API expectations
      final resp = await ApiService.post(
        ApiConfig.storeRoomTypeEndpoint,
        token: token,
        data: {
          'hotel_id': hotelId,
          'name': _nameCtrl.text.trim(),
          'description': _descCtrl.text.trim(),
          'price_per_night': double.tryParse(_priceCtrl.text) ?? 0,
          'capacity': int.tryParse(_capacityCtrl.text) ?? 2,
          'room_size': _sizeCtrl.text.trim(),
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              resp['success'] == true
                  ? 'Room added successfully!'
                  : resp['message'] ?? 'Failed',
            ),
            backgroundColor: resp['success'] == true
                ? AppColors.success
                : AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
        if (resp['success'] == true) Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.darkGray,
        title: const Text(
          'Add Room Type',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Room Details',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkGray,
                        ),
                      ),
                      const SizedBox(height: 14),
                      _field(
                        'Room Type Name *',
                        _nameCtrl,
                        Icons.hotel_rounded,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _field(
                        'Description',
                        _descCtrl,
                        Icons.description_rounded,
                        maxLines: 3,
                      ),
                      _field(
                        'Base Price / Night (NPR) *',
                        _priceCtrl,
                        Icons.payments_outlined,
                        type: TextInputType.number,
                        validator: (v) => v!.isEmpty ? 'Required' : null,
                      ),
                      _field(
                        'Max Capacity (guests)',
                        _capacityCtrl,
                        Icons.people_rounded,
                        type: TextInputType.number,
                      ),
                      _field(
                        'Room Size (e.g. 35 sqm)',
                        _sizeCtrl,
                        Icons.square_foot_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
              color: Colors.white,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _submitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Add Room Type',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController ctrl,
    IconData icon, {
    TextInputType type = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: TextFormField(
      controller: ctrl,
      keyboardType: type,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: maxLines == 1
            ? Icon(icon, size: 20, color: AppColors.gray)
            : null,
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    ),
  );
}
