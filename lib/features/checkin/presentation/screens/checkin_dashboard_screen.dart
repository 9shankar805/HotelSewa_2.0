import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/services/owner/checkin_service.dart';
import '../../../hotel/presentation/services/hotel_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

/// Shows today's expected arrivals and currently checked-in guests.
/// Has a prominent "Scan QR" button to launch the scanner.
class CheckinDashboardScreen extends StatefulWidget {
  const CheckinDashboardScreen({Key? key}) : super(key: key);

  @override
  State<CheckinDashboardScreen> createState() => _CheckinDashboardScreenState();
}

class _CheckinDashboardScreenState extends State<CheckinDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Map<String, dynamic>> _arrivals = [];
  List<Map<String, dynamic>> _activeGuests = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
      final auth = Provider.of<AuthProvider>(context, listen: false);
      HotelService.setToken(auth.token ?? '');
      CheckinService.setToken(auth.token ?? '');

      // Fetch hotel ID from hotel status
      final hotelService = HotelService();
      final hotelResponse = await hotelService.getHotelStatus();
      final hotelId = hotelResponse['data']?['id']?.toString() ?? '';

      final results = await Future.wait([
        CheckinService.getTodayArrivals(hotelId),
        CheckinService.getActiveGuests(hotelId),
      ]);

      setState(() {
        _arrivals = results[0];
        _activeGuests = results[1];
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Check-in / Check-out'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(AppConstants.primaryRed),
          labelColor: const Color(AppConstants.primaryRed),
          unselectedLabelColor: const Color(AppConstants.mediumGray),
          tabs: [
            Tab(
              text: 'Arrivals Today'
                  '${_arrivals.isNotEmpty ? ' (${_arrivals.length})' : ''}',
            ),
            Tab(
              text: 'Active Guests'
                  '${_activeGuests.isNotEmpty ? ' (${_activeGuests.length})' : ''}',
            ),
          ],
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGuestList(_arrivals, isArrival: true),
                    _buildGuestList(_activeGuests, isArrival: false),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/qr-checkin'),
        backgroundColor: const Color(AppConstants.primaryRed),
        icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
        label: const Text('Scan QR',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Color(AppConstants.errorRed)),
          const SizedBox(height: 12),
          Text(_error!, textAlign: TextAlign.center,
              style: const TextStyle(color: Color(AppConstants.mediumGray))),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ],
      ),
    );
  }

  Widget _buildGuestList(List<Map<String, dynamic>> guests,
      {required bool isArrival}) {
    if (guests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isArrival ? Icons.no_luggage_rounded : Icons.hotel_rounded,
              size: 56,
              color: const Color(AppConstants.mediumGray),
            ),
            const SizedBox(height: 12),
            Text(
              isArrival ? 'No arrivals today' : 'No active guests',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: const Color(AppConstants.mediumGray),
                  ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(AppConstants.primaryRed),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: guests.length,
        itemBuilder: (context, index) =>
            _GuestCard(guest: guests[index], isArrival: isArrival),
      ),
    );
  }
}

class _GuestCard extends StatelessWidget {
  final Map<String, dynamic> guest;
  final bool isArrival;

  const _GuestCard({required this.guest, required this.isArrival});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = guest['guest_name']?.toString() ?? 'Guest';
    final room = guest['room_number']?.toString() ?? '—';
    final bookingId = guest['booking_id']?.toString() ?? '—';
    final time = guest['check_in_time']?.toString() ??
        guest['check_out_time']?.toString() ??
        '—';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          CircleAvatar(
            radius: 22,
            backgroundColor: const Color(AppConstants.primaryRed).withOpacity(0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'G',
              style: const TextStyle(
                color: Color(AppConstants.primaryRed),
                fontWeight: FontWeight.w700,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 15)),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.bed_rounded,
                        size: 13, color: Color(AppConstants.mediumGray)),
                    const SizedBox(width: 4),
                    Text('Room $room',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(AppConstants.mediumGray))),
                    const SizedBox(width: 10),
                    const Icon(Icons.confirmation_number_outlined,
                        size: 13, color: Color(AppConstants.mediumGray)),
                    const SizedBox(width: 4),
                    Text('#$bookingId',
                        style: const TextStyle(
                            fontSize: 12,
                            color: Color(AppConstants.mediumGray))),
                  ],
                ),
              ],
            ),
          ),
          // Time badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isArrival
                      ? const Color(AppConstants.successGreen).withOpacity(0.12)
                      : const Color(AppConstants.warningOrange).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isArrival ? 'Arriving' : 'Checked In',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isArrival
                        ? const Color(AppConstants.successGreen)
                        : const Color(AppConstants.warningOrange),
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(time,
                  style: const TextStyle(
                      fontSize: 12, color: Color(AppConstants.mediumGray))),
            ],
          ),
        ],
      ),
    );
  }
}


