import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/brand_trust_service.dart';

class PostStaySurveyScreen extends StatefulWidget {
  final String bookingId;
  final String hotelName;
  const PostStaySurveyScreen({super.key, required this.bookingId, required this.hotelName});

  @override
  State<PostStaySurveyScreen> createState() => _PostStaySurveyScreenState();
}

class _PostStaySurveyScreenState extends State<PostStaySurveyScreen> {
  int _cleanlinessRating = 0;
  int _accuracyRating    = 0;  // photos matched reality
  int _communicationRating = 0;
  int _valueRating       = 0;
  bool _wouldReturn      = true;
  final _commentsCtrl    = TextEditingController();
  bool _submitting       = false;
  bool _submitted        = false;

  @override
  void dispose() { _commentsCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_cleanlinessRating == 0 || _accuracyRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Please rate cleanliness and photo accuracy'),
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _submitting = true);
    try {
      await BrandTrustService.submitPostStaySurvey({
        'booking_id': widget.bookingId,
        'cleanliness_rating': _cleanlinessRating,
        'photo_accuracy_rating': _accuracyRating,
        'communication_rating': _communicationRating,
        'value_rating': _valueRating,
        'would_return': _wouldReturn,
        'comments': _commentsCtrl.text.trim(),
      });
      setState(() { _submitted = true; _submitting = false; });
    } catch (_) {
      setState(() => _submitting = false);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to submit survey. Please try again.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.close_rounded, color: Color(0xFF374151)),
            onPressed: () => context.pop()),
        title: const Text('Rate Your Stay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        centerTitle: true,
      ),
      body: _submitted ? _successState() : _surveyForm(),
    );
  }

  Widget _successState() => Center(child: Padding(
    padding: const EdgeInsets.all(32),
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 80, height: 80,
        decoration: const BoxDecoration(color: Color(0xFFECFDF5), shape: BoxShape.circle),
        child: const Icon(Icons.check_circle_rounded, size: 48, color: Color(0xFF10B981)),
      ),
      const SizedBox(height: 20),
      const Text('Thank You!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
      const SizedBox(height: 8),
      const Text('Your feedback helps us maintain quality standards across all HotelSewa properties.',
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

  Widget _surveyForm() => SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Hotel name header
      Container(
        width: double.infinity, padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          const Icon(Icons.hotel_rounded, color: AppColors.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(widget.hotelName, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const Text('How was your stay?', style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
          ])),
        ]),
      ),
      const SizedBox(height: 20),
      _ratingRow('Cleanliness 🧹', 'Was the room clean and well-maintained?', _cleanlinessRating,
          (v) => setState(() => _cleanlinessRating = v), required: true),
      _ratingRow('Photos Accuracy 📸', 'Did the room match the photos?', _accuracyRating,
          (v) => setState(() => _accuracyRating = v), required: true),
      _ratingRow('Communication 💬', 'Did the owner respond promptly?', _communicationRating,
          (v) => setState(() => _communicationRating = v)),
      _ratingRow('Value for Money 💰', 'Was it worth the price?', _valueRating,
          (v) => setState(() => _valueRating = v)),

      // Would return
      Container(
        padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Row(children: [
          const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Would you stay here again?', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          ])),
          Row(children: [
            GestureDetector(
              onTap: () => setState(() => _wouldReturn = true),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _wouldReturn ? const Color(0xFF10B981) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _wouldReturn ? const Color(0xFF10B981) : const Color(0xFFE5E7EB)),
                ),
                child: Text('Yes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: _wouldReturn ? Colors.white : const Color(0xFF374151))),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: () => setState(() => _wouldReturn = false),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: !_wouldReturn ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: !_wouldReturn ? AppColors.primary : const Color(0xFFE5E7EB)),
                ),
                child: Text('No', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                    color: !_wouldReturn ? Colors.white : const Color(0xFF374151))),
              ),
            ),
          ]),
        ]),
      ),

      // Comments
      Container(
        padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Additional Comments (optional)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E))),
          const SizedBox(height: 10),
          TextField(
            controller: _commentsCtrl, maxLines: 4,
            decoration: InputDecoration(
              hintText: 'Tell us what was great or what could improve...',
              hintStyle: const TextStyle(color: Color(0xFFADB5BD), fontSize: 13),
              filled: true, fillColor: const Color(0xFFF5F6FA),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
        ]),
      ),

      SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _submitting ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary, elevation: 0,
            padding: const EdgeInsets.symmetric(vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _submitting
              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Submit Survey', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
        ),
      ),
      const SizedBox(height: 32),
    ]),
  );

  Widget _ratingRow(String title, String subtitle, int current, ValueChanged<int> onChanged, {bool required = false}) {
    return Container(
      padding: const EdgeInsets.all(16), margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)))),
          if (required) Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
            child: const Text('Required', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary)),
          ),
        ]),
        const SizedBox(height: 4),
        Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF))),
        const SizedBox(height: 12),
        Row(mainAxisAlignment: MainAxisAlignment.start, children: List.generate(5, (i) {
          final filled = i < current;
          return GestureDetector(
            onTap: () => onChanged(i + 1),
            child: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(filled ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 32, color: filled ? const Color(0xFFF59E0B) : const Color(0xFFD1D5DB)),
            ),
          );
        })),
      ]),
    );
  }
}
