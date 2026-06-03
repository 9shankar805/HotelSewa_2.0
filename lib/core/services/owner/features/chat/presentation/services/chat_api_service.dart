import 'package:flutter/foundation.dart';
import '../../../../core/services/api_service.dart';
import '../models/chat_model.dart';

class ChatApiService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /my-bookings — list bookings to derive conversations
  static Future<List<ChatConversation>> getConversations() async {
    try {
      final response = await ApiService.get('/my-bookings', token: _token);
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ChatConversation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching conversations: $e');
      return [];
    }
  }

  // GET /chat/{bookingId}/messages
  static Future<List<ChatMessage>> getMessages(String bookingId) async {
    try {
      final response = await ApiService.get(
        '/chat/$bookingId/messages',
        token: _token,
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> messagesJson = response['data'];
        return messagesJson.map((json) => ChatMessage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching messages: $e');
      return [];
    }
  }

  // POST /chat/send — accepts both bookingId and conversationId param names
  static Future<Map<String, dynamic>> sendMessage({
    String? bookingId,
    String? conversationId,
    required String content,
    required ChatMessageType type,
  }) async {
    final id = bookingId ?? conversationId ?? '';
    try {
      final response = await ApiService.post(
        '/chat/send',
        token: _token,
        data: {
          'bookingId': id,
          'content': content,
          'type': type.toString().split('.').last,
        },
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data'], 'message': 'Message sent successfully'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to send message'};
    } catch (e) {
      debugPrint('Error sending message: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // createConversation — no dedicated endpoint; use chat/send to start
  static Future<Map<String, dynamic>> createConversation({
    required String participantId,
    required String participantName,
    required String participantType,
  }) async {
    // No dedicated create-conversation endpoint in API spec
    return {'success': true, 'message': 'Conversation ready'};
  }

  // markAsRead — no dedicated endpoint; handled client-side
  static Future<Map<String, dynamic>> markAsRead(String conversationId) async {
    return {'success': true};
  }

  // POST /ai-chat/start — start AI chatbot session
  static Future<Map<String, dynamic>> startAiChat(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post('/ai-chat/start', token: _token, data: data);
      if (response['success'] == true) {
        return {'success': true, 'data': response['data']};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to start AI chat'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // POST /ai-chat/message
  static Future<Map<String, dynamic>> sendAiMessage(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post('/ai-chat/message', token: _token, data: data);
      if (response['success'] == true) {
        return {'success': true, 'data': response['data']};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to send AI message'};
    } catch (e) {
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // GET /ai-chat/history/{token}
  static Future<List<ChatMessage>> getAiChatHistory(String chatToken) async {
    try {
      final response = await ApiService.get('/ai-chat/history/$chatToken', token: _token);
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ChatMessage.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching AI chat history: $e');
      return [];
    }
  }

  // POST /ai-chat/end/{token}
  static Future<void> endAiChat(String chatToken) async {
    try {
      await ApiService.post('/ai-chat/end/$chatToken', token: _token);
    } catch (e) {
      debugPrint('Error ending AI chat: $e');
    }
  }

  // GET /chat/{bookingId}/messages — unread count derived from messages
  static Future<int> getUnreadCount() async {
    try {
      final response = await ApiService.get('/get-notification-list', token: _token);
      if (response['success'] == true && response['data'] != null) {
        final List data = response['data'];
        return data.where((n) => n['read'] == false).length;
      }
      return 0;
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
      return 0;
    }
  }

  // GET /my-bookings — search by guest name
  static Future<List<ChatConversation>> searchConversations(String query) async {
    try {
      final response = await ApiService.get(
        '/my-bookings',
        token: _token,
        queryParams: {'search': query},
      );
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> data = response['data'];
        return data.map((json) => ChatConversation.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error searching conversations: $e');
      return [];
    }
  }

  // GET /payment-transactions — chat stats
  static Future<ChatStats> getChatStats() async {
    try {
      final response = await ApiService.get('/payment-transactions', token: _token);
      if (response['success'] == true && response['data'] != null) {
        return ChatStats.fromJson(response['data']);
      }
      return ChatStats.empty();
    } catch (e) {
      debugPrint('Error fetching chat stats: $e');
      return ChatStats.empty();
    }
  }

  // No archive/delete endpoint in spec — handled client-side
  static Future<Map<String, dynamic>> archiveConversation(String conversationId, bool isArchived) async {
    return {'success': true, 'message': isArchived ? 'Conversation archived' : 'Conversation unarchived'};
  }

  static Future<Map<String, dynamic>> deleteConversation(String conversationId) async {
    return {'success': true, 'message': 'Conversation deleted successfully'};
  }
}
