import '../../../../core/services/api_service.dart';

class CalendarService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotels/{hotelId}/blackout-dates + /my-bookings for calendar view
  Future<List<Map<String, dynamic>>> getCalendarData(String hotelId, int month, int year) async {
    final response = await ApiService.get(
      '/hotels/$hotelId/blackout-dates',
      token: _token,
      queryParams: {'month': month.toString(), 'year': year.toString()},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch calendar data');
  }

  // GET /my-bookings — bookings for calendar
  Future<List<Map<String, dynamic>>> getBookingsForCalendar({
    required int month,
    required int year,
  }) async {
    final response = await ApiService.get(
      '/my-bookings',
      token: _token,
      queryParams: {'month': month.toString(), 'year': year.toString()},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch bookings for calendar');
  }
}
