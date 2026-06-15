import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_model.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../hotel/presentation/services/hotel_service.dart';
import 'yearly_calendar_screen.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});
  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  bool _initDone = false;

  static const _monthNames = [
    '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  static const _dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initDone) {
      _initDone = true;
      _initCalendar();
    }
  }

  Future<void> _initCalendar() async {
    final provider = context.read<CalendarProvider>();
    final auth = context.read<AuthProvider>();
    if (auth.token != null) {
      HotelService.setToken(auth.token!);
      try {
        final hotelService = HotelService();
        final hotelData = await hotelService.getHotelStatus();
        if (hotelData['success'] == true && hotelData['data'] != null) {
          final hotelId = hotelData['data']['id']?.toString() ?? '';
          provider.setHotelId(hotelId);
          await provider.loadCalendarData();
          await provider.loadCalendarAnalytics();
        }
      } catch (_) {
        // Use empty state gracefully
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CalendarProvider>();
    final summary = provider.getMonthSummary();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.darkGray,
        title: const Text('Booking Calendar', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_view_month_rounded, color: AppColors.darkGray),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const YearlyCalendarScreen())),
            tooltip: 'Yearly View',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray),
            onPressed: () => provider.refresh(),
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: () => provider.refresh(),
              color: AppColors.primary,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Column(children: [
                  _buildMonthHeader(provider),
                  _buildMonthStats(summary),
                  _buildCalendarGrid(provider),
                  if (provider.selectedDate != null)
                    _buildSelectedDayDetail(provider),
                  const SizedBox(height: 24),
                ]),
              ),
            ),
    );
  }

  // ── Month navigation header ───────────────────────────────────────────────
  Widget _buildMonthHeader(CalendarProvider provider) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        GestureDetector(
          onTap: provider.previousMonth,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.chevron_left_rounded, color: AppColors.darkGray),
          ),
        ),
        Expanded(
          child: Column(children: [
            Text(
              '${_monthNames[provider.currentMonth]} ${provider.currentYear}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.darkGray),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 2),
            GestureDetector(
              onTap: () {
                final now = DateTime.now();
                provider.navigateToMonth(now.month, now.year);
              },
              child: const Text('Today', style: TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w600)),
            ),
          ]),
        ),
        GestureDetector(
          onTap: provider.nextMonth,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.chevron_right_rounded, color: AppColors.darkGray),
          ),
        ),
      ]),
    );
  }

  // ── Month stats strip ─────────────────────────────────────────────────────
  Widget _buildMonthStats(Map<String, dynamic> summary) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      child: Row(children: [
        _statChip('${summary['totalBookings']}', 'Bookings', AppColors.primary),
        const SizedBox(width: 8),
        _statChip('NPR ${_fmtAmount((summary['totalRevenue'] as double?) ?? 0)}', 'Revenue', AppColors.success),
        const SizedBox(width: 8),
        _statChip('${((summary['averageOccupancy'] as double?) ?? 0).toStringAsFixed(0)}%', 'Occupancy', AppColors.warning),
        const SizedBox(width: 8),
        _statChip('${summary['blockedDays']}', 'Blocked', AppColors.error),
      ]),
    );
  }

  Widget _statChip(String value, String label, Color color) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
      child: Column(children: [
        Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: color)),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.gray, fontWeight: FontWeight.w500)),
      ]),
    ),
  );

  // ── Calendar grid ─────────────────────────────────────────────────────────
  Widget _buildCalendarGrid(CalendarProvider provider) {
    final days = provider.getDaysInMonth();
    final firstWeekday = provider.getFirstDayOfWeek(); // 1=Mon, 7=Sun
    final paddingDays = firstWeekday - 1;
    final today = DateTime.now();
    final selectedDate = provider.selectedDate;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(children: [
        // Day name headers
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
          child: Row(
            children: _dayNames.map((d) => Expanded(child: Center(
              child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.gray)),
            ))).toList(),
          ),
        ),
        // Grid
        GridView.builder(
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7, crossAxisSpacing: 2, mainAxisSpacing: 2, childAspectRatio: 0.85,
          ),
          itemCount: paddingDays + days.length,
          itemBuilder: (_, i) {
            if (i < paddingDays) return const SizedBox();
            final day = days[i - paddingDays];
            final dailyData = provider.getDailyData(day);
            final isToday = day.year == today.year && day.month == today.month && day.day == today.day;
            final isSelected = selectedDate != null && day.year == selectedDate.year && day.month == selectedDate.month && day.day == selectedDate.day;
            final isPast = day.isBefore(DateTime(today.year, today.month, today.day));
            return _buildDayCell(day, dailyData, isToday, isSelected, isPast, provider);
          },
        ),
      ]),
    );
  }

  Widget _buildDayCell(DateTime day, CalendarDailyData? data, bool isToday, bool isSelected, bool isPast, CalendarProvider provider) {
    final isBlocked = data?.isBlocked ?? false;
    final hasBookings = (data?.totalBookings ?? 0) > 0;
    final availableRooms = data?.availableRooms ?? 0;
    final occupancyRate = data?.occupancyRate ?? 0;

    Color bgColor = Colors.transparent;
    Color textColor = isPast ? AppColors.placeholder : AppColors.darkGray;

    if (isSelected) {
      bgColor = AppColors.primary;
      textColor = Colors.white;
    } else if (isToday) {
      bgColor = AppColors.primary.withOpacity(0.12);
      textColor = AppColors.primary;
    } else if (isBlocked) {
      bgColor = AppColors.errorLight;
      textColor = AppColors.error;
    } else if (occupancyRate >= 90) {
      bgColor = AppColors.successLight;
    } else if (hasBookings) {
      bgColor = AppColors.infoLight;
    }

    // Determine dot color
    Color? dotColor;
    if (!isSelected && hasBookings) dotColor = isBlocked ? AppColors.error : AppColors.success;

    return GestureDetector(
      onTap: () => provider.selectDate(day),
      onLongPress: isPast ? null : () => _showBlockDateMenu(day, isBlocked, provider),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(8)),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Text(
            '${day.day}',
            style: TextStyle(fontSize: 13, fontWeight: isToday || isSelected ? FontWeight.w800 : FontWeight.w500, color: textColor),
          ),
          if (dotColor != null) ...[
            const SizedBox(height: 2),
            Container(width: 5, height: 5, decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle)),
          ],
        ]),
      ),
    );
  }

  // ── Selected day detail ───────────────────────────────────────────────────
  Widget _buildSelectedDayDetail(CalendarProvider provider) {
    final day = provider.selectedDate;
    final data = provider.getDailyData(day!);
    final isBlocked = data?.isBlocked ?? false;
    final today = DateTime.now();
    final isPast = day.isBefore(DateTime(today.year, today.month, today.day));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${day.day} ${_monthNames[day.month]} ${day.year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          if (!isPast)
            GestureDetector(
              onTap: () => _showBlockDateMenu(day, isBlocked, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isBlocked ? AppColors.errorLight : AppColors.successLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(isBlocked ? Icons.lock_rounded : Icons.lock_open_rounded, size: 14, color: isBlocked ? AppColors.error : AppColors.success),
                  const SizedBox(width: 4),
                  Text(isBlocked ? 'Blocked' : 'Available', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: isBlocked ? AppColors.error : AppColors.success)),
                ]),
              ),
            ),
        ]),
        const SizedBox(height: 14),
        if (data != null) ...[
          _dayDetailRow('Bookings', '${data.totalBookings}', Icons.calendar_today_rounded, AppColors.primary),
          _dayDetailRow('Available Rooms', '${data.availableRooms}', Icons.meeting_room_rounded, AppColors.success),
          _dayDetailRow('Occupancy', '${data.occupancyRate.toStringAsFixed(0)}%', Icons.percent_rounded, AppColors.warning),
          if (data.totalRevenue > 0) _dayDetailRow('Revenue', 'NPR ${_fmtAmount(data.totalRevenue)}', Icons.account_balance_wallet_rounded, AppColors.info),
        ] else
          const Center(child: Text('No data for this date', style: TextStyle(color: AppColors.gray, fontSize: 13))),
      ]),
    );
  }

  Widget _dayDetailRow(String label, String value, IconData icon, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(children: [
      Container(width: 32, height: 32, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: Icon(icon, size: 16, color: color)),
      const SizedBox(width: 12),
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray))),
      Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
    ]),
  );

  void _showBlockDateMenu(DateTime date, bool isCurrentlyBlocked, CalendarProvider provider) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: AppColors.lightGray, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          Text('${date.day} ${_monthNames[date.month]}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 16),
          if (isCurrentlyBlocked)
            _sheetAction(Icons.lock_open_rounded, 'Unblock Date', AppColors.success, () async {
              Navigator.pop(context);
              await provider.blockDates(dates: [date], isBlocked: false);
            })
          else
            _sheetAction(Icons.block_rounded, 'Block Date', AppColors.error, () async {
              Navigator.pop(context);
              await provider.blockDates(dates: [date], isBlocked: true, reason: 'Blocked by owner');
            }),
          const SizedBox(height: 10),
          _sheetAction(Icons.price_change_rounded, 'Set Custom Price', AppColors.primary, () {
            Navigator.pop(context);
            _showPriceDialog(date, provider);
          }),
        ]),
      ),
    );
  }

  Widget _sheetAction(IconData icon, String label, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(children: [
        Icon(icon, color: color, size: 22),
        const SizedBox(width: 14),
        Text(label, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: color)),
      ]),
    ),
  );

  void _showPriceDialog(DateTime date, CalendarProvider provider) {
    final ctrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Set Price for ${date.day} ${_monthNames[date.month]}', style: const TextStyle(fontWeight: FontWeight.w700)),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Price per night (NPR)',
            prefixText: 'NPR ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final price = double.tryParse(ctrl.text);
              if (price != null) {
                Navigator.pop(context);
                await provider.updatePricing(date: date, roomPrices: {'default': price});
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Price updated'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0),
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  String _fmtAmount(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}
