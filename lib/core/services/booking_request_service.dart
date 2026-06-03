import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

class BookingRequestService {
  // POST /booking-requests/special-time - Request early check-in/late check-out
  Future<Map<String, dynamic>> requestSpecialTime({
    required String bookingId,
    required String type, // 'early_checkin' or 'late_checkout'
    required String requestedTime,
  }) async {
    try {
      final response = await ApiService.post('/booking-requests/special-time', data: {
        'booking_id': bookingId,
        'type': type,
        'requested_time': requestedTime,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit request'};
    }
  }

  // POST /booking-requests/{id}/respond - Respond to request (owner)
  Future<Map<String, dynamic>> respondToRequest({
    required String requestId,
    required String status, // 'approved' or 'rejected'
    String? notes,
  }) async {
    try {
      final response = await ApiService.post('/booking-requests/$requestId/respond', data: {
        'status': status,
        if (notes != null) 'notes': notes,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to respond to request'};
    }
  }

  // GET /booking-requests/my - Guest's requests
  Future<Map<String, dynamic>> getMyRequests() async {
    try {
      final response = await ApiService.get('/booking-requests/my');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load requests'};
    }
  }

  // GET /booking-requests/owner - Owner's pending requests
  Future<Map<String, dynamic>> getOwnerRequests() async {
    try {
      final response = await ApiService.get('/booking-requests/owner');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load requests'};
    }
  }

  // POST /booking-modifications/request - Request booking modification
  Future<Map<String, dynamic>> requestModification({
    required String bookingId,
    required String modificationType,
    String? newCheckInDate,
    String? newCheckOutDate,
  }) async {
    try {
      final response = await ApiService.post('/booking-modifications/request', data: {
        'booking_id': bookingId,
        'modification_type': modificationType,
        if (newCheckInDate != null) 'new_check_in_date': newCheckInDate,
        if (newCheckOutDate != null) 'new_check_out_date': newCheckOutDate,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to request modification'};
    }
  }

  // POST /booking-modifications/{id}/respond - Respond to modification
  Future<Map<String, dynamic>> respondToModification({
    required String modificationId,
    required String status,
    String? notes,
  }) async {
    try {
      final response = await ApiService.post('/booking-modifications/$modificationId/respond', data: {
        'status': status,
        if (notes != null) 'notes': notes,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to respond to modification'};
    }
  }
}





