import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/services/shared/api_service.dart';

class ChatScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;

  const ChatScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  bool _sending = false;
  Timer? _pollTimer;
  String? _token;

  String get _bookingId =>
      widget.arguments?['bookingId']?.toString() ??
      widget.arguments?['booking_id']?.toString() ??
      '';

  String get _hotelName =>
      widget.arguments?['hotelName']?.toString() ??
      widget.arguments?['hotel_name']?.toString() ??
      'Hotel';

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('authToken');
    await _loadMessages();
    // Poll for new messages every 5 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _loadMessages(silent: true));
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (_bookingId.isEmpty) {
      if (mounted) setState(() => _loading = false);
      return;
    }
    try {
      final response = await ApiService.get(
        '${ApiConfig.chatMessagesEndpoint}/$_bookingId/messages',
        token: _token,
      );
      if (!mounted) return;
      if (response['success'] == true) {
        final raw = response['data'];
        final list = raw is List ? raw : (raw is Map ? (raw['messages'] ?? raw['data'] ?? []) : []);
        final msgs = list.map<Map<String, dynamic>>((m) {
          final senderId = m['sender_id']?.toString() ?? m['sender']?.toString() ?? '';
          final userId = widget.arguments?['userId']?.toString() ?? '';
          final isUser = senderId == userId || (m['sender_type'] ?? '') == 'guest';
          return {
            'id': m['id']?.toString() ?? UniqueKey().toString(),
            'text': m['message']?.toString() ?? m['text']?.toString() ?? '',
            'sender': isUser ? 'user' : 'hotel',
            'timestamp': _formatTime(m['created_at']?.toString() ?? m['timestamp']?.toString() ?? ''),
          };
        }).toList();
        setState(() {
          _messages
            ..clear()
            ..addAll(msgs);
          _loading = false;
        });
        _scrollToBottom();
      } else {
        if (!silent) setState(() => _loading = false);
      }
    } catch (_) {
      if (!silent && mounted) setState(() => _loading = false);
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _sending) return;

    // Optimistic UI
    final tempMsg = {
      'id': 'temp_${DateTime.now().millisecondsSinceEpoch}',
      'text': text,
      'sender': 'user',
      'timestamp': _formatTime(DateTime.now().toIso8601String()),
      'pending': true,
    };
    setState(() {
      _messages.add(tempMsg);
      _sending = true;
    });
    _messageController.clear();
    _scrollToBottom();

    try {
      final response = await ApiService.post(
        ApiConfig.chatSendEndpoint,
        token: _token,
        data: {
          'booking_id': _bookingId,
          'message': text,
        },
      );
      if (mounted) {
        setState(() {
          _sending = false;
          // Remove pending flag
          final idx = _messages.indexWhere((m) => m['id'] == tempMsg['id']);
          if (idx != -1) _messages[idx] = {..._messages[idx], 'pending': false};
        });
        if (response['success'] == true) {
          await _loadMessages(silent: true);
        }
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _sending = false;
          _messages.removeWhere((m) => m['id'] == tempMsg['id']);
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to send message. Try again.'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  String _formatTime(String raw) {
    if (raw.isEmpty) return TimeOfDay.now().format(context);
    try {
      final dt = DateTime.parse(raw).toLocal();
      final h = dt.hour.toString().padLeft(2, '0');
      final m = dt.minute.toString().padLeft(2, '0');
      return '$h:$m';
    } catch (_) {
      return raw;
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.hotel_rounded, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_hotelName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray), overflow: TextOverflow.ellipsis),
                        const Text('Support Chat', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded, size: 20, color: AppColors.gray),
                    onPressed: () => _loadMessages(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.lightGray),

            // Messages
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : _messages.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) => _buildBubble(_messages[index]),
                        ),
            ),

            // Input bar
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: InputDecoration(
                        hintText: 'Type your message...',
                        hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.lightGray),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.lightGray),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        filled: true,
                        fillColor: AppColors.background,
                      ),
                      maxLines: null,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: _sending ? AppColors.primaryLight : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.primaryShadow,
                      ),
                      child: _sending
                          ? const Padding(
                              padding: EdgeInsets.all(12),
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.send_rounded, size: 20, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBubble(Map<String, dynamic> msg) {
    final isUser = msg['sender'] == 'user';
    final isPending = msg['pending'] == true;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isUser ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: isUser ? const Radius.circular(18) : const Radius.circular(4),
            bottomRight: isUser ? const Radius.circular(4) : const Radius.circular(18),
          ),
          boxShadow: isUser ? [] : AppColors.cardShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              msg['text'] as String? ?? '',
              style: TextStyle(fontSize: 14, color: isUser ? Colors.white : AppColors.darkGray, height: 1.4),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  msg['timestamp'] as String? ?? '',
                  style: TextStyle(fontSize: 11, color: isUser ? Colors.white60 : AppColors.placeholder),
                ),
                if (isUser) ...[
                  const SizedBox(width: 4),
                  Icon(
                    isPending ? Icons.access_time_rounded : Icons.done_rounded,
                    size: 12,
                    color: Colors.white60,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: AppColors.primary, size: 36),
          ),
          const SizedBox(height: 16),
          const Text('No messages yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 6),
          const Text('Send a message to start the conversation', style: TextStyle(fontSize: 13, color: AppColors.gray)),
        ],
      ),
    );
  }
}
