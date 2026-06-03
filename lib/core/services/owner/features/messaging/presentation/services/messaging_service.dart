import '../../../../core/services/api_service.dart';

class MessagingService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /chat/owner/all — owner: all chat conversations
  static Future<List<Map<String, dynamic>>> getOwnerConversations() async {
    final response = await ApiService.get('/chat/owner/all', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch conversations');
  }

  // GET /chat/{bookingId}/messages
  Future<List<Map<String, dynamic>>> getConversations() async {
    return getOwnerConversations();
  }

  // GET /chat/{bookingId}/messages
  Future<List<Map<String, dynamic>>> getMessages(String bookingId) async {
    final response = await ApiService.get(
      '/chat/$bookingId/messages',
      token: _token,
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch messages');
  }

  // POST /chat/send
  Future<Map<String, dynamic>> sendMessage(String bookingId, String content, String receiverId) async {
    final response = await ApiService.post(
      '/chat/send',
      token: _token,
      data: {
        'bookingId': bookingId,
        'content': content,
        'receiverId': receiverId,
      },
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to send message');
  }
}
