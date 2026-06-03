import '../../../../core/services/api_service.dart';

class ReportsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/reports
  static Future<Map<String, dynamic>> getReports({Map<String, String>? filters}) async {
    final response =
        await ApiService.get('/hotel-owner/reports', token: _token, queryParams: filters);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch reports');
  }

  // GET /hotel-owner/analytics
  static Future<Map<String, dynamic>> getAnalytics({Map<String, String>? filters}) async {
    final response =
        await ApiService.get('/hotel-owner/analytics', token: _token, queryParams: filters);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch analytics');
  }

  // Convenience wrappers
  Future<Map<String, dynamic>> getRevenueReport(String period) async =>
      getReports(filters: {'period': period, 'type': 'revenue'});

  Future<Map<String, dynamic>> getOccupancyReport(String period) async =>
      getReports(filters: {'period': period, 'type': 'occupancy'});

  Future<Map<String, dynamic>> getBookingReport(String period) async =>
      getReports(filters: {'period': period, 'type': 'bookings'});
}
