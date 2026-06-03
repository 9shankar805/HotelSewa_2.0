import 'api_service.dart';

/// Dashboard & Analytics endpoints for hotel owner.
class DashboardService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /hotel-owner/dashboard (also /dashboard)
  static Future<Map<String, dynamic>> getDashboard() async {
    final response = await ApiService.get('/hotel-owner/dashboard', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch dashboard');
  }

  // GET /owner-analytics
  static Future<Map<String, dynamic>> getOwnerAnalytics() async {
    final response = await ApiService.get('/owner-analytics', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch analytics');
  }

  // GET /hotel-owner/analytics
  static Future<Map<String, dynamic>> getExtendedAnalytics({String? hotelId}) async {
    final response = await ApiService.get(
      '/hotel-owner/analytics',
      token: _token,
      queryParams: hotelId != null ? {'hotel_id': hotelId} : null,
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch extended analytics');
  }

  // GET /hotel-owner/reports (also /reports)
  static Future<Map<String, dynamic>> getReports({String? hotelId}) async {
    final response = await ApiService.get(
      '/hotel-owner/reports',
      token: _token,
      queryParams: hotelId != null ? {'hotel_id': hotelId} : null,
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch reports');
  }
}
