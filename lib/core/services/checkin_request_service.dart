import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

/// Feature 7: Early check-in / late check-out dedicated requests
class CheckinRequestService {
  // POST booking-requests/early-checkin
  Future<Map<String, dynamic>> requestEarlyCheckin({
    required String bookingId,
    required String requestedTime, // e.g. "08:00"
    String? note,
  }) async {
    try {
      final response = await ApiService.post('/booking-requests/early-checkin', data: {
        'booking_id': bookingId,
        'requested_time': requestedTime,
        if (note != null) 'note': note,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to request early check-in'};
    }
  }

  // POST booking-requests/late-checkout
  Future<Map<String, dynamic>> requestLateCheckout({
    required String bookingId,
    required String requestedTime, // e.g. "14:00"
    String? note,
  }) async {
    try {
      final response = await ApiService.post('/booking-requests/late-checkout', data: {
        'booking_id': bookingId,
        'requested_time': requestedTime,
        if (note != null) 'note': note,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to request late check-out'};
    }
  }

  // POST booking-requests/special-time — generic fallback (existing endpoint)
  Future<Map<String, dynamic>> requestSpecialTime({
    required String bookingId,
    required String type, // 'early_checkin' | 'late_checkout' | 'other'
    required String requestedTime,
    String? note,
  }) async {
    try {
      final response = await ApiService.post('/booking-requests/special-time', data: {
        'booking_id': bookingId,
        'type': type,
        'requested_time': requestedTime,
        if (note != null) 'note': note,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit request'};
    }
  }
}





