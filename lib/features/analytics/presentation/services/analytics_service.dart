import '../../../../core/services/shared/api_service.dart';

class AnalyticsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/analytics
  static Future<Map<String, dynamic>> getAnalytics({String? period}) async {
    final queryParams = <String, String>{};
    if (period != null) queryParams['period'] = period;
    final response = await ApiService.get(
      '/hotel-owner/analytics',
      token: _token,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch analytics');
  }

  // GET /owner-analytics
  static Future<Map<String, dynamic>> getOwnerAnalytics({String? period}) async {
    final queryParams = <String, String>{};
    if (period != null) queryParams['period'] = period;
    final response = await ApiService.get(
      '/owner-analytics',
      token: _token,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch owner analytics');
  }

  // GET /hotel-owner/order-analytics
  static Future<Map<String, dynamic>> getOrderAnalytics() async {
    final response = await ApiService.get('/hotel-owner/order-analytics', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch order analytics');
  }

  // Legacy compat
  Future<Map<String, dynamic>> getAnalyticsOverview({String period = 'month'}) async {
    return getAnalytics(period: period);
  }
}

