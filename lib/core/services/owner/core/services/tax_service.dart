import 'api_service.dart';

/// Tax Rates & Reports for hotel owners.
class TaxService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /taxes?hotel_id=
  static Future<List<Map<String, dynamic>>> getTaxes(String hotelId) async {
    final response = await ApiService.get(
      '/taxes',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch taxes');
  }

  // POST /taxes — add or update
  // body: { hotel_id, name, rate, is_inclusive, is_active }
  static Future<Map<String, dynamic>> saveTax(Map<String, dynamic> data) async {
    final response = await ApiService.post('/taxes', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to save tax');
  }

  // DELETE /taxes/{id}
  static Future<void> deleteTax(String id) async {
    final response = await ApiService.delete('/taxes/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete tax');
    }
  }

  // GET /taxes/report?hotel_id=&from=&to=
  static Future<Map<String, dynamic>> getTaxReport({
    required String hotelId,
    String? from,
    String? to,
  }) async {
    final params = <String, String>{'hotel_id': hotelId};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final response = await ApiService.get('/taxes/report', token: _token, queryParams: params);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch tax report');
  }

  // GET /taxes/report/export?hotel_id=&from=&to=
  static Future<Map<String, dynamic>> exportTaxReport({
    required String hotelId,
    String? from,
    String? to,
  }) async {
    final params = <String, String>{'hotel_id': hotelId};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    final response = await ApiService.get('/taxes/report/export', token: _token, queryParams: params);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to export tax report');
  }
}
