import 'package:flutter/material.dart';
import 'dart:async';
import '../utils/responsive.dart';

class LiveChat extends StatefulWidget {
  final String hotelName;

  const LiveChat({super.key, required this.hotelName});

  @override
  State<LiveChat> createState() => _LiveChatState();
}

class _LiveChatState extends State<LiveChat> {
  final List<ChatMessage> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  String _inputText = '';

  final List<String> _quickReplies = [
    'Room availability',
    'Amenities info',
    'Cancellation policy',
    'Check-in time',
  ];

  @override
  void initState() {
    super.initState();
    _messages.add(ChatMessage(
      text: 'Hello! Welcome to ${widget.hotelName}. How can I help you today?',
      sender: 'support',
      timestamp: DateTime.now(),
    ));
    _controller.addListener(() {
      setState(() {
        _inputText = _controller.text;
      });
    });
  }

  void _sendMessage([String? text]) {
    final messageText = text ?? _controller.text.trim();
    if (messageText.isEmpty) return;

    setState(() {
      _messages.add(ChatMessage(
        text: messageText,
        sender: 'user',
        timestamp: DateTime.now(),
      ));
      _isTyping = true;
    });

    _controller.clear();
    _scrollToBottom();

    Timer(const Duration(milliseconds: 1500), () {
      setState(() {
        _messages.add(ChatMessage(
          text: _getAutoResponse(messageText),
          sender: 'support',
          timestamp: DateTime.now(),
        ));
        _isTyping = false;
      });
      _scrollToBottom();
    });
  }

  String _getAutoResponse(String userMessage) {
    final msg = userMessage.toLowerCase();
    if (msg.contains('room') || msg.contains('availability')) {
      return 'We have rooms available for your dates. Would you like me to check specific room types?';
    }
    if (msg.contains('amenities')) {
      return 'Our hotel offers WiFi, AC, parking, restaurant, and room service. Is there a specific amenity you\'d like to know about?';
    }
    if (msg.contains('cancel')) {
      return 'You can cancel your booking up to 24 hours before check-in for a full refund. Need help with cancellation?';
    }
    if (msg.contains('check-in') || msg.contains('time')) {
      return 'Check-in is at 2:00 PM and check-out is at 11:00 AM. Early check-in may be available upon request.';
    }
    return 'Thank you for your message. A support representative will assist you shortly. Is there anything else I can help with?';
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: const Color(0xFFE60023),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Live Chat', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Text(widget.hotelName, style: const TextStyle(fontSize: 14, color: Colors.white70)),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF52C41A),
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                const Text('Online', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message.sender == 'user';
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    constraints: BoxConstraints(maxWidth: Responsive.wp(context, 80)),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isUser ? const Color(0xFFE60023) : Colors.white,
                      borderRadius: BorderRadius.circular(18).copyWith(
                        bottomRight: isUser ? const Radius.circular(4) : null,
                        bottomLeft: !isUser ? const Radius.circular(4) : null,
                      ),
                      boxShadow: !isUser ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 2)] : null,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          message.text,
                          style: TextStyle(
                            fontSize: 16,
                            color: isUser ? Colors.white : const Color(0xFF333333),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFF999999)),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('Support is typing...', style: TextStyle(fontSize: 14, color: Color(0xFF666666), fontStyle: FontStyle.italic)),
              ),
            ),
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _quickReplies.length,
              itemBuilder: (context, index) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: OutlinedButton(
                    onPressed: () => _sendMessage(_quickReplies[index]),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFE60023)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: Text(_quickReplies[index], style: const TextStyle(color: Color(0xFFE60023))),
                  ),
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFF0F0F0))),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    maxLines: null,
                    maxLength: 500,
                    onChanged: (value) => setState(() => _inputText = value),
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      counterText: '',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: _inputText.trim().isEmpty ? null : () => _sendMessage(),
                  child: CircleAvatar(
                    backgroundColor: _inputText.trim().isEmpty ? const Color(0xFFCCCCCC) : const Color(0xFFE60023),
                    child: const Icon(Icons.send, color: Colors.white, size: 20),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}

class ChatMessage {
  final String text;
  final String sender;
  final DateTime timestamp;

  ChatMessage({required this.text, required this.sender, required this.timestamp});
}
