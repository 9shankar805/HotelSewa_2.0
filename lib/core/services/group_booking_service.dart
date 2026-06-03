import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

/// Feature 6: Multi-room / group booking
class GroupBookingService {
  // POST create-booking — multi-room variant
  // Sends a list of rooms instead of a single room
  Future<Map<String, dynamic>> createGroupBooking({
    required String hotelId,
    required String checkIn,
    required String checkOut,
    required List<Map<String, dynamic>> rooms, // [{room_type_id, guests: [{name, ...}]}, ...]
    String? specialRequests,
    String? couponCode,
    Map<String, dynamic>? extra,
  }) async {
    try {
      final response = await ApiService.post('/create-booking', data: {
        'hotel_id': hotelId,
        'check_in': checkIn,
        'check_out': checkOut,
        'rooms': rooms,
        'is_group_booking': true,
        if (specialRequests != null) 'special_requests': specialRequests,
        if (couponCode != null) 'coupon_code': couponCode,
        ...?extra,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Group booking failed'};
    }
  }

  // GET preview-price — price preview for multiple rooms
  Future<Map<String, dynamic>> previewGroupPrice({
    required String hotelId,
    required String checkIn,
    required String checkOut,
    required List<Map<String, dynamic>> rooms,
    String? couponCode,
  }) async {
    try {
      final response = await ApiService.get('/preview-price', queryParams: {
        'hotel_id': hotelId,
        'check_in': checkIn,
        'check_out': checkOut,
        'rooms': rooms,
        if (couponCode != null) 'coupon_code': couponCode,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to preview group price'};
    }
  }
}





