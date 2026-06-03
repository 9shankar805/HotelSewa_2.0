import 'package:flutter/foundation.dart';
import '../models/chat_model.dart';
import '../services/chat_api_service.dart';

class ChatProvider extends ChangeNotifier {
  List<ChatConversation> _conversations = [];
  Map<String, List<ChatMessage>> _messages = {};
  bool _isLoading = false;
  String? _error;
  String? _selectedConversationId;
  int _unreadCount = 0;
  ChatStats? _stats;

  // Getters
  List<ChatConversation> get conversations => _conversations;
  Map<String, List<ChatMessage>> get messages => _messages;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedConversationId => _selectedConversationId;
  int get unreadCount => _unreadCount;
  ChatStats? get stats => _stats;

  // Filtered conversations
  List<ChatConversation> get activeConversations => 
      _conversations.where((c) => !c.isArchived).toList();
  List<ChatConversation> get archivedConversations => 
      _conversations.where((c) => c.isArchived).toList();
  List<ChatConversation> get conversationsWithUnread => 
      _conversations.where((c) => c.hasUnreadMessages).toList();

  /// Load all conversations
  Future<void> loadConversations() async {
    _setLoading(true);
    _clearError();

    try {
      final conversations = await ChatApiService.getConversations();
      _conversations = conversations;
      
      // Update unread count
      _unreadCount = conversations.fold(0, (sum, conv) => sum + conv.unreadCount);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to load conversations: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Load messages for a specific conversation
  Future<void> loadMessages(String conversationId) async {
    _setLoading(true);
    _clearError();

    try {
      final messages = await ChatApiService.getMessages(conversationId);
      _messages[conversationId] = messages;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load messages: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Send a message
  Future<bool> sendMessage({
    required String conversationId,
    required String content,
    ChatMessageType type = ChatMessageType.text,
  }) async {
    try {
      final result = await ChatApiService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
      );

      if (result['success'] == true) {
        // Refresh messages for this conversation
        await loadMessages(conversationId);
        
        // Update conversation's last message
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          // This would be updated by the API response in a real implementation
          await loadConversations();
        }
        
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to send message: ${e.toString()}');
      return false;
    }
  }

  /// Create a new conversation
  Future<bool> createConversation({
    required String participantId,
    required String participantName,
    required String participantType,
  }) async {
    try {
      final result = await ChatApiService.createConversation(
        participantId: participantId,
        participantName: participantName,
        participantType: participantType,
      );

      if (result['success'] == true) {
        await loadConversations();
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to create conversation: ${e.toString()}');
      return false;
    }
  }

  /// Mark messages as read
  Future<bool> markAsRead(String conversationId) async {
    try {
      final result = await ChatApiService.markAsRead(conversationId);

      if (result['success'] == true) {
        // Update local unread count
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          final conversation = _conversations[conversationIndex];
          _unreadCount = (_unreadCount - conversation.unreadCount).clamp(0, _unreadCount);
          
          // Update conversation
          _conversations[conversationIndex] = conversation.copyWith(unreadCount: 0);
          
          // Update messages
          if (_messages.containsKey(conversationId)) {
            _messages[conversationId] = _messages[conversationId]!.map((message) {
              return message.copyWith(isRead: true, readAt: DateTime.now());
            }).toList();
          }
          
          notifyListeners();
        }
        
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to mark as read: ${e.toString()}');
      return false;
    }
  }

  /// Get unread message count
  Future<void> getUnreadCount() async {
    try {
      final count = await ChatApiService.getUnreadCount();
      _unreadCount = count;
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching unread count: $e');
    }
  }

  /// Search conversations
  Future<List<ChatConversation>> searchConversations(String query) async {
    if (query.trim().isEmpty) {
      return _conversations;
    }

    try {
      return await ChatApiService.searchConversations(query);
    } catch (e) {
      debugPrint('Error searching conversations: $e');
      return [];
    }
  }

  /// Load chat statistics
  Future<void> loadChatStats() async {
    try {
      final stats = await ChatApiService.getChatStats();
      _stats = stats;
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading chat stats: $e');
    }
  }

  /// Archive or unarchive conversation
  Future<bool> archiveConversation(String conversationId, bool isArchived) async {
    try {
      final result = await ChatApiService.archiveConversation(conversationId, isArchived);

      if (result['success'] == true) {
        await loadConversations();
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to archive conversation: ${e.toString()}');
      return false;
    }
  }

  /// Delete conversation
  Future<bool> deleteConversation(String conversationId) async {
    try {
      final result = await ChatApiService.deleteConversation(conversationId);

      if (result['success'] == true) {
        _conversations.removeWhere((c) => c.id == conversationId);
        _messages.remove(conversationId);
        
        // Update unread count
        final removedConversation = _conversations.firstWhere(
          (c) => c.id == conversationId,
          orElse: () => ChatConversation(
            id: conversationId,
            participantId: '',
            participantName: '',
            participantType: '',
            unreadCount: 0,
            isArchived: false,
            isOnline: false,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
        _unreadCount = (_unreadCount - removedConversation.unreadCount).clamp(0, _unreadCount);
        
        notifyListeners();
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete conversation: ${e.toString()}');
      return false;
    }
  }

  /// Select a conversation
  void selectConversation(String? conversationId) {
    _selectedConversationId = conversationId;
    notifyListeners();
  }

  /// Get messages for selected conversation
  List<ChatMessage>? get selectedConversationMessages {
    if (_selectedConversationId == null) return null;
    return _messages[_selectedConversationId];
  }

  /// Get selected conversation
  ChatConversation? get selectedConversation {
    if (_selectedConversationId == null) return null;
    return _conversations.firstWhere(
      (c) => c.id == _selectedConversationId,
      orElse: () => ChatConversation(
        id: _selectedConversationId!,
        participantId: '',
        participantName: '',
        participantType: '',
        unreadCount: 0,
        isArchived: false,
        isOnline: false,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ),
    );
  }

  /// Refresh all data
  Future<void> refresh() async {
    await Future.wait([
      loadConversations(),
      getUnreadCount(),
      loadChatStats(),
    ]);
    
    if (_selectedConversationId != null) {
      await loadMessages(_selectedConversationId!);
    }
  }

  /// Clear all data
  void clearAll() {
    _conversations.clear();
    _messages.clear();
    _selectedConversationId = null;
    _unreadCount = 0;
    _stats = null;
    notifyListeners();
  }

  /// Get conversation summary
  Map<String, dynamic> getConversationSummary() {
    return {
      'totalConversations': _conversations.length,
      'activeConversations': activeConversations.length,
      'archivedConversations': archivedConversations.length,
      'conversationsWithUnread': conversationsWithUnread.length,
      'unreadMessages': _unreadCount,
      'onlineParticipants': _conversations.where((c) => c.isOnline).length,
    };
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
