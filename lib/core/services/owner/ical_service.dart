import '../shared/api_service.dart';

/// iCal / Channel Manager Sync for hotel owners.
class ICalService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /ical/channels?hotel_id=
  static Future<List<Map<String, dynamic>>> getChannels(String hotelId) async {
    final response = await ApiService.get(
      '/ical/channels',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch iCal channels');
  }

  // POST /ical/channels — add Airbnb/Booking.com iCal URL
  // body: { hotel_id, room_type_id, platform, ical_url }
  static Future<Map<String, dynamic>> addChannel(Map<String, dynamic> data) async {
    final response = await ApiService.post('/ical/channels', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add iCal channel');
  }

  // POST /ical/channels/{id}/sync — manually trigger sync
  static Future<Map<String, dynamic>> syncChannel(String id) async {
    final response = await ApiService.post('/ical/channels/$id/sync', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to sync iCal channel');
  }

  // DELETE /ical/channels/{id}
  static Future<void> removeChannel(String id) async {
    final response = await ApiService.delete('/ical/channels/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to remove iCal channel');
    }
  }

  /// Returns the outbound iCal feed URL to share with OTAs (public endpoint).
  static String getExportUrl(String token) => '${ApiService.baseUrl}/ical/export/$token';
}


