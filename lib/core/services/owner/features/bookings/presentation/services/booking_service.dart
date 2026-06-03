import '../../../../core/services/api_service.dart';

class BookingService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/bookings
  Future<List<Map<String, dynamic>>> getBookings({String filter = 'all'}) async {
    final response = await ApiService.get(
      '/hotel-owner/bookings',
      token: _token,
      queryParams: filter != 'all' ? {'status': filter} : null,
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch bookings');
  }

  // GET /hotel-owner/bookings with date range filter
  Future<List<Map<String, dynamic>>> getBookingsByDateRange({
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final response = await ApiService.get(
      '/hotel-owner/bookings',
      token: _token,
      queryParams: {
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
      },
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch bookings by date range');
  }

  // POST /create-booking
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> bookingData) async {
    final response = await ApiService.post(
      '/create-booking',
      token: _token,
      data: bookingData,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to create booking');
  }

  // POST /update-booking-status/{id} — owner updates booking status
  Future<Map<String, dynamic>> updateBookingStatus(String bookingId, String newStatus) async {
    final response = await ApiService.post(
      '/update-booking-status/$bookingId',
      token: _token,
      data: {'status': newStatus},
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to update booking status');
  }

  // POST /cancel-booking/{id}
  Future<Map<String, dynamic>> cancelBooking(String bookingId) async {
    final response = await ApiService.post(
      '/cancel-booking/$bookingId',
      token: _token,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to cancel booking');
  }

  // DELETE — not in spec, use cancel instead
  Future<Map<String, dynamic>> deleteBooking(String bookingId) async {
    return await cancelBooking(bookingId);
  }

  // GET /my-bookings filtered by id
  Future<Map<String, dynamic>> getBookingDetails(String bookingId) async {
    final response = await ApiService.get(
      '/my-bookings',
      token: _token,
      queryParams: {'bookingId': bookingId},
    );
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List && data.isNotEmpty) return data.first;
      if (data is Map) return Map<String, dynamic>.from(data);
      return {};
    }
    throw Exception(response['message'] ?? 'Failed to fetch booking details');
  }

  // POST /confirm-payment
  Future<Map<String, dynamic>> confirmPayment(Map<String, dynamic> paymentData) async {
    final response = await ApiService.post(
      '/confirm-payment',
      token: _token,
      data: paymentData,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to confirm payment');
  }

  // POST /payment-intent
  Future<Map<String, dynamic>> processPayment(String bookingId, double amount) async {
    final response = await ApiService.post(
      '/payment-intent',
      token: _token,
      data: {'bookingId': bookingId, 'amount': amount},
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to process payment');
  }

  // POST /validate-coupon
  Future<Map<String, dynamic>> validateCoupon(String couponCode, String bookingId) async {
    final response = await ApiService.post(
      '/validate-coupon',
      token: _token,
      data: {'couponCode': couponCode, 'bookingId': bookingId},
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to validate coupon');
  }

  // GET /preview-price
  Future<Map<String, dynamic>> previewPrice(Map<String, dynamic> params) async {
    final queryParams = params.map((k, v) => MapEntry(k, v.toString()));
    final response = await ApiService.get(
      '/preview-price',
      token: _token,
      queryParams: queryParams,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to preview price');
  }

  // GET /invoice/{bookingId}/download
  Future<Map<String, dynamic>> downloadInvoice(String bookingId) async {
    final response = await ApiService.get(
      '/invoice/$bookingId/download',
      token: _token,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to download invoice');
  }

  // GET /invoice/{bookingId}/preview
  Future<Map<String, dynamic>> previewInvoice(String bookingId) async {
    final response = await ApiService.get(
      '/invoice/$bookingId/preview',
      token: _token,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to preview invoice');
  }

  // POST /rate-hotel
  Future<Map<String, dynamic>> rateHotel(Map<String, dynamic> ratingData) async {
    final response = await ApiService.post(
      '/rate-hotel',
      token: _token,
      data: ratingData,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to rate hotel');
  }

  // GET /checkin/qr/{bookingId}
  Future<Map<String, dynamic>> getCheckinQr(String bookingId) async {
    final response = await ApiService.get(
      '/checkin/qr/$bookingId',
      token: _token,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to get QR code');
  }

  // Legacy — kept for compatibility
  Future<Map<String, dynamic>> checkInGuest(String bookingId) async {
    return await getCheckinQr(bookingId);
  }

  Future<Map<String, dynamic>> checkOutGuest(String bookingId) async {
    final response = await ApiService.post(
      '/cancel-booking/$bookingId',
      token: _token,
      data: {'action': 'checkout'},
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to check out guest');
  }

  Future<Map<String, dynamic>> refundPayment(String bookingId, double amount) async {
    final response = await ApiService.post(
      '/payment-intent',
      token: _token,
      data: {'bookingId': bookingId, 'amount': amount, 'type': 'refund'},
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to process refund');
  }

  Future<List<Map<String, dynamic>>> getBookingHistory(String guestId) async {
    final response = await ApiService.get(
      '/my-bookings',
      token: _token,
      queryParams: {'guestId': guestId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch booking history');
  }
}
