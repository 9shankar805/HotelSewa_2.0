import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

/// Automated Guest Messaging service for hotel owners.
/// Manages message templates and logs for automated guest communication.
class GuestMessagingService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// GET /guest-messaging/templates — Get all message templates.
  Future<Map<String, dynamic>> getTemplates() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.guestMessagingTemplatesEndpoint,
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load templates'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load templates: $e'};
    }
  }

  /// POST /guest-messaging/templates — Create or update a template.
  /// [data] should include: trigger (e.g. 'booking_confirmed'), message, subject
  Future<Map<String, dynamic>> saveTemplate(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.guestMessagingTemplatesEndpoint,
        data: data,
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to save template'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to save template: $e'};
    }
  }

  /// DELETE /guest-messaging/templates/{id} — Delete a template.
  Future<Map<String, dynamic>> deleteTemplate(String templateId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete(
        ApiConfig.buildPath(ApiConfig.guestMessagingTemplatesEndpoint, templateId),
        token: token,
      );
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete template'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete template: $e'};
    }
  }

  /// GET /guest-messaging/logs — Get message send history.
  Future<Map<String, dynamic>> getLogs({int page = 1}) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.guestMessagingLogsEndpoint,
        token: token,
        queryParams: {'page': page.toString()},
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load logs'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load logs: $e'};
    }
  }

  /// POST /guest-messaging/test — Send a test message using a template.
  Future<Map<String, dynamic>> testTemplate(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.guestMessagingTestEndpoint,
        data: data,
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to send test message'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send test message: $e'};
    }
  }
}
