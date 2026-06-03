import '../../../../core/services/api_service.dart';

class PricingService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // POST /set-dynamic-pricing — set dynamic pricing rules
  static Future<Map<String, dynamic>> setDynamicPricing(Map<String, dynamic> data) async {
    final response =
        await ApiService.post('/set-dynamic-pricing', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to set dynamic pricing');
  }

  // GET /preview-price — preview price for a room/booking
  static Future<Map<String, dynamic>> previewPrice(Map<String, dynamic> params) async {
    final queryParams = params.map((k, v) => MapEntry(k, v.toString()));
    final response =
        await ApiService.get('/preview-price', token: _token, queryParams: queryParams);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to preview price');
  }

  // GET /get-package — pricing packages
  static Future<List<Map<String, dynamic>>> getPackages() async {
    final response = await ApiService.get('/get-package', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch packages');
  }

  // Instance wrappers (screens use PricingService().getPricing() etc.)
  Future<List<Map<String, dynamic>>> getPricing() => PricingService.getPackages();

  Future<Map<String, dynamic>> updateRoomPrice(String roomId, double price) =>
      PricingService.setDynamicPricing({'roomId': roomId, 'pricePerNight': price});

  Future<List<Map<String, dynamic>>> getDynamicPricing() => PricingService.getPackages();
}
