import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class AddressBookScreen extends StatefulWidget {
  const AddressBookScreen({Key? key}) : super(key: key);

  @override
  State<AddressBookScreen> createState() => _AddressBookScreenState();
}

class _AddressBookScreenState extends State<AddressBookScreen> {
  List<Map<String, dynamic>> _addresses = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.profileAddressesEndpoint, token: token);
      if (response['success'] == true) {
        final raw = response['data'];
        List items = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['addresses'] ?? []) : []);
        setState(() {
          _addresses = items.map<Map<String, dynamic>>((a) => {
            'id': a['id']?.toString() ?? '',
            'label': a['label'] ?? a['type'] ?? 'Home',
            'line1': a['address_line1'] ?? a['line1'] ?? a['address'] ?? '',
            'line2': a['address_line2'] ?? a['line2'] ?? '${a['city'] ?? ''}, ${a['state'] ?? ''}',
            'isDefault': a['is_default'] == true || a['default'] == true,
            'icon': _iconFor(a['label'] ?? a['type'] ?? 'Home'),
            'color': _colorFor(a['label'] ?? a['type'] ?? 'Home'),
          }).toList();
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _saveAddress(Map<String, dynamic> data, {String? id}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      if (id != null) {
        await ApiService.put(ApiConfig.buildPath(ApiConfig.profileAddressesEndpoint, id), token: token, data: data);
      } else {
        await ApiService.post(ApiConfig.profileAddressesEndpoint, token: token, data: data);
      }
      await _load();
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save address'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  Future<void> _deleteAddress(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      await ApiService.delete(ApiConfig.buildPath(ApiConfig.profileAddressesEndpoint, id), token: token);
      await _load();
    } catch (_) {}
  }

  void _addOrEdit({Map<String, dynamic>? existing}) {
    final labelCtrl = TextEditingController(text: existing?['label'] ?? '');
    final line1Ctrl = TextEditingController(text: existing?['line1'] ?? '');
    final line2Ctrl = TextEditingController(text: existing?['line2'] ?? '');
    String selectedType = existing?['label'] ?? 'Home';
    final types = ['Home', 'Work', 'Other'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Text(existing == null ? 'Add Address' : 'Edit Address', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                  IconButton(icon: const Icon(Icons.close_rounded, color: AppColors.gray), onPressed: () => Navigator.pop(ctx)),
                ]),
                const SizedBox(height: 16),
                Row(children: types.map((t) {
                  final sel = selectedType == t;
                  return Expanded(child: GestureDetector(
                    onTap: () { setModal(() => selectedType = t); labelCtrl.text = t; },
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray, width: sel ? 1.5 : 1),
                      ),
                      child: Center(child: Text(t, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? AppColors.primary : AppColors.gray))),
                    ),
                  ));
                }).toList()),
                const SizedBox(height: 16),
                _sheetField('Address Line 1', line1Ctrl, 'Street, Building, Flat no.'),
                const SizedBox(height: 12),
                _sheetField('Address Line 2', line2Ctrl, 'Area, City, PIN code'),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      if (line1Ctrl.text.isEmpty) return;
                      Navigator.pop(ctx);
                      await _saveAddress({
                        'label': selectedType,
                        'type': selectedType.toLowerCase(),
                        'address_line1': line1Ctrl.text,
                        'address_line2': line2Ctrl.text,
                      }, id: existing?['id']);
                    },
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                    child: Text(existing == null ? 'Add Address' : 'Save Changes', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(String label, TextEditingController ctrl, String hint) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
      const SizedBox(height: 6),
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          filled: true, fillColor: AppColors.background,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }

  void _delete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Address'),
        content: const Text('Remove this address from your address book?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(onPressed: () { Navigator.pop(context); _deleteAddress(id); },
              child: const Text('Delete', style: TextStyle(color: AppColors.error))),
        ],
      ),
    );
  }

  void _setDefault(String id) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      await ApiService.put(ApiConfig.buildPath(ApiConfig.profileAddressesEndpoint, id), token: token, data: {'is_default': true});
      await _load();
    } catch (_) {
      setState(() {
        for (final a in _addresses) a['isDefault'] = a['id'] == id;
      });
    }
  }

  IconData _iconFor(String t) {
    switch (t) {
      case 'Work': return Icons.business_rounded;
      case 'Other': return Icons.location_on_rounded;
      default: return Icons.home_rounded;
    }
  }

  Color _colorFor(String t) {
    switch (t) {
      case 'Work': return AppColors.info;
      case 'Other': return AppColors.purple;
      default: return AppColors.primary;
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
        title: const Text('Address Book', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.add_rounded, color: AppColors.primary), onPressed: () => _addOrEdit()),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _addresses.isEmpty
          ? _buildEmpty()
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _addresses.length + 1,
              itemBuilder: (_, i) {
                if (i == _addresses.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: GestureDetector(
                      onTap: () => _addOrEdit(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.primary.withOpacity(0.4), style: BorderStyle.solid),
                          boxShadow: AppColors.cardShadow,
                        ),
                        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                          Icon(Icons.add_rounded, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('Add New Address', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary)),
                        ]),
                      ),
                    ),
                  );
                }
                final addr = _addresses[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: addr['isDefault'] == true ? Border.all(color: AppColors.primary.withOpacity(0.3)) : null,
                    boxShadow: AppColors.cardShadow,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42, height: 42,
                        decoration: BoxDecoration(color: (addr['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Icon(addr['icon'] as IconData, color: addr['color'] as Color, size: 20),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(children: [
                              Text(addr['label'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                              if (addr['isDefault'] == true) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(6)),
                                  child: const Text('Default', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.success)),
                                ),
                              ],
                            ]),
                            const SizedBox(height: 4),
                            Text(addr['line1'] as String, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)),
                            Text(addr['line2'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                          ],
                        ),
                      ),
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert_rounded, color: AppColors.gray, size: 20),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        onSelected: (v) {
                          if (v == 'edit') _addOrEdit(existing: addr);
                          if (v == 'default') _setDefault(addr['id'] as String);
                          if (v == 'delete') _delete(addr['id'] as String);
                        },
                        itemBuilder: (_) => [
                          const PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit_outlined, size: 16), SizedBox(width: 8), Text('Edit')])),
                          if (addr['isDefault'] != true) const PopupMenuItem(value: 'default', child: Row(children: [Icon(Icons.check_circle_outline, size: 16), SizedBox(width: 8), Text('Set as Default')])),
                          const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.error))])),
                        ],
                      ),
                    ],
                  ),
                ).animate(delay: (i * 50).ms).fadeIn().slideY(begin: 0.05);
              },
            ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(width: 80, height: 80, decoration: BoxDecoration(color: AppColors.surfaceVariant, shape: BoxShape.circle), child: const Icon(Icons.location_off_rounded, size: 40, color: AppColors.placeholder)),
          const SizedBox(height: 16),
          const Text('No saved addresses', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          const Text('Add your home, work or other addresses', style: TextStyle(fontSize: 14, color: AppColors.gray)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _addOrEdit(),
            icon: const Icon(Icons.add_rounded, color: Colors.white, size: 18),
            label: const Text('Add Address', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
          ),
        ],
      ),
    );
  }
}
