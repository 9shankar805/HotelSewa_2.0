import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/brand_trust_service.dart';

class GuestComplaintScreen extends StatefulWidget {
  final String? bookingId;
  final String? hotelName;
  const GuestComplaintScreen({super.key, this.bookingId, this.hotelName});

  @override
  State<GuestComplaintScreen> createState() => _GuestComplaintScreenState();
}

class _GuestComplaintScreenState extends State<GuestComplaintScreen> {
  final _subjectCtrl     = TextEditingController();
  final _descCtrl        = TextEditingController();
  String _category       = 'cleanliness';
  bool   _submitting     = false;
  bool   _submitted      = false;

  static const _categories = [
    ('cleanliness', '🧹 Cleanliness', 'Room was dirty or not as described'),
    ('photos',      '📸 Misleading Photos', 'Room didn\'t match listing photos'),
    ('amenities',   '🛎 Missing Amenities', 'Advertised amenities were not available'),
    ('safety',      '🔒 Safety Concern', 'Security or safety issue'),
    ('communication','💬 No Response', 'Owner did not respond to messages'),
    ('other',       '📋 Other Issue', 'Something else went wrong'),
  ];

  @override
  void dispose() { _subjectCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_subjectCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Please fill in subject and description'),
          behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _submitting = true);
    try {
      await BrandTrustService.raiseComplaint({
        if (widget.bookingId != null) 'booking_id': widget.bookingId,
        'category': _category,
        'subject': _subjectCtrl.text.trim(),
        'description': _descCtrl.text.trim(),
      });
      setState(() { _submitted = true; _submitting = false; });
    } catch (_) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Failed to submit complaint'),
          backgroundColor: AppColors.primary, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Color(0xFF374151)),
            onPressed: () => context.pop()),
        title: const Text('Report an Issue', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
      ),
      body: _submitted ? _successState() : _form(),
    );
  }

  Widget _successState() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 80, height: 80,
          decoration: const BoxDecoration(color: Color(0xFFEFF6FF), shape: BoxShape.circle),
          child: const Icon(Icons.support_agent_rounded, size: 44, color: Color(0xFF3B82F6))),
      const SizedBox(height: 20),
      const Text('Complaint Received', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 8),
      const Text('Our team will review your complaint and respond within 24 hours. We take quality seriously.',
          textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(0xFF6B7280), height: 1.5)),
      const SizedBox(height: 24),
      ElevatedButton(
        onPressed: () => context.pop(),
        style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14)),
        child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    ]),
  ));

  Widget _form() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Info banner
      Container(
        padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(color: const Color(0xFFEFF6FF), borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFBFDBFE))),
        child: const Row(children: [
          Icon(Icons.info_outline_rounded, color: Color(0xFF3B82F6), size: 20),
          SizedBox(width: 10),
          Expanded(child: Text('HotelSewa reviews all complaints within 24 hours and enforces hotel standards.',
              style: TextStyle(fontSize: 12, color: Color(0xFF1D4ED8), fontWeight: FontWeight.w500))),
        ]),
      ),

      if (widget.hotelName != null) ...[
        _label('Hotel'),
        Container(
          padding: const EdgeInsets.all(14), margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
          child: Row(children: [
            const Icon(Icons.hotel_rounded, color: AppColors.primary, size: 18),
            const SizedBox(width: 10),
            Text(widget.hotelName!, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          ]),
        ),
      ],

      _label('Issue Category *'),
      Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(
          children: _categories.map((c) {
            final on = _category == c.$1;
            return InkWell(
              onTap: () => setState(() => _category = c.$1),
              borderRadius: BorderRadius.circular(14),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(children: [
                  Text(c.$2, style: TextStyle(fontSize: 14, fontWeight: on ? FontWeight.w700 : FontWeight.w500,
                      color: on ? AppColors.primary : const Color(0xFF374151))),
                  const Spacer(),
                  if (on) const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                ]),
              ),
            );
          }).toList(),
        ),
      ),

      _label('Subject *'),
      _textField(_subjectCtrl, 'Brief description of the issue', maxLines: 1),
      const SizedBox(height: 12),

      _label('Full Description *'),
      _textField(_descCtrl, 'Please describe what happened in detail...', maxLines: 5),
      const SizedBox(height: 24),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: _submitting ? null : _submit,
          icon: _submitting
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(Icons.send_rounded, size: 18),
          label: Text(_submitting ? 'Submitting...' : 'Submit Complaint',
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, foregroundColor: Colors.white, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      ),
      const SizedBox(height: 32),
    ]),
  );

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF374151))),
  );

  Widget _textField(TextEditingController ctrl, String hint, {int maxLines = 1}) => Container(
    margin: const EdgeInsets.only(bottom: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
    ),
    child: TextField(
      controller: ctrl, maxLines: maxLines,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint, hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
        filled: true, fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
        contentPadding: const EdgeInsets.all(14),
      ),
    ),
  );
}
