import 'dart:io';
import '../../../../core/services/api_service.dart';

class RealRoomService {
  /// GET /my-hotels — returns list of hotels, each with room_types containing rooms.
  /// We flatten all rooms from all room_types for the owner's hotel.
  /// Falls back to GET /hotel-details/{hotelId} which returns full hotel with rooms.
  static Future<Map<String, dynamic>> getRooms({
    required String hotelId,
    String? status,
    String? type,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      // Primary: GET /hotel-details/{hotelId} — full hotel object with room_types
      final response = await ApiService.get(
        '/hotel-details/$hotelId',
        token: token,
      );

      if (response['success'] == true || response['data'] != null) {
        final data = response['data'];
        final List<dynamic> rooms = _extractRooms(data, hotelId);

        // Apply status filter if needed
        final filtered = status != null
            ? rooms.where((r) {
                final s = (r['status'] ?? r['room_status'] ?? '').toString().toLowerCase();
                return s == status.toLowerCase();
              }).toList()
            : rooms;

        // Apply type filter if needed
        final typed = type != null
            ? filtered.where((r) {
                final t = (r['type'] ?? r['room_type'] ?? '').toString().toLowerCase();
                return t == type.toLowerCase();
              }).toList()
            : filtered;

        return {'success': true, 'data': typed};
      }

      // Fallback: GET /my-hotels
      final fallback = await ApiService.get('/my-hotels', token: token);
      if (fallback['success'] == true) {
        final data = fallback['data'];
        List<dynamic> allRooms = [];
        if (data is List) {
          for (final hotel in data) {
            if (hotel['id']?.toString() == hotelId || data.length == 1) {
              allRooms = _extractRooms(hotel, hotelId);
              break;
            }
          }
        } else if (data is Map) {
          allRooms = _extractRooms(data, hotelId);
        }
        return {'success': true, 'data': allRooms};
      }

      return {'success': true, 'data': <dynamic>[]};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load rooms: ${e.toString()}'};
    }
  }

  /// Extracts a flat list of room maps from a hotel data object.
  /// Handles both:
  ///   - hotel.rooms (flat array)
  ///   - hotel.room_types[].rooms (nested)
  static List<dynamic> _extractRooms(dynamic hotelData, String hotelId) {
    if (hotelData == null) return [];
    final List<dynamic> result = [];

    // Flat rooms array
    if (hotelData['rooms'] is List) {
      result.addAll(hotelData['rooms'] as List);
    }

    // Nested via room_types
    if (hotelData['room_types'] is List) {
      for (final rt in hotelData['room_types'] as List) {
        if (rt is Map && rt['rooms'] is List) {
          for (final room in rt['rooms'] as List) {
            if (room is Map) {
              // Enrich room with room_type info if not already set
              final enriched = Map<String, dynamic>.from(room as Map);
              enriched['hotel_id'] ??= hotelId;
              enriched['type'] ??= rt['name']?.toString() ?? '';
              enriched['price_per_night'] ??= rt['price_per_night'] ?? rt['base_price'] ?? 0;
              enriched['capacity'] ??= rt['capacity'] ?? 1;
              result.add(enriched);
            }
          }
        }
      }
    }

    return result;
  }

  // GET /filters/search — rooms by capacity
  Future<List<Map<String, dynamic>>> getRoomsByCapacity(int capacity) async {
    try {
      final response = await ApiService.get(
        '/filters/search',
        queryParams: {'capacity': capacity.toString()},
      );
      if (response['success'] == true) {
        return List<Map<String, dynamic>>.from(response['data'] ?? []);
      }
      return [];
    } catch (e) {
      throw Exception('Failed to get rooms by capacity: ${e.toString()}');
    }
  }

  // POST /store-room — create room with correct snake_case fields
  Future<Map<String, dynamic>> createRoom(Map<String, dynamic> roomData) async {
    try {
      final response = await ApiService.post(
        '/store-room',
        data: {
          'hotel_id': roomData['hotel_id'] ?? roomData['hotelId'],
          'room_number': roomData['room_number'] ?? roomData['roomNumber'],
          'type': roomData['type'] ?? 'STANDARD',
          'price_per_night': roomData['price_per_night'] ?? roomData['pricePerNight'] ?? 0,
          'capacity': roomData['capacity'] ?? 1,
          'status': roomData['status'] ?? 'available',
          if ((roomData['description'] ?? '').toString().isNotEmpty)
            'description': roomData['description'],
          if (roomData['amenities'] != null) 'amenities': roomData['amenities'],
        },
      );
      if (response['success'] == true) {
        return response['data'] ?? {};
      }
      throw Exception(response['message'] ?? 'Failed to create room');
    } catch (e) {
      throw Exception('Failed to create room: ${e.toString()}');
    }
  }

  // POST /update-room/{id} — update room
  Future<Map<String, dynamic>> updateRoom(String roomId, Map<String, dynamic> roomData) async {
    try {
      final response = await ApiService.post(
        '/update-room/$roomId',
        data: roomData,
      );
      if (response['success'] == true) {
        return response['data'] ?? {};
      }
      throw Exception(response['message'] ?? 'Failed to update room');
    } catch (e) {
      throw Exception('Failed to update room: ${e.toString()}');
    }
  }

  // DELETE /delete-room/{id} — delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      final response = await ApiService.delete('/delete-room/$roomId');
      if (response['success'] != true) {
        throw Exception(response['message'] ?? 'Failed to delete room');
      }
    } catch (e) {
      throw Exception('Failed to delete room: ${e.toString()}');
    }
  }

  // GET /hotel-details/{hotelId} — room details from hotel
  static Future<Map<String, dynamic>> getRoomDetails(String roomId, {String? token}) async {
    try {
      final response = await ApiService.get(
        '/hotel-details/$roomId',
        token: token,
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to load room details: ${e.toString()}'};
    }
  }

  // POST /update-room/{id} — update room status
  static Future<Map<String, dynamic>> updateRoomStatus({
    required String roomId,
    required String newStatus,
    String? token,
  }) async {
    try {
      final response = await ApiService.post(
        '/update-room/$roomId',
        data: {'status': newStatus},
        token: token,
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to update room status: ${e.toString()}'};
    }
  }

  // GET /filters/options — room types
  static Future<Map<String, dynamic>> getRoomTypes({String? token}) async {
    try {
      final response = await ApiService.get('/filters/options', token: token);
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to load room types: ${e.toString()}'};
    }
  }

  // GET /hotels/{hotelId}/blackout-dates — room availability
  static Future<Map<String, dynamic>> getRoomAvailability({
    required String roomId,
    required String startDate,
    required String endDate,
    String? token,
  }) async {
    try {
      final response = await ApiService.get(
        '/filters/search',
        token: token,
        queryParams: {
          'roomId': roomId,
          'startDate': startDate,
          'endDate': endDate,
        },
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to check availability: ${e.toString()}'};
    }
  }

  // POST /update-profile — upload room images
  static Future<Map<String, dynamic>> uploadRoomImages({
    required String roomId,
    required List<File> images,
    String? token,
  }) async {
    try {
      final response = await ApiService.uploadFiles(
        '/update-profile',
        images,
        token: token,
        fields: {'roomId': roomId, 'type': 'room'},
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload images: ${e.toString()}'};
    }
  }
}
