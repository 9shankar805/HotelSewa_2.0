import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';

class DatePickerScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const DatePickerScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<DatePickerScreen> createState() => _DatePickerScreenState();
}

class _DatePickerScreenState extends State<DatePickerScreen> {
  DateTime? _checkIn;
  DateTime? _checkOut;
  bool _selectingCheckIn = true;
  late DateTime _displayMonth;

  @override
  void initState() {
    super.initState();
    _displayMonth = DateTime.now();
    final args = widget.arguments ?? {};
    if (args['checkIn'] != null) {
      try { _checkIn = DateTime.parse(args['checkIn']); } catch (_) {}
    }
    if (args['checkOut'] != null) {
      try { _checkOut = DateTime.parse(args['checkOut']); } catch (_) {}
    }
  }

  int get _nights {
    if (_checkIn == null || _checkOut == null) return 0;
    return _checkOut!.difference(_checkIn!).inDays;
  }

  void _onDayTap(DateTime day) {
    if (day.isBefore(DateTime.now().subtract(const Duration(days: 1)))) return;
    setState(() {
      if (_selectingCheckIn || (_checkIn != null && day.isBefore(_checkIn!))) {
        _checkIn = day;
        _checkOut = null;
        _selectingCheckIn = false;
      } else {
        if (_checkIn != null && day.isAtSameMomentAs(_checkIn!)) return;
        _checkOut = day;
        _selectingCheckIn = true;
      }
    });
  }

  bool _isInRange(DateTime day) {
    if (_checkIn == null || _checkOut == null) return false;
    return day.isAfter(_checkIn!) && day.isBefore(_checkOut!);
  }

  bool _isCheckIn(DateTime day) => _checkIn != null && _isSameDay(day, _checkIn!);
  bool _isCheckOut(DateTime day) => _checkOut != null && _isSameDay(day, _checkOut!);
  bool _isSameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;
  bool _isPast(DateTime day) => day.isBefore(DateTime.now().subtract(const Duration(days: 1)));

  String _fmt(DateTime? d) {
    if (d == null) return '—';
    return '${d.day} ${_months[d.month - 1]} ${d.year}';
  }

  final _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  final _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Select Dates', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Check-in / Check-out summary
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(child: _dateChip('Check-in', _fmt(_checkIn), _selectingCheckIn, () => setState(() { _selectingCheckIn = true; _checkOut = null; }))),
                Container(width: 1, height: 40, color: AppColors.lightGray, margin: const EdgeInsets.symmetric(horizontal: 12)),
                Expanded(child: _dateChip('Check-out', _fmt(_checkOut), !_selectingCheckIn && _checkIn != null, () {
                  if (_checkIn != null) setState(() => _selectingCheckIn = false);
                })),
              ],
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  _buildCalendar(_displayMonth),
                  _buildCalendar(DateTime(_displayMonth.year, _displayMonth.month + 1)),
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: Column(
              children: [
                if (_nights > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text('$_nights night${_nights > 1 ? 's' : ''} selected',
                        style: const TextStyle(fontSize: 14, color: AppColors.gray)),
                  ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkIn != null && _checkOut != null
                        ? () => Navigator.pop(context, {'checkIn': _checkIn!.toIso8601String(), 'checkOut': _checkOut!.toIso8601String(), 'nights': _nights})
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      disabledBackgroundColor: AppColors.lightGray,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: const Text('Apply Dates', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dateChip(String label, String value, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: active ? AppColors.primary.withOpacity(0.08) : AppColors.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: active ? AppColors.primary : AppColors.lightGray, width: active ? 1.5 : 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: active ? AppColors.primary : AppColors.gray, fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: active ? AppColors.primary : AppColors.darkGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendar(DateTime month) {
    final firstDay = DateTime(month.year, month.month, 1);
    final daysInMonth = DateTime(month.year, month.month + 1, 0).day;
    final startWeekday = (firstDay.weekday - 1) % 7;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('${_months[month.month - 1]} ${month.year}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: _weekdays.map((d) => Expanded(
              child: Center(child: Text(d, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.gray))),
            )).toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 7, childAspectRatio: 1),
            itemCount: startWeekday + daysInMonth,
            itemBuilder: (_, i) {
              if (i < startWeekday) return const SizedBox();
              final day = DateTime(month.year, month.month, i - startWeekday + 1);
              final isCI = _isCheckIn(day);
              final isCO = _isCheckOut(day);
              final inRange = _isInRange(day);
              final past = _isPast(day);

              return GestureDetector(
                onTap: () => _onDayTap(day),
                child: Container(
                  margin: const EdgeInsets.all(1),
                  decoration: BoxDecoration(
                    color: isCI || isCO ? AppColors.primary : inRange ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(
                    child: Text(
                      '${day.day}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isCI || isCO ? FontWeight.w700 : FontWeight.w400,
                        color: isCI || isCO ? Colors.white : past ? AppColors.placeholder : inRange ? AppColors.primary : AppColors.darkGray,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
