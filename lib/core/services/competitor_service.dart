import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

/// Competitor Benchmarking service for hotel owners.
/// Tracks competitor prices and rate parity.
class CompetitorService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// GET /competitor/prices — Get all tracked competitor prices.
  Future<Map<String, dynamic>> getPrices() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.competitorPricesEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load competitor prices'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load competitor prices: $e'};
    }
  }

  /// POST /competitor/prices — Add a competitor price entry.
  /// [data] should include: competitor_name, price, date, room_type
  Future<Map<String, dynamic>> addPrice(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.competitorPricesEndpoint,
        data: data,
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add price'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add price: $e'};
    }
  }

  /// DELETE /competitor/prices/{id} — Remove a competitor price entry.
  Future<Map<String, dynamic>> deletePrice(String priceId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete(
        ApiConfig.buildPath(ApiConfig.competitorPricesEndpoint, priceId),
        token: token,
      );
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete price'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete price: $e'};
    }
  }

  /// GET /competitor/summary — Get competitive positioning summary.
  Future<Map<String, dynamic>> getSummary() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.competitorSummaryEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load summary'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load summary: $e'};
    }
  }

  /// GET /competitor/parity-check — Check rate parity across channels.
  Future<Map<String, dynamic>> getParityCheck() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.competitorParityCheckEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to check parity'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to check parity: $e'};
    }
  }

  /// GET /competitor/trend — Get 30-day price trend vs competitors.
  Future<Map<String, dynamic>> getTrend() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.competitorTrendEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load trend'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load trend: $e'};
    }
  }
}
