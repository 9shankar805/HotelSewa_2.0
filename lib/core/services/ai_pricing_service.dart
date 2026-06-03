import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

/// AI Dynamic Pricing service for hotel owners.
/// Manages pricing rules, suggestions, and auto-apply.
class AiPricingService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// GET /ai-pricing/rules — Get all pricing rules for the owner's hotel.
  Future<Map<String, dynamic>> getRules() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.aiPricingRulesEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load pricing rules'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load pricing rules: $e'};
    }
  }

  /// POST /ai-pricing/rules — Save a new pricing rule.
  Future<Map<String, dynamic>> saveRule(Map<String, dynamic> rule) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.aiPricingRulesEndpoint, data: rule, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to save rule'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to save rule: $e'};
    }
  }

  /// DELETE /ai-pricing/rules/{id} — Delete a pricing rule.
  Future<Map<String, dynamic>> deleteRule(String ruleId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete(
        ApiConfig.buildPath(ApiConfig.aiPricingRulesEndpoint, ruleId),
        token: token,
      );
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete rule'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete rule: $e'};
    }
  }

  /// GET /ai-pricing/suggest — Get AI price suggestion for a specific date.
  Future<Map<String, dynamic>> getSuggestion({
    required String date,
    String? roomTypeId,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.aiPricingSuggestEndpoint,
        token: token,
        queryParams: {
          'date': date,
          if (roomTypeId != null) 'room_type_id': roomTypeId,
        },
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get suggestion'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get suggestion: $e'};
    }
  }

  /// GET /ai-pricing/suggest-range — Get suggestions for a date range (calendar view).
  Future<Map<String, dynamic>> getSuggestionRange({
    required String startDate,
    required String endDate,
    String? roomTypeId,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.aiPricingSuggestRangeEndpoint,
        token: token,
        queryParams: {
          'start_date': startDate,
          'end_date': endDate,
          if (roomTypeId != null) 'room_type_id': roomTypeId,
        },
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get range suggestions'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get range suggestions: $e'};
    }
  }

  /// POST /ai-pricing/apply — Apply a suggested price for a specific date.
  Future<Map<String, dynamic>> applyPrice(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.aiPricingApplyEndpoint, data: data, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to apply price'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to apply price: $e'};
    }
  }

  /// POST /ai-pricing/auto-apply — Auto-apply AI prices for a date range.
  Future<Map<String, dynamic>> autoApply({
    required String startDate,
    required String endDate,
    String? roomTypeId,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.aiPricingAutoApplyEndpoint,
        data: {
          'start_date': startDate,
          'end_date': endDate,
          if (roomTypeId != null) 'room_type_id': roomTypeId,
        },
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to auto-apply prices'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to auto-apply prices: $e'};
    }
  }
}
