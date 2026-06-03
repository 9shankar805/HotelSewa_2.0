import '../../../../constants/api_config.dart';
import 'api_service.dart';

/// Dynamic pricing and AI pricing endpoints.
class PricingService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // POST /set-dynamic-pricing
  // body: { hotel_id, room_type_id, pricing_type, label, start_date, end_date, multiplier }
  static Future<Map<String, dynamic>> setDynamicPricing(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.setDynamicPricingEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to set dynamic pricing');
  }

  // GET /preview-price?hotel_id=&room_id=&check_in=&check_out=
  static Future<Map<String, dynamic>> previewPrice({
    required String hotelId,
    required String roomId,
    required String checkIn,
    required String checkOut,
  }) async {
    final response = await ApiService.get(
      ApiConfig.previewPriceEndpoint,
      token: _token,
      queryParams: {
        'hotel_id': hotelId,
        'room_id': roomId,
        'check_in': checkIn,
        'check_out': checkOut,
      },
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to preview price');
  }

  // ==================== AI PRICING ====================

  // GET /ai-pricing/rules?hotel_id=
  static Future<List<Map<String, dynamic>>> getAiPricingRules(String hotelId) async {
    final response = await ApiService.get(
      ApiConfig.aiPricingRulesEndpoint,
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch AI pricing rules');
  }

  // POST /ai-pricing/rules — create or update
  // body: { hotel_id, room_type_id, min_price, max_price, strategy, is_active }
  static Future<Map<String, dynamic>> saveAiPricingRule(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.aiPricingRulesEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to save AI pricing rule');
  }

  // DELETE /ai-pricing/rules/{id}
  static Future<void> deleteAiPricingRule(String id) async {
    final response = await ApiService.delete(
      ApiConfig.buildPath(ApiConfig.aiPricingRulesEndpoint, id),
      token: _token,
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete AI pricing rule');
    }
  }

  // GET /ai-pricing/suggest?hotel_id=&room_type_id=&date=
  static Future<Map<String, dynamic>> getAiPriceSuggestion({
    required String hotelId,
    required String roomTypeId,
    required String date,
  }) async {
    final response = await ApiService.get(
      ApiConfig.aiPricingSuggestEndpoint,
      token: _token,
      queryParams: {'hotel_id': hotelId, 'room_type_id': roomTypeId, 'date': date},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to get AI price suggestion');
  }

  // GET /ai-pricing/suggest-range?hotel_id=&room_type_id=&from=&to=
  static Future<List<Map<String, dynamic>>> getAiPriceSuggestionRange({
    required String hotelId,
    required String roomTypeId,
    required String from,
    required String to,
  }) async {
    final response = await ApiService.get(
      ApiConfig.aiPricingSuggestRangeEndpoint,
      token: _token,
      queryParams: {
        'hotel_id': hotelId,
        'room_type_id': roomTypeId,
        'from': from,
        'to': to,
      },
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to get AI price suggestion range');
  }

  // POST /ai-pricing/apply
  // body: { hotel_id, room_type_id, date, price }
  static Future<Map<String, dynamic>> applyAiPrice(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.aiPricingApplyEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to apply AI price');
  }

  // POST /ai-pricing/auto-apply
  static Future<Map<String, dynamic>> autoApplyAiPrices(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.aiPricingAutoApplyEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to auto-apply AI prices');
  }
}
