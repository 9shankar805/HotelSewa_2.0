import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/services/shared/api_service.dart';

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

  // POST /hotel-owner/media/images — upload images to gallery
  static Future<Map<String, dynamic>> uploadImages(
    List<File> images, {
    required String hotelId,
    String category = 'other',
  }) async {
    debugPrint('[GalleryService] Uploading ${images.length} image(s) to hotel $hotelId, category: $category');

    final response = await ApiService.uploadFiles(
      '/hotel-owner/media/images',
      images,
      token: _token,
      fields: {
        'hotel_id': hotelId,
        'category': category,
      },
      fieldName: 'images',
      useIndexedFieldNames: true,
    );

    if (response['success'] == true) return {'data': response['data'] ?? []};
    throw Exception(response['message'] ?? 'Failed to upload images');
  }

  // POST /hotel-owner/media/video — upload video file
  static Future<Map<String, dynamic>> uploadVideo(File video, {required String hotelId}) async {
    final response = await ApiService.uploadFile(
      '/hotel-owner/media/video',
      video,
      token: _token,
      fields: {'hotel_id': hotelId},
      fieldName: 'video',
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to upload video');
  }

  // POST /hotel-owner/media/video-link — add video link
  static Future<Map<String, dynamic>> addVideoLink(String url, {required String hotelId}) async {
    final response = await ApiService.post(
      '/hotel-owner/media/video-link',
      token: _token,
      data: {'url': url, 'hotel_id': hotelId, 'video_url': url},
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

