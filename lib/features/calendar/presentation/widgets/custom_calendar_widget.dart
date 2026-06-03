import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/calendar_provider.dart';
import '../models/calendar_model.dart';
import '../../../../core/constants/app_colors.dart';

class CustomCalendarWidget extends StatefulWidget {
  final Function(DateTime) onDateSelected;

  const CustomCalendarWidget({
    super.key,
    required this.onDateSelected,
  });

  @override
  State<CustomCalendarWidget> createState() => _CustomCalendarWidgetState();
}

class _CustomCalendarWidgetState extends State<CustomCalendarWidget> {
  @override
  Widget build(BuildContext context) {
    return Consumer<CalendarProvider>(
      builder: (context, calendarProvider, child) {
        final daysInMonth = calendarProvider.getDaysInMonth();
        final firstDayOfWeek = calendarProvider.getFirstDayOfWeek();

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Weekday headers
              _buildWeekdayHeaders(),
              const SizedBox(height: 8),

              // Calendar grid
              _buildCalendarGrid(daysInMonth, firstDayOfWeek, calendarProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildWeekdayHeaders() {
    final weekdays = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

    return Row(
      children: weekdays.map((weekday) {
        return Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              weekday,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Color(0xFF666666),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCalendarGrid(List<DateTime> daysInMonth, int firstDayOfWeek,
      CalendarProvider calendarProvider) {
    return Column(
      children: List.generate(6, (weekIndex) {
        return Row(
          children: List.generate(7, (colIndex) {
            final cellIndex = weekIndex * 7 + colIndex;

            // Empty cells before month starts
            if (cellIndex < firstDayOfWeek - 1) {
              return const Expanded(child: SizedBox());
            }

            // Calculate actual day index
            final dayNumber = cellIndex - (firstDayOfWeek - 1);

            // Empty cells after month ends
            if (dayNumber >= daysInMonth.length) {
              return const Expanded(child: SizedBox());
            }

            final date = daysInMonth[dayNumber];
            final dailyData = calendarProvider.getDailyData(date);
            final isSelected =
                calendarProvider.selectedDate.year == date.year &&
                    calendarProvider.selectedDate.month == date.month &&
                    calendarProvider.selectedDate.day == date.day;
            final isToday = _isToday(date);

            return Expanded(
              child: _buildCalendarCell(
                date: date,
                dailyData: dailyData,
                isSelected: isSelected,
                isToday: isToday,
                onTap: () => widget.onDateSelected(date),
              ),
            );
          }),
        );
      }),
    );
  }

  Widget _buildCalendarCell({
    required DateTime date,
    required CalendarDailyData? dailyData,
    required bool isSelected,
    required bool isToday,
    required VoidCallback onTap,
  }) {
    final availabilityStatus =
        dailyData?.availabilityStatus ?? CalendarAvailabilityStatus.available;
    final color = _getStatusColor(availabilityStatus);
    final isPast =
        date.isBefore(DateTime.now().subtract(const Duration(days: 1)));

    return GestureDetector(
      onTap: isPast ? null : onTap,
      child: Container(
        margin: const EdgeInsets.all(2),
        height: 50,
        decoration: BoxDecoration(
          color: isPast ? AppColors.gray[100] : color.withOpacity(0.1),
          border: Border.all(
            color: isSelected
                ? const Color(0xFFE60023)
                : isToday
                    ? const Color(0xFFE60023).withOpacity(0.5)
                    : AppColors.lightGray!,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          children: [
            // Day number
            Positioned(
              top: 4,
              left: 4,
              child: Text(
                date.day.toString(),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected || isToday
                      ? FontWeight.bold
                      : FontWeight.normal,
                  color: isPast
                      ? AppColors.gray[400]
                      : isSelected
                          ? const Color(0xFFE60023)
                          : AppColors.darkGray,
                ),
              ),
            ),

            // Status indicator
            if (dailyData != null && !isPast) ...[
              Positioned(
                bottom: 2,
                right: 2,
                child: _buildStatusIndicator(dailyData),
              ),
            ],

            // Today indicator
            if (isToday && !isSelected)
              Positioned(
                bottom: 2,
                left: 2,
                child: Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE60023),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(CalendarDailyData dailyData) {
    if (dailyData.isBlocked) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.gray,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.block,
          size: 12,
          color: Colors.white,
        ),
      );
    }

    if (dailyData.availableRooms == 0) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.error,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.close,
          size: 12,
          color: Colors.white,
        ),
      );
    }

    if (dailyData.occupancyRate >= 0.8) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.warning,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.warning,
          size: 12,
          color: Colors.white,
        ),
      );
    }

    if (dailyData.totalBookings > 0) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: AppColors.success,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Icon(
          Icons.check,
          size: 12,
          color: Colors.white,
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Color _getStatusColor(CalendarAvailabilityStatus status) {
    switch (status) {
      case CalendarAvailabilityStatus.available:
        return AppColors.success;
      case CalendarAvailabilityStatus.limited:
        return AppColors.warning;
      case CalendarAvailabilityStatus.full:
        return AppColors.error;
      case CalendarAvailabilityStatus.blocked:
        return AppColors.gray;
    }
  }

  bool _isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year &&
        date.month == now.month &&
        date.day == now.day;
  }
}
