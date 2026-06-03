import '../../../../core/services/shared/api_service.dart';

class AiPricingService {
  static String? _token;
  static void setToken(String token) => _token = token;

  // GET /api/ai-pricing/rules?hotel_id=
  Future<List<Map<String, dynamic>>> getRules(String hotelId) async {
    final response = await ApiService.get(
      '/ai-pricing/rules',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    return [];
  }

  // POST /api/ai-pricing/rules
  Future<Map<String, dynamic>> saveRule(Map<String, dynamic> data) async {
    final response = await ApiService.post('/ai-pricing/rules', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to save AI pricing rule');
  }

  // DELETE /api/ai-pricing/rules/{id}
  Future<void> deleteRule(String id) async {
    final response = await ApiService.delete('/ai-pricing/rules/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete rule');
    }
  }

  // GET /api/ai-pricing/suggest?hotel_id=&room_type_id=&date=
  Future<Map<String, dynamic>> getSuggestion({
    required String hotelId,
    required String roomTypeId,
    required String date,
  }) async {
    final response = await ApiService.get(
      '/ai-pricing/suggest',
      token: _token,
      queryParams: {'hotel_id': hotelId, 'room_type_id': roomTypeId, 'date': date},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to get AI suggestion');
  }

  // POST /api/ai-pricing/apply
  Future<Map<String, dynamic>> applyPrice(Map<String, dynamic> data) async {
    final response = await ApiService.post('/ai-pricing/apply', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to apply price');
  }
}

