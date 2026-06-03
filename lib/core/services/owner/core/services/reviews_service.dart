import '../../../../constants/api_config.dart';
import 'api_service.dart';

/// Reviews management for hotel owners.
class ReviewsService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /hotel-owner/reviews?hotel_id=
  static Future<List<Map<String, dynamic>>> getReviews(String hotelId) async {
    final response = await ApiService.get(
      ApiConfig.ownerReviewsEndpoint,
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch reviews');
  }

  // POST /hotel-owner/reviews/{id}/reply
  // body: { reply }
  static Future<Map<String, dynamic>> replyToReview(String id, String reply) async {
    final response = await ApiService.post(
      ApiConfig.buildPath(ApiConfig.ownerReviewReplyEndpoint, '$id/reply'),
      token: _token,
      data: {'reply': reply},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to reply to review');
  }

  // POST /review-requests/send
  static Future<Map<String, dynamic>> sendReviewRequest(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.sendReviewRequestEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to send review request');
  }
}
