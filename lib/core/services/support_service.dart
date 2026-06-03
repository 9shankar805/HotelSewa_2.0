import '../constants/api_config.dart';
import 'shared/api_service.dart';

class SupportService {
  // POST /support/tickets - Create ticket
  Future<Map<String, dynamic>> createTicket(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post(ApiConfig.supportTicketsEndpoint, data: data);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create ticket'};
    }
  }

  // GET /support/tickets - My tickets (alias for getMyTickets)
  Future<Map<String, dynamic>> getTickets() async {
    return await getMyTickets();
  }

  // GET /support/tickets - My tickets
  Future<Map<String, dynamic>> getMyTickets() async {
    try {
      final response = await ApiService.get(ApiConfig.supportTicketsEndpoint);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load tickets'};
    }
  }

  // GET /support/tickets/{id} - Ticket details
  Future<Map<String, dynamic>> getTicketDetails(String ticketId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.supportTicketDetailEndpoint, ticketId));
      return {'success': true, 'data': response['data']};
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
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.supportTicketMessagesEndpoint, '$ticketId/messages'),
        data: {'message': message},
      );
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add message'};
    }
  }

  // POST /support/chat/start - Start live chat
  Future<Map<String, dynamic>> startChat() async {
    try {
      final response = await ApiService.post(ApiConfig.supportChatStartEndpoint);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to start chat'};
    }
  }

  // GET /support/chat/{token} - Get chat session
  Future<Map<String, dynamic>> getChatSession(String token) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.supportChatGetEndpoint, token));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load chat session'};
    }
  }

  // POST /support/chat/{token}/message - Send chat message
  Future<Map<String, dynamic>> sendChatMessage({
    required String token,
    required String message,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.supportChatMessageEndpoint, '$token/message'),
        data: {'message': message},
      );
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send message'};
    }
  }

  // POST /support/chat/{token}/end - End chat
  Future<Map<String, dynamic>> endChat(String token) async {
    try {
      final response = await ApiService.post(ApiConfig.buildPath(ApiConfig.supportChatEndEndpoint, '$token/end'));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to end chat'};
    }
  }
}





