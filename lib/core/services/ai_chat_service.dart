import 'shared/api_service.dart';

class AiChatService {
  // POST /ai-chat/start - Start chat session
  Future<Map<String, dynamic>> startSession() async {
    try {
      final response = await ApiService.post('/ai-chat/start');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to start chat session'};
    }
  }

  // POST /ai-chat/message - Send message
  Future<Map<String, dynamic>> sendMessage({
    required String token,
    required String message,
  }) async {
    try {
      final response = await ApiService.post('/ai-chat/message', data: {
        'token': token,
        'message': message,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send message'};
    }
  }

  // GET /ai-chat/history/{token} - Chat history
  Future<Map<String, dynamic>> getHistory(String token) async {
    try {
      final response = await ApiService.get('/ai-chat/history/$token');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load chat history'};
    }
  }

  // POST /ai-chat/end/{token} - End session
  Future<Map<String, dynamic>> endSession(String token) async {
    try {
      final response = await ApiService.post('/ai-chat/end/$token');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to end chat session'};
    }
  }
}





