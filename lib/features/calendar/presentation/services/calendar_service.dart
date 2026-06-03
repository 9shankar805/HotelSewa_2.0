import '../../../../core/services/shared/api_service.dart';

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

  // GET /api/owner/calendar?hotel_id=&year= — yearly occupancy + blocked dates
  static Future<Map<String, dynamic>> getYearlyCalendar({String? token, int? year}) async {
    final params = <String, String>{};
    if (year != null) params['year'] = year.toString();
    final response = await ApiService.get(
      '/api/owner/calendar',
      token: token ?? _token,
      queryParams: params.isNotEmpty ? params : null,
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch yearly calendar');
  }
}

