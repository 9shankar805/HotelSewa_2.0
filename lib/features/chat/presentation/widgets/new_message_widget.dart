import 'package:flutter/material.dart';
import '../models/chat_model.dart';
import '../../../../core/constants/app_colors.dart';

class NewMessageWidget extends StatefulWidget {
  final Function(String content, ChatMessageType type) onSendMessage;

  const NewMessageWidget({
    super.key,
    required this.onSendMessage,
  });

  @override
  State<NewMessageWidget> createState() => _NewMessageWidgetState();
}

class _NewMessageWidgetState extends State<NewMessageWidget> {
  final TextEditingController _textController = TextEditingController();
  ChatMessageType _selectedType = ChatMessageType.text;
  bool _isTyping = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Message Type Selector
          if (_selectedType != ChatMessageType.text)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE60023).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    _getMessageTypeIcon(_selectedType),
                    color: const Color(0xFFE60023),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _getMessageTypeLabel(_selectedType),
                    style: const TextStyle(
                      color: Color(0xFFE60023),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () {
                      setState(() {
                        _selectedType = ChatMessageType.text;
                      });
                    },
                  ),
                ],
              ),
            ),
          
          // Input Area
          Row(
            children: [
              // Attachment Button
              Container(
                decoration: BoxDecoration(
                  color: AppColors.gray[100],
                  borderRadius: BorderRadius.circular(25),
                ),
                child: PopupMenuButton<ChatMessageType>(
                  icon: Icon(
                    Icons.add,
                    color: AppColors.gray[600],
                  ),
                  onSelected: (ChatMessageType type) {
                    setState(() {
                      _selectedType = type;
                    });
                  },
                  itemBuilder: (BuildContext context) => [
                    PopupMenuItem<ChatMessageType>(
                      value: ChatMessageType.text,
                      child: Row(
                        children: [
                          Icon(Icons.text_fields, color: AppColors.gray[700]),
                          const SizedBox(width: 8),
                          const Text('Text'),
                        ],
                      ),
                    ),
                    PopupMenuItem<ChatMessageType>(
                      value: ChatMessageType.image,
                      child: Row(
                        children: [
                          Icon(Icons.image, color: AppColors.gray[700]),
                          const SizedBox(width: 8),
                          const Text('Image'),
                        ],
                      ),
                    ),
                    PopupMenuItem<ChatMessageType>(
                      value: ChatMessageType.file,
                      child: Row(
                        children: [
                          Icon(Icons.attach_file, color: AppColors.gray[700]),
                          const SizedBox(width: 8),
                          const Text('File'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Text Input
              Expanded(
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: InputDecoration(
                    hintText: _getHintText(),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(25),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: AppColors.gray[100],
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isTyping = value.trim().isNotEmpty;
                    });
                  },
                  onSubmitted: (value) {
                    if (value.trim().isNotEmpty) {
                      _sendMessage();
                    }
                  },
                ),
              ),
              
              const SizedBox(width: 8),
              
              // Send Button
              Container(
                decoration: BoxDecoration(
                  color: _isTyping ? const Color(0xFFE60023) : AppColors.lightGray,
                  borderRadius: BorderRadius.circular(25),
                ),
                child: IconButton(
                  icon: const Icon(
                    Icons.send,
                    color: Colors.white,
                  ),
                  onPressed: _isTyping ? _sendMessage : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _sendMessage() {
    final content = _textController.text.trim();
    if (content.isEmpty) return;

    widget.onSendMessage(content, _selectedType);
    _textController.clear();
    
    setState(() {
      _isTyping = false;
      _selectedType = ChatMessageType.text;
    });
  }

  String _getHintText() {
    switch (_selectedType) {
      case ChatMessageType.text:
        return 'Type a message...';
      case ChatMessageType.image:
        return 'Add image caption (optional)...';
      case ChatMessageType.file:
        return 'Add file description (optional)...';
      default:
        return 'Type a message...';
    }
  }

  IconData _getMessageTypeIcon(ChatMessageType type) {
    switch (type) {
      case ChatMessageType.text:
        return Icons.text_fields;
      case ChatMessageType.image:
        return Icons.image;
      case ChatMessageType.file:
        return Icons.attach_file;
      default:
        return Icons.text_fields;
    }
  }

  String _getMessageTypeLabel(ChatMessageType type) {
    switch (type) {
      case ChatMessageType.text:
        return 'Text Message';
      case ChatMessageType.image:
        return 'Image Message';
      case ChatMessageType.file:
        return 'File Message';
      default:
        return 'Text Message';
    }
  }
}
