import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../providers/room_provider.dart';
import '../models/room_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ManageRoomsScreen extends StatefulWidget {
  const ManageRoomsScreen({super.key});
  @override
  State<ManageRoomsScreen> createState() => _ManageRoomsScreenState();
}

class _ManageRoomsScreenState extends State<ManageRoomsScreen> with TickerProviderStateMixin {
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

  Future<String?> _resolveHotelId(String token) async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString('hotelId') ?? prefs.getString('hotel_id');
    if (stored != null && stored.isNotEmpty) return stored;

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.user;
      if (user != null) {
        final dynamic hid = (user as dynamic).hotelId;
        if (hid != null && hid.toString().isNotEmpty) {
          await prefs.setString('hotelId', hid.toString());
          return hid.toString();
        }
      }
    } catch (_) {}

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
    } catch (e) {
      debugPrint('Failed to resolve hotelId: $e');
    }

    return null;
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
    if (_token == null || _token!.isEmpty) {
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
      setState(() {});
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
      case 'available': return const Color(0xFF10B981);
      case 'occupied': return const Color(0xFF3B82F6);
      case 'maintenance': return const Color(0xFFEF4444);
      case 'cleaning': return const Color(0xFFF59E0B);
      default: return const Color(0xFF9CA3AF);
    }
  }

  IconData _statusIcon(String s) {
    switch (s) {
      case 'available': return Icons.check_circle_rounded;
      case 'occupied': return Icons.person_rounded;
      case 'maintenance': return Icons.build_rounded;
      case 'cleaning': return Icons.cleaning_services_rounded;
      default: return Icons.circle_outlined;
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
          _actionTile('Mark Available', Icons.check_circle_rounded, const Color(0xFF10B981), () => _updateStatus(room.id, 'available')),
          _actionTile('Mark Occupied', Icons.person_rounded, const Color(0xFF3B82F6), () => _updateStatus(room.id, 'occupied')),
          _actionTile('Mark Maintenance', Icons.build_rounded, const Color(0xFFEF4444), () => _updateStatus(room.id, 'maintenance')),
          _actionTile('Mark Cleaning', Icons.cleaning_services_rounded, const Color(0xFFF59E0B), () => _updateStatus(room.id, 'cleaning')),
          const Divider(height: 8),
          _actionTile('Edit Room', Icons.edit_rounded, const Color(0xFF6366F1), () { Navigator.pop(context); _showEditRoom(room); }),
          _actionTile('Delete Room', Icons.delete_outline_rounded, const Color(0xFFEF4444), () => _confirmDelete(room)),
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
              context.read<RoomProvider>().deleteRoom(room.id, token: _token);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _showAddRoomBottomSheet() {
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

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: DefaultTabController(
            length: 2,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 12),
                TabBar(
                  tabs: const [
                    Tab(text: 'Add Room Type'),
                    Tab(text: 'Add Individual Room'),
                  ],
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.gray,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 2.5,
                  indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.5,
                  child: TabBarView(
                    children: [
                      _AddRoomTypeTab(
                        hotelId: _hotelId!,
                        token: _token!,
                        onRoomTypeCreated: () {
                          if (mounted) {
                            Navigator.pop(context);
                            _load();
                          }
                        },
                      ),
                      _AddIndividualRoomTab(
                        hotelId: _hotelId!,
                        token: _token!,
                        onRoomCreated: () {
                          if (mounted) {
                            Navigator.pop(context);
                            _load();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditRoom(Room room) => _showAddRoomBottomSheet(); // TODO: Implement edit

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomProvider>();
    final rooms = provider.rooms;

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
        onPressed: _showAddRoomBottomSheet,
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Add', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(children: [
            _statChip('Total', '${provider.totalRooms}', const Color(0xFF6366F1)),
            const SizedBox(width: 8),
            _statChip('Available', '${provider.availableRooms}', const Color(0xFF10B981)),
            const SizedBox(width: 8),
            _statChip('Occupied', '${provider.occupiedRooms}', const Color(0xFF3B82F6)),
            const SizedBox(width: 8),
            _statChip('Maintenance', '${provider.maintenanceRooms}', const Color(0xFFEF4444)),
          ]),
        ),
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
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color)),
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
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: sc)),
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
    const Text('Tap +Add to get started', style: TextStyle(fontSize: 13, color: Color(0xFFD1D5DB))),
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

class _AddRoomTypeTab extends StatefulWidget {
  final String hotelId;
  final String token;
  final VoidCallback onRoomTypeCreated;
  const _AddRoomTypeTab({
    required this.hotelId,
    required this.token,
    required this.onRoomTypeCreated,
  });
  @override
  State<_AddRoomTypeTab> createState() => _AddRoomTypeTabState();
}

class _AddRoomTypeTabState extends State<_AddRoomTypeTab> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _priceCtrl = TextEditingController();
  final _capacityCtrl = TextEditingController();
  final _totalRoomsCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();
  File? _coverPhoto;
  final ImagePicker _picker = ImagePicker();
  bool _isLoading = false;

  Future<void> _pickCoverPhoto() async {
    final XFile? picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _coverPhoto = File(picked.path));
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final result = await Provider.of<RoomProvider>(context, listen: false).createRoomType(
        hotelId: widget.hotelId,
        name: _nameCtrl.text.trim(),
        price: double.parse(_priceCtrl.text.trim()),
        capacity: int.parse(_capacityCtrl.text.trim()),
        totalRooms: int.parse(_totalRoomsCtrl.text.trim()),
        description: _descriptionCtrl.text.trim().isEmpty ? null : _descriptionCtrl.text.trim(),
        size: _sizeCtrl.text.trim().isEmpty ? null : _sizeCtrl.text.trim(),
        coverPhoto: _coverPhoto,
        token: widget.token,
      );

      if (result['success'] == true) {
        widget.onRoomTypeCreated();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create room type'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            // Cover Photo
            GestureDetector(
              onTap: _pickCoverPhoto,
              child: Container(
                width: double.infinity, height: 150,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F6FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: _coverPhoto != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(_coverPhoto!, fit: BoxFit.cover))
                    : Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        const Icon(Icons.image_rounded, size: 36, color: Color(0xFFADB5BD)),
                        const SizedBox(height: 8),
                        const Text('Add Cover Photo (Optional)',
                            style: TextStyle(color: Color(0xFF6B7280), fontSize: 13, fontWeight: FontWeight.w600)),
                      ]),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                hintText: 'Room Type Name *',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.category_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _priceCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Price per Night (NPR) *',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.attach_money_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _capacityCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Max Guests *',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.people_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (int.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _totalRoomsCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Total Rooms of this Type *',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.meeting_room_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (int.tryParse(v.trim()) == null) return 'Invalid number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _sizeCtrl,
              decoration: InputDecoration(
                hintText: 'Room Size (Optional, e.g. "35 sqm")',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.square_foot_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Description (Optional)',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.description_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Room Type',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddIndividualRoomTab extends StatefulWidget {
  final String hotelId;
  final String token;
  final VoidCallback onRoomCreated;
  const _AddIndividualRoomTab({
    required this.hotelId,
    required this.token,
    required this.onRoomCreated,
  });
  @override
  State<_AddIndividualRoomTab> createState() => _AddIndividualRoomTabState();
}

class _AddIndividualRoomTabState extends State<_AddIndividualRoomTab> {
  final _formKey = GlobalKey<FormState>();
  final _roomNumberCtrl = TextEditingController();
  final _floorCtrl = TextEditingController();
  List<dynamic> _roomTypes = [];
  int? _selectedRoomTypeId;
  String _selectedStatus = 'available';
  bool _isLoadingRoomTypes = false;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _loadRoomTypes();
  }

  Future<void> _loadRoomTypes() async {
    setState(() => _isLoadingRoomTypes = true);
    try {
      final result = await context.read<RoomProvider>().getRoomTypes(
        hotelId: widget.hotelId,
        token: widget.token,
      );
      if (result['success'] == true) {
        setState(() {
          _roomTypes = result['data'] ?? [];
          if (_roomTypes.isNotEmpty) _selectedRoomTypeId = _roomTypes.first['id'];
        });
      }
    } finally {
      if (mounted) setState(() => _isLoadingRoomTypes = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedRoomTypeId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a room type'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    try {
      final result = await context.read<RoomProvider>().createRoom(
        roomTypeId: _selectedRoomTypeId!,
        roomNumber: _roomNumberCtrl.text.trim(),
        floor: int.tryParse(_floorCtrl.text.trim()),
        status: _selectedStatus,
        token: widget.token,
        hotelId: widget.hotelId,
      );
      if (result['success'] == true) {
        widget.onRoomCreated();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(result['message'] ?? 'Failed to create room'),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _isLoadingRoomTypes
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _roomTypes.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No room types found! Please create a room type first.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.error),
                        ),
                      )
                    : DropdownButtonFormField<int>(
                        value: _selectedRoomTypeId,
                        decoration: InputDecoration(
                          hintText: 'Select Room Type *',
                          hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                          prefixIcon: const Icon(Icons.category_rounded, size: 18, color: AppColors.primary),
                          filled: true, fillColor: const Color(0xFFF5F6FA),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        ),
                        items: _roomTypes.map((rt) {
                          return DropdownMenuItem<int>(
                            value: rt['id'],
                            child: Text('${rt['name']} (Rs.${rt['base_price'] ?? rt['effective_price'] ?? 0})'),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() => _selectedRoomTypeId = value);
                        },
                        validator: (v) => v == null ? 'Please select a room type' : null,
                      ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _roomNumberCtrl,
              decoration: InputDecoration(
                hintText: 'Room Number * (e.g. 101, 202)',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.meeting_room_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _floorCtrl,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Floor (Optional)',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.layers_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: _selectedStatus,
              decoration: InputDecoration(
                hintText: 'Status',
                hintStyle: const TextStyle(color: Color(0xFFADB5BD)),
                prefixIcon: const Icon(Icons.info_outline_rounded, size: 18, color: AppColors.primary),
                filled: true, fillColor: const Color(0xFFF5F6FA),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              ),
              items: const [
                DropdownMenuItem(value: 'available', child: Text('Available')),
                DropdownMenuItem(value: 'maintenance', child: Text('Maintenance')),
              ],
              onChanged: (value) {
                setState(() => _selectedStatus = value ?? 'available');
              },
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Add Individual Room',
                        style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
