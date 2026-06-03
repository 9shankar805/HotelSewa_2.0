import '../../constants/api_config.dart';
import '../shared/api_service.dart';

/// Bookings management for hotel owners.
class BookingsManagementService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /hotel-owner/bookings?hotel_id=
  static Future<List<Map<String, dynamic>>> getOwnerBookings({
    required String hotelId,
    Map<String, String>? filters,
  }) async {
    final params = {'hotel_id': hotelId, ...?filters};
    final response = await ApiService.get(ApiConfig.ownerBookingsEndpoint, token: _token, queryParams: params);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch bookings');
  }

  // POST /update-booking-status/{id}
  // body: { status: "confirmed" | "cancelled" }
  static Future<Map<String, dynamic>> updateBookingStatus(String id, String status) async {
    final response = await ApiService.post(
      ApiConfig.buildPath(ApiConfig.updateBookingStatusEndpoint, id),
      token: _token,
      data: {'status': status},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update booking status');
  }
}


