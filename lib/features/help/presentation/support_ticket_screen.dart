import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/support_service.dart';
import 'ticket_detail_screen.dart';

class SupportTicketScreen extends StatefulWidget {
  final String? bookingId;
  final String? initialCategory;

  const SupportTicketScreen({Key? key, this.bookingId, this.initialCategory}) : super(key: key);

  @override
  State<SupportTicketScreen> createState() => _SupportTicketScreenState();
}

class _SupportTicketScreenState extends State<SupportTicketScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        title: const Text('Support', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.gray,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          tabs: const [Tab(text: 'New Ticket'), Tab(text: 'My Tickets')],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _NewTicketTab(bookingId: widget.bookingId, initialCategory: widget.initialCategory),
          _MyTicketsTab(),
        ],
      ),
    );
  }
}

class _NewTicketTab extends StatefulWidget {
  final String? bookingId;
  final String? initialCategory;

  const _NewTicketTab({this.bookingId, this.initialCategory});

  @override
  State<_NewTicketTab> createState() => _NewTicketTabState();
}

class _NewTicketTabState extends State<_NewTicketTab> {
  final SupportService _service = SupportService();
  late String _category;
  String _priority = 'Medium';
  final _subjectCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _bookingIdCtrl = TextEditingController();
  bool _loading = false;

  final _categories = ['Booking Issue', 'Payment Problem', 'Cancellation & Refund', 'Hotel Complaint', 'App Bug', 'Account Issue', 'Other'];
  final _priorities = ['Low', 'Medium', 'High', 'Urgent'];

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? 'Booking Issue';
    if (widget.bookingId != null) {
      _bookingIdCtrl.text = widget.bookingId!;
    }
  }

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _descCtrl.dispose();
    _bookingIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_subjectCtrl.text.isEmpty || _descCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please fill subject and description'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    final result = await _service.createTicket({
      'subject': _subjectCtrl.text.trim(),
      'description': _descCtrl.text.trim(),
      'category': _category,
      'priority': _priority.toLowerCase(),
      if (_bookingIdCtrl.text.isNotEmpty) 'booking_id': _bookingIdCtrl.text.trim(),
    });
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success']) {
      _subjectCtrl.clear();
      _descCtrl.clear();
      _bookingIdCtrl.clear();
      final ticketId = result['data'] is Map ? (result['data']['id'] ?? result['data']['ticket_id'] ?? '') : '';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ticket${ticketId.isNotEmpty ? ' #$ticketId' : ''} created. We\'ll respond within 24 hours.'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 4)),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to create ticket'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.infoLight, borderRadius: BorderRadius.circular(14)),
            child: const Row(children: [
              Icon(Icons.access_time_rounded, color: AppColors.info, size: 16),
              SizedBox(width: 8),
              Expanded(child: Text('Average response time: 2–4 hours', style: TextStyle(fontSize: 12, color: AppColors.info, fontWeight: FontWeight.w600))),
            ]),
          ).animate().fadeIn(),
          const SizedBox(height: 20),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _label('Category'),
                _dropdown(_category, _categories, (v) => setState(() => _category = v!)),
                const SizedBox(height: 16),
                _label('Priority'),
                Row(
                  children: _priorities.map((p) {
                    final sel = _priority == p;
                    return Expanded(child: GestureDetector(
                      onTap: () => setState(() => _priority = p),
                      child: Container(
                        margin: const EdgeInsets.only(right: 6),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: BoxDecoration(
                          color: sel ? _priorityColor(p).withOpacity(0.1) : AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: sel ? _priorityColor(p) : AppColors.lightGray, width: sel ? 1.5 : 1),
                        ),
                        child: Center(child: Text(p, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: sel ? _priorityColor(p) : AppColors.gray))),
                      ),
                    ));
                  }).toList(),
                ),
                const SizedBox(height: 16),
                _label('Booking ID (optional)'),
                _textField(_bookingIdCtrl, 'e.g. HS-2024-001'),
                const SizedBox(height: 16),
                _label('Subject'),
                _textField(_subjectCtrl, 'Brief description of your issue'),
                const SizedBox(height: 16),
                _label('Description'),
                TextField(
                  controller: _descCtrl,
                  maxLines: 5,
                  maxLength: 1000,
                  decoration: InputDecoration(
                    hintText: 'Describe your issue in detail...',
                    filled: true, fillColor: AppColors.background,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.1),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _loading ? null : _submit,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: _loading
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Submit Ticket', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ).animate().fadeIn(delay: 120.ms),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _label(String t) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(t, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)));

  Widget _dropdown(String value, List<String> items, ValueChanged<String?> onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.lightGray)),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(value: value, isExpanded: true, items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(), onChanged: onChanged),
      ),
    );
  }

  Widget _textField(TextEditingController ctrl, String hint) {
    return TextField(
      controller: ctrl,
      decoration: InputDecoration(
        hintText: hint,
        filled: true, fillColor: AppColors.background,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.lightGray)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Color _priorityColor(String p) {
    switch (p) {
      case 'Low': return AppColors.success;
      case 'Medium': return AppColors.info;
      case 'High': return AppColors.warning;
      case 'Urgent': return AppColors.error;
      default: return AppColors.gray;
    }
  }
}

class _MyTicketsTab extends StatefulWidget {
  @override
  State<_MyTicketsTab> createState() => _MyTicketsTabState();
}

class _MyTicketsTabState extends State<_MyTicketsTab> {
  final SupportService _service = SupportService();
  List<Map<String, dynamic>> _tickets = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final result = await _service.getTickets();
    if (result['success'] && mounted) {
      final raw = result['data'];
      List items = raw is List ? raw : (raw is Map ? (raw['data'] ?? raw['tickets'] ?? []) : []);
      setState(() {
        _tickets = items.map<Map<String, dynamic>>((t) => {
          'id': t['id']?.toString() ?? '',
          'subject': t['subject'] ?? t['title'] ?? 'Support Ticket',
          'category': t['category'] ?? 'General',
          'status': t['status'] ?? 'open',
          'priority': t['priority'] ?? 'medium',
          'date': _fmt(t['created_at']),
          'lastReply': _fmt(t['updated_at']),
        }).toList();
        _loading = false;
      });
    } else {
      setState(() => _loading = false);
    }
  }

  String _fmt(dynamic raw) {
    if (raw == null) return '';
    try {
      final dt = DateTime.parse(raw.toString());
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) { return raw.toString(); }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    if (_tickets.isEmpty) return const Center(child: Text('No tickets yet', style: TextStyle(color: AppColors.gray)));
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _tickets.length,
      itemBuilder: (_, i) {
        final t = _tickets[i];
        final status = t['status'] as String;
        return InkWell(
          onTap: () {
            context.push('/ticket-detail', extra: {'ticketId': t['id'] as String});
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(t['id'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray, fontWeight: FontWeight.w600)),
                    _statusBadge(status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(t['subject'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                const SizedBox(height: 4),
                Text(t['category'] as String, style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 12, color: AppColors.placeholder),
                    const SizedBox(width: 4),
                    Text('Last reply: ${t['lastReply']}', style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
                    const Spacer(),
                    Text(t['date'] as String, style: const TextStyle(fontSize: 11, color: AppColors.placeholder)),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, size: 16, color: AppColors.placeholder),
                  ],
                ),
              ],
            ),
          ),
        ).animate(delay: (i * 60).ms).fadeIn().slideY(begin: 0.05);
      },
    );
  }

  Widget _statusBadge(String status) {
    Color color;
    String label;
    switch (status) {
      case 'open': color = AppColors.info; label = 'Open'; break;
      case 'in_progress': color = AppColors.warning; label = 'In Progress'; break;
      case 'resolved': color = AppColors.success; label = 'Resolved'; break;
      default: color = AppColors.gray; label = status;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
    );
  }
}
