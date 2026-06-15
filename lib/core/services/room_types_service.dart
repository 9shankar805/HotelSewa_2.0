import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class RoomTypesService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /room-types - List all room types (now fixed on backend — was 405)
  Future<Map<String, dynamic>> getRoomTypes({String? hotelId}) async {
    try {
      final queryParams = <String, String>{};
      if (hotelId != null) queryParams['hotel_id'] = hotelId;
      final response = await ApiService.get(
        ApiConfig.roomTypesEndpoint,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      return response['success'] == true || response['error'] == false
          ? {'success': true, 'room_types': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load room types'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load room types'};
    }
  }

  // GET /room-types/{roomTypeId}/gallery - Room type gallery (Public)
  Future<Map<String, dynamic>> getRoomTypeGallery(String roomTypeId) async {
    try {
      final response = await ApiService.get('${ApiConfig.roomTypeGalleryEndpoint}/$roomTypeId/gallery');
      return response['success'] == true
          ? {'success': true, 'gallery': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load room type gallery'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load room type gallery'};
    }
  }

  // GET /room-types/{roomTypeId}/videos - Room type videos (Public)
  Future<Map<String, dynamic>> getRoomTypeVideos(String roomTypeId) async {
    try {
      final response = await ApiService.get('${ApiConfig.roomTypeVideosEndpoint}/$roomTypeId/videos');
      return response['success'] == true
          ? {'success': true, 'videos': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load room type videos'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load room type videos'};
    }
  }

  // GET /hotel-owner/room-types/media - Room type media for owner
  Future<Map<String, dynamic>> getOwnerRoomTypeMedia(String roomTypeId, {String? token}) async {
    try {
      final response = await ApiService.get(ApiConfig.ownerRoomTypeMediaEndpoint, 
          token: token, 
          queryParams: {'room_type_id': roomTypeId});
      return response['success'] == true
          ? {'success': true, 'media': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load room type media'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load room type media'};
    }
  }

  // POST /room-types/{roomTypeId}/media/images - Upload room type images
  Future<Map<String, dynamic>> uploadRoomTypeImages(
    String roomTypeId,
    List<File> images, {
    String? token,
    Map<String, String>? additionalFields,
  }) async {
    try {
      final fields = <String, String>{
        'room_type_id': roomTypeId,
        ...?additionalFields,
      };
      
      final response = await ApiService.uploadFiles(
        '${ApiConfig.roomTypeMediaImagesEndpoint}/$roomTypeId/media/images',
        images,
        token: token,
        fields: fields,
      );
      return response['success'] == true
          ? {'success': true, 'images': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to upload room type images'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload room type images'};
    }
  }

  // POST /room-types/{roomTypeId}/media/video - Upload room type video
  Future<Map<String, dynamic>> uploadRoomTypeVideo(
    String roomTypeId,
    File video, {
    String? token,
    String? title,
    String? description,
  }) async {
    try {
      final fields = <String, String>{
        'room_type_id': roomTypeId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
      };
      
      final response = await ApiService.uploadFile(
        '${ApiConfig.roomTypeMediaVideoEndpoint}/$roomTypeId/media/video',
        video,
        token: token,
        fields: fields,
        fieldName: 'video',
      );
      return response['success'] == true
          ? {'success': true, 'video': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to upload room type video'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload room type video'};
    }
  }

  // POST /room-types/{roomTypeId}/media/video-link - Add room type video link
  Future<Map<String, dynamic>> addRoomTypeVideoLink({
    required String roomTypeId,
    required String videoUrl,
    required String type, // 'youtube', 'vimeo', '360'
    String? title,
    String? description,
    bool isPrimary = false,
    String? token,
  }) async {
    try {
      final response = await ApiService.post('${ApiConfig.roomTypeMediaVideoLinkEndpoint}/$roomTypeId/media/video-link',
          token: token,
          data: {
            'room_type_id': roomTypeId,
            'video_url': videoUrl,
            'type': type,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            'is_primary': isPrimary,
          });
      return response['success'] == true
          ? {'success': true, 'video': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add room type video link'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add room type video link'};
    }
  }

  // PUT /room-types/media/{id} - Update room type media
  Future<Map<String, dynamic>> updateRoomTypeMedia(
    String mediaId, {
    String? title,
    String? description,
    bool? isPrimary,
    int? sortOrder,
    String? token,
  }) async {
    try {
      final data = <String, dynamic>{};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (isPrimary != null) data['is_primary'] = isPrimary;
      if (sortOrder != null) data['sort_order'] = sortOrder;
      
      final response = await ApiService.put('${ApiConfig.roomTypeMediaUpdateEndpoint}/$mediaId', token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'media': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update room type media'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update room type media'};
    }
  }

  // DELETE /room-types/media/{id} - Delete room type media
  Future<Map<String, dynamic>> deleteRoomTypeMedia(String mediaId, {String? token}) async {
    try {
      final response = await ApiService.delete('${ApiConfig.roomTypeMediaUpdateEndpoint}/$mediaId', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Room type media deleted successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete room type media'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete room type media'};
    }
  }

  // POST /room-types/{roomTypeId}/media/reorder - Reorder room type media
  Future<Map<String, dynamic>> reorderRoomTypeMedia(
    String roomTypeId,
    List<Map<String, dynamic>> mediaOrder, {
    String? token,
  }) async {
    try {
      final response = await ApiService.post('${ApiConfig.roomTypeMediaReorderEndpoint}/$roomTypeId/media/reorder',
          token: token,
          data: {
            'room_type_id': roomTypeId,
            'media_order': mediaOrder,
          });
      return response['success'] == true
          ? {'success': true, 'message': 'Room type media reordered successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to reorder room type media'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to reorder room type media'};
    }
  }

  // POST /room-types/{roomTypeId}/videos/upload - Upload room type video tour
  Future<Map<String, dynamic>> uploadRoomTypeVideoTour(
    String roomTypeId,
    File video, {
    String? token,
    String? title,
    String? description,
    bool isPrimary = false,
  }) async {
    try {
      final fields = <String, String>{
        'room_type_id': roomTypeId,
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        'is_primary': isPrimary.toString(),
      };
      
      final response = await ApiService.uploadFile(
        '${ApiConfig.roomTypeVideosUploadEndpoint}/$roomTypeId/videos/upload',
        video,
        token: token,
        fields: fields,
        fieldName: 'video',
      );
      return response['success'] == true
          ? {'success': true, 'video': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to upload room type video tour'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload room type video tour'};
    }
  }

  // POST /room-types/{roomTypeId}/videos/link - Add room type video tour link
  Future<Map<String, dynamic>> addRoomTypeVideoTourLink({
    required String roomTypeId,
    required String videoUrl,
    String? title,
    String? description,
    bool isPrimary = false,
    String? token,
  }) async {
    try {
      final response = await ApiService.post('${ApiConfig.roomTypeVideosLinkEndpoint}/$roomTypeId/videos/link',
          token: token,
          data: {
            'room_type_id': roomTypeId,
            'video_url': videoUrl,
            if (title != null) 'title': title,
            if (description != null) 'description': description,
            'is_primary': isPrimary,
          });
      return response['success'] == true
          ? {'success': true, 'video': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add room type video tour link'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add room type video tour link'};
    }
  }

  // DELETE /room-types/videos/{id} - Delete room type video
  Future<Map<String, dynamic>> deleteRoomTypeVideo(String videoId, {String? token}) async {
    try {
      final response = await ApiService.delete('${ApiConfig.roomTypeVideosSetPrimaryEndpoint}/$videoId', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Room type video deleted successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete room type video'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete room type video'};
    }
  }

  // POST /room-types/videos/{id}/set-primary - Set primary room type video
  Future<Map<String, dynamic>> setPrimaryRoomTypeVideo(String videoId, {String? token}) async {
    try {
      final response = await ApiService.post('${ApiConfig.roomTypeVideosSetPrimaryEndpoint}/$videoId/set-primary', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Primary room type video set successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to set primary room type video'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to set primary room type video'};
    }
  }

  // Get room type details with media
  Future<Map<String, dynamic>> getRoomTypeWithMedia(String roomTypeId) async {
    try {
      final results = <String, dynamic>{};
      
      // Get gallery
      final galleryResult = await getRoomTypeGallery(roomTypeId);
      if (galleryResult['success'] == true) {
        results['gallery'] = galleryResult['gallery'];
      }
      
      // Get videos
      final videosResult = await getRoomTypeVideos(roomTypeId);
      if (videosResult['success'] == true) {
        results['videos'] = videosResult['videos'];
      }
      
      return {'success': true, 'room_type_media': results};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load room type media'};
    }
  }
}