import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

/// Guest-facing: browse & book activities for an active booking.
/// Owner-facing: manage activities (create/update/delete) and view bookings.
/// The `isOwner` flag switches between the two modes.
class ActivitiesScreen extends StatefulWidget {
  final bool isOwner;
  final Map<String, dynamic>? arguments;

  const ActivitiesScreen({
    Key? key,
    this.isOwner = false,
    this.arguments,
  }) : super(key: key);

  @override
  State<ActivitiesScreen> createState() => _ActivitiesScreenState();
}

class _ActivitiesScreenState extends State<ActivitiesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _activities = [];
  List<Map<String, dynamic>> _myBookings = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
        length: widget.isOwner ? 2 : 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');

      if (widget.isOwner) {
        final results = await Future.wait([
          ApiService.get(ApiConfig.ownerActivitiesEndpoint,
              token: token),
          ApiService.get(ApiConfig.ownerActivityBookingsEndpoint,
              token: token),
        ]);
        if (results[0]['success'] == true) {
          final data = results[0]['data'];
          List raw = data is List
              ? data
              : (data is Map
                  ? (data['data'] ?? data['activities'] ?? [])
                  : []);
          _activities = List<Map<String, dynamic>>.from(raw);
        }
        if (results[1]['success'] == true) {
          final data = results[1]['data'];
          List raw = data is List
              ? data
              : (data is Map
                  ? (data['data'] ?? data['bookings'] ?? [])
                  : []);
          _myBookings = List<Map<String, dynamic>>.from(raw);
        }
      } else {
        final hotelId =
            widget.arguments?['hotel_id']?.toString() ?? '';
        final results = await Future.wait([
          ApiService.get(
              '${ApiConfig.hotelActivitiesEndpoint}/$hotelId/activities'),
          ApiService.get(ApiConfig.activitiesMyEndpoint,
              token: token),
        ]);
        if (results[0]['success'] == true) {
          final data = results[0]['data'];
          List raw = data is List
              ? data
              : (data is Map
                  ? (data['data'] ?? data['activities'] ?? [])
                  : []);
          _activities = List<Map<String, dynamic>>.from(raw);
        }
        if (results[1]['success'] == true) {
          final data = results[1]['data'];
          List raw = data is List
              ? data
              : (data is Map
                  ? (data['data'] ?? data['bookings'] ?? [])
                  : []);
          _myBookings = List<Map<String, dynamic>>.from(raw);
        }
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() {
        _error = 'Failed to load activities';
        _loading = false;
      });
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
            widget.isOwner
                ? 'Manage Activities'
                : 'Activities & Experiences',
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          if (widget.isOwner)
            IconButton(
                icon: const Icon(Icons.add_rounded,
                    color: AppColors.primary),
                onPressed: _showCreateDialog),
          IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.darkGray),
              onPressed: _load),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          tabs: [
            const Tab(text: 'Activities'),
            Tab(
                text: widget.isOwner
                    ? 'Bookings'
                    : 'My Bookings'),
          ],
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildActivitiesTab(),
                    _buildBookingsTab(),
                  ],
                ),
    );
  }

  Widget _buildActivitiesTab() {
    if (_activities.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(24)),
                child: const Icon(Icons.kayaking_rounded,
                    size: 40, color: AppColors.teal),
              ),
              const SizedBox(height: 20),
              const Text('No Activities',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 8),
              Text(
                  widget.isOwner
                      ? 'Add activities like yoga, trekking, or city tours.'
                      : 'No activities available at this hotel.',
                  style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray,
                      height: 1.5),
                  textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _activities.length,
      itemBuilder: (_, i) => _buildActivityCard(_activities[i]),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.cardShadow),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
                color: AppColors.tealLight,
                borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.kayaking_rounded,
                color: AppColors.teal, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity['name'] ?? '',
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkGray)),
                Text(
                    '${activity['duration_minutes'] ?? 0} min · Max ${activity['max_participants'] ?? 0} people',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.gray)),
                Text('NPR ${activity['price'] ?? 0}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ),
          if (widget.isOwner)
            PopupMenuButton<String>(
              onSelected: (action) async {
                if (action == 'delete') {
                  final prefs =
                      await SharedPreferences.getInstance();
                  final token = prefs.getString('authToken');
                  await ApiService.delete(
                      '${ApiConfig.ownerActivitiesEndpoint}/${activity['id']}',
                      token: token);
                  _load();
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(
                    value: 'delete',
                    child: Text('Delete',
                        style: TextStyle(color: AppColors.error))),
              ],
            )
          else
            ElevatedButton(
              onPressed: () => _showBookDialog(activity),
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.teal,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 8),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10))),
              child: const Text('Book',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }

  Widget _buildBookingsTab() {
    if (_myBookings.isEmpty) {
      return const Center(
          child: Text('No activity bookings yet',
              style: TextStyle(color: AppColors.gray)));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _myBookings.length,
      itemBuilder: (_, i) {
        final b = _myBookings[i];
        final status = b['status'] ?? 'pending';
        final statusColor = status == 'confirmed'
            ? AppColors.success
            : status == 'cancelled'
                ? AppColors.error
                : AppColors.warning;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppColors.cardShadow),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.kayaking_rounded,
                    color: AppColors.teal, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        b['activity_name'] ??
                            b['activity']?['name'] ??
                            'Activity',
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.darkGray)),
                    Text(
                        '${b['date'] ?? ''} · ${b['participants'] ?? 1} participants',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.gray)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20)),
                    child: Text(status.toUpperCase(),
                        style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: statusColor)),
                  ),
                  if (widget.isOwner && status == 'pending') ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () async {
                        final prefs =
                            await SharedPreferences.getInstance();
                        final token = prefs.getString('authToken');
                        await ApiService.put(
                          '${ApiConfig.ownerActivityBookingStatusEndpoint}/${b['id']}/status',
                          data: {'status': 'confirmed'},
                          token: token,
                        );
                        _load();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                            color: AppColors.successLight,
                            borderRadius: BorderRadius.circular(8)),
                        child: const Text('Confirm',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: AppColors.success)),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showBookDialog(Map<String, dynamic> activity) {
    final dateCtrl = TextEditingController();
    final participantsCtrl = TextEditingController(text: '1');
    final bookingIdCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              Text('Book: ${activity['name']}',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 16),
              _field('Booking ID', bookingIdCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _field('Date (YYYY-MM-DD)', dateCtrl),
              const SizedBox(height: 10),
              _field('Participants', participantsCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    Navigator.pop(context);
                    final prefs =
                        await SharedPreferences.getInstance();
                    final token = prefs.getString('authToken');
                    final response = await ApiService.post(
                      ApiConfig.activitiesBookEndpoint,
                      data: {
                        'activity_id': activity['id'],
                        'booking_id': int.tryParse(
                                bookingIdCtrl.text) ??
                            0,
                        'date': dateCtrl.text,
                        'participants': int.tryParse(
                                participantsCtrl.text) ??
                            1,
                      },
                      token: token,
                    );
                    if (response['success'] == true) {
                      _load();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Activity booked!'),
                              backgroundColor: AppColors.success),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.teal,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  child: const Text('Confirm Booking',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showCreateDialog() {
    final nameCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final durationCtrl = TextEditingController();
    final maxCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Create Activity',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 16),
              _field('Activity Name', nameCtrl),
              const SizedBox(height: 10),
              _field('Description', descCtrl, maxLines: 2),
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                    child: _field('Price (NPR)', priceCtrl,
                        keyboardType: TextInputType.number)),
                const SizedBox(width: 10),
                Expanded(
                    child: _field('Duration (min)', durationCtrl,
                        keyboardType: TextInputType.number)),
              ]),
              const SizedBox(height: 10),
              _field('Max Participants', maxCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final prefs =
                      await SharedPreferences.getInstance();
                  final token = prefs.getString('authToken');
                  await ApiService.post(
                    ApiConfig.ownerActivitiesEndpoint,
                    data: {
                      'name': nameCtrl.text,
                      'description': descCtrl.text,
                      'price':
                          double.tryParse(priceCtrl.text) ?? 0,
                      'duration_minutes':
                          int.tryParse(durationCtrl.text) ?? 60,
                      'max_participants':
                          int.tryParse(maxCtrl.text) ?? 10,
                    },
                    token: token,
                  );
                  _load();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.teal,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Create Activity',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      {int maxLines = 1, TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.placeholder),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.gray),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
