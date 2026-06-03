import '../../../../core/services/api_service.dart';

class ReviewsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/reviews
  static Future<List<Map<String, dynamic>>> getReviews(
      {Map<String, String>? filters}) async {
    final response =
        await ApiService.get('/hotel-owner/reviews', token: _token, queryParams: filters);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch reviews');
  }

  // POST /hotel-owner/reviews/{id}/reply — reply to a review
  static Future<Map<String, dynamic>> replyToReview(String reviewId, String reply) async {
    final response = await ApiService.post(
      '/hotel-owner/reviews/$reviewId/reply',
      token: _token,
      data: {'reply': reply},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to reply to review');
  }

  // Instance wrappers (screens use ReviewsService().fetchReviews() etc.)
  Future<Map<String, dynamic>> fetchReviews() async {
    final list = await ReviewsService.getReviews();
    return {'data': list};
  }

  Future<Map<String, dynamic>> submitReply(String reviewId, String reply) =>
      ReviewsService.replyToReview(reviewId, reply);
}
