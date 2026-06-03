import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class FrontDeskScreen extends StatefulWidget {
  const FrontDeskScreen({Key? key}) : super(key: key);

  @override
  State<FrontDeskScreen> createState() => _FrontDeskScreenState();
}

class _FrontDeskScreenState extends State<FrontDeskScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  List<Map<String, dynamic>> _roomGrid = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.frontDeskRoomGridEndpoint, token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List ? data : (data is Map ? (data['data'] ?? data['rooms'] ?? []) : []);
        _roomGrid = List<Map<String, dynamic>>.from(raw);
      }
    } catch (_) {}
    setState(() => _loading = false);
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
        title: const Text('Front Desk', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: const [Tab(text: 'Room Grid'), Tab(text: 'Walk-in')],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(
              controller: _tabController,
              children: [_buildRoomGrid(), _buildWalkIn()],
            ),
    );
  }

  Widget _buildRoomGrid() {
    if (_roomGrid.isEmpty) {
      return const Center(child: Text('No room data available', style: TextStyle(color: AppColors.gray)));
    }
    final statusColors = {'vacant': AppColors.success, 'occupied': AppColors.error, 'dirty': AppColors.warning, 'maintenance': AppColors.info};
    return Column(
      children: [
        // Legend
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: statusColors.entries.map((e) => Row(children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(color: e.value, borderRadius: BorderRadius.circular(3))),
              const SizedBox(width: 4),
              Text(e.key[0].toUpperCase() + e.key.substring(1), style: const TextStyle(fontSize: 11, color: AppColors.gray)),
            ])).toList(),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 1.1),
            itemCount: _roomGrid.length,
            itemBuilder: (_, i) {
              final room = _roomGrid[i];
              final status = room['status'] ?? 'vacant';
              final color = statusColors[status] ?? AppColors.gray;
              return GestureDetector(
                onTap: () => _showRoomActions(room),
                child: Container(
                  decoration: BoxDecoration(color: color.withOpacity(0.15), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.4))),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(room['room_number'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
                      Text(status.substring(0, 1).toUpperCase(), style: TextStyle(fontSize: 10, color: color)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showRoomActions(Map<String, dynamic> room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 20),
            Text('Room ${room['room_number']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            const SizedBox(height: 20),
            _actionTile(Icons.assignment_ind_rounded, 'Assign to Booking', AppColors.info, () async {
              Navigator.pop(context);
              _showAssignDialog(room['id']);
            }),
            _actionTile(Icons.receipt_long_rounded, 'View Folio', AppColors.purple, () => Navigator.pop(context)),
            _actionTile(Icons.add_circle_outline_rounded, 'Add Charge', AppColors.warning, () => Navigator.pop(context)),
          ],
        ),
      ),
    );
  }

  Widget _actionTile(IconData icon, String label, Color color, VoidCallback onTap) {
    return ListTile(
      leading: Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
        child: Icon(icon, color: color, size: 20)),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
      trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.gray),
      onTap: onTap,
    );
  }

  void _showAssignDialog(int roomId) {
    final bookingIdCtrl = TextEditingController();
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
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Assign Room', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              const SizedBox(height: 16),
              TextField(controller: bookingIdCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(hintText: 'Booking ID', prefixIcon: const Icon(Icons.confirmation_number_outlined, color: AppColors.gray), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)))),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs = await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    await ApiService.post(ApiConfig.frontDeskRoomAssignEndpoint, data: {'booking_id': int.tryParse(bookingIdCtrl.text) ?? 0, 'room_id': roomId}, token: token);
                    _load();
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                  child: const Text('Assign', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildWalkIn() {
    final nameCtrl = TextEditingController();
    final mobileCtrl = TextEditingController();
    final checkInCtrl = TextEditingController();
    final checkOutCtrl = TextEditingController();
    final roomTypeCtrl = TextEditingController();
    bool submitting = false;

    return StatefulBuilder(
      builder: (ctx, setLocalState) => SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  Container(width: 52, height: 52, decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(14)),
                    child: const Icon(Icons.person_add_rounded, color: Colors.white, size: 26)),
                  const SizedBox(width: 16),
                  const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Walk-in Booking', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
                    SizedBox(height: 4),
                    Text('Create a booking for a walk-in guest.', style: TextStyle(fontSize: 12, color: Colors.white70)),
                  ])),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _field('Guest Name', nameCtrl, Icons.person_outline),
            const SizedBox(height: 12),
            _field('Mobile', mobileCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
            const SizedBox(height: 12),
            _field('Room Type ID', roomTypeCtrl, Icons.hotel_rounded, keyboardType: TextInputType.number),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: _field('Check-in', checkInCtrl, Icons.calendar_today_rounded, hint: 'YYYY-MM-DD')),
              const SizedBox(width: 12),
              Expanded(child: _field('Check-out', checkOutCtrl, Icons.calendar_today_rounded, hint: 'YYYY-MM-DD')),
            ]),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitting ? null : () async {
                  setLocalState(() => submitting = true);
                  final prefs = await SharedPreferences.getInstance();
                  final token = prefs.getString('authToken');
                  final response = await ApiService.post(
                    ApiConfig.frontDeskWalkInEndpoint,
                    data: {'room_type_id': int.tryParse(roomTypeCtrl.text) ?? 0, 'guest_name': nameCtrl.text, 'mobile': mobileCtrl.text, 'check_in': checkInCtrl.text, 'check_out': checkOutCtrl.text, 'guests': 1},
                    token: token,
                  );
                  setLocalState(() => submitting = false);
                  if (response['success'] == true) {
                    if (ctx.mounted) ScaffoldMessenger.of(ctx).showSnackBar(const SnackBar(content: Text('Walk-in booking created'), backgroundColor: AppColors.success));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: submitting
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create Walk-in Booking', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, TextEditingController ctrl, IconData icon, {String? hint, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
        const SizedBox(height: 6),
        TextField(
          controller: ctrl,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint ?? label,
            prefixIcon: Icon(icon, color: AppColors.gray, size: 20),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary)),
          ),
        ),
      ],
    );
  }
}
