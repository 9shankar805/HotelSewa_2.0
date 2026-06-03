import 'api_service.dart';

class PriceAlertsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // POST /price-alerts
  static Future<Map<String, dynamic>> createAlert(Map<String, dynamic> data) async {
    final response = await ApiService.post('/price-alerts', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create price alert');
  }

  // GET /price-alerts/my
  static Future<List<Map<String, dynamic>>> getMyAlerts() async {
    final response = await ApiService.get('/price-alerts/my', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch price alerts');
  }

  // DELETE /price-alerts/{id}
  static Future<void> deleteAlert(String alertId) async {
    final response = await ApiService.delete('/price-alerts/$alertId', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete price alert');
    }
  }
}
