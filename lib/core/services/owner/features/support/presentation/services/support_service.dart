import '../../../../core/services/api_service.dart';

class SupportService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /support/tickets
  Future<List<Map<String, dynamic>>> getSupportTickets() async {
    final response = await ApiService.get('/support/tickets', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch support tickets');
  }

  // POST /support/tickets
  Future<Map<String, dynamic>> createSupportTicket(Map<String, dynamic> ticketData) async {
    final response = await ApiService.post('/support/tickets', token: _token, data: ticketData);
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to create support ticket');
  }

  // GET /support/tickets/{id}
  Future<Map<String, dynamic>> getTicketDetail(String ticketId) async {
    final response = await ApiService.get('/support/tickets/$ticketId', token: _token);
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to fetch ticket detail');
  }

  // POST /support/tickets/{id}/messages
  Future<Map<String, dynamic>> sendTicketMessage(String ticketId, String message) async {
    final response = await ApiService.post(
      '/support/tickets/$ticketId/messages',
      token: _token,
      data: {'message': message},
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to send message');
  }

  // POST /support/chat/start
  Future<Map<String, dynamic>> startSupportChat(Map<String, dynamic> data) async {
    final response = await ApiService.post('/support/chat/start', token: _token, data: data);
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to start support chat');
  }

  // GET /support/chat/{token}
  Future<Map<String, dynamic>> getSupportChat(String chatToken) async {
    final response = await ApiService.get('/support/chat/$chatToken', token: _token);
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to fetch support chat');
  }

  // POST /support/chat/{token}/message
  Future<Map<String, dynamic>> sendSupportChatMessage(String chatToken, String message) async {
    final response = await ApiService.post(
      '/support/chat/$chatToken/message',
      token: _token,
      data: {'message': message},
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to send chat message');
  }

  // POST /support/chat/{token}/end
  Future<void> endSupportChat(String chatToken) async {
    await ApiService.post('/support/chat/$chatToken/end', token: _token);
  }
}
