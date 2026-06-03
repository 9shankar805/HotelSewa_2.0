import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

/// iCal / Channel Manager service for hotel owners.
/// Manages external channel connections (Airbnb, Booking.com, etc.)
/// and calendar sync.
class ICalService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// GET /ical/channels — Get all connected channels.
  Future<Map<String, dynamic>> getChannels() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.icalChannelsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load channels'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load channels: $e'};
    }
  }

  /// POST /ical/channels — Add a new channel (Airbnb, Booking.com, etc.)
  /// [data] should include: name, ical_url, channel_type
  Future<Map<String, dynamic>> addChannel(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.icalChannelsEndpoint, data: data, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add channel'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add channel: $e'};
    }
  }

  /// POST /ical/channels/{id}/sync — Sync a specific channel.
  Future<Map<String, dynamic>> syncChannel(String channelId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.icalSyncEndpoint, '$channelId/sync'),
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to sync channel'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to sync channel: $e'};
    }
  }

  /// DELETE /ical/channels/{id} — Remove a channel.
  Future<Map<String, dynamic>> deleteChannel(String channelId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete(
        ApiConfig.buildPath(ApiConfig.icalChannelsEndpoint, channelId),
        token: token,
      );
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete channel'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete channel: $e'};
    }
  }

  /// GET /ical/export/{token} — Get the iCal export URL for a hotel.
  /// Returns the public URL that external services can subscribe to.
  Future<Map<String, dynamic>> getExportUrl(String exportToken) async {
    try {
      final response = await ApiService.get(
        ApiConfig.buildPath(ApiConfig.icalExportEndpoint, exportToken),
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get export URL'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get export URL: $e'};
    }
  }
}
