import 'api_service.dart';

/// Offers / Promotions for hotel owners.
class OffersService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /hotel-owner/offers?hotel_id=
  static Future<List<Map<String, dynamic>>> getOffers(String hotelId) async {
    final response = await ApiService.get(
      '/hotel-owner/offers',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch offers');
  }

  // POST /hotel-owner/offers
  static Future<Map<String, dynamic>> createOffer(Map<String, dynamic> data) async {
    final response = await ApiService.post('/hotel-owner/offers', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create offer');
  }

  // POST /hotel-owner/offers/{id}
  static Future<Map<String, dynamic>> updateOffer(String id, Map<String, dynamic> data) async {
    final response = await ApiService.post('/hotel-owner/offers/$id', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update offer');
  }

  // DELETE /hotel-owner/offers/{id}
  static Future<void> deleteOffer(String id) async {
    final response = await ApiService.delete('/hotel-owner/offers/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete offer');
    }
  }
}
