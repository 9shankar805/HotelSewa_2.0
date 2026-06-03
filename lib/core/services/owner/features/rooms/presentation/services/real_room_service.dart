import 'dart:io';
import '../../../../core/services/api_service.dart';

class RealRoomService {
  // GET /hotels/{hotelId}/menu — rooms are part of hotel menu/details
  static Future<Map<String, dynamic>> getRooms({
    required String hotelId,
    String? status,
    String? type,
    int page = 1,
    int limit = 20,
    String? token,
  }) async {
    try {
      final queryParams = <String, String>{
        'page': page.toString(),
        'limit': limit.toString(),
      };
      if (status != null) queryParams['status'] = status;
      if (type != null) queryParams['type'] = type;

      final response = await ApiService.get(
        '/hotels/$hotelId/menu',
        token: token,
        queryParams: queryParams,
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to load rooms: ${e.toString()}'};
    }
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

  // POST /store-room — create room
  Future<Map<String, dynamic>> createRoom(Map<String, dynamic> roomData) async {
    try {
      final response = await ApiService.post(
        '/store-room',
        data: {
          'roomNumber': roomData['roomNumber'],
          'type': (roomData['type'] ?? 'STANDARD').toString().toUpperCase(),
          'pricePerNight': roomData['pricePerNight'],
          'capacity': roomData['capacity'],
          'hotelId': roomData['hotelId'],
          'amenities': roomData['amenities'] ?? [],
          'description': roomData['description'],
          'floor': roomData['floor'],
          'size': roomData['size'],
          'hasAc': roomData['hasAc'] ?? false,
          'hasWifi': roomData['hasWifi'] ?? false,
          'hasTv': roomData['hasTv'] ?? false,
          'hasMiniBar': roomData['hasMiniBar'] ?? false,
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
