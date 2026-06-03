import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import 'shared/cache_service.dart';
import '../constants/api_config.dart';

class BookingService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.createBookingEndpoint, data: data, token: token);
      if (response['success'] == true) {
        // Invalidate bookings cache so My Trips refreshes
        await CacheService.invalidateBookings();
        return {'success': true, 'data': response['data']};
      }
      return {'success': false, 'message': response['message'] ?? 'Booking failed'};
    } catch (e) {
      return {'success': false, 'message': 'Booking failed: $e'};
    }
  }

  Future<Map<String, dynamic>> confirmPayment(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.confirmPaymentEndpoint, data: data, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Payment confirmation failed'};
    } catch (e) {
      return {'success': false, 'message': 'Payment confirmation failed: $e'};
    }
  }

  Future<Map<String, dynamic>> getMyBookings() async {
    try {
      final token = await _getToken();

      // Return cached bookings immediately while fetching fresh data
      final cached = CacheService.getBookings();

      final response = await ApiService.get(ApiConfig.myBookingsEndpoint, token: token);
      debugPrint('📋 Raw my-bookings response: $response');
      if (response['success'] == true) {
        final raw = response['data'];
        debugPrint('📋 Raw data type: ${raw.runtimeType}, value: $raw');
        List bookings = [];
        if (raw is Map) {
          bookings = (raw['data'] ?? raw['bookings'] ?? raw['items'] ?? raw['results'] ?? []) as List;
        } else if (raw is List) {
          bookings = raw;
        }
        debugPrint('📋 Extracted ${bookings.length} bookings');
        if (bookings.isNotEmpty) debugPrint('📋 First booking keys: ${bookings[0].keys.toList()}');

        // Update cache
        final bookingMaps = bookings.whereType<Map<String, dynamic>>().toList();
        await CacheService.saveBookings(bookingMaps);

        return {'success': true, 'bookings': bookings};
      }

      // API failed — return cached if available
      if (cached != null) {
        debugPrint('📋 API failed, returning ${cached.length} cached bookings');
        return {'success': true, 'bookings': cached, 'fromCache': true};
      }

      return {'success': false, 'message': response['message'] ?? 'Failed to load bookings'};
    } catch (e) {
      // Network error — return cached bookings
      final cached = CacheService.getBookings();
      if (cached != null) {
        debugPrint('📋 Network error, returning ${cached.length} cached bookings');
        return {'success': true, 'bookings': cached, 'fromCache': true};
      }
      return {'success': false, 'message': 'Failed to load bookings: $e'};
    }
  }

  Future<Map<String, dynamic>> cancelBooking(String id) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.buildPath(ApiConfig.cancelBookingEndpoint, id), token: token);
      if (response['success'] == true) {
        await CacheService.invalidateBookings();
        return {'success': true, 'data': response['data']};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to cancel booking'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to cancel booking: $e'};
    }
  }

  Future<Map<String, dynamic>> rateHotel(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.rateHotelEndpoint, data: data, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to submit rating'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit rating: $e'};
    }
  }

  Future<Map<String, dynamic>> validateCoupon(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.validateCouponEndpoint, data: data, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Invalid coupon'};
    } catch (e) {
      return {'success': false, 'message': 'Invalid coupon: $e'};
    }
  }

  Future<Map<String, dynamic>> downloadInvoice(String bookingId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.invoiceDownloadEndpoint, '$bookingId/download'), token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to download invoice'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to download invoice: $e'};
    }
  }

  Future<Map<String, dynamic>> previewInvoice(String bookingId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.invoicePreviewEndpoint, '$bookingId/preview'), token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to preview invoice'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to preview invoice: $e'};
    }
  }

  Future<Map<String, dynamic>> previewPrice(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final queryParams = data.map((k, v) => MapEntry(k, v.toString()));
      final response = await ApiService.get(ApiConfig.previewPriceEndpoint, token: token, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to preview price'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to preview price: $e'};
    }
  }

  /// Create hourly booking — POST /create-booking with booking_type=hourly
  Future<Map<String, dynamic>> createHourlyBooking(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.createBookingEndpoint, data: {
        ...data,
        'booking_type': 'hourly',
      }, token: token);
      return response['success'] == true || response['status'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Hourly booking failed'};
    } catch (e) {
      return {'success': false, 'message': 'Hourly booking failed: $e'};
    }
  }

}
