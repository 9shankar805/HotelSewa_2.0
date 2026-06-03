import '../../../../core/constants/api_config.dart';
import '../../../../core/services/shared/api_service.dart';

class PricingService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // POST /set-dynamic-pricing
  static Future<Map<String, dynamic>> setDynamicPricing(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.setDynamicPricingEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to set dynamic pricing');
  }

  // GET /preview-price
  static Future<Map<String, dynamic>> previewPrice(Map<String, dynamic> params) async {
    final queryParams = params.map((k, v) => MapEntry(k, v.toString()));
    final response = await ApiService.get(ApiConfig.previewPriceEndpoint, token: _token, queryParams: queryParams);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to preview price');
  }

  // GET /get-package
  static Future<List<Map<String, dynamic>>> getPackages() async {
    final response = await ApiService.get(ApiConfig.getPackagesEndpoint, token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch packages');
  }

  // GET /api/owner/competitor-benchmark
  static Future<Map<String, dynamic>> getCompetitorBenchmark({String? token}) async {
    final response = await ApiService.get(ApiConfig.ownerCompetitorBenchmarkEndpoint, token: token ?? _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch competitor benchmark');
  }

  // Instance wrappers
  Future<List<Map<String, dynamic>>> getPricing() => PricingService.getPackages();

  Future<Map<String, dynamic>> updateRoomPrice(String roomId, double price) =>
      PricingService.setDynamicPricing({'roomId': roomId, 'pricePerNight': price});

  Future<List<Map<String, dynamic>>> getDynamicPricing() => PricingService.getPackages();
}

