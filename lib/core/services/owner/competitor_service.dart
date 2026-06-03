import '../shared/api_service.dart';

/// Competitor Benchmarking for hotel owners.
class CompetitorService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /competitor/prices?hotel_id=
  static Future<List<Map<String, dynamic>>> getCompetitorPrices(String hotelId) async {
    final response = await ApiService.get(
      '/competitor/prices',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch competitor prices');
  }

  // POST /competitor/prices — add manually
  static Future<Map<String, dynamic>> addCompetitorPrice(Map<String, dynamic> data) async {
    final response = await ApiService.post('/competitor/prices', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add competitor price');
  }

  // DELETE /competitor/prices/{id}
  static Future<void> removeCompetitorPrice(String id) async {
    final response = await ApiService.delete('/competitor/prices/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to remove competitor price');
    }
  }

  // GET /competitor/summary?hotel_id= — 30-day chart data
  static Future<Map<String, dynamic>> getSummary(String hotelId) async {
    final response = await ApiService.get(
      '/competitor/summary',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch competitor summary');
  }

  // GET /competitor/parity-check?hotel_id=
  static Future<List<Map<String, dynamic>>> getParityViolations(String hotelId) async {
    final response = await ApiService.get(
      '/competitor/parity-check',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch parity violations');
  }

  // GET /competitor/trend?hotel_id=&competitor=
  static Future<List<Map<String, dynamic>>> getCompetitorTrend({
    required String hotelId,
    required String competitor,
  }) async {
    final response = await ApiService.get(
      '/competitor/trend',
      token: _token,
      queryParams: {'hotel_id': hotelId, 'competitor': competitor},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch competitor trend');
  }
}


