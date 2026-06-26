import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/support_service.dart';

class TicketDetailScreen extends StatefulWidget {
  final String ticketId;

  const TicketDetailScreen({Key? key, required this.ticketId}) : super(key: key);

  @override
  State<TicketDetailScreen> createState() => _TicketDetailScreenState();
}

class _TicketDetailScreenState extends State<TicketDetailScreen> {
  final SupportService _service = SupportService();
  Map<String, dynamic>? _ticket;
  List<Map<String, dynamic>> _messages = [];
  bool _loading = true;
  final TextEditingController _replyCtrl = TextEditingController();
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _replyCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final result = await _service.getTicketDetails(widget.ticketId);
    if (mounted) {
      if (result['success']) {
        setState(() {
          _ticket = result['data'] is Map ? result['data'] as Map<String, dynamic> : null;
          _messages = [];
          _loading = false;
        });
      } else {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _sendReply() async {
    if (_replyCtrl.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final result = await _service.addTicketMessage(ticketId: widget.ticketId, message: _replyCtrl.text.trim());
    if (mounted) {
      setState(() => _sending = false);
      if (result['success']) {
        _replyCtrl.clear();
        _load();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Reply sent successfully'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
      } else {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to send reply'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
      }
    }
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'open':
        color = AppColors.info;
        label = 'Open';
        break;
      case 'in_progress':
        color = AppColors.warning;
        label = 'In Progress';
        break;
      case 'resolved':
        color = AppColors.success;
        label = 'Resolved';
        break;
      default:
        color = AppColors.gray;
        label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Ticket Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildTicketInfo().animate().fadeIn(),
                        const SizedBox(height: 20),
                        _buildConversation().animate().fadeIn(delay: 60.ms),
                      ],
                    ),
                  ),
                ),
                _buildReplyBox(),
              ],
            ),
    );
  }

  Widget _buildTicketInfo() {
    if (_ticket == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(_ticket!['id']?.toString() ?? 'Ticket', style: const TextStyle(fontSize: 14, color: AppColors.gray, fontWeight: FontWeight.w600)),
              _statusBadge(_ticket!['status']?.toString() ?? 'open'),
            ],
          ),
          const SizedBox(height: 12),
          Text(_ticket!['subject']?.toString() ?? 'Support Ticket', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          Text(_ticket!['category']?.toString() ?? 'General', style: const TextStyle(fontSize: 13, color: AppColors.gray)),
          const SizedBox(height: 12),
          Text(_ticket!['description']?.toString() ?? '', style: const TextStyle(fontSize: 14, color: AppColors.darkGray, height: 1.5)),
        ],
      ),
    );
  }

  Widget _buildConversation() {
    if (_messages.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
        child: const Center(child: Text('No messages yet. Start a conversation below!', style: TextStyle(color: AppColors.gray), textAlign: TextAlign.center)),
      );
    }
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        itemCount: _messages.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (_, i) {
          final msg = _messages[i];
          final isMe = msg['isMe'] as bool? ?? false;
          return Row(
            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            children: [
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe ? AppColors.primary : AppColors.background,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                    children: [
                      Text(msg['message']?.toString() ?? '', style: TextStyle(fontSize: 14, color: isMe ? Colors.white : AppColors.darkGray)),
                      const SizedBox(height: 4),
                      Text(msg['time']?.toString() ?? '', style: TextStyle(fontSize: 11, color: isMe ? Colors.white70 : AppColors.placeholder)),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReplyBox() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, -2))]),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _replyCtrl,
                decoration: InputDecoration(
                  hintText: 'Type your reply...',
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _sending ? null : _sendReply,
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(color: _sending ? AppColors.gray : AppColors.primary, borderRadius: BorderRadius.circular(14)),
                child: _sending
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.send_rounded, color: Colors.white, size: 22),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
