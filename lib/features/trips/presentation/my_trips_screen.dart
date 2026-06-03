import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/booking_service.dart';
import '../../../core/widgets/cached_image.dart';
import '../../../core/widgets/common_header.dart';

class MyTripsScreen extends StatefulWidget {
  const MyTripsScreen({Key? key}) : super(key: key);

  @override
  State<MyTripsScreen> createState() => _MyTripsScreenState();
}

class _MyTripsScreenState extends State<MyTripsScreen> with SingleTickerProviderStateMixin {
  final BookingService _bookingService = BookingService();
  late TabController _tabController;
  
  List<Map<String, dynamic>> _bookings = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    setState(() { _loading = true; _error = null; });
    try {
      final result = await _bookingService.getMyBookings();
      if (result['success'] == true) {
        setState(() {
          _bookings = (result['bookings'] as List).cast<Map<String, dynamic>>();
          _loading = false;
        });
      } else {
        setState(() { _error = result['message'] ?? 'Failed to load bookings'; _loading = false; });
      }
    } catch (e) {
      setState(() { _error = 'Failed to load bookings'; _loading = false; });
    }
  }

  List<Map<String, dynamic>> _filterByStatus(String status) {
    if (status == 'upcoming') {
      return _bookings.where((b) => b['status'] == 'confirmed' || b['status'] == 'pending').toList();
    } else if (status == 'completed') {
      return _bookings.where((b) => b['status'] == 'completed').toList();
    } else if (status == 'cancelled') {
      return _bookings.where((b) => b['status'] == 'cancelled').toList();
    }
    return [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          const CommonHeader(title: 'My Trips'),
          TabBar(
            controller: _tabController,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.gray,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            tabs: const [Tab(text: 'Upcoming'), Tab(text: 'Completed'), Tab(text: 'Cancelled')],
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _error != null
                    ? _buildError()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildBookingList(_filterByStatus('upcoming')),
                          _buildBookingList(_filterByStatus('completed')),
                          _buildBookingList(_filterByStatus('cancelled')),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBookingList(List<Map<String, dynamic>> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.business_center_outlined, size: 64, color: AppColors.placeholder.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text('No bookings found', style: TextStyle(fontSize: 16, color: AppColors.gray, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBookings,
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildBookingCard(list[i]),
      ),
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {
    final hotel = booking['hotel'] ?? {};
    final status = booking['status']?.toString().toUpperCase() ?? 'PENDING';
    final color = status == 'CONFIRMED' ? Colors.green : status == 'CANCELLED' ? Colors.red : Colors.orange;

    return GestureDetector(
      onTap: () => context.push('/booking-detail', extra: {'bookingId': booking['id']}),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: AppCachedImage(
                      url: hotel['image'] ?? '',
                      width: 80, height: 80, fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                              child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color)),
                            ),
                            Text('#${booking['booking_id'] ?? booking['id']}', style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(hotel['name'] ?? 'Hotel Name', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                        const SizedBox(height: 4),
                        Text('${booking['check_in_date']} - ${booking['check_out_date']}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: Color(0xFFF0F0F0)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total Paid: ₹${booking['total_amount']}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const Text('View Details', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(duration: 300.ms),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_error ?? 'Unknown error', style: const TextStyle(fontSize: 16, color: AppColors.gray)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadBookings,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
