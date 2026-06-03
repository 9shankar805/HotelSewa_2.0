import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

class NotificationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get('/get-notification-list', token: token);
      return response['success'] == true
          ? {'success': true, 'notifications': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load notifications'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load notifications'};
    }
  }

  Future<Map<String, dynamic>> markAsRead(String notificationId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.put('/notifications/$notificationId/read', token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to mark as read'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to mark as read'};
    }
  }

  Future<Map<String, dynamic>> markAllAsRead() async {
    try {
      final token = await _getToken();
      final response = await ApiService.put('/notifications/read-all', token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to mark all as read'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to mark all as read'};
    }
  }

  Future<Map<String, dynamic>> deleteNotification(String notificationId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.put('/notifications/$notificationId/read', token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data'], 'message': 'Notification marked as read'}
          : {'success': false, 'message': response['message'] ?? 'Failed to update notification'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update notification'};
    }
  }

  Future<Map<String, dynamic>> updateFCMToken(String fcmToken) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post('/update-fcm-token', data: {'fcm_token': fcmToken}, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update FCM token'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update FCM token'};
    }
  }

  Future<Map<String, dynamic>> subscribeToTopic(String topic) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post('/subscribe-topic', data: {'topic': topic}, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to subscribe to topic'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to subscribe to topic'};
    }
  }

  Future<Map<String, dynamic>> unsubscribeFromTopic(String topic) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post('/unsubscribe-topic', data: {'topic': topic}, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to unsubscribe from topic'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to unsubscribe from topic'};
    }
  }

  Future<int> getUnreadCount() async {
    try {
      final result = await getNotifications();
      if (result['success'] != true) return 0;
      final List notifications = result['notifications'] as List? ?? [];
      return notifications.where((n) => n['read_at'] == null).length;
    } catch (e) {
      return 0;
    }
  }
}

