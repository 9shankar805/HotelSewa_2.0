import '../../../../core/services/shared/api_service.dart';

class NotificationService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /get-notification-list
  static Future<List<Map<String, dynamic>>> getNotifications() async {
    final response = await ApiService.get('/get-notification-list', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch notifications');
  }

  // Note: The real API uses /get-notification-list (GET).
  // Mark-as-read endpoints are not in the provided API spec —
  // handled optimistically client-side until confirmed by backend.
  static Future<void> markAsRead(String notificationId) async {
    // Optimistic client-side update only
  }

  static Future<void> markAllAsRead() async {
    // Optimistic client-side update only
  }

  // Instance wrapper (screens use NotificationService().fetchNotifications())
  Future<List<Map<String, dynamic>>> fetchNotifications() =>
      NotificationService.getNotifications();
}

