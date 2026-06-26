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
  /// Handles: hotel.rooms[], hotel.room_types[].rooms[] and creates dummy rooms from room_types if needed
  static List<dynamic> _extractRooms(dynamic hotelData, String hotelId) {
    print('🔍 [RealRoomService (Owner)] _extractRooms called with hotelData: $hotelData, type: ${hotelData.runtimeType}');
    if (hotelData == null) return [];
    final result = <dynamic>[];

    // 1. Check for direct rooms list
    if (hotelData is Map && hotelData['rooms'] is List) {
      print('🔍 [RealRoomService (Owner)] Found direct rooms list: ${hotelData['rooms']}');
      result.addAll(hotelData['rooms'] as List);
    }

    // 2. Check for room_types with rooms nested inside
    if (hotelData is Map && hotelData['room_types'] is List) {
      print('🔍 [RealRoomService (Owner)] Found room_types list: ${hotelData['room_types']}');
      for (final rt in hotelData['room_types'] as List) {
        if (rt is! Map) continue;
        
        // If room_type has rooms list, use that
        if (rt['rooms'] is List && (rt['rooms'] as List).isNotEmpty) {
          for (final room in rt['rooms'] as List) {
            if (room is! Map) continue;
            final enriched = Map<String, dynamic>.from(room);
            enriched['hotel_id'] ??= hotelId;
            enriched['type'] ??= rt['name']?.toString() ?? '';
            enriched['price_per_night'] ??= rt['price_per_night'] ?? rt['base_price'] ?? 0;
            enriched['capacity'] ??= rt['max_adults'] ?? 1;
            result.add(enriched);
          }
        } else {
          // No rooms in room_type, create dummy rooms using total_rooms from room_type
          final totalRooms = rt['total_rooms'] ?? 1;
          final roomTypeName = rt['name']?.toString() ?? 'Room';
          print('🔍 [RealRoomService (Owner)] Creating $totalRooms dummy rooms for room type: $roomTypeName');
          
          for (int i = 0; i < totalRooms; i++) {
            final dummyRoom = <String, dynamic>{
              'id': 'dummy-${rt['id']}-$i',
              'hotel_id': hotelId,
              'room_number': '$roomTypeName ${i + 1}',
              'type': roomTypeName,
              'status': 'available',
              'price_per_night': rt['base_price'] ?? rt['effective_price'] ?? 0,
              'capacity': rt['max_adults'] ?? 1,
              'description': rt['description'] ?? '',
              'amenities': rt['amenities'] ?? [],
              'images': rt['images'] ?? [],
            };
            result.add(dummyRoom);
          }
        }
      }
    }
    print('🔍 [RealRoomService (Owner)] Extracted ${result.length} rooms');
    return result;
  }

  // GET /filters/search — rooms by capacity
  static Future<List<Map<String, dynamic>>> getRoomsByCapacity(int capacity, {String? token}) async {
    try {
      final response = await ApiService.get(
        '/filters/search',
        token: token,
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

  // GET /room-types — get all room types for a hotel
  static Future<Map<String, dynamic>> getRoomTypes({String? hotelId, String? token}) async {
    try {
      // First try to get hotel details which has room_types
      if (hotelId != null) {
        final response = await ApiService.get('/hotel-details/$hotelId', token: token);
        if (response['success'] == true) {
          return {'success': true, 'data': response['data']['room_types'] ?? []};
        }
      }
      // Fallback to /my-hotels
      final fallback = await ApiService.get('/my-hotels', token: token);
      if (fallback['success'] == true) {
        final data = fallback['data'];
        dynamic hotel;
        if (data is List && data.isNotEmpty) {
          hotel = data.first;
        } else if (data is Map) {
          hotel = data;
        }
        if (hotel != null && hotel['room_types'] is List) {
          return {'success': true, 'data': hotel['room_types']};
        }
      }
      return {'success': true, 'data': []};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load room types: ${e.toString()}'};
    }
  }

  // POST /store-room — create room with correct snake_case fields
  static Future<Map<String, dynamic>> createRoom(Map<String, dynamic> roomData, {String? token}) async {
    try {
      final response = await ApiService.post(
        '/store-room',
        token: token,
        data: {
          'room_type_id': roomData['room_type_id'],
          'room_number': roomData['room_number'],
          'floor': roomData['floor'],
          'status': roomData['status'] ?? 'available',
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
  static Future<Map<String, dynamic>> updateRoom(String roomId, Map<String, dynamic> roomData, {String? token}) async {
    try {
      final response = await ApiService.post(
        '/update-room/$roomId',
        token: token,
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
  static Future<void> deleteRoom(String roomId, {String? token}) async {
    try {
      final response = await ApiService.delete('/delete-room/$roomId', token: token);
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
