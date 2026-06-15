import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class SupportService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // POST /support/tickets - Create ticket
  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.supportTicketsEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to create ticket'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create ticket'};
    }
  }

  // GET /support/tickets - My tickets (alias)
  Future<Map<String, dynamic>> getTickets() async => getMyTickets();

  // GET /support/tickets - My tickets
  Future<Map<String, dynamic>> getMyTickets() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.supportTicketsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load tickets'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load tickets'};
    }
  }

  // GET /support/tickets/{id} - Ticket details
  Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.buildPath(ApiConfig.supportTicketDetailEndpoint, ticketId),
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load ticket details'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load ticket details'};
    }
  }

  // POST /support/tickets/{id}/messages - Add message to ticket
  Future<Map<String, dynamic>> addTicketMessage({
    required String ticketId,
    required String message,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.supportTicketMessagesEndpoint, '$ticketId/messages'),
        token: token,
        data: {'message': message},
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add message'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add message'};
    }
  }

  // POST /support/chat/start - Start live chat
  Future<Map<String, dynamic>> startChat() async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.supportChatStartEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to start chat'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to start chat'};
    }
  }

  // GET /support/chat/{token} - Get chat session
  Future<Map<String, dynamic>> getChatSession(String chatToken) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.buildPath(ApiConfig.supportChatGetEndpoint, chatToken),
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load chat session'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load chat session'};
    }
  }

  // POST /support/chat/{token}/message - Send chat message
  Future<Map<String, dynamic>> sendChatMessage({
    required String chatToken,
    required String message,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.supportChatMessageEndpoint, '$chatToken/message'),
        token: token,
        data: {'message': message},
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to send message'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send message'};
    }
  }

  // POST /support/chat/{token}/end - End chat
  Future<Map<String, dynamic>> endChat(String chatToken) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.supportChatEndEndpoint, '$chatToken/end'),
        token: token,
      );
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to end chat'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to end chat'};
    }
  }
}
