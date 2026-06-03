import '../../../../core/services/api_service.dart';

class RoomService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // POST /store-room — create room
  static Future<Map<String, dynamic>> createRoom(Map<String, dynamic> roomData) async {
    final response = await ApiService.post('/store-room', token: _token, data: roomData);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create room');
  }

  // POST /update-room/{id} — update room
  static Future<Map<String, dynamic>> updateRoom(
      String roomId, Map<String, dynamic> roomData) async {
    final response =
        await ApiService.post('/update-room/$roomId', token: _token, data: roomData);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update room');
  }

  // DELETE /delete-room/{id} — delete room
  static Future<void> deleteRoom(String roomId) async {
    final response = await ApiService.delete('/delete-room/$roomId', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete room');
    }
  }

  // POST /store-room-type — create room type
  static Future<Map<String, dynamic>> createRoomType(Map<String, dynamic> data) async {
    final response = await ApiService.post('/store-room-type', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create room type');
  }

  // POST /update-room-type/{id} — update room type
  static Future<Map<String, dynamic>> updateRoomType(
      String typeId, Map<String, dynamic> data) async {
    final response =
        await ApiService.post('/update-room-type/$typeId', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update room type');
  }

  // DELETE /delete-room-type/{id} — delete room type
  static Future<void> deleteRoomType(String typeId) async {
    final response = await ApiService.delete('/delete-room-type/$typeId', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete room type');
    }
  }

  // GET /filters/search — available rooms by date/capacity
  static Future<List<Map<String, dynamic>>> getAvailableRooms({
    required DateTime checkIn,
    required DateTime checkOut,
    int? capacity,
  }) async {
    final queryParams = <String, String>{
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
    };
    if (capacity != null) queryParams['capacity'] = capacity.toString();
    final response =
        await ApiService.get('/filters/search', token: _token, queryParams: queryParams);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch available rooms');
  }

  // Convenience: update room status
  static Future<Map<String, dynamic>> updateRoomStatus(
      String roomId, String newStatus) async {
    return updateRoom(roomId, {'status': newStatus});
  }
}
