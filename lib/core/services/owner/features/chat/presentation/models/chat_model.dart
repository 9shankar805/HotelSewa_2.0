class ChatConversation {
  final String id;
  final String participantId;
  final String participantName;
  final String participantType;
  final String? participantAvatar;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final bool isArchived;
  final bool isOnline;
  final DateTime createdAt;
  final DateTime updatedAt;

  ChatConversation({
    required this.id,
    required this.participantId,
    required this.participantName,
    required this.participantType,
    this.participantAvatar,
    this.lastMessage,
    required this.unreadCount,
    required this.isArchived,
    required this.isOnline,
    required this.createdAt,
    required this.updatedAt,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String,
      participantId: json['participantId'] as String,
      participantName: json['participantName'] as String,
      participantType: json['participantType'] as String,
      participantAvatar: json['participantAvatar'] as String?,
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] as int? ?? 0,
      isArchived: json['isArchived'] as bool? ?? false,
      isOnline: json['isOnline'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantId': participantId,
      'participantName': participantName,
      'participantType': participantType,
      'participantAvatar': participantAvatar,
      'lastMessage': lastMessage?.toJson(),
      'unreadCount': unreadCount,
      'isArchived': isArchived,
      'isOnline': isOnline,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  /// Get display text for last message
  String get lastMessageText {
    if (lastMessage == null) return 'No messages yet';

    switch (lastMessage!.type) {
      case ChatMessageType.text:
        return lastMessage!.content.length > 30
            ? '${lastMessage!.content.substring(0, 30)}...'
            : lastMessage!.content;
      case ChatMessageType.image:
        return '📷 Image';
      case ChatMessageType.file:
        return '📎 File';
      case ChatMessageType.system:
        return lastMessage!.content;
    }
  }

  /// Get formatted time for last message
  String get lastMessageTime {
    if (lastMessage == null) return '';

    final now = DateTime.now();
    final messageTime = lastMessage!.createdAt;

    if (now.day == messageTime.day &&
        now.month == messageTime.month &&
        now.year == messageTime.year) {
      return '${messageTime.hour.toString().padLeft(2, '0')}:${messageTime.minute.toString().padLeft(2, '0')}';
    } else if (now.year == messageTime.year) {
      return '${messageTime.day}/${messageTime.month}';
    } else {
      return '${messageTime.day}/${messageTime.month}/${messageTime.year}';
    }
  }

  /// Check if conversation has unread messages
  bool get hasUnreadMessages => unreadCount > 0;

  /// Get participant type display text
  String get participantTypeDisplay {
    switch (participantType.toLowerCase()) {
      case 'guest':
        return 'Guest';
      case 'admin':
        return 'Admin';
      case 'support':
        return 'Support';
      default:
        return participantType;
    }
  }

  /// Create a copy of this ChatConversation with optionally updated fields
  ChatConversation copyWith({
    String? id,
    String? participantId,
    String? participantName,
    String? participantType,
    String? participantAvatar,
    ChatMessage? lastMessage,
    int? unreadCount,
    bool? isArchived,
    bool? isOnline,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantId: participantId ?? this.participantId,
      participantName: participantName ?? this.participantName,
      participantType: participantType ?? this.participantType,
      participantAvatar: participantAvatar ?? this.participantAvatar,
      lastMessage: lastMessage ?? this.lastMessage,
      unreadCount: unreadCount ?? this.unreadCount,
      isArchived: isArchived ?? this.isArchived,
      isOnline: isOnline ?? this.isOnline,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String senderName;
  final String senderType;
  final String content;
  final ChatMessageType type;
  final String? fileUrl;
  final String? fileName;
  final bool isRead;
  final DateTime createdAt;
  final DateTime? readAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.senderName,
    required this.senderType,
    required this.content,
    required this.type,
    this.fileUrl,
    this.fileName,
    required this.isRead,
    required this.createdAt,
    this.readAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String,
      conversationId: json['conversationId'] as String,
      senderId: json['senderId'] as String,
      senderName: json['senderName'] as String,
      senderType: json['senderType'] as String,
      content: json['content'] as String,
      type: ChatMessageType.values.firstWhere(
        (type) => type.toString() == 'ChatMessageType.${json['type']}',
        orElse: () => ChatMessageType.text,
      ),
      fileUrl: json['fileUrl'] as String?,
      fileName: json['fileName'] as String?,
      isRead: json['isRead'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
      readAt: json['readAt'] != null
          ? DateTime.parse(json['readAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'conversationId': conversationId,
      'senderId': senderId,
      'senderName': senderName,
      'senderType': senderType,
      'content': content,
      'type': type.toString().split('.').last,
      'fileUrl': fileUrl,
      'fileName': fileName,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
      'readAt': readAt?.toIso8601String(),
    };
  }

  /// Check if message is sent by current user (owner)
  bool get isFromOwner => senderType.toLowerCase() == 'owner';

  /// Get formatted time
  String get formattedTime {
    return '${createdAt.hour.toString().padLeft(2, '0')}:${createdAt.minute.toString().padLeft(2, '0')}';
  }

  /// Get formatted date
  String get formattedDate {
    final now = DateTime.now();
    if (now.day == createdAt.day &&
        now.month == createdAt.month &&
        now.year == createdAt.year) {
      return 'Today';
    } else if (now.year == createdAt.year) {
      return '${createdAt.day} ${_getMonthName(createdAt.month)}';
    } else {
      return '${createdAt.day} ${_getMonthName(createdAt.month)} ${createdAt.year}';
    }
  }

  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  /// Create a copy of this ChatMessage with optionally updated fields
  ChatMessage copyWith({
    String? id,
    String? conversationId,
    String? senderId,
    String? senderName,
    String? senderType,
    String? content,
    ChatMessageType? type,
    String? fileUrl,
    String? fileName,
    bool? isRead,
    DateTime? createdAt,
    DateTime? readAt,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      conversationId: conversationId ?? this.conversationId,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      senderType: senderType ?? this.senderType,
      content: content ?? this.content,
      type: type ?? this.type,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
      readAt: readAt ?? this.readAt,
    );
  }
}

class ChatStats {
  final int totalConversations;
  final int unreadMessages;
  final int activeConversations;
  final int archivedConversations;
  final int messagesToday;
  final int messagesThisWeek;
  final double averageResponseTime;
  final Map<String, int> conversationsByType;

  ChatStats({
    required this.totalConversations,
    required this.unreadMessages,
    required this.activeConversations,
    required this.archivedConversations,
    required this.messagesToday,
    required this.messagesThisWeek,
    required this.averageResponseTime,
    required this.conversationsByType,
  });

  factory ChatStats.fromJson(Map<String, dynamic> json) {
    return ChatStats(
      totalConversations: json['totalConversations'] as int? ?? 0,
      unreadMessages: json['unreadMessages'] as int? ?? 0,
      activeConversations: json['activeConversations'] as int? ?? 0,
      archivedConversations: json['archivedConversations'] as int? ?? 0,
      messagesToday: json['messagesToday'] as int? ?? 0,
      messagesThisWeek: json['messagesThisWeek'] as int? ?? 0,
      averageResponseTime:
          (json['averageResponseTime'] as num?)?.toDouble() ?? 0.0,
      conversationsByType:
          Map<String, int>.from(json['conversationsByType'] ?? {}),
    );
  }

  static ChatStats empty() {
    return ChatStats(
      totalConversations: 0,
      unreadMessages: 0,
      activeConversations: 0,
      archivedConversations: 0,
      messagesToday: 0,
      messagesThisWeek: 0,
      averageResponseTime: 0.0,
      conversationsByType: {},
    );
  }
}

enum ChatMessageType {
  text,
  image,
  file,
  system,
}
