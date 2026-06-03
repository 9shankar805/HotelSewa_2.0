import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../../../../core/constants/app_colors.dart';

class YearlyCalendarScreen extends StatefulWidget {
  const YearlyCalendarScreen({super.key});
  @override
  State<YearlyCalendarScreen> createState() => _YearlyCalendarScreenState();
}

class _YearlyCalendarScreenState extends State<YearlyCalendarScreen> {
  int _year = DateTime.now().year;

  // Mock occupancy data per month — replace with real API data when available
  final Map<String, double> _occupancy = {
    '1': 0.62, '2': 0.71, '3': 0.85, '4': 0.78,
    '5': 0.55, '6': 0.48, '7': 0.90, '8': 0.88,
    '9': 0.73, '10': 0.66, '11': 0.80, '12': 0.95,
  };

  // Mock blocked dates
  final Set<String> _blocked = {'2025-3-15', '2025-3-16', '2025-7-4', '2025-12-25', '2025-12-26'};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yearly Calendar'),
        actions: [
          IconButton(icon: const Icon(Icons.today_rounded), onPressed: () => setState(() => _year = DateTime.now().year), tooltip: 'Go to current year'),
        ],
      ),
      body: Column(
        children: [
          // Year navigator
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  onPressed: () => setState(() => _year--),
                  icon: const Icon(Icons.chevron_left_rounded),
                  style: IconButton.styleFrom(backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray)),
                ),
                Text('$_year', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
                IconButton(
                  onPressed: () => setState(() => _year++),
                  icon: const Icon(Icons.chevron_right_rounded),
                  style: IconButton.styleFrom(backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray)),
                ),
              ],
            ),
          ),
          // Legend
          Container(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                _legendDot(const Color(AppConstants.successGreen), 'Available'),
                const SizedBox(width: 16),
                _legendDot(const Color(AppConstants.warningOrange), 'Moderate'),
                const SizedBox(width: 16),
                _legendDot(const Color(AppConstants.primaryRed), 'High demand'),
                const SizedBox(width: 16),
                _legendDot(AppColors.gray, 'Blocked'),
              ],
            ),
          ),
          const Divider(height: 1),
          // 12-month grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.85,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: 12,
              itemBuilder: (_, i) => _buildMonthCard(i + 1, isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMonthCard(int month, bool isDark) {
    final occ = _occupancy[month.toString()] ?? 0.0;
    final now = DateTime.now();
    final isCurrentMonth = now.year == _year && now.month == month;
    final daysInMonth = DateUtils.getDaysInMonth(_year, month);
    final firstWeekday = DateTime(_year, month, 1).weekday % 7; // 0=Sun

    Color occColor;
    if (occ >= 0.85) occColor = const Color(AppConstants.primaryRed);
    else if (occ >= 0.65) occColor = const Color(AppConstants.warningOrange);
    else occColor = const Color(AppConstants.successGreen);

    return GestureDetector(
      onTap: () => _showMonthDetail(month),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isCurrentMonth ? const Color(AppConstants.primaryRed) : (isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE)),
            width: isCurrentMonth ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Month header
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 10, 10, 6),
              child: Row(
                children: [
                  Text(
                    DateFormat('MMM').format(DateTime(_year, month)),
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isCurrentMonth ? const Color(AppConstants.primaryRed) : (isDark ? Colors.white : Colors.black)),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: occColor.withOpacity(0.12), borderRadius: BorderRadius.circular(6)),
                    child: Text('${(occ * 100).toInt()}%', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: occColor)),
                  ),
                ],
              ),
            ),
            // Day headers
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) =>
                  Text(d, style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w600, color: Color(AppConstants.mediumGray)))
                ).toList(),
              ),
            ),
            const SizedBox(height: 2),
            // Day grid
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, mainAxisSpacing: 1, crossAxisSpacing: 1),
                  itemCount: firstWeekday + daysInMonth,
                  itemBuilder: (_, idx) {
                    if (idx < firstWeekday) return const SizedBox();
                    final day = idx - firstWeekday + 1;
                    final dateKey = '$_year-$month-$day';
                    final isBlocked = _blocked.contains(dateKey);
                    final isToday = now.year == _year && now.month == month && now.day == day;

                    Color? bg;
                    if (isBlocked) bg = AppColors.gray.withOpacity(0.3);
                    else if (isToday) bg = const Color(AppConstants.primaryRed);

                    return Container(
                      margin: const EdgeInsets.all(0.5),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
                            color: isToday ? Colors.white : isBlocked ? AppColors.gray : (isDark ? Colors.white70 : const Color(AppConstants.darkGray)),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            // Occupancy bar
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: occ,
                  minHeight: 4,
                  backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray),
                  valueColor: AlwaysStoppedAnimation<Color>(occColor),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Color(AppConstants.mediumGray))),
      ],
    );
  }

  void _showMonthDetail(int month) {
    final occ = _occupancy[month.toString()] ?? 0.0;
    final monthName = DateFormat('MMMM yyyy').format(DateTime(_year, month));
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monthName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _statRow('Occupancy Rate', '${(occ * 100).toInt()}%'),
            _statRow('Est. Revenue', 'Rs. ${(occ * 450000).toStringAsFixed(0)}'),
            _statRow('Blocked Days', _blocked.where((d) => d.startsWith('$_year-$month-')).length.toString()),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryRed), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('View Month Calendar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Color(AppConstants.mediumGray))),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
