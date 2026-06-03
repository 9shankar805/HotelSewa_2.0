import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class CouponService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // POST /validate-coupon - Validate coupon
  Future<Map<String, dynamic>> validateCoupon(String code, {String? hotelId, double? amount}) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.validateCouponEndpoint, 
          token: token, 
          data: {
            'code': code,
            if (hotelId != null) 'hotel_id': hotelId,
            if (amount != null) 'amount': amount,
          });
      return response['success'] == true
          ? {'success': true, 'coupon': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Invalid coupon code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to validate coupon'};
    }
  }

  // GET /coupons/available - List available coupons
  Future<Map<String, dynamic>> getAvailableCoupons({String? hotelId}) async {
    try {
      final token = await _getToken();
      final queryParams = hotelId != null ? {'hotel_id': hotelId} : null;
      final response = await ApiService.get(ApiConfig.availableCouponsEndpoint, token: token, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'coupons': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load coupons'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load coupons'};
    }
  }

  // POST /apply-coupon - Apply coupon to booking
  Future<Map<String, dynamic>> applyCoupon(String code, String bookingId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.applyCouponEndpoint, 
          token: token, 
          data: {'code': code, 'booking_id': bookingId});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to apply coupon'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to apply coupon'};
    }
  }
}
