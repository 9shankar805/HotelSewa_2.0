import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

/// Covers all 23 BrandTrustController endpoints
class BrandTrustService {
  static Future<String?> _token() async {
    final p = await SharedPreferences.getInstance();
    return p.getString('authToken') ?? p.getString('auth_token');
  }

  // ── Verified Badge + Tier ──────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getHotelTrustBadge(String hotelId) =>
      ApiService.get('/hotels/$hotelId/trust-badge');

  static Future<Map<String, dynamic>> getTierCriteria() =>
      ApiService.get('/tier-criteria');

  // ── Guest Protection ───────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getGuestProtection() =>
      ApiService.get('/guest-protection');

  // ── Transparent Pricing ────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getPriceEstimate(
    String hotelId, {
    String? checkIn,
    String? checkOut,
    int rooms = 1,
    int guests = 1,
  }) =>
      ApiService.get('/hotels/$hotelId/price-estimate', queryParams: {
        if (checkIn != null) 'check_in': checkIn,
        if (checkOut != null) 'check_out': checkOut,
        'rooms': rooms.toString(),
        'guests': guests.toString(),
      });

  static Future<Map<String, dynamic>> getPriceBreakdown(String bookingId) async {
    final token = await _token();
    return ApiService.get('/bookings/$bookingId/price-breakdown', token: token);
  }

  // ── Booking Confirmation Summary ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getConfirmationSummary(String bookingId) async {
    final token = await _token();
    return ApiService.get('/bookings/$bookingId/confirmation-summary', token: token);
  }

  // ── Post-Stay Quality Survey ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> submitPostStaySurvey(Map<String, dynamic> data) async {
    final token = await _token();
    return ApiService.post('/post-stay/survey', token: token, data: data);
  }

  static Future<Map<String, dynamic>> getPostStaySurvey(String bookingId) async {
    final token = await _token();
    return ApiService.get('/post-stay/survey/$bookingId', token: token);
  }

  // ── Verified Reviews + Report Fake ────────────────────────────────────────
  static Future<Map<String, dynamic>> getHotelReviews(String hotelId, {int page = 1}) =>
      ApiService.get('/hotels/$hotelId/reviews', queryParams: {'page': page.toString()});

  static Future<Map<String, dynamic>> reportReview(String reviewId, String reason) async {
    final token = await _token();
    return ApiService.post('/reviews/$reviewId/report', token: token, data: {'reason': reason});
  }

  // ── Dispute / Complaint Flow ───────────────────────────────────────────────
  static Future<Map<String, dynamic>> raiseComplaint(Map<String, dynamic> data) async {
    final token = await _token();
    return ApiService.post('/complaints/raise', token: token, data: data);
  }

  static Future<Map<String, dynamic>> getMyComplaints() async {
    final token = await _token();
    return ApiService.get('/complaints/my', token: token);
  }

  // ── Owner Accountability Score ─────────────────────────────────────────────
  static Future<Map<String, dynamic>> getOwnerAccountability() async {
    final token = await _token();
    return ApiService.get('/hotel-owner/accountability', token: token);
  }

  // ── Best Value Algorithm ───────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getBestValueHotels({
    String? city,
    String? checkIn,
    String? checkOut,
    int? guests,
  }) =>
      ApiService.get('/hotels/best-value', queryParams: {
        if (city != null) 'city': city,
        if (checkIn != null) 'check_in': checkIn,
        if (checkOut != null) 'check_out': checkOut,
        if (guests != null) 'guests': guests.toString(),
      });
}
