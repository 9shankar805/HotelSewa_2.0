import '../../../../core/services/api_service.dart';
import '../models/calendar_model.dart';

class CalendarApiService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotels/{hotelId}/blackout-dates — calendar data
  static Future<CalendarData> getCalendarData({
    required String hotelId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await ApiService.get(
        '/hotels/$hotelId/blackout-dates',
        token: _token,
        queryParams: {'month': month.toString(), 'year': year.toString()},
      );
      if (response['success'] == true && response['data'] != null) {
        return CalendarData.fromJson(response['data']);
      }
      return CalendarData(hotelId: hotelId, month: month, year: year, dailyData: {}, monthlyStats: CalendarMonthlyStats.empty());
    } catch (e) {
      debugPrint('Error fetching calendar data: $e');
      return CalendarData(hotelId: hotelId, month: month, year: year, dailyData: {}, monthlyStats: CalendarMonthlyStats.empty());
    }
  }

  // GET /my-bookings — bookings for a specific date
  static Future<List<CalendarBooking>> getBookingsForDate({
    required String hotelId,
    required DateTime date,
  }) async {
    try {
      final response = await ApiService.get(
        '/my-bookings',
        token: _token,
        queryParams: {'date': date.toIso8601String().split('T')[0], 'hotelId': hotelId},
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> bookingsJson = response['data'];
        return bookingsJson.map((json) => CalendarBooking.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching bookings for date: $e');
      return [];
    }
  }

  // GET /filters/search — room availability for a date
  static Future<List<CalendarRoomAvailability>> getRoomAvailability({
    required String hotelId,
    required DateTime date,
  }) async {
    try {
      final response = await ApiService.get(
        '/filters/search',
        token: _token,
        queryParams: {'hotelId': hotelId, 'date': date.toIso8601String().split('T')[0]},
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> availabilityJson = response['data'];
        return availabilityJson.map((json) => CalendarRoomAvailability.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching room availability: $e');
      return [];
    }
  }

  // POST /update-profile — update room availability
  static Future<Map<String, dynamic>> updateRoomAvailability({
    required String hotelId,
    required String roomId,
    required DateTime date,
    required bool isAvailable,
  }) async {
    try {
      final response = await ApiService.post(
        '/update-profile',
        token: _token,
        data: {
          'hotelId': hotelId,
          'roomId': roomId,
          'date': date.toIso8601String().split('T')[0],
          'isAvailable': isAvailable,
        },
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data'], 'message': 'Room availability updated'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to update room availability'};
    } catch (e) {
      debugPrint('Error updating room availability: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // GET /payment-transactions — calendar analytics
  static Future<CalendarAnalytics> getCalendarAnalytics({
    required String hotelId,
    required int month,
    required int year,
  }) async {
    try {
      final response = await ApiService.get(
        '/payment-transactions',
        token: _token,
        queryParams: {'hotelId': hotelId, 'month': month.toString(), 'year': year.toString()},
      );
      if (response['success'] == true && response['data'] != null) {
        return CalendarAnalytics.fromJson(response['data']);
      }
      return CalendarAnalytics.empty();
    } catch (e) {
      debugPrint('Error fetching calendar analytics: $e');
      return CalendarAnalytics.empty();
    }
  }

  // POST /update-profile — block/unblock dates (blackout dates)
  static Future<Map<String, dynamic>> blockDates({
    required String hotelId,
    required List<DateTime> dates,
    required bool isBlocked,
    String? reason,
  }) async {
    try {
      final response = await ApiService.post(
        '/update-profile',
        token: _token,
        data: {
          'hotelId': hotelId,
          'blackoutDates': dates.map((d) => d.toIso8601String().split('T')[0]).toList(),
          'isBlocked': isBlocked,
          'reason': reason,
        },
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data'], 'message': isBlocked ? 'Dates blocked' : 'Dates unblocked'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to update dates'};
    } catch (e) {
      debugPrint('Error blocking dates: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // GET /preview-price — pricing for date range
  static Future<List<CalendarPricing>> getPricingForRange({
    required String hotelId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    try {
      final response = await ApiService.get(
        '/preview-price',
        token: _token,
        queryParams: {
          'hotelId': hotelId,
          'startDate': startDate.toIso8601String().split('T')[0],
          'endDate': endDate.toIso8601String().split('T')[0],
        },
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> pricingJson = response['data'];
        return pricingJson.map((json) => CalendarPricing.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching pricing: $e');
      return [];
    }
  }

  // POST /update-profile — update pricing
  static Future<Map<String, dynamic>> updatePricing({
    required String hotelId,
    required DateTime date,
    required Map<String, double> roomPrices,
  }) async {
    try {
      final response = await ApiService.post(
        '/update-profile',
        token: _token,
        data: {
          'hotelId': hotelId,
          'date': date.toIso8601String().split('T')[0],
          'roomPrices': roomPrices,
        },
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data'], 'message': 'Pricing updated'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to update pricing'};
    } catch (e) {
      debugPrint('Error updating pricing: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}
