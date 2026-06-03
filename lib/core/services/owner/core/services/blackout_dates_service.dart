import 'api_service.dart';

/// Blackout dates management for hotel owners.
class BlackoutDatesService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // POST /hotel-owner/blackout-dates
  // body: { hotel_id, dates: [...], reason }
  static Future<Map<String, dynamic>> addBlackoutDates(Map<String, dynamic> data) async {
    final response = await ApiService.post('/hotel-owner/blackout-dates', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add blackout dates');
  }

  // POST /hotel-owner/blackout-dates/range
  static Future<Map<String, dynamic>> addBlackoutDateRange(Map<String, dynamic> data) async {
    final response = await ApiService.post('/hotel-owner/blackout-dates/range', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add blackout date range');
  }

  // DELETE /hotel-owner/blackout-dates (body: { hotel_id, dates: [...] })
  static Future<void> removeBlackoutDates(Map<String, dynamic> data) async {
    final response = await ApiService.delete(
      '/hotel-owner/blackout-dates',
      token: _token,
      data: data,
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to remove blackout dates');
    }
  }

  // GET /hotels/{hotelId}/blackout-dates (public)
  static Future<List<Map<String, dynamic>>> getBlackoutDates(String hotelId) async {
    final response = await ApiService.get('/hotels/$hotelId/blackout-dates', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch blackout dates');
  }
}
