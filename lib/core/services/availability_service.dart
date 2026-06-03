import '../constants/api_config.dart';
import 'shared/api_service.dart';

/// Room availability — derived from hotel-details room_types
/// (dedicated availability endpoint not available on this server)
class AvailabilityService {

  Future<Map<String, dynamic>> getRoomAvailability({
    required String hotelId,
    required String from,
    required String to,
    String? roomTypeId,
  }) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelDetailsEndpoint, hotelId));
      final data = response['data']['data'];
      final roomTypes = data['room_types'] as List? ?? [];
      final filtered = roomTypeId != null
          ? roomTypes.where((r) => r['id'].toString() == roomTypeId).toList()
          : roomTypes;
      return {'success': true, 'data': filtered};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load availability'};
    }
  }

  Future<Map<String, dynamic>> checkAvailability({
    required String hotelId,
    required String checkIn,
    required String checkOut,
    int rooms = 1,
    int adults = 1,
  }) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelDetailsEndpoint, hotelId));
      final data = response['data']['data'];
      final roomTypes = (data['room_types'] as List? ?? [])
          .where((r) => r['is_available'] == true && (r['available_rooms'] ?? 0) >= rooms)
          .toList();
      return {'success': true, 'data': roomTypes};
    } catch (e) {
      return {'success': false, 'message': 'Failed to check availability'};
    }
  }
}






