import '../../../../core/services/shared/api_service.dart';

class SettingsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /get-system-settings
  Future<Map<String, dynamic>> getSettings() async {
    final response = await ApiService.get('/get-system-settings', token: _token);
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to fetch settings');
  }

  // POST /update-profile — update user/app settings
  Future<Map<String, dynamic>> updateSettings(Map<String, dynamic> settingsData) async {
    final response = await ApiService.post(
      '/update-profile',
      token: _token,
      data: settingsData,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to update settings');
  }

  // GET /get-languages
  Future<List<Map<String, dynamic>>> getLanguages() async {
    final response = await ApiService.get('/get-languages', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch languages');
  }

  // GET /app-payment-status
  Future<Map<String, dynamic>> getPaymentStatus() async {
    final response = await ApiService.get('/app-payment-status', token: _token);
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to fetch payment status');
  }
}

