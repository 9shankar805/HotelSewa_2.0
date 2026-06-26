import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../providers/room_provider.dart';
import '../models/room_model.dart';
// Import the owner auth provider to read hotelId at runtime
import '../../../auth/presentation/providers/auth_provider.dart'
    show AuthProvider;

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});
  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> {
  String _filter = 'all';
  final _searchCtrl = TextEditingController();
  String? _hotelId;
  String? _token;

  static const _filters = ['all', 'available', 'occupied', 'maintenance', 'cleaning'];
  static const _filterLabels = {
    'all': 'All', 'available': 'Available', 'occupied': 'Occupied',
    'maintenance': 'Maintenance', 'cleaning': 'Cleaning',
  };

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Resolves the hotelId using three fallback strategies:
  /// 1. SharedPreferences ('hotelId' / 'hotel_id')
  /// 2. AuthProvider (from the running session)
  /// 3. Live API call to /my-hotels (fetches first hotel's id)
  Future<String?> _resolveHotelId(String token) async {
    // ── Strategy 1: SharedPreferences ──
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('hotelId') ?? prefs.getString('hotel_id');
    if (stored != null && stored.isNotEmpty) return stored;

    // ── Strategy 2: AuthProvider in-memory ──
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user != null) {
        // Some builds store hotelId in the user model
        final dynamic hid = (user as dynamic).hotelId;
        if (hid != null && hid.toString().isNotEmpty) {
          await prefs.setString('hotelId', hid.toString());
          return hid.toString();
        }
      }
    } catch (_) {}

    // ── Strategy 3: Live API /my-hotels ──
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
          // Persist it so future reads are instant
          await prefs.setString('hotelId', id);
          await prefs.setString('hotel_id', id);
          debugPrint('✅ ManageRooms: hotelId resolved via API → $id');
          return id;
        }
      }
    } catch (e) {
      debugPrint('❌ ManageRooms: /my-hotels fetch failed: $e');
    }

    return null;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');

    if (_token == null || _token!.isEmpty) {
      // No token at all — nothing we can do
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Session expired. Please log in again.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    _hotelId = await _resolveHotelId(_token!);

    if (_hotelId == null || _hotelId!.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find your hotel. Please register a hotel first.'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    if (mounted) {
      setState(() {}); // trigger rebuild so _hotelId is available for _showAddRoom guard
      _load();
    }
  }

  void _load() {
    if (_hotelId == null || _token == null) return;
    context.read<RoomProvider>().loadRooms(
      filter: _filter, hotelId: _hotelId, token: _token,
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'available':   return const Color(0xFF10B981);
      case 'occupied':    return const Color(0xFF3B82F6);
      case 'maintenance': return const Color(0xFFEF4444);
      case 'cleaning':    return const Color(0xFFF59E0B);
      default:            return const Color(0xFF9CA3AF);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'available':   return Icons.check_circle_rounded;
      case 'occupied':    return Icons.person_rounded;
      case 'maintenance': return Icons.build_rounded;
      case 'cleaning':    return Icons.cleaning_services_rounded;
      default:            return Icons.circle_outlined;
    }
  }

  void _showRoomActions(Room room) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const SizedBox(height: 8),
          Container(width: 40, height: 4,
              decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: _statusColor(room.status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(_statusIcon(room.status), color: _statusColor(room.status), size: 22),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Room ${room.roomNumber}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                Text(room.type, style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF))),
              ]),
            ]),
          ),
          const Divider(height: 24),
          _actionTile('Mark Available',   Icons.check_circle_rounded,    const Color(0xFF10B981), () => _updateStatus(room.id, 'available')),
          _actionTile('Mark Occupied',    Icons.person_rounded,           const Color(0xFF3B82F6), () => _updateStatus(room.id, 'occupied')),
          _actionTile('Mark Maintenance', Icons.build_rounded,            const Color(0xFFEF4444), () => _updateStatus(room.id, 'maintenance')),
          _actionTile('Mark Cleaning',    Icons.cleaning_services_rounded, const Color(0xFFF59E0B), () => _updateStatus(room.id, 'cleaning')),
          const Divider(height: 8),
          _actionTile('Edit Room',        Icons.edit_rounded,              const Color(0xFF6366F1), () { Navigator.pop(context); _showEditRoom(room); }),
          _actionTile('Delete Room',      Icons.delete_outline_rounded,    const Color(0xFFEF4444), () => _confirmDelete(room)),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }

  Widget _actionTile(String label, IconData icon, Color color, VoidCallback onTap) {
    return ListTile(
      onTap: () { Navigator.pop(context); onTap(); },
      leading: Container(width: 38, height: 38,
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 18, color: color)),
      title: Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A2E))),
      dense: true,
    );
  }

  void _updateStatus(String roomId, String status) {
    context.read<RoomProvider>().updateRoomStatus(roomId, status, token: _token);
  }

  void _confirmDelete(Room room) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Room', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Delete Room ${room.roomNumber}? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Color(0xFF9CA3AF)))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            onPressed: () {
              Navigator.pop(context);
              context.read<RoomProvider>().deleteRoom(room.id);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddRoom() {
    if (_hotelId == null || _hotelId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Hotel ID not found. Please log in again.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    _showRoomForm(null);
  }
  
  void _showEditRoom(Room room) => _showRoomForm(room);

  void _showRoomForm(Room? existing) {
    final numberCtrl = TextEditingController(text: existing?.roomNumber ?? '');
    final typeCtrl   = TextEditingController(text: existing?.type ?? '');
    final priceCtrl  = TextEditingController(text: existing?.pricePerNight.toStringAsFixed(0) ?? '');
    final capCtrl    = TextEditingController(text: existing?.capacity.toString() ?? '1');
    final descCtrl   = TextEditingController(text: existing?.description ?? '');
    final formKey    = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: formKey,
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 40, height: 4,
                    decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(2))),
                const SizedBox(height: 16),
                Text(existing == null ? 'Add New Room' : 'Edit Room',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
                const SizedBox(height: 20),
                _formField('Room Number', numberCtrl, Icons.meeting_room_rounded, required: true),
                const SizedBox(height: 12),
                _formField('Room Type (e.g. Deluxe, Suite)', typeCtrl, Icons.category_rounded, required: true),
                const SizedBox(height: 12),
                _formField('Price per Night (Rs.)', priceCtrl, Icons.attach_money_rounded,
                    required: true, keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _formField('Capacity (guests)', capCtrl, Icons.people_rounded,
                    required: true, keyboard: TextInputType.number),
                const SizedBox(height: 12),
                _formField('Description (optional)', descCtrl, Icons.description_rounded),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary, elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      if (!formKey.currentState!.validate()) return;
                      final provider = context.read<RoomProvider>();
                      final newRoom = Room(
                        id: existing?.id ?? '',
                        roomNumber: numberCtrl.text.trim(),
                        type: typeCtrl.text.trim(),
                        status: existing?.status ?? 'available',
                        capacity: int.tryParse(capCtrl.text.trim()) ?? 1,
                        pricePerNight: double.tryParse(priceCtrl.text.trim()) ?? 0,
                        hotelId: _hotelId,
                        description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                      );
                      try {
                        if (existing == null) {
                          await provider.createRoom(newRoom);
                        } else {
                          await provider.updateRoom(newRoom);
                        }
                        if (mounted) Navigator.pop(context);
                      } catch (e) {
                        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating));
                      }
                    },
                    child: Text(existing == null ? 'Add Room' : 'Save Changes',
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  Widget _formField(String hint, TextEditingController ctrl, IconData icon,
      {bool required = false, TextInputType? keyboard}) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
        prefixIcon: Icon(icon, size: 18, color: AppColors.primary),
        filled: true, fillColor: const Color(0xFFF5F6FA),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomProvider>();
    final rooms    = provider.rooms;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Manage Rooms',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: Color(0xFF374151)), onPressed: _load),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddRoom,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add Room', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        // ── Stats row ─────────────────────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            _statChip('Total',       '${provider.totalRooms}',       const Color(0xFF6366F1)),
            const SizedBox(width: 8),
            _statChip('Available',   '${provider.availableRooms}',   const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _statChip('Occupied',    '${provider.occupiedRooms}',    const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            _statChip('Maintenance', '${provider.maintenanceRooms}', const Color(0xFFEF4444)),
          ]),
        ),
        // ── Search ────────────────────────────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: TextField(
            controller: _searchCtrl,
            onChanged: provider.searchRooms,
            decoration: InputDecoration(
              hintText: 'Search by room number or type...',
              hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
              prefixIcon: const Icon(Icons.search_rounded, size: 20, color: Color(0xFF9CA3AF)),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF9CA3AF)),
                      onPressed: () { _searchCtrl.clear(); provider.clearSearch(); })
                  : null,
              filled: true, fillColor: Colors.white,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
        // ── Filter chips ──────────────────────────────────────────────
        SizedBox(
          height: 48,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: _filters.map((f) {
              final on = _filter == f;
              return GestureDetector(
                onTap: () { setState(() => _filter = f); _load(); },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: on ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: on ? AppColors.primary : const Color(0xFFE5E7EB)),
                  ),
                  child: Text(_filterLabels[f]!,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700,
                          color: on ? Colors.white : const Color(0xFF374151))),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        // ── Room list ─────────────────────────────────────────────────
        Expanded(
          child: provider.isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : provider.errorMessage != null
                  ? _errorState(provider.errorMessage!)
                  : rooms.isEmpty
                      ? _emptyState()
                      : RefreshIndicator(
                          onRefresh: () async => _load(),
                          color: AppColors.primary,
                          child: ListView.builder(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                            itemCount: rooms.length,
                            itemBuilder: (_, i) => _roomCard(rooms[i]),
                          ),
                        ),
        ),
      ]),
    );
  }

  Widget _statChip(String label, String value, Color color) {
    return Expanded(child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
        Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color.withOpacity(0.8))),
      ]),
    ));
  }

  Widget _roomCard(Room room) {
    final sc = _statusColor(room.status);
    return GestureDetector(
      onTap: () => _showRoomActions(room),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(_statusIcon(room.status), size: 22, color: sc),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('Room ${room.roomNumber}',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(color: sc.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(room.status.toUpperCase(),
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: sc)),
              ),
            ]),
            const SizedBox(height: 4),
            Row(children: [
              Text(room.type, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
              const Text(' • ', style: TextStyle(color: Color(0xFFD1D5DB))),
              Icon(Icons.people_rounded, size: 12, color: const Color(0xFF9CA3AF)),
              const SizedBox(width: 3),
              Text('${room.capacity} guests', style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
            ]),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Rs.${room.pricePerNight.toStringAsFixed(0)}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
            const Text('/night', style: TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          ]),
          const SizedBox(width: 8),
          const Icon(Icons.more_vert_rounded, size: 18, color: Color(0xFF9CA3AF)),
        ]),
      ),
    );
  }

  Widget _emptyState() => Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
    const Icon(Icons.meeting_room_outlined, size: 56, color: Color(0xFFD1D5DB)),
    const SizedBox(height: 12),
    const Text('No rooms found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
    const SizedBox(height: 6),
    const Text('Tap + Add Room to get started', style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
  ]));

  Widget _errorState(String msg) => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.wifi_off_rounded, size: 48, color: Color(0xFFD1D5DB)),
      const SizedBox(height: 12),
      Text(msg, textAlign: TextAlign.center, style: const TextStyle(color: Color(0xFF9CA3AF))),
      const SizedBox(height: 16),
      ElevatedButton.icon(onPressed: _load,
          icon: const Icon(Icons.refresh_rounded, size: 16),
          label: const Text('Retry'),
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary,
              foregroundColor: Colors.white, elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)))),
    ]),
  ));
}
