import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

/// Tax Reporting service for hotel owners and admins.
/// Manages tax rates and generates tax reports.
class TaxService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// GET /taxes — Get all configured tax rates.
  Future<Map<String, dynamic>> getTaxRates() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.taxesEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load tax rates'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load tax rates: $e'};
    }
  }

  /// POST /taxes — Save a tax rate configuration.
  /// [data] should include: name, rate (percentage), type (inclusive/exclusive)
  Future<Map<String, dynamic>> saveTaxRate(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.taxesEndpoint, data: data, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to save tax rate'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to save tax rate: $e'};
    }
  }

  /// DELETE /taxes/{id} — Delete a tax rate.
  Future<Map<String, dynamic>> deleteTaxRate(String taxId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete(
        ApiConfig.buildPath(ApiConfig.taxesEndpoint, taxId),
        token: token,
      );
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete tax rate'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete tax rate: $e'};
    }
  }

  /// GET /taxes/report — Get tax report for a date range.
  Future<Map<String, dynamic>> getReport({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.taxesReportEndpoint,
        token: token,
        queryParams: {'start_date': startDate, 'end_date': endDate},
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load tax report'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load tax report: $e'};
    }
  }

  /// GET /taxes/report/export — Export tax report as PDF.
  /// Returns a download URL or base64 PDF data.
  Future<Map<String, dynamic>> exportReport({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.taxesReportExportEndpoint,
        token: token,
        queryParams: {'start_date': startDate, 'end_date': endDate},
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to export report'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to export report: $e'};
    }
  }
}
