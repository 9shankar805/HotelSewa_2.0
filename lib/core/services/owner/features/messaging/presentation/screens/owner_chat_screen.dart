import 'package:flutter/material.dart';
import '../../../../../../../core/constants/app_colors.dart';

class OwnerChatScreen extends StatefulWidget {
  const OwnerChatScreen({super.key});

  @override
  State<OwnerChatScreen> createState() => _OwnerChatScreenState();
}

class _OwnerChatScreenState extends State<OwnerChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hello! I have a question about my booking.', 'sender': 'guest', 'time': '10:30 AM'},
    {'text': 'Hello! I\'m here to help. What can I assist you with?', 'sender': 'owner', 'time': '10:32 AM'},
    {'text': 'I need to check in early around 11 AM. Is that possible?', 'sender': 'guest', 'time': '10:35 AM'},
  ];

  final List<String> _quickReplies = [
    'Room is ready for early check-in',
    'Please wait, checking availability',
    'Thank you for choosing our hotel',
    'Is there anything else I can help with?',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('John Doe'),
            Text('Booking: HS001234', style: TextStyle(fontSize: 12)),
          ],
        ),
        actions: [
          Row(
            children: [
              Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF52C41A), shape: BoxShape.circle)),
              const SizedBox(width: 6),
              const Text('Online', style: TextStyle(fontSize: 12, color: Color(0xFF52C41A))),
              const SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final m = _messages[index];
                final isOwner = m['sender'] == 'owner';
                return Align(
                  alignment: isOwner ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.8),
                    decoration: BoxDecoration(
                      color: isOwner ? const Color(0xFFE60023) : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(m['text'], style: TextStyle(color: isOwner ? Colors.white : Colors.black)),
                        const SizedBox(height: 4),
                        Text(m['time'], style: TextStyle(fontSize: 12, color: isOwner ? Colors.white70 : AppColors.gray)),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Quick Replies:', style: TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickReplies.map((reply) => GestureDetector(
                    onTap: () {},
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.gray[200], borderRadius: BorderRadius.circular(16)),
                      child: Text(reply, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                    ),
                  )).toList(),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: InputDecoration(
                          hintText: 'Type message...',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(20)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    CircleAvatar(
                      backgroundColor: const Color(0xFFE60023),
                      child: IconButton(icon: const Icon(Icons.send, color: Colors.white), onPressed: () {}),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
