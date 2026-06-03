import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';
import '../../../core/services/hotel_service.dart';

class BookingModificationScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const BookingModificationScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<BookingModificationScreen> createState() => _BookingModificationScreenState();
}

class _BookingModificationScreenState extends State<BookingModificationScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  int _adults = 2;
  int _children = 0;
  String _selectedRoom = '';
  bool _loading = false;
  bool _loadingRooms = true;

  // Loaded from API; falls back to static list
  List<Map<String, dynamic>> _roomTypes = [];

  static const _fallbackRooms = [
    {'id': null, 'name': 'Standard Room'},
    {'id': null, 'name': 'Deluxe Room'},
    {'id': null, 'name': 'Premium Suite'},
    {'id': null, 'name': 'Family Room'},
  ];

  @override
  void initState() {
    super.initState();
    final b = widget.arguments ?? {};
    _selectedRoom = b['roomType'] ?? '';
    _adults = b['adults'] ?? 2;
    _children = b['children'] ?? 0;
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    setState(() => _loadingRooms = true);
    try {
      final hotelId = widget.arguments?['hotelId']?.toString();
      if (hotelId != null) {
        final result = await HotelService().getHotelDetails(hotelId);
        if (result['success'] == true) {
          final data = result['data'] as Map<String, dynamic>;
          final rooms = data['room_types'] ?? data['rooms'] ?? [];
          if (rooms is List && rooms.isNotEmpty) {
            setState(() {
              _roomTypes = rooms.map<Map<String, dynamic>>((r) => {
                'id': r['id']?.toString(),
                'name': r['name'] ?? r['type'] ?? 'Room',
              }).toList();
              if (_selectedRoom.isEmpty && _roomTypes.isNotEmpty) {
                _selectedRoom = _roomTypes[0]['name'] as String;
              }
              _loadingRooms = false;
            });
            return;
          }
        }
      }
    } catch (_) {}
    // Fallback to static list
    setState(() {
      _roomTypes = List<Map<String, dynamic>>.from(_fallbackRooms);
      if (_selectedRoom.isEmpty) _selectedRoom = _roomTypes[0]['name'] as String;
      _loadingRooms = false;
    });
  }

  Future<void> _pickDate(bool isCheckIn) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: isCheckIn ? (_checkIn ?? now.add(const Duration(days: 1))) : (_checkOut ?? now.add(const Duration(days: 3))),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: AppColors.primary)),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        if (isCheckIn) {
          _checkIn = picked;
          if (_checkOut != null && _checkOut!.isBefore(picked)) _checkOut = picked.add(const Duration(days: 1));
        } else {
          _checkOut = picked;
        }
      });
    }
  }

  int get _nights {
    if (_checkIn == null || _checkOut == null) return widget.arguments?['nights'] ?? 2;
    return _checkOut!.difference(_checkIn!).inDays.clamp(1, 365);
  }

  String _fmt(DateTime? d) {
    if (d == null) return 'Select date';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

  Future<void> _saveChanges() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final bookingId = widget.arguments?['bookingId']?.toString() ?? widget.arguments?['id']?.toString();
      if (bookingId == null) throw Exception('No booking ID');

      final response = await ApiService.post(
        ApiConfig.bookingModificationsRequestEndpoint,
        token: token,
        data: {
          'booking_id': bookingId,
          if (_checkIn != null) 'check_in_date': _checkIn!.toIso8601String().split('T')[0],
          if (_checkOut != null) 'check_out_date': _checkOut!.toIso8601String().split('T')[0],
          'adults': _adults,
          'children': _children,
          'room_type': _selectedRoom,
        },
      );
      if (!mounted) return;
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Modification request submitted!'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(response['message'] ?? 'Failed to modify booking'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _loading = false);
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
        title: const Text('Modify Booking', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
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
                  // Info banner
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
                    child: const Row(
                      children: [
                        Icon(Icons.info_outline_rounded, color: AppColors.info, size: 18),
                        SizedBox(width: 10),
                        Expanded(child: Text('Modifications are subject to availability and may affect pricing.',
                            style: TextStyle(fontSize: 12, color: AppColors.info, height: 1.4))),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),

                  _sectionTitle('Dates'),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(child: _dateTile('Check-in', _fmt(_checkIn), Icons.login_rounded, () => _pickDate(true))),
                      const SizedBox(width: 12),
                      Expanded(child: _dateTile('Check-out', _fmt(_checkOut), Icons.logout_rounded, () => _pickDate(false))),
                    ],
                  ).animate().fadeIn(delay: 60.ms),
                  const SizedBox(height: 6),
                  Center(child: Text('$_nights night${_nights > 1 ? 's' : ''}', style: const TextStyle(fontSize: 13, color: AppColors.gray))),
                  const SizedBox(height: 20),

                  _sectionTitle('Guests'),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                    child: Column(
                      children: [
                        _guestRow('Adults', 'Age 18+', _adults, (v) => setState(() => _adults = v), 1, 6),
                        const Divider(color: AppColors.lightGray, height: 20),
                        _guestRow('Children', 'Age 0-17', _children, (v) => setState(() => _children = v), 0, 4),
                      ],
                    ),
                  ).animate().fadeIn(delay: 120.ms),
                  const SizedBox(height: 20),

                  _sectionTitle('Room Type'),
                  const SizedBox(height: 10),
                  if (_loadingRooms)
                    const Center(child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                    ))
                  else
                    ..._roomTypes.asMap().entries.map((e) {
                    final room = e.value['name'] as String;
                    final selected = _selectedRoom == room;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRoom = room),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          color: selected ? AppColors.primary.withOpacity(0.06) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: selected ? AppColors.primary : AppColors.lightGray, width: selected ? 1.5 : 1),
                          boxShadow: selected ? [] : AppColors.cardShadow,
                        ),
                        child: Row(
                          children: [
                            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                                color: selected ? AppColors.primary : AppColors.placeholder, size: 20),
                            const SizedBox(width: 12),
                            Expanded(child: Text(room, style: TextStyle(fontSize: 14, fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                                color: selected ? AppColors.primary : AppColors.darkGray))),
                          ],
                        ),
                      ).animate(delay: (e.key * 40).ms).fadeIn(),
                    );
                  }),
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
                onPressed: _loading ? null : _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Changes', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String t) => Text(t, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray));

  Widget _dateTile(String label, String value, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppColors.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [Icon(icon, size: 14, color: AppColors.primary), const SizedBox(width: 4),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.gray))]),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          ],
        ),
      ),
    );
  }

  Widget _guestRow(String label, String sub, int value, ValueChanged<int> onChange, int min, int max) {
    return Row(
      children: [
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          Text(sub, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
        ])),
        Row(children: [
          _counterBtn(Icons.remove_rounded, value > min ? () => onChange(value - 1) : null),
          SizedBox(width: 36, child: Text('$value', textAlign: TextAlign.center, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray))),
          _counterBtn(Icons.add_rounded, value < max ? () => onChange(value + 1) : null),
        ]),
      ],
    );
  }

  Widget _counterBtn(IconData icon, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: onTap != null ? AppColors.primary.withOpacity(0.1) : AppColors.surfaceVariant,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: onTap != null ? AppColors.primary : AppColors.placeholder),
      ),
    );
  }
}