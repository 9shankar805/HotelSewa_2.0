import '../../../../core/services/shared/api_service.dart';

class OffersService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/offers
  static Future<List<Map<String, dynamic>>> getOffers() async {
    final response = await ApiService.get('/hotel-owner/offers', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch offers');
  }

  // POST /hotel-owner/offers — create offer
  static Future<Map<String, dynamic>> createOffer(Map<String, dynamic> offerData) async {
    final response =
        await ApiService.post('/hotel-owner/offers', token: _token, data: offerData);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create offer');
  }

  // POST /hotel-owner/offers/{id} — update offer
  static Future<Map<String, dynamic>> updateOffer(
      String offerId, Map<String, dynamic> offerData) async {
    final response = await ApiService.post('/hotel-owner/offers/$offerId',
        token: _token, data: offerData);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update offer');
  }

  // DELETE /hotel-owner/offers/{id} — delete offer
  static Future<void> deleteOffer(String offerId) async {
    final response = await ApiService.delete('/hotel-owner/offers/$offerId', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete offer');
    }
  }

  // POST /validate-coupon — validate coupon (guest-facing)
  static Future<Map<String, dynamic>> validateCoupon(
      String couponCode, String bookingId) async {
    final response = await ApiService.post(
      '/validate-coupon',
      token: _token,
      data: {'couponCode': couponCode, 'bookingId': bookingId},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to validate coupon');
  }
}

