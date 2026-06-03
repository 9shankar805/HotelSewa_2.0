import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class WaitlistService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // POST /waitlist/join - Join waitlist
  Future<Map<String, dynamic>> joinWaitlist({
    required String hotelId,
    required String checkIn,
    required String checkOut,
    required int guests,
    String? roomTypeId,
    String? specialRequests,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.waitlistJoinEndpoint,
          token: token,
          data: {
            'hotel_id': hotelId,
            'check_in': checkIn,
            'check_out': checkOut,
            'guests': guests,
            if (roomTypeId != null) 'room_type_id': roomTypeId,
            if (specialRequests != null) 'special_requests': specialRequests,
          });
      return response['success'] == true
          ? {'success': true, 'waitlist': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to join waitlist'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to join waitlist'};
    }
  }

  // GET /waitlist/my - Get user's waitlist entries
  Future<Map<String, dynamic>> getMyWaitlist({
    int? page,
    int? limit,
    String? status, // 'active', 'notified', 'expired', 'cancelled'
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      
      final response = await ApiService.get(ApiConfig.waitlistMyEndpoint,
          token: token,
          queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'waitlist': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load waitlist'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load waitlist'};
    }
  }

  // DELETE /waitlist/{id} - Remove from waitlist
  Future<Map<String, dynamic>> removeFromWaitlist(String waitlistId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete('${ApiConfig.waitlistDeleteEndpoint}/$waitlistId', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Removed from waitlist successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to remove from waitlist'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to remove from waitlist'};
    }
  }

  // Get waitlist details
  Future<Map<String, dynamic>> getWaitlistDetails(String waitlistId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get('${ApiConfig.waitlistDeleteEndpoint}/$waitlistId', token: token);
      return response['success'] == true
          ? {'success': true, 'waitlist': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load waitlist details'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load waitlist details'};
    }
  }

  // Update waitlist entry
  Future<Map<String, dynamic>> updateWaitlistEntry({
    required String waitlistId,
    String? checkIn,
    String? checkOut,
    int? guests,
    String? roomTypeId,
    String? specialRequests,
  }) async {
    try {
      final token = await _getToken();
      final data = <String, dynamic>{};
      if (checkIn != null) data['check_in'] = checkIn;
      if (checkOut != null) data['check_out'] = checkOut;
      if (guests != null) data['guests'] = guests;
      if (roomTypeId != null) data['room_type_id'] = roomTypeId;
      if (specialRequests != null) data['special_requests'] = specialRequests;
      
      final response = await ApiService.put('${ApiConfig.waitlistDeleteEndpoint}/$waitlistId', token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'waitlist': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update waitlist entry'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update waitlist entry'};
    }
  }

  // Check if user is already on waitlist for specific criteria
  Future<Map<String, dynamic>> checkWaitlistStatus({
    required String hotelId,
    required String checkIn,
    required String checkOut,
    String? roomTypeId,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{
        'hotel_id': hotelId,
        'check_in': checkIn,
        'check_out': checkOut,
      };
      if (roomTypeId != null) queryParams['room_type_id'] = roomTypeId;
      
      final response = await ApiService.get(ApiConfig.waitlistCheckStatusEndpoint,
          token: token,
          queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'on_waitlist': response['data']['on_waitlist'], 'waitlist_id': response['data']['waitlist_id']}
          : {'success': false, 'message': response['message'] ?? 'Failed to check waitlist status'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to check waitlist status'};
    }
  }

  // Get waitlist notifications
  Future<Map<String, dynamic>> getWaitlistNotifications({
    int? page,
    int? limit,
    bool? unreadOnly,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (unreadOnly != null) queryParams['unread_only'] = unreadOnly.toString();
      
      final response = await ApiService.get(ApiConfig.waitlistNotificationsEndpoint,
          token: token,
          queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'notifications': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load waitlist notifications'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load waitlist notifications'};
    }
  }

  // Mark waitlist notification as read
  Future<Map<String, dynamic>> markNotificationAsRead(String notificationId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.put('${ApiConfig.waitlistNotificationsEndpoint}/$notificationId/read', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Notification marked as read'}
          : {'success': false, 'message': response['message'] ?? 'Failed to mark notification as read'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to mark notification as read'};
    }
  }

  // Get waitlist statistics
  Future<Map<String, dynamic>> getWaitlistStatistics() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.waitlistStatisticsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'statistics': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load waitlist statistics'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load waitlist statistics'};
    }
  }

  // Set waitlist preferences
  Future<Map<String, dynamic>> setWaitlistPreferences({
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
    int? notificationAdvanceHours,
  }) async {
    try {
      final token = await _getToken();
      final data = <String, dynamic>{};
      if (emailNotifications != null) data['email_notifications'] = emailNotifications;
      if (smsNotifications != null) data['sms_notifications'] = smsNotifications;
      if (pushNotifications != null) data['push_notifications'] = pushNotifications;
      if (notificationAdvanceHours != null) data['notification_advance_hours'] = notificationAdvanceHours;
      
      final response = await ApiService.put(ApiConfig.waitlistPreferencesEndpoint, token: token, data: data);
      return response['success'] == true
          ? {'success': true, 'preferences': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update waitlist preferences'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update waitlist preferences'};
    }
  }

  // Get waitlist preferences
  Future<Map<String, dynamic>> getWaitlistPreferences() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.waitlistPreferencesEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'preferences': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load waitlist preferences'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load waitlist preferences'};
    }
  }

  // Get active waitlist count for user
  Future<Map<String, dynamic>> getActiveWaitlistCount() async {
    try {
      final waitlistResult = await getMyWaitlist(status: 'active');
      if (waitlistResult['success'] == true) {
        final waitlist = waitlistResult['waitlist'] as List;
        return {'success': true, 'count': waitlist.length};
      }
      return waitlistResult;
    } catch (e) {
      return {'success': false, 'message': 'Failed to get active waitlist count'};
    }
  }

  // Cancel all waitlist entries for a hotel
  Future<Map<String, dynamic>> cancelAllWaitlistForHotel(String hotelId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.waitlistCancelAllEndpoint,
          token: token,
          data: {'hotel_id': hotelId});
      return response['success'] == true
          ? {'success': true, 'message': 'All waitlist entries cancelled for hotel'}
          : {'success': false, 'message': response['message'] ?? 'Failed to cancel waitlist entries'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to cancel waitlist entries'};
    }
  }

  // Get waitlist position
  Future<Map<String, dynamic>> getWaitlistPosition(String waitlistId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get('${ApiConfig.waitlistDeleteEndpoint}/$waitlistId/position', token: token);
      return response['success'] == true
          ? {'success': true, 'position': response['data']['position'], 'total': response['data']['total']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get waitlist position'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get waitlist position'};
    }
  }
}