import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/review_service.dart';

class RateStayScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const RateStayScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<RateStayScreen> createState() => _RateStayScreenState();
}

class _RateStayScreenState extends State<RateStayScreen> {
  final ReviewService _reviewService = ReviewService();
  double _overallRating = 0;
  double _cleanlinessRating = 0;
  double _serviceRating = 0;
  double _locationRating = 0;
  double _valueRating = 0;
  final _reviewCtrl = TextEditingController();
  final Set<String> _highlights = {};
  bool _loading = false;

  final _highlightOptions = [
    'Great location', 'Excellent service', 'Clean rooms', 'Good value',
    'Amazing breakfast', 'Comfortable beds', 'Friendly staff', 'Beautiful views',
    'Great pool', 'Quiet & peaceful',
  ];

  String get _ratingLabel {
    if (_overallRating == 0) return 'Tap to rate';
    if (_overallRating <= 1) return 'Terrible';
    if (_overallRating <= 2) return 'Poor';
    if (_overallRating <= 3) return 'Average';
    if (_overallRating <= 4) return 'Good';
    return 'Excellent';
  }

  Color get _ratingColor {
    if (_overallRating == 0) return AppColors.gray;
    if (_overallRating <= 2) return AppColors.error;
    if (_overallRating <= 3) return AppColors.warning;
    return AppColors.success;
  }

  Future<void> _submit() async {
    if (_overallRating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please rate your stay'), behavior: SnackBarBehavior.floating));
      return;
    }
    setState(() => _loading = true);
    final booking = widget.arguments ?? {};
    final result = await _reviewService.submitReview(
      hotelId: booking['hotelId']?.toString() ?? '',
      rating: _overallRating.toInt(),
      comment: _reviewCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (result['success']) {
      _showThankYou();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message'] ?? 'Failed to submit review'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  void _showThankYou() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(28),
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 72, height: 72, decoration: BoxDecoration(color: AppColors.goldLight, shape: BoxShape.circle), child: const Icon(Icons.star_rounded, color: AppColors.gold, size: 36)),
            const SizedBox(height: 16),
            const Text('Thank You!', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
            const SizedBox(height: 8),
            const Text('Your review helps other travelers make better decisions.', style: TextStyle(fontSize: 14, color: AppColors.gray, height: 1.5), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(color: AppColors.successLight, borderRadius: BorderRadius.circular(14)),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.diamond_outlined, color: AppColors.success, size: 18),
                SizedBox(width: 8),
                Text('+50 loyalty points earned!', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.success)),
              ]),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () { Navigator.pop(context); Navigator.pop(context); },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 14), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text('Done', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _reviewCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.arguments ?? {};
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Rate Your Stay', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Hotel info
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
                    child: Row(
                      children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: AppColors.surfaceVariant, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.hotel_rounded, color: AppColors.gray, size: 24)),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(booking['hotelName'] ?? 'Grand Horizon Resort', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                          Text('${booking['checkIn'] ?? '15 Jan'} – ${booking['checkOut'] ?? '17 Jan'}', style: const TextStyle(fontSize: 12, color: AppColors.gray)),
                        ])),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),

                  // Overall rating
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                    child: Column(
                      children: [
                        const Text('Overall Experience', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        const SizedBox(height: 16),
                        RatingBar.builder(
                          initialRating: _overallRating,
                          minRating: 1,
                          itemSize: 44,
                          glow: false,
                          itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.gold),
                          onRatingUpdate: (r) => setState(() => _overallRating = r),
                        ),
                        const SizedBox(height: 10),
                        Text(_ratingLabel, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _ratingColor)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 60.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  // Category ratings
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Rate by Category', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        const SizedBox(height: 16),
                        _categoryRating('Cleanliness', Icons.cleaning_services_outlined, _cleanlinessRating, (v) => setState(() => _cleanlinessRating = v)),
                        _categoryRating('Service', Icons.room_service_outlined, _serviceRating, (v) => setState(() => _serviceRating = v)),
                        _categoryRating('Location', Icons.location_on_outlined, _locationRating, (v) => setState(() => _locationRating = v)),
                        _categoryRating('Value for Money', Icons.attach_money_rounded, _valueRating, (v) => setState(() => _valueRating = v)),
                      ],
                    ),
                  ).animate().fadeIn(delay: 120.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  // Highlights
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('What did you love?', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _highlightOptions.map((h) {
                            final sel = _highlights.contains(h);
                            return GestureDetector(
                              onTap: () => setState(() => sel ? _highlights.remove(h) : _highlights.add(h)),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: sel ? AppColors.primary.withOpacity(0.1) : AppColors.background,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray, width: sel ? 1.5 : 1),
                                ),
                                child: Text(h, style: TextStyle(fontSize: 12, fontWeight: sel ? FontWeight.w600 : FontWeight.w400, color: sel ? AppColors.primary : AppColors.darkGray)),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.1),
                  const SizedBox(height: 16),

                  // Written review
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Write a Review', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
                        const SizedBox(height: 4),
                        const Text('Optional — share your experience in detail', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _reviewCtrl,
                          maxLines: 5,
                          maxLength: 500,
                          decoration: InputDecoration(
                            hintText: 'Tell others about your stay...',
                            filled: true, fillColor: AppColors.background,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.lightGray)),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.1),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _loading
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Submit Review', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoryRating(String label, IconData icon, double value, ValueChanged<double> onChanged) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.gray),
          const SizedBox(width: 10),
          SizedBox(width: 110, child: Text(label, style: const TextStyle(fontSize: 13, color: AppColors.darkGray))),
          Expanded(
            child: RatingBar.builder(
              initialRating: value,
              minRating: 1,
              itemSize: 22,
              glow: false,
              itemBuilder: (_, __) => const Icon(Icons.star_rounded, color: AppColors.gold),
              onRatingUpdate: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}
