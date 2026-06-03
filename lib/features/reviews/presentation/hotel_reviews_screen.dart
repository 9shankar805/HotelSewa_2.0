import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/review_service.dart';
import '../../../core/navigation/app_routes.dart';

class HotelReviewsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  
  const HotelReviewsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<HotelReviewsScreen> createState() => _HotelReviewsScreenState();
}

class _HotelReviewsScreenState extends State<HotelReviewsScreen> {
  String _sortBy = 'recent';
  List<Map<String, dynamic>> _reviews = [];
  Map<String, dynamic> _hotel = {};
  bool _loading = false;
  
  final ReviewService _reviewService = ReviewService();
  Map<int, int> _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};

  @override
  void initState() {
    super.initState();
    _extractArguments();
    _loadReviews();
  }

  void _extractArguments() {
    if (widget.arguments != null) {
      _hotel = widget.arguments!['hotel'] ?? {};
    }
  }

  Future<void> _loadReviews() async {
    final hotelId = _hotel['id']?.toString();
    if (hotelId == null) {
      setState(() => _loading = false);
      return;
    }

    setState(() => _loading = true);
    
    try {
      final result = await _reviewService.getHotelReviews(hotelId);
      if (result['success'] && mounted) {
        final List reviews = result['reviews'] as List;
        _reviews = reviews.map((review) => {
          'id': review['id'],
          'user': {
            'name': review['user']?['name'] ?? 'Anonymous',
            'avatar': review['user']?['profile'] ?? 'https://images.unsplash.com/photo-1542314831-068cd1dbfeeb?w=400',
          },
          'rating': review['rating']?.toInt() ?? 0,
          'comment': review['comment'] ?? '',
          'stayDate': review['stay_date'] ?? '',
          'createdAt': review['created_at']?.toString().split('T')[0] ?? '',
        }).toList();
        
        _calculateRatingDistribution();
      }
    } catch (e) {
      debugPrint('Error loading reviews: $e');
    }
    
    setState(() => _loading = false);
  }

  void _calculateRatingDistribution() {
    _ratingDistribution = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
    
    for (var review in _reviews) {
      final rating = review['rating'] as int;
      if (rating >= 1 && rating <= 5) {
        _ratingDistribution[rating] = (_ratingDistribution[rating] ?? 0) + 1;
      }
    }
  }

  List<Map<String, dynamic>> _getSortedReviews() {
    List<Map<String, dynamic>> sortedReviews = List.from(_reviews);
    
    switch (_sortBy) {
      case 'recent':
        sortedReviews.sort((a, b) => (b['createdAt'] as String).compareTo(a['createdAt'] as String));
        break;
      case 'rating_high':
        sortedReviews.sort((a, b) => (b['rating'] as int).compareTo(a['rating'] as int));
        break;
      case 'rating_low':
        sortedReviews.sort((a, b) => (a['rating'] as int).compareTo(b['rating'] as int));
        break;
    }
    
    return sortedReviews;
  }

  Future<void> _reportReview(String reviewId) async {
    // Show dialog to enter reason
    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Report Review'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(
            hintText: 'Reason for reporting...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Report'),
          ),
        ],
      ),
    );
    
    if (result != null && result.isNotEmpty) {
      try {
        final response = await _reviewService.reportReview(
          reviewId: reviewId,
          reason: result,
        );
        
        if (response['success'] && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Review reported successfully')),
          );
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(response['message'] ?? 'Failed to report review')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error reporting review')),
          );
        }
      }
    }
  }

  Widget _avatarPlaceholder(String name) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: const TextStyle(
            color: AppColors.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final total = _ratingDistribution.values.reduce((a, b) => a + b);
    final averageRating = total > 0 
        ? (_ratingDistribution.entries.fold<double>(0, (sum, entry) => sum + (entry.key * entry.value)) / total)
        : 0.0;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(icon: const Icon(Icons.arrow_back, color: Colors.black), onPressed: () => AppRoutes.goBack(context)),
        title: Text(
          'Reviews - ${_hotel['name'] ?? 'Hotel'}',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black),
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.rate_review, color: AppColors.primary),
            onPressed: () {
              AppRoutes.navigateTo(context, AppRoutes.reviewSubmission, arguments: {
                'hotelId': _hotel['id'],
                'hotelName': _hotel['name'],
              });
            },
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadReviews,
              child: ListView(
                children: [
                  Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(color: const Color(0xFFF9F9F9), borderRadius: BorderRadius.circular(8)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(
                              width: 90,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    averageRating.toStringAsFixed(1),
                                    style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                  Row(
                                    children: List.generate(5, (i) => Icon(
                                      i < averageRating.round() ? Icons.star : Icons.star_border,
                                      size: 16,
                                      color: const Color(0xFFFFD700),
                                    )),
                                  ),
                                  Text('$total reviews', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Breakdown', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 8),
                                  ...[5, 4, 3, 2, 1].map((rating) {
                                    final count = _ratingDistribution[rating] ?? 0;
                                    final percentage = total > 0 ? (count / total) * 100 : 0;
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          SizedBox(width: 16, child: Text('$rating', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
                                          const SizedBox(width: 2),
                                          const Icon(Icons.star, size: 10, color: Color(0xFFFFD700)),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Container(
                                              height: 6,
                                              decoration: BoxDecoration(color: const Color(0xFFEEEEEE), borderRadius: BorderRadius.circular(3)),
                                              child: FractionallySizedBox(
                                                alignment: Alignment.centerLeft,
                                                widthFactor: percentage / 100,
                                                child: Container(decoration: BoxDecoration(color: const Color(0xFFFFD700), borderRadius: BorderRadius.circular(3))),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          SizedBox(width: 24, child: Text('$count', style: const TextStyle(fontSize: 11, color: Color(0xFF666666)), textAlign: TextAlign.right)),
                                        ],
                                      ),
                                    );
                                  }).toList(),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          const Text('Sort by:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                          const SizedBox(width: 12),
                          ...[
                            {'key': 'recent', 'label': 'Most Recent'},
                            {'key': 'rating_high', 'label': 'Highest Rating'},
                            {'key': 'rating_low', 'label': 'Lowest Rating'},
                          ].map((option) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: InkWell(
                                onTap: () => setState(() => _sortBy = option['key']!),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: _sortBy == option['key'] ? AppColors.primary : const Color(0xFFF0F0F0),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Text(option['label']!, style: TextStyle(fontSize: 12, color: _sortBy == option['key'] ? Colors.white : const Color(0xFF666666))),
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      ),
                    ),
                  ),
                  ..._getSortedReviews().map((review) {
                    final avatar = (review['user'] as Map)['avatar']?.toString() ?? '';
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE)))),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(20),
                                      child: avatar.isNotEmpty 
                                        ? Image.network(
                                            avatar, 
                                            width: 40, height: 40, fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) => _avatarPlaceholder((review['user'] as Map)['name'] ?? 'A'),
                                          )
                                        : _avatarPlaceholder((review['user'] as Map)['name'] ?? 'A'),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text((review['user'] as Map)['name'], style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                          if (review['stayDate'].isNotEmpty) 
                                            Text('Stayed: ${review['stayDate']}', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Row(
                                    children: List.generate(5, (i) => Icon(i < (review['rating'] as num) ? Icons.star : Icons.star_outline, size: 14, color: i < (review['rating'] as num) ? const Color(0xFFFFD700) : const Color(0xFFDDDDDD))),
                                  ),
                                  const SizedBox(height: 2),
                                  Text('${review['rating']}/5', style: const TextStyle(fontSize: 12, color: Color(0xFF666666))),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(review['comment'] as String, style: const TextStyle(fontSize: 14, height: 1.4, color: Color(0xFF333333))),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(review['createdAt'] as String, style: const TextStyle(fontSize: 12, color: Color(0xFF888888))),
                              IconButton(
                                icon: const Icon(Icons.flag, size: 16, color: Color(0xFF999999)),
                                onPressed: () => _reportReview(review['id'].toString()),
                                tooltip: 'Report review',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  if (_reviews.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      child: const Center(
                        child: Column(
                          children: [
                            Icon(Icons.rate_review, size: 64, color: Color(0xFFDDDDDD)),
                            SizedBox(height: 16),
                            Text('No reviews yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF666666))),
                            SizedBox(height: 8),
                            Text('Be the first to review this hotel!', style: TextStyle(fontSize: 14, color: Color(0xFF999999))),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
    );
  }
}
