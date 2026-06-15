import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../models/booking_model.dart';
import '../providers/booking_provider.dart';
import '../widgets/booking_card.dart';
import '../widgets/booking_filter_chip.dart';
import 'add_booking_screen.dart';

class BookingManagementScreen extends StatefulWidget {
  const BookingManagementScreen({Key? key}) : super(key: key);

  @override
  State<BookingManagementScreen> createState() => _BookingManagementScreenState();
}

class _BookingManagementScreenState extends State<BookingManagementScreen> 
    with RefreshIndicatorHandler {
  String _selectedFilter = 'all';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadBookings();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
    await bookingProvider.loadBookings(filter: _selectedFilter);
  }

  Future<void> _onRefresh() async {
    await _loadBookings();
  }

  void _onFilterChanged(String filter) {
    setState(() {
      _selectedFilter = filter;
    });
    _loadBookings();
  }

  void _onSearchChanged(String query) {
    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        final bookingProvider = Provider.of<BookingProvider>(context, listen: false);
        bookingProvider.searchBookings(query);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Bookings'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.filter_list_rounded), onPressed: _showFilterDialog),
        ],
      ),
      body: Consumer<BookingProvider>(
        builder: (context, provider, child) {
          return RefreshIndicator(
            color: const Color(AppConstants.primaryRed),
            onRefresh: _onRefresh,
            child: Column(
              children: [
                // Search Bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search by guest name or room...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear, size: 18), onPressed: () { _searchController.clear(); provider.clearSearch(); })
                          : null,
                    ),
                  ),
                ),

                // Filter Chips
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      BookingFilterChip(label: 'All', isSelected: _selectedFilter == 'all', onTap: () => _onFilterChanged('all')),
                      const SizedBox(width: 8),
                      BookingFilterChip(label: 'Confirmed', isSelected: _selectedFilter == 'confirmed', onTap: () => _onFilterChanged('confirmed')),
                      const SizedBox(width: 8),
                      BookingFilterChip(label: 'Checked In', isSelected: _selectedFilter == 'checked_in', onTap: () => _onFilterChanged('checked_in')),
                      const SizedBox(width: 8),
                      BookingFilterChip(label: 'Checked Out', isSelected: _selectedFilter == 'checked_out', onTap: () => _onFilterChanged('checked_out')),
                      const SizedBox(width: 8),
                      BookingFilterChip(label: 'Cancelled', isSelected: _selectedFilter == 'cancelled', onTap: () => _onFilterChanged('cancelled')),
                    ],
                  ),
                ),

                const Divider(height: 1),

                // Bookings List
                Expanded(
                  child: provider.isLoading
                      ? _buildSkeleton()
                      : provider.bookings.isEmpty
                          ? _buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.all(16),
                              itemCount: provider.bookings.length,
                              itemBuilder: (context, index) {
                                final booking = provider.bookings[index];
                                return BookingCard(
                                  booking: booking,
                                  onTap: () => _showBookingDetails(booking),
                                  onStatusChange: (newStatus) => _updateBookingStatus(booking.id, newStatus),
                                );
                              },
                            ),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _createNewBooking,
        backgroundColor: const Color(AppConstants.primaryRed),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Container(
          height: 130,
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.book_online_outlined,
            size: 64,
            color: Color(AppConstants.mediumGray),
          ),
          const SizedBox(height: 16),
          Text(
            'No bookings found',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Color(AppConstants.mediumGray),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your filters or search terms',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Color(AppConstants.mediumGray),
            ),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filter Bookings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Date Range'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () {
                Navigator.pop(context);
                _showDateRangePicker();
              },
            ),
            ListTile(
              title: const Text('Room Type'),
              trailing: const Icon(Icons.bed),
              onTap: () {
                Navigator.pop(context);
                _showRoomTypeFilter();
              },
            ),
            ListTile(
              title: const Text('Payment Status'),
              trailing: const Icon(Icons.payment),
              onTap: () {
                Navigator.pop(context);
                _showPaymentStatusFilter();
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showDateRangePicker() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null) {
      final provider = Provider.of<BookingProvider>(context, listen: false);
      await provider.filterByDateRange(picked.start, picked.end);
    }
  }

  void _showRoomTypeFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Room Type', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('All Rooms'),
              onTap: () {
                Navigator.pop(context);
                _onFilterChanged('all');
              },
            ),
            ListTile(
              title: const Text('Deluxe'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filtering by Deluxe rooms...')),
                );
              },
            ),
            ListTile(
              title: const Text('Standard'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Filtering by Standard rooms...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentStatusFilter() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Filter by Payment Status', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.check_circle, color: AppColors.success),
              title: const Text('Paid'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Showing paid bookings...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.pending, color: AppColors.warning),
              title: const Text('Pending'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Showing pending payments...')),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cancel, color: AppColors.error),
              title: const Text('Failed'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Showing failed payments...')),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showBookingDetails(Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (context, scrollController) => _buildBookingDetailsSheet(booking, scrollController),
      ),
    );
  }

  Widget _buildBookingDetailsSheet(Booking booking, ScrollController scrollController) {
    return Container(
      padding: const EdgeInsets.all(AppConstants.defaultPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Color(AppConstants.mediumGray),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Guest Info
          Text(
            'Guest Information',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Name', booking.guestName),
          _buildInfoRow('Email', booking.guestEmail),
          _buildInfoRow('Phone', booking.guestPhone),
          
          const SizedBox(height: 24),
          
          // Booking Info
          Text(
            'Booking Details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),
          _buildInfoRow('Room', booking.roomNumber),
          _buildInfoRow('Check-in', _formatDate(booking.checkIn)),
          _buildInfoRow('Check-out', _formatDate(booking.checkOut)),
          _buildInfoRow('Amount', 'NPR ${booking.amount.toStringAsFixed(0)}'),
          _buildInfoRow('Status', booking.status),
          
          const Spacer(),
          
          // Action Buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _updateBookingStatus(booking.id, 'confirmed');
                  },
                  child: const Text('Confirm'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Color(AppConstants.mediumGray),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  void _updateBookingStatus(String bookingId, String newStatus) async {
    final provider = Provider.of<BookingProvider>(context, listen: false);
    try {
      await provider.updateBookingStatus(bookingId, newStatus);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Booking status updated to $newStatus'),
            backgroundColor: Color(AppConstants.successGreen),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update booking: ${e.toString()}'),
            backgroundColor: Color(AppConstants.errorRed),
          ),
        );
      }
    }
  }

  void _createNewBooking() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => AddBookingScreen()),
    );
  }
}

mixin RefreshIndicatorHandler {
  Future<void> onRefresh() async {}
}
