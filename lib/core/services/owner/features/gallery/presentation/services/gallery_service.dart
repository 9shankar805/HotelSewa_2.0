import 'dart:io';
import '../../../../core/services/api_service.dart';

class GalleryService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/gallery — owner gallery (accepts optional hotelId for compat)
  static Future<Map<String, dynamic>> getGallery({String? hotelId}) async {
    // If hotelId provided, use public endpoint; otherwise use owner endpoint
    final endpoint = hotelId != null
        ? '/hotels/$hotelId/gallery'
        : '/hotel-owner/gallery';
    final response = await ApiService.get(endpoint, token: _token);
    if (response['success'] == true) return response['data'] ?? {'images': []};
    return {'images': []};
  }

  // GET /hotel-owner/media — all media
  static Future<Map<String, dynamic>> getMedia() async {
    final response = await ApiService.get('/hotel-owner/media', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch media');
  }

  // POST /hotels/{hotelId}/gallery — upload images to gallery
  static Future<Map<String, dynamic>> uploadImages(List<File> images, {required String hotelId}) async {
    final response = await ApiService.uploadFiles(
      '/hotels/$hotelId/gallery',
      images,
      token: _token,
      fields: {'hotel_id': hotelId},  // Include hotel_id as form field too
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to upload images');
  }

  // POST /hotel-owner/media/video — upload video file
  static Future<Map<String, dynamic>> uploadVideo(File video) async {
    final response = await ApiService.uploadFile(
      '/hotel-owner/media/video',
      video,
      token: _token,
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to upload video');
  }

  // POST /hotel-owner/media/video-link — add video link
  static Future<Map<String, dynamic>> addVideoLink(String url) async {
    final response = await ApiService.post(
      '/hotel-owner/media/video-link',
      token: _token,
      data: {'url': url},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add video link');
  }

  // POST /hotel-owner/media/{id} — update media item
  static Future<Map<String, dynamic>> updateMedia(
      String mediaId, Map<String, dynamic> data) async {
    final response =
        await ApiService.post('/hotel-owner/media/$mediaId', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update media');
  }

  // DELETE /hotel-owner/media/{id} — delete media item
  static Future<void> deleteMedia(String mediaId) async {
    final response = await ApiService.delete('/hotel-owner/media/$mediaId', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete media');
    }
  }

  // POST /hotel-owner/media/reorder — reorder media
  static Future<void> reorderMedia(List<String> orderedIds) async {
    final response = await ApiService.post(
      '/hotel-owner/media/reorder',
      token: _token,
      data: {'ids': orderedIds},
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to reorder media');
    }
  }

  // Public: GET /hotels/{hotelId}/gallery
  static Future<List<Map<String, dynamic>>> getHotelGallery(String hotelId) async {
    final response = await ApiService.get('/hotels/$hotelId/gallery', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    return [];
  }
}
