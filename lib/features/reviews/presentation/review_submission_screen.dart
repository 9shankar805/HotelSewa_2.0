import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/review_service.dart';
import '../../../core/navigation/app_routes.dart';

class ReviewSubmissionScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const ReviewSubmissionScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<ReviewSubmissionScreen> createState() => _ReviewSubmissionScreenState();
}

class _ReviewSubmissionScreenState extends State<ReviewSubmissionScreen> {
  int _rating = 0;
  final _commentController = TextEditingController();
  bool _isSubmitting = false;
  Map<String, dynamic> _hotel = {};
  Map<String, dynamic> _booking = {};

  final ReviewService _reviewService = ReviewService();

  @override
  void initState() {
    super.initState();
    _extractArguments();
  }

  void _extractArguments() {
    if (widget.arguments != null) {
      _hotel = widget.arguments!['hotel'] ?? {};
      _booking = widget.arguments!['booking'] ?? {};
    }
  }

  String _getRatingText() {
    const texts = {1: 'Poor', 2: 'Fair', 3: 'Good', 4: 'Very Good', 5: 'Excellent'};
    return _rating > 0 ? texts[_rating]! : 'Tap to rate';
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a rating')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final result = await _reviewService.submitReview(
        hotelId: _hotel['id'].toString(),
        rating: _rating,
        comment: _commentController.text.trim(),
      );

      setState(() => _isSubmitting = false);

      if (result['success'] && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: const Text('Thank You!', style: TextStyle(fontWeight: FontWeight.w700)),
            content: const Text('Your review has been submitted successfully.'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(ctx).pop(); // close dialog only
                  context.go('/main-navigation'); // safe single navigation to root
                },
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: const Text('OK', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Failed to submit review')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error submitting review')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => AppRoutes.goBack(context)),
        title: Text('Write Review - ${_hotel['name'] ?? 'Hotel'}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black)),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      _hotel['image'] ?? 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400',
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        width: 80, height: 80, color: const Color(0xFFEEEEEE),
                        child: const Icon(Icons.image_not_supported_rounded, color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _hotel['name'] ?? 'Hotel Name',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [_hotel['city'], _hotel['state']].where((v) => v != null && v.toString().isNotEmpty).join(', '),
                          style: const TextStyle(fontSize: 14, color: Color(0xFF666666)),
                        ),
                        if (_booking.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Stay: ${_booking['check_in_date'] ?? ''} - ${_booking['check_out_date'] ?? ''}',
                            style: const TextStyle(fontSize: 12, color: Color(0xFF888888)),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text('How was your stay?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final star = index + 1;
                      return InkWell(
                        onTap: () => setState(() => _rating = star),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            star <= _rating ? Icons.star : Icons.star_outline,
                            size: 40,
                            color: star <= _rating ? const Color(0xFFFFD700) : const Color(0xFFDDDDDD),
                          ),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(_getRatingText(), style: const TextStyle(fontSize: 16, color: Color(0xFF666666))),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Share your experience (Optional)', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _commentController,
                    maxLength: 500,
                    maxLines: 4,
                    decoration: InputDecoration(
                      hintText: 'Tell others about your stay...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFFDDDDDD))),
                      contentPadding: const EdgeInsets.all(12),
                    ),
                    onChanged: (value) => setState(() {}),
                  ),
                  Text('${_commentController.text.length}/500', style: const TextStyle(fontSize: 12, color: Color(0xFF888888)), textAlign: TextAlign.right),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting || _rating == 0 ? null : _submitReview,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: const Color(0xFFCCCCCC),
                    padding: const EdgeInsets.all(16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: Text(_isSubmitting ? 'Submitting...' : 'Submit Review', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Your review will be visible to other users and help them make better decisions.',
                style: TextStyle(fontSize: 12, color: Color(0xFF888888), height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }
}
