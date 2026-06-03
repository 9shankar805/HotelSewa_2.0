import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import 'shared/api_service.dart';

class RoomMediaService {
  // GET /room-types/{roomTypeId}/gallery - Room images
  Future<Map<String, dynamic>> getGallery(String roomTypeId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.roomTypesGalleryEndpoint, '$roomTypeId/gallery'));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load gallery'};
    }
  }

  // GET /room-types/{roomTypeId}/videos - Room videos
  Future<Map<String, dynamic>> getVideos(String roomTypeId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.roomTypesVideosEndpoint, '$roomTypeId/videos'));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load videos'};
    }
  }

  // POST /room-types/{roomTypeId}/media/images - Upload images (owner)
  Future<Map<String, dynamic>> uploadImages({
    required String roomTypeId,
    required List<String> images,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.buildPath(ApiConfig.roomTypesMediaEndpoint, '$roomTypeId/media/images'), data: {
        'images': images,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload images'};
    }
  }

  // POST /room-types/{roomTypeId}/media/video - Upload video (owner)
  Future<Map<String, dynamic>> uploadVideo({
    required String roomTypeId,
    required String video,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.buildPath(ApiConfig.roomTypesMediaEndpoint, '$roomTypeId/media/video'), data: {
        'video': video,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload video'};
    }
  }

  // POST /room-types/{roomTypeId}/media/video-link - Add video link (owner)
  Future<Map<String, dynamic>> addVideoLink({
    required String roomTypeId,
    required String url,
    String? title,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.buildPath(ApiConfig.roomTypesMediaEndpoint, '$roomTypeId/media/video-link'), data: {
        'url': url,
        if (title != null) 'title': title,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add video link'};
    }
  }

  // PUT /room-types/media/{id} - Update media (owner)
  Future<Map<String, dynamic>> updateMedia({
    required String mediaId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final response = await ApiService.put(ApiConfig.buildPath(ApiConfig.roomTypesMediaEndpoint, 'media/$mediaId'), data: metadata);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update media'};
    }
  }

  // DELETE /room-types/media/{id} - Delete media (owner)
  Future<Map<String, dynamic>> deleteMedia(String mediaId) async {
    try {
      final response = await ApiService.delete(ApiConfig.buildPath(ApiConfig.roomTypesMediaEndpoint, 'media/$mediaId'));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete media'};
    }
  }

  // POST /room-types/{roomTypeId}/media/reorder - Reorder media (owner)
  Future<Map<String, dynamic>> reorderMedia({
    required String roomTypeId,
    required List<String> mediaIds,
  }) async {
    try {
      final response = await ApiService.post('/room-types/$roomTypeId/media/reorder', data: {
        'media_ids': mediaIds,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to reorder media'};
    }
  }
}





