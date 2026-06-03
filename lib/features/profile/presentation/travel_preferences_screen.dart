import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/user_service.dart';

class TravelPreferencesScreen extends StatefulWidget {
  const TravelPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<TravelPreferencesScreen> createState() => _TravelPreferencesScreenState();
}

class _TravelPreferencesScreenState extends State<TravelPreferencesScreen> {
  final _userService = UserService();
  String _roomType = 'No preference';
  String _bedType = 'No preference';
  String _floor = 'No preference';
  String _pillow = 'Soft';
  String _dietary = 'None';
  bool _smokingRoom = false;
  bool _accessibleRoom = false;
  bool _quietRoom = true;
  bool _highFloor = false;
  final Set<String> _amenities = {'Free WiFi', 'AC'};
  bool _loading = true;
  bool _saving = false;

  final _roomTypes = ['No preference', 'Standard', 'Deluxe', 'Suite', 'Family Room'];
  final _bedTypes = ['No preference', 'King', 'Queen', 'Twin', 'Double'];
  final _floors = ['No preference', 'Low floor', 'Mid floor', 'High floor', 'Top floor'];
  final _pillows = ['Soft', 'Medium', 'Firm', 'Hypoallergenic'];
  final _dietaryOptions = ['None', 'Vegetarian', 'Vegan', 'Halal', 'Kosher', 'Gluten-free'];
  final _amenityOptions = ['Free WiFi', 'AC', 'Pool', 'Gym', 'Spa', 'Parking', 'Restaurant', 'Room Service', 'Bar'];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final result = await _userService.getTravelPreferences();
      if (result['success'] == true && result['data'] is Map) {
        final d = result['data'] as Map;
        setState(() {
          _roomType = d['room_type'] ?? _roomType;
          _bedType = d['bed_type'] ?? _bedType;
          _floor = d['floor_preference'] ?? _floor;
          _pillow = d['pillow_type'] ?? _pillow;
          _dietary = d['dietary'] ?? _dietary;
          _smokingRoom = d['smoking_room'] == true;
          _accessibleRoom = d['accessible_room'] == true;
          _quietRoom = d['quiet_room'] != false;
          _highFloor = d['high_floor'] == true;
          if (d['amenities'] is List) {
            _amenities.clear();
            _amenities.addAll((d['amenities'] as List).map((a) => a.toString()));
          }
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await _userService.updateTravelPreferences({
        'room_type': _roomType,
        'bed_type': _bedType,
        'floor_preference': _floor,
        'pillow_type': _pillow,
        'dietary': _dietary,
        'smoking_room': _smokingRoom,
        'accessible_room': _accessibleRoom,
        'quiet_room': _quietRoom,
        'high_floor': _highFloor,
        'amenities': _amenities.toList(),
      });
      if (!mounted) return;
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preferences saved!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to save'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save preferences'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
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
        title: const Text('Travel Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionLabel('Room Preferences'),
                  const SizedBox(height: 10),
                  _card(child: Column(children: [
                    _dropdownRow('Room Type', _roomType, _roomTypes, (v) => setState(() => _roomType = v!)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _dropdownRow('Bed Type', _bedType, _bedTypes, (v) => setState(() => _bedType = v!)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _dropdownRow('Floor Preference', _floor, _floors, (v) => setState(() => _floor = v!)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _dropdownRow('Pillow Type', _pillow, _pillows, (v) => setState(() => _pillow = v!)),
                  ])).animate().fadeIn().slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  _sectionLabel('Special Requirements'),
                  const SizedBox(height: 10),
                  _card(child: Column(children: [
                    _toggleRow(Icons.smoke_free_rounded, AppColors.error, 'Smoking Room', _smokingRoom, (v) => setState(() => _smokingRoom = v)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _toggleRow(Icons.accessible_rounded, AppColors.info, 'Accessible Room', _accessibleRoom, (v) => setState(() => _accessibleRoom = v)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _toggleRow(Icons.volume_off_rounded, AppColors.purple, 'Quiet Room', _quietRoom, (v) => setState(() => _quietRoom = v)),
                    const Divider(color: AppColors.lightGray, height: 1),
                    _toggleRow(Icons.arrow_upward_rounded, AppColors.success, 'High Floor Preferred', _highFloor, (v) => setState(() => _highFloor = v)),
                  ])).animate().fadeIn(delay: 80.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  _sectionLabel('Dietary Preferences'),
                  const SizedBox(height: 10),
                  _card(child: _dropdownRow('Dietary Requirement', _dietary, _dietaryOptions, (v) => setState(() => _dietary = v!))).animate().fadeIn(delay: 140.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  _sectionLabel('Must-Have Amenities'),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8, runSpacing: 8,
                    children: _amenityOptions.map((a) {
                      final selected = _amenities.contains(a);
                      return GestureDetector(
                        onTap: () => setState(() => selected ? _amenities.remove(a) : _amenities.add(a)),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary.withOpacity(0.1) : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? AppColors.primary : AppColors.lightGray, width: selected ? 1.5 : 1),
                            boxShadow: selected ? [] : AppColors.cardShadow,
                          ),
                          child: Text(a, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w600 : FontWeight.w400, color: selected ? AppColors.primary : AppColors.darkGray)),
                        ),
                      );
                    }).toList(),
                  ).animate().fadeIn(delay: 200.ms),
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
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Preferences', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String t) => Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray, letterSpacing: 0.5));

  Widget _card({required Widget child}) => Container(
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
    child: child,
  );

  Widget _dropdownRow(String label, String value, List<String> options, ValueChanged<String?> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGray))),
          DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
              items: options.map((o) => DropdownMenuItem(value: o, child: Text(o, style: const TextStyle(fontSize: 13, color: AppColors.darkGray)))).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _toggleRow(IconData icon, Color color, String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGray))),
          Switch(value: value, onChanged: onChanged, activeColor: AppColors.primary),
        ],
      ),
    );
  }
}
