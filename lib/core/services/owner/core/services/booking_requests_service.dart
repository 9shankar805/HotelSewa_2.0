import 'api_service.dart';

class BookingRequestsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /booking-requests/owner?hotel_id= — owner: all pending requests
  static Future<List<Map<String, dynamic>>> getOwnerRequests(String hotelId) async {
    final response = await ApiService.get(
      '/booking-requests/owner',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch owner requests');
  }

  // POST /booking-requests/{id}/respond
  // body: { status, extra_charge?, owner_response? }
  static Future<Map<String, dynamic>> respondToRequest(String requestId, Map<String, dynamic> data) async {
    final response = await ApiService.post('/booking-requests/$requestId/respond', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to respond to request');
  }

  // POST /booking-modifications/{id}/respond — approve or reject date change
  static Future<Map<String, dynamic>> respondToModification(String modificationId, Map<String, dynamic> data) async {
    final response = await ApiService.post('/booking-modifications/$modificationId/respond', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to respond to modification');
  }

  // POST /booking-requests/special-time (guest)
  static Future<Map<String, dynamic>> requestSpecialTime(Map<String, dynamic> data) async {
    final response = await ApiService.post('/booking-requests/special-time', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to request special time');
  }

  // GET /booking-requests/my (guest)
  static Future<List<Map<String, dynamic>>> getMyRequests() async {
    final response = await ApiService.get('/booking-requests/my', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch booking requests');
  }

  // POST /booking-modifications/request (guest)
  static Future<Map<String, dynamic>> requestModification(Map<String, dynamic> data) async {
    final response = await ApiService.post('/booking-modifications/request', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to request modification');
  }
}
