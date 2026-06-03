import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import 'shared/api_service.dart';

class QrCheckinService {
  // GET checkin/qr/{bookingId} — generate QR for guest
  Future<Map<String, dynamic>> getCheckinQr(String bookingId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.checkinQrEndpoint, bookingId));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get QR code'};
    }
  }

  // GET checkin/scan/{token} — public scan endpoint
  Future<Map<String, dynamic>> scanCheckin(String token) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.checkinScanEndpoint, token));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Invalid QR token'};
    }
  }

  // POST checkin/confirm — confirm check-in
  Future<Map<String, dynamic>> confirmCheckin(String qrToken) async {
    try {
      final response = await ApiService.post(ApiConfig.checkinConfirmEndpoint, data: {'qr_token': qrToken});
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to confirm check-in'};
    }
  }

  // POST checkin/checkout — confirm check-out
  Future<Map<String, dynamic>> confirmCheckout(String bookingId) async {
    try {
      final response = await ApiService.post(ApiConfig.checkinCheckoutEndpoint, data: {'booking_id': bookingId});
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to confirm check-out'};
    }
  }

  // GET checkin/today — today's check-ins (owner)
  Future<Map<String, dynamic>> getTodayCheckins() async {
    try {
      final response = await ApiService.get(ApiConfig.checkinTodayEndpoint);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get today\'s check-ins'};
    }
  }

  // GET checkin/active-guests — active guests (owner)
  Future<Map<String, dynamic>> getActiveGuests() async {
    try {
      final response = await ApiService.get(ApiConfig.checkinActiveGuestsEndpoint);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get active guests'};
    }
  }
}





