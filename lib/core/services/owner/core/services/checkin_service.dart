import 'api_service.dart';

/// QR Check-in / Check-out for hotel owners.
class CheckinService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // POST /checkin/confirm
  // body: { qr_token, hotel_id }
  static Future<Map<String, dynamic>> confirmCheckin(Map<String, dynamic> data) async {
    final response = await ApiService.post('/checkin/confirm', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to confirm check-in');
  }

  // POST /checkin/checkout
  static Future<Map<String, dynamic>> confirmCheckout(Map<String, dynamic> data) async {
    final response = await ApiService.post('/checkin/checkout', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to confirm check-out');
  }

  // GET /checkin/today?hotel_id=
  static Future<List<Map<String, dynamic>>> getTodayArrivals(String hotelId) async {
    final response = await ApiService.get(
      '/checkin/today',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch today arrivals');
  }

  // GET /checkin/active-guests?hotel_id=
  static Future<List<Map<String, dynamic>>> getActiveGuests(String hotelId) async {
    final response = await ApiService.get(
      '/checkin/active-guests',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch active guests');
  }
}
