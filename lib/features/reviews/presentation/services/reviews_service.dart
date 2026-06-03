import '../../../../core/constants/api_config.dart';
import '../../../../core/services/shared/api_service.dart';

class ReviewsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /my-review
  Future<Map<String, dynamic>> getMyReviews() async {
    try {
      final response = await ApiService.get(ApiConfig.myReviewEndpoint);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load reviews'};
    }
  }

  // POST /add-review-report
  Future<Map<String, dynamic>> reportReview(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post(ApiConfig.addReviewReportEndpoint, data: data);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to report review'};
    }
  }

  // GET /hotel-reviews/{hotelId}
  Future<Map<String, dynamic>> getHotelReviews(String hotelId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.rateHotelEndpoint, hotelId));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load hotel reviews'};
    }
  }

  // GET /hotel-owner/reviews
  static Future<List<Map<String, dynamic>>> getReviews({Map<String, String>? filters}) async {
    final response = await ApiService.get(ApiConfig.ownerReviewsEndpoint, token: _token, queryParams: filters);
    if (response['success'] == true) {
      final data = response['data'];
      List raw = data is List
          ? data
          : (data is Map ? (data['data'] ?? data['reviews'] ?? data['items'] ?? []) : []);
      return List<Map<String, dynamic>>.from(raw);
    }
    throw Exception(response['message'] ?? 'Failed to fetch reviews');
  }

  // POST /hotel-owner/reviews/{id}/reply
  static Future<Map<String, dynamic>> replyToReview(String reviewId, String reply) async {
    final response = await ApiService.post(
      ApiConfig.buildPath(ApiConfig.ownerReviewReplyEndpoint, '$reviewId/reply'),
      token: _token,
      data: {'reply': reply},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to reply to review');
  }

  // GET /api/owner/review-requests
  static Future<Map<String, dynamic>> getReviewRequests({String? token}) async {
    final response = await ApiService.get(ApiConfig.ownerReviewRequestsEndpoint, token: token ?? _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch review requests');
  }

  // Instance wrappers
  Future<Map<String, dynamic>> fetchReviews() async {
    final list = await ReviewsService.getReviews();
    return {'data': list};
  }

  Future<Map<String, dynamic>> submitReply(String reviewId, String reply) =>
      ReviewsService.replyToReview(reviewId, reply);
}

