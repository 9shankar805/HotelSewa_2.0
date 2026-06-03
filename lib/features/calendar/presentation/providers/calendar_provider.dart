import 'package:flutter/foundation.dart';
import '../models/calendar_model.dart';
import '../services/calendar_api_service.dart';

class CalendarProvider extends ChangeNotifier {
  CalendarData? _calendarData;
  bool _isLoading = false;
  String? _error;
  DateTime _selectedDate = DateTime.now();
  String _hotelId = '';
  int _currentMonth = DateTime.now().month;
  int _currentYear = DateTime.now().year;
  Map<String, List<CalendarBooking>> _bookingsCache = {};
  Map<String, List<CalendarRoomAvailability>> _availabilityCache = {};
  CalendarAnalytics? _analytics;

  // Getters
  CalendarData? get calendarData => _calendarData;
  bool get isLoading => _isLoading;
  String? get error => _error;
  DateTime get selectedDate => _selectedDate;
  String get hotelId => _hotelId;
  int get currentMonth => _currentMonth;
  int get currentYear => _currentYear;
  Map<String, List<CalendarBooking>> get bookingsCache => _bookingsCache;
  Map<String, List<CalendarRoomAvailability>> get availabilityCache =>
      _availabilityCache;
  CalendarAnalytics? get analytics => _analytics;

  /// Set hotel ID
  void setHotelId(String hotelId) {
    _hotelId = hotelId;
    notifyListeners();
  }

  /// Navigate to previous month
  void previousMonth() {
    if (_currentMonth == 1) {
      _currentMonth = 12;
      _currentYear--;
    } else {
      _currentMonth--;
    }
    _loadCalendarData();
    notifyListeners();
  }

  /// Navigate to next month
  void nextMonth() {
    if (_currentMonth == 12) {
      _currentMonth = 1;
      _currentYear++;
    } else {
      _currentMonth++;
    }
    _loadCalendarData();
    notifyListeners();
  }

  /// Navigate to specific month
  void navigateToMonth(int month, int year) {
    _currentMonth = month;
    _currentYear = year;
    _loadCalendarData();
    notifyListeners();
  }

  /// Select a specific date
  void selectDate(DateTime date) {
    _selectedDate = date;
    notifyListeners();
  }

  /// Load calendar data for current month
  Future<void> loadCalendarData() async {
    if (_hotelId.isEmpty) {
      _setError('Hotel ID not set');
      return;
    }

    await _loadCalendarDataForMonth(_currentMonth, _currentYear);
  }

  /// Load calendar data for current month (called internally)
  Future<void> _loadCalendarData() async {
    await _loadCalendarDataForMonth(_currentMonth, _currentYear);
  }

  /// Load calendar data for specific month
  Future<void> _loadCalendarDataForMonth(int month, int year) async {
    _setLoading(true);
    _clearError();

    try {
      final data = await CalendarApiService.getCalendarData(
        hotelId: _hotelId,
        month: month,
        year: year,
      );

      _calendarData = data;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load calendar data: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Get bookings for a specific date
  Future<List<CalendarBooking>> getBookingsForDate(DateTime date) async {
    final dateKey = _formatDateKey(date);

    // Check cache first
    if (_bookingsCache.containsKey(dateKey)) {
      return _bookingsCache[dateKey]!;
    }

    try {
      final bookings = await CalendarApiService.getBookingsForDate(
        hotelId: _hotelId,
        date: date,
      );

      _bookingsCache[dateKey] = bookings;
      notifyListeners();

      return bookings;
    } catch (e) {
      debugPrint('Error fetching bookings for date: $e');
      return [];
    }
  }

  /// Get room availability for a specific date
  Future<List<CalendarRoomAvailability>> getRoomAvailabilityForDate(
      DateTime date) async {
    final dateKey = _formatDateKey(date);

    // Check cache first
    if (_availabilityCache.containsKey(dateKey)) {
      return _availabilityCache[dateKey]!;
    }

    try {
      final availability = await CalendarApiService.getRoomAvailability(
        hotelId: _hotelId,
        date: date,
      );

      _availabilityCache[dateKey] = availability;
      notifyListeners();

      return availability;
    } catch (e) {
      debugPrint('Error fetching room availability: $e');
      return [];
    }
  }

  /// Update room availability
  Future<bool> updateRoomAvailability({
    required String roomId,
    required DateTime date,
    required bool isAvailable,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await CalendarApiService.updateRoomAvailability(
        hotelId: _hotelId,
        roomId: roomId,
        date: date,
        isAvailable: isAvailable,
      );

      if (result['success'] == true) {
        // Refresh calendar data
        await _loadCalendarDataForMonth(_currentMonth, _currentYear);

        // Clear cache for the specific date
        final dateKey = _formatDateKey(date);
        _availabilityCache.remove(dateKey);

        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to update room availability: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Block or unblock dates
  Future<bool> blockDates({
    required List<DateTime> dates,
    required bool isBlocked,
    String? reason,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await CalendarApiService.blockDates(
        hotelId: _hotelId,
        dates: dates,
        isBlocked: isBlocked,
        reason: reason,
      );

      if (result['success'] == true) {
        // Refresh calendar data
        await _loadCalendarDataForMonth(_currentMonth, _currentYear);

        // Clear cache for affected dates
        for (final date in dates) {
          final dateKey = _formatDateKey(date);
          _bookingsCache.remove(dateKey);
          _availabilityCache.remove(dateKey);
        }

        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to update dates: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load calendar analytics
  Future<void> loadCalendarAnalytics() async {
    if (_hotelId.isEmpty) {
      _setError('Hotel ID not set');
      return;
    }

    try {
      final analytics = await CalendarApiService.getCalendarAnalytics(
        hotelId: _hotelId,
        month: _currentMonth,
        year: _currentYear,
      );

      _analytics = analytics;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading calendar analytics: $e');
    }
  }

  /// Get pricing for date range
  Future<List<CalendarPricing>> getPricingForRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      return await CalendarApiService.getPricingForRange(
        hotelId: _hotelId,
        startDate: startDate,
        endDate: endDate,
      );
    } catch (e) {
      debugPrint('Error fetching pricing: $e');
      return [];
    }
  }

  /// Update pricing for a specific date
  Future<bool> updatePricing({
    required DateTime date,
    required Map<String, double> roomPrices,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await CalendarApiService.updatePricing(
        hotelId: _hotelId,
        date: date,
        roomPrices: roomPrices,
      );

      if (result['success'] == true) {
        // Refresh calendar data
        await _loadCalendarDataForMonth(_currentMonth, _currentYear);
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to update pricing: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Get daily data for a specific date
  CalendarDailyData? getDailyData(DateTime date) {
    if (_calendarData == null) return null;

    final dateKey = _formatDateKey(date);
    return _calendarData!.dailyData[dateKey];
  }

  /// Get month summary statistics
  Map<String, dynamic> getMonthSummary() {
    if (_calendarData == null) {
      return {
        'totalBookings': 0,
        'totalRevenue': 0.0,
        'averageOccupancy': 0.0,
        'totalDays': 0,
        'availableDays': 0,
        'fullDays': 0,
        'blockedDays': 0,
      };
    }

    final stats = _calendarData!.monthlyStats;
    int availableDays = 0;
    int fullDays = 0;
    int blockedDays = 0;

    _calendarData!.dailyData.forEach((date, data) {
      if (data.isBlocked) {
        blockedDays++;
      } else if (data.availableRooms == 0) {
        fullDays++;
      } else {
        availableDays++;
      }
    });

    return {
      'totalBookings': stats.totalBookings,
      'totalRevenue': stats.totalRevenue,
      'averageOccupancy': stats.averageOccupancy,
      'totalDays': _calendarData!.dailyData.length,
      'availableDays': availableDays,
      'fullDays': fullDays,
      'blockedDays': blockedDays,
    };
  }

  /// Refresh calendar data
  Future<void> refresh() async {
    await _loadCalendarDataForMonth(_currentMonth, _currentYear);
    await loadCalendarAnalytics();
  }

  /// Clear caches
  void clearCaches() {
    _bookingsCache.clear();
    _availabilityCache.clear();
    notifyListeners();
  }

  /// Format date key for caching
  String _formatDateKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  /// Get days in month
  List<DateTime> getDaysInMonth() {
    final firstDay = DateTime(_currentYear, _currentMonth, 1);
    final lastDay = DateTime(_currentYear, _currentMonth + 1, 0);
    final daysInMonth = lastDay.day;

    return List.generate(daysInMonth, (index) {
      return DateTime(_currentYear, _currentMonth, index + 1);
    });
  }

  /// Get first day of month weekday
  int getFirstDayOfWeek() {
    return DateTime(_currentYear, _currentMonth, 1).weekday;
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
