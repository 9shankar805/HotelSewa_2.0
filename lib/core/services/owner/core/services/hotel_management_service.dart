import 'dart:io';
import 'api_service.dart';

/// Hotel Management: CRUD for hotels, room types, rooms, and amenities.
class HotelManagementService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /my-hotels (also /hotels/my)
  static Future<List<Map<String, dynamic>>> getMyHotels() async {
    final response = await ApiService.get('/my-hotels', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch hotels');
  }

  // POST /store-hotel (also /hotels/register) — multipart for image
  static Future<Map<String, dynamic>> storeHotel({
    required Map<String, dynamic> fields,
    File? image,
  }) async {
    if (image != null) {
      final strFields = fields.map((k, v) => MapEntry(k, v.toString()));
      return ApiService.uploadFile('/store-hotel', image, token: _token, fields: strFields);
    }
    return ApiService.post('/store-hotel', token: _token, data: fields);
  }

  // POST /update-hotel/{id} (also PUT /hotels/{id})
  static Future<Map<String, dynamic>> updateHotel(
    String id, {
    required Map<String, dynamic> fields,
    File? image,
  }) async {
    if (image != null) {
      final strFields = fields.map((k, v) => MapEntry(k, v.toString()));
      return ApiService.uploadFile('/update-hotel/$id', image, token: _token, fields: strFields);
    }
    return ApiService.post('/update-hotel/$id', token: _token, data: fields);
  }

  // DELETE /delete-hotel/{id} (also DELETE /hotels/{id})
  static Future<void> deleteHotel(String id) async {
    final response = await ApiService.delete('/delete-hotel/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete hotel');
    }
  }

  // GET /hotel-owner/amenities?hotel_id=
  static Future<List<Map<String, dynamic>>> getAmenities(String hotelId) async {
    final response = await ApiService.get(
      '/hotel-owner/amenities',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch amenities');
  }

  // POST /hotel-owner/amenities (also PUT /hotels/{id}/amenities)
  static Future<Map<String, dynamic>> updateAmenities(Map<String, dynamic> data) async {
    final response = await ApiService.post('/hotel-owner/amenities', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update amenities');
  }

  // ==================== ROOM TYPES ====================

  // POST /store-room-type (also POST /room-types)
  static Future<Map<String, dynamic>> storeRoomType(Map<String, dynamic> data) async {
    final response = await ApiService.post('/store-room-type', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create room type');
  }

  // POST /update-room-type/{id} (also PUT /room-types/{id})
  static Future<Map<String, dynamic>> updateRoomType(String id, Map<String, dynamic> data) async {
    final response = await ApiService.post('/update-room-type/$id', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update room type');
  }

  // DELETE /delete-room-type/{id} (also DELETE /room-types/{id})
  static Future<void> deleteRoomType(String id) async {
    final response = await ApiService.delete('/delete-room-type/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete room type');
    }
  }

  // ==================== ROOMS ====================

  // POST /store-room (also POST /rooms)
  static Future<Map<String, dynamic>> storeRoom(Map<String, dynamic> data) async {
    final response = await ApiService.post('/store-room', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create room');
  }

  // POST /update-room/{id} (also PUT /rooms/{id})
  static Future<Map<String, dynamic>> updateRoom(String id, Map<String, dynamic> data) async {
    final response = await ApiService.post('/update-room/$id', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update room');
  }

  // DELETE /delete-room/{id} (also DELETE /rooms/{id})
  static Future<void> deleteRoom(String id) async {
    final response = await ApiService.delete('/delete-room/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete room');
    }
  }
}
