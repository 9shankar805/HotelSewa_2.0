import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/chat_model.dart';
import '../../../../core/constants/app_colors.dart';

class ChatMessagesWidget extends StatefulWidget {
  final List<ChatMessage> messages;
  final Future<void> Function() onRefresh;

  const ChatMessagesWidget({
    super.key,
    required this.messages,
    required this.onRefresh,
  });

  @override
  State<ChatMessagesWidget> createState() => _ChatMessagesWidgetState();
}

class _ChatMessagesWidgetState extends State<ChatMessagesWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 64,
              color: AppColors.gray[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                fontSize: 18,
                color: AppColors.gray[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start the conversation with a message',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.gray,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(16),
        reverse: true, // Show messages from bottom to top
        itemCount: widget.messages.length,
        itemBuilder: (context, index) {
          final message = widget.messages[index];
          return _buildMessageBubble(message);
        },
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    final isFromMe = message.isFromOwner;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment:
            isFromMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isFromMe) ...[
            // Sender Avatar
            CircleAvatar(
              radius: 16,
              backgroundColor: const Color(0xFFE60023).withOpacity(0.1),
              child: Icon(
                Icons.person,
                color: const Color(0xFFE60023),
                size: 16,
              ),
            ),
            const SizedBox(width: 8),
          ],

          // Message Bubble
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isFromMe ? const Color(0xFFE60023) : AppColors.gray[200],
                borderRadius: BorderRadius.circular(20).copyWith(
                  bottomLeft: isFromMe
                      ? const Radius.circular(20)
                      : const Radius.circular(4),
                  bottomRight: isFromMe
                      ? const Radius.circular(4)
                      : const Radius.circular(20),
                  topLeft: isFromMe
                      ? const Radius.circular(20)
                      : const Radius.circular(20),
                  topRight: isFromMe
                      ? const Radius.circular(20)
                      : const Radius.circular(20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Message Type Specific Content
                  _buildMessageContent(message),

                  const SizedBox(height: 4),

                  // Message Metadata
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        message.formattedTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: isFromMe
                              ? Colors.white.withOpacity(0.8)
                              : AppColors.gray[600],
                        ),
                      ),
                      if (!message.isRead && isFromMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.done_all,
                          size: 12,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),

          if (isFromMe) ...[
            const SizedBox(width: 8),
            // Read Status Indicator
            CircleAvatar(
              radius: 16,
              backgroundColor: AppColors.lightGray,
              child: Icon(
                message.isRead ? Icons.done_all : Icons.done,
                size: 16,
                color: message.isRead ? AppColors.info : AppColors.gray[600],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageContent(ChatMessage message) {
    switch (message.type) {
      case ChatMessageType.text:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromOwner ? Colors.white : AppColors.darkGray,
            fontSize: 16,
          ),
        );

      case ChatMessageType.image:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.fileUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  message.fileUrl!,
                  width: 200,
                  height: 200,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: AppColors.lightGray,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.broken_image,
                        color: AppColors.gray,
                      ),
                    );
                  },
                ),
              ),
            if (message.content.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message.content,
                style: TextStyle(
                  color: message.isFromOwner ? Colors.white : AppColors.darkGray,
                  fontSize: 16,
                ),
              ),
            ],
          ],
        );

      case ChatMessageType.file:
        final bgColor = message.isFromOwner
            ? Colors.white
            : (AppColors.gray[100] ?? AppColors.gray[200]!);
        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: bgColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.attach_file,
                color: message.isFromOwner ? Colors.white : AppColors.gray[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      message.fileName ?? 'File',
                      style: TextStyle(
                        color: message.isFromOwner
                            ? Colors.white
                            : AppColors.gray[700],
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (message.content.isNotEmpty)
                      Text(
                        message.content,
                        style: TextStyle(
                          color: message.isFromOwner
                              ? Colors.white70
                              : AppColors.gray[600],
                          fontSize: 12,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          ),
        );

      case ChatMessageType.system:
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.gray[200],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            message.content,
            style: TextStyle(
              color: AppColors.gray[700],
              fontSize: 13,
              fontStyle: FontStyle.italic,
            ),
            textAlign: TextAlign.center,
          ),
        );

      default:
        return Text(
          message.content,
          style: TextStyle(
            color: message.isFromOwner ? Colors.white : AppColors.darkGray,
            fontSize: 16,
          ),
        );
    }
  }
}
