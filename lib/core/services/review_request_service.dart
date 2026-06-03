import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

/// Review Request service for hotel owners.
/// Allows owners to send review requests to guests after checkout.
class ReviewRequestService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// POST /review-requests/send — Send a review request to a guest.
  /// [data] should include: booking_id, guest_email (optional override)
  Future<Map<String, dynamic>> sendReviewRequest(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.reviewRequestsSendEndpoint,
        data: data,
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to send review request'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send review request: $e'};
    }
  }
}
