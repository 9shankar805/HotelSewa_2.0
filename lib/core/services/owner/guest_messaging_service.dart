import '../shared/api_service.dart';

/// Automated Guest Messaging for hotel owners.
///
/// Available triggers:
///   booking_confirmed · pre_arrival_24h · pre_arrival_2h · post_checkout · review_request
class GuestMessagingService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /guest-messaging/templates?hotel_id=
  static Future<List<Map<String, dynamic>>> getTemplates(String hotelId) async {
    final response = await ApiService.get(
      '/guest-messaging/templates',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch templates');
  }

  // POST /guest-messaging/templates — create or update
  // body: { hotel_id, name, trigger, subject, body, channel, is_active }
  static Future<Map<String, dynamic>> saveTemplate(Map<String, dynamic> data) async {
    final response = await ApiService.post('/guest-messaging/templates', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to save template');
  }

  // DELETE /guest-messaging/templates/{id}
  static Future<void> deleteTemplate(String id) async {
    final response = await ApiService.delete('/guest-messaging/templates/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete template');
    }
  }

  // GET /guest-messaging/logs?booking_id=
  static Future<List<Map<String, dynamic>>> getLogs(String bookingId) async {
    final response = await ApiService.get(
      '/guest-messaging/logs',
      token: _token,
      queryParams: {'booking_id': bookingId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch message logs');
  }

  // POST /guest-messaging/test
  static Future<Map<String, dynamic>> sendTestMessage(Map<String, dynamic> data) async {
    final response = await ApiService.post('/guest-messaging/test', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to send test message');
  }
}


