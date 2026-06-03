import '../../../../core/constants/api_config.dart';
import '../../../../core/services/shared/api_service.dart';

class ReportsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/reports
  static Future<Map<String, dynamic>> getReports({Map<String, String>? filters}) async {
    final response = await ApiService.get(ApiConfig.ownerReportsEndpoint, token: _token, queryParams: filters);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch reports');
  }

  // GET /hotel-owner/analytics
  static Future<Map<String, dynamic>> getAnalytics({Map<String, String>? filters}) async {
    final response = await ApiService.get(ApiConfig.ownerAnalyticsEndpoint, token: _token, queryParams: filters);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch analytics');
  }

  // GET /api/owner/tax-report
  static Future<Map<String, dynamic>> getTaxReport({
    String? token,
    String? period,
    String? from,
    String? to,
  }) async {
    final params = <String, String>{};
    if (period != null) params['period'] = period;
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final response = await ApiService.get(
      ApiConfig.ownerTaxReportEndpoint,
      token: token ?? _token,
      queryParams: params.isNotEmpty ? params : null,
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch tax report');
  }

  // Convenience wrappers
  Future<Map<String, dynamic>> getRevenueReport(String period) async =>
      getReports(filters: {'period': period, 'type': 'revenue'});

  Future<Map<String, dynamic>> getOccupancyReport(String period) async =>
      getReports(filters: {'period': period, 'type': 'occupancy'});

  Future<Map<String, dynamic>> getBookingReport(String period) async =>
      getReports(filters: {'period': period, 'type': 'bookings'});
}

