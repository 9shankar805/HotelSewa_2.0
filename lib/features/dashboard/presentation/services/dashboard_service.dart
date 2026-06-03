import '../../../../core/services/shared/api_service.dart';

class DashboardService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/dashboard (static)
  static Future<Map<String, dynamic>> fetchDashboard({
    String? period,
    String? token,
  }) async {
    final queryParams = <String, String>{};
    if (period != null) queryParams['period'] = period;
    final response = await ApiService.get(
      '/hotel-owner/dashboard',
      token: token ?? _token,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch dashboard data');
  }

  // GET /get-notification-list
  static Future<Map<String, dynamic>> getNotifications({String? token}) async {
    return ApiService.get('/get-notification-list', token: token ?? _token);
  }

  // ── Instance wrappers (called by DashboardProvider via _dashboardService.x()) ──

  Future<Map<String, dynamic>> getDashboardData({String? period, String? token}) =>
      DashboardService.fetchDashboard(period: period, token: token);

  Future<Map<String, dynamic>> getRecentBookings({int limit = 5, String? token}) =>
      ApiService.get(
        '/hotel-owner/bookings',
        token: token ?? _token,
        queryParams: {'limit': limit.toString(), 'sort': 'recent'},
      );

  Future<Map<String, dynamic>> getEarningsData({String? period, String? token}) =>
      ApiService.get(
        '/hotel-owner/earnings',
        token: token ?? _token,
        queryParams: period != null ? {'period': period} : null,
      );
}

