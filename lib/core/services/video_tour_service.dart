import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

/// Video Tours service for hotel owners.
/// Allows uploading and managing hotel video tours visible to guests.
class VideoTourService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// POST /hotel-owner/videos/upload — Upload a video file.
  Future<Map<String, dynamic>> uploadVideo(File videoFile, {String? title}) async {
    try {
      final token = await _getToken();
      final response = await ApiService.uploadFile(
        ApiConfig.ownerVideosUploadEndpoint,
        videoFile,
        token: token,
        fields: {if (title != null) 'title': title},
        fieldName: 'video',
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to upload video'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to upload video: $e'};
    }
  }

  /// POST /hotel-owner/videos/link — Add a YouTube or Vimeo video link.
  /// [data] should include: url, title (optional), platform (youtube/vimeo)
  Future<Map<String, dynamic>> addVideoLink(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.ownerVideosLinkEndpoint,
        data: data,
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add video link'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add video link: $e'};
    }
  }

  /// DELETE /hotel-owner/videos/{id} — Delete a video.
  Future<Map<String, dynamic>> deleteVideo(String videoId) async {
    try {
      final token = await _getToken();
      // The endpoint pattern is /hotel-owner/videos/{id}
      final response = await ApiService.delete(
        '/hotel-owner/videos/$videoId',
        token: token,
      );
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete video'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete video: $e'};
    }
  }

  /// POST /hotel-owner/videos/{id}/set-primary — Set a video as the primary tour.
  Future<Map<String, dynamic>> setPrimary(String videoId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.ownerVideosSetPrimaryEndpoint, '$videoId/set-primary'),
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to set primary video'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to set primary video: $e'};
    }
  }
}
