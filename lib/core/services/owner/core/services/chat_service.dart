import 'api_service.dart';

/// Guest-Hotel Chat for hotel owners.
class ChatService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /chat/owner/all?hotel_id=
  static Future<List<Map<String, dynamic>>> getAllConversations(String hotelId) async {
    final response = await ApiService.get(
      '/chat/owner/all',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch conversations');
  }

  // GET /chat/{bookingId}/messages
  static Future<List<Map<String, dynamic>>> getMessages(String bookingId) async {
    final response = await ApiService.get('/chat/$bookingId/messages', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch messages');
  }

  // POST /chat/send
  // body: { booking_id, message, attachment? }
  static Future<Map<String, dynamic>> sendMessage(Map<String, dynamic> data) async {
    final response = await ApiService.post('/chat/send', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to send message');
  }
}
