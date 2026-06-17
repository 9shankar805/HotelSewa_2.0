import 'dart:io';
import '../shared/api_service.dart';
import '../../constants/api_config.dart';

/// Media / Gallery / Video Tours for hotel owners.
class MediaService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /hotel-owner/media?hotel_id=
  static Future<List<Map<String, dynamic>>> getMedia(String hotelId) async {
    final response = await ApiService.get(
      ApiConfig.ownerMediaEndpoint,
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch media');
  }

  // POST /hotel-owner/media/images — upload photos (multiple)
  static Future<Map<String, dynamic>> uploadImages(
    List<File> images, {
    required Map<String, String> fields,
  }) async {
    return ApiService.uploadFiles(ApiConfig.ownerMediaImagesEndpoint, images, token: _token, fields: fields);
  }

  // POST /hotel-owner/media/video — upload video file
  static Future<Map<String, dynamic>> uploadVideo(
    File video, {
    required Map<String, String> fields,
  }) async {
    return ApiService.uploadFile(ApiConfig.ownerMediaVideoEndpoint, video, token: _token, fields: fields);
  }

  // POST /hotel-owner/media/video-link — add YouTube/Vimeo/360 link
  // body: { hotel_id, video_url, type, title, is_primary }
  static Future<Map<String, dynamic>> addVideoLink(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.ownerMediaVideoLinkEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add video link');
  }

  // POST /hotel-owner/media/{id} — update media item
  static Future<Map<String, dynamic>> updateMedia(String id, Map<String, dynamic> data) async {
    final response = await ApiService.post('${ApiConfig.ownerMediaEndpoint}/$id', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update media');
  }

  // DELETE /hotel-owner/media/{id}
  static Future<void> deleteMedia(String id) async {
    final response = await ApiService.delete('${ApiConfig.ownerMediaEndpoint}/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete media');
    }
  }

  // POST /hotel-owner/media/reorder
  static Future<Map<String, dynamic>> reorderGallery(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.ownerMediaReorderEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to reorder gallery');
  }

  // POST /hotel-owner/videos/upload
  static Future<Map<String, dynamic>> uploadVideoTour(
    File video, {
    required Map<String, String> fields,
  }) async {
    return ApiService.uploadFile(ApiConfig.ownerVideosUploadEndpoint, video, token: _token, fields: fields);
  }

  // POST /hotel-owner/videos/link
  static Future<Map<String, dynamic>> addVideoTourLink(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.ownerVideosLinkEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add video tour link');
  }

  // DELETE /hotel-owner/videos/{id}
  static Future<void> deleteVideoTour(String id) async {
    final response = await ApiService.delete('${ApiConfig.ownerVideosEndpoint}/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete video tour');
    }
  }

  // POST /hotel-owner/videos/{id}/set-primary
  static Future<Map<String, dynamic>> setPrimaryVideo(String id) async {
    final response = await ApiService.post('${ApiConfig.ownerVideosSetPrimaryEndpoint}/$id/set-primary', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to set primary video');
  }

  // POST /hotels/{hotelId}/gallery — alias upload to gallery
  static Future<Map<String, dynamic>> uploadToGallery(
    String hotelId,
    List<File> images,
  ) async {
    return ApiService.uploadFiles(
      '${ApiConfig.hotelGalleryEndpoint}/$hotelId/gallery',
      images,
      token: _token,
    );
  }
}


