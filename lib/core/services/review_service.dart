import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class ReviewService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> getHotelReviews(String hotelId) async {
    try {
      // Reviews are embedded in hotel-details endpoint
      final response = await ApiService.get('${ApiConfig.hotelDetailsEndpoint}/$hotelId');
      final data = response['data'] is Map && response['data'].containsKey('data') 
          ? response['data']['data'] 
          : response['data'];
      final reviews = data['reviews'] ?? [];
      return {'success': true, 'reviews': reviews};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load reviews'};
    }
  }

  Future<Map<String, dynamic>> submitReview({
    required String hotelId,
    required int rating,
    required String comment,
    List<String>? images,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.rateHotelEndpoint, 
          token: token,
          data: {
            'hotel_id': hotelId,
            'rating': rating,
            'comment': comment,
            'images': images ?? [],
          });
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to submit review'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit review'};
    }
  }

  Future<Map<String, dynamic>> getMyReviews() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.myReviewEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'reviews': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load my reviews'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load my reviews'};
    }
  }

  Future<Map<String, dynamic>> updateReview({
    required String reviewId,
    required int rating,
    required String comment,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.put('${ApiConfig.baseUrl}/reviews/$reviewId', 
          token: token,
          data: {
            'rating': rating,
            'comment': comment,
          });
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update review'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update review'};
    }
  }

  Future<Map<String, dynamic>> deleteReview(String reviewId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete('${ApiConfig.baseUrl}/reviews/$reviewId', token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete review'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete review'};
    }
  }

  Future<Map<String, dynamic>> reportReview({
    required String reviewId,
    required String reason,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.addReviewReportEndpoint, 
          token: token,
          data: {
            'review_id': reviewId,
            'reason': reason,
          });
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to report review'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to report review'};
    }
  }
}







