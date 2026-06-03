import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class AIChatScreen extends StatefulWidget {
  const AIChatScreen({Key? key}) : super(key: key);

  @override
  State<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends State<AIChatScreen> {
  final _messageController = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final name = auth.user?.name?.split(' ').first ?? 'there';
      setState(() {
        _messages.add({
          'id': '1',
          'text': 'Hi $name! I\'m your AI assistant. I can help you find the best hotels in Nepal, check your bookings, or manage your loyalty points. How can I help you today?',
          'sender': 'bot',
          'timestamp': TimeOfDay.now().format(context),
          'suggestions': ['Find luxury hotels', 'Check my points', 'Nearby attractions']
        });
      });
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final userName = auth.user?.name ?? 'Guest';

    final userMessage = {
      'id': DateTime.now().millisecondsSinceEpoch.toString(),
      'text': _messageController.text.trim(),
      'sender': 'user',
      'timestamp': TimeOfDay.now().format(context),
    };

    setState(() {
      _messages.add(userMessage);
      _isTyping = true;
    });
    
    final messageText = _messageController.text.trim();
    _messageController.clear();

    try {
      final groqApiKey = dotenv.env['GROQ_API_KEY'] ?? '';
      
      final response = await http.post(
        Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $groqApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-70b-versatile',
          'messages': [
            {
              'role': 'system', 
              'content': 'You are a premium hotel booking assistant for HotelSewa. The user name is $userName. You are helpful, professional, and knowledgeable about Nepal tourism. Help users find hotels, make bookings, and answer questions about their reservations. If they ask about points, remind them about the HotelSewa Rewards program.'
            },
            {'role': 'user', 'content': messageText},
          ],
          'temperature': 0.7,
          'max_tokens': 1024,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200 && mounted) {
        final data = jsonDecode(response.body);
        final aiResponse = data['choices'][0]['message']['content'];
        
        await Future.delayed(const Duration(milliseconds: 500));
        
        setState(() {
          _messages.add({
            'id': (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            'text': aiResponse,
            'sender': 'bot',
            'timestamp': TimeOfDay.now().format(context),
            'quickReplies': ['Show more', 'Book now', 'Help'],
          });
          _isTyping = false;
        });
      } else {
        throw Exception('Failed: ${response.statusCode}');
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _messages.add({
            'id': (DateTime.now().millisecondsSinceEpoch + 1).toString(),
            'text': 'I can help you find hotels, check bookings, or answer questions. What would you like to know?',
            'sender': 'bot',
            'timestamp': TimeOfDay.now().format(context),
          });
          _isTyping = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF333333)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const Icon(Icons.smart_toy, size: 24, color: AppColors.primary),
            const SizedBox(width: 8),
            const Expanded(child: Text('AI Assistant', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333)))),
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFF52C41A), shape: BoxShape.circle),
            ),
            const SizedBox(width: 4),
            const Text('Online', style: TextStyle(fontSize: 12, color: Color(0xFF52C41A))),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                final isUser = message['sender'] == 'user';
                return Column(
                  crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                  children: [
                    Container(
                      constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isUser ? AppColors.primary : Colors.white,
                        border: isUser ? null : Border.all(color: const Color(0xFFE0E0E0)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(message['text'], style: TextStyle(fontSize: 16, height: 1.4, color: isUser ? Colors.white : const Color(0xFF333333))),
                          const SizedBox(height: 4),
                          Text(message['timestamp'], style: const TextStyle(fontSize: 12, color: Color(0xFF999999))),
                        ],
                      ),
                    ),
                    if (message['suggestions'] != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (message['suggestions'] as List).map((s) {
                          return InkWell(
                            onTap: () => _messageController.text = s,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: const Color(0xFFF0F0F0), borderRadius: BorderRadius.circular(16)),
                              child: Text(s, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
                            ),
                          );
                        }).toList(),
                      ),
                    if (message['quickReplies'] != null)
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: (message['quickReplies'] as List).map((r) {
                          return InkWell(
                            onTap: () => _messageController.text = r,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
                              child: Text(r, style: const TextStyle(fontSize: 14, color: Colors.white)),
                            ),
                          );
                        }).toList(),
                      ),
                  ],
                );
              },
            ),
          ),
          if (_isTyping)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('AI is typing...', style: TextStyle(fontSize: 14, color: Color(0xFF666666), fontStyle: FontStyle.italic)),
            ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFE0E0E0))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask me anything...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(20), borderSide: const BorderSide(color: Color(0xFFE0E0E0))),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _sendMessage,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(Icons.send, size: 20, color: Colors.white),
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
    _messageController.dispose();
    super.dispose();
  }
}
