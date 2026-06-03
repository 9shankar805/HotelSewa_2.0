import 'dart:io';
import 'api_service.dart';

/// Handles Auth & Account endpoints that require Bearer token.
class AuthAccountService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // POST /update-profile
  static Future<Map<String, dynamic>> updateProfile({
    Map<String, String>? fields,
    File? photo,
  }) async {
    if (photo != null) {
      return ApiService.uploadFile(
        '/update-profile',
        photo,
        token: _token,
        fields: fields,
      );
    }
    return ApiService.post('/update-profile', token: _token, data: fields?.cast<String, dynamic>());
  }

  // POST /logout
  static Future<Map<String, dynamic>> logout() async {
    final response = await ApiService.post('/logout', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Logout failed');
  }

  // GET /get-notification-list
  static Future<List<Map<String, dynamic>>> getNotificationList() async {
    final response = await ApiService.get('/get-notification-list', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch notifications');
  }

  // PUT /notifications/{id}/read
  static Future<Map<String, dynamic>> markNotificationRead(String id) async {
    final response = await ApiService.put('/notifications/$id/read', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to mark notification read');
  }

  // PUT /notifications/read-all
  static Future<Map<String, dynamic>> markAllNotificationsRead() async {
    final response = await ApiService.put('/notifications/read-all', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to mark all notifications read');
  }

  // GET /2fa/status
  static Future<Map<String, dynamic>> get2faStatus() async {
    final response = await ApiService.get('/2fa/status', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch 2FA status');
  }

  // POST /2fa/setup — returns TOTP secret + QR
  static Future<Map<String, dynamic>> setup2fa() async {
    final response = await ApiService.post('/2fa/setup', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to setup 2FA');
  }

  // POST /2fa/verify — activate 2FA with OTP
  static Future<Map<String, dynamic>> verify2fa(String otp) async {
    final response = await ApiService.post('/2fa/verify', token: _token, data: {'otp': otp});
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to verify 2FA');
  }

  // POST /2fa/validate — validate OTP at login
  static Future<Map<String, dynamic>> validate2fa(String otp) async {
    final response = await ApiService.post('/2fa/validate', token: _token, data: {'otp': otp});
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to validate 2FA');
  }

  // POST /2fa/disable
  static Future<Map<String, dynamic>> disable2fa(String otp) async {
    final response = await ApiService.post('/2fa/disable', token: _token, data: {'otp': otp});
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to disable 2FA');
  }

  // POST /2fa/biometric/toggle
  static Future<Map<String, dynamic>> toggleBiometric(bool enabled) async {
    final response = await ApiService.post(
      '/2fa/biometric/toggle',
      token: _token,
      data: {'enabled': enabled},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to toggle biometric');
  }
}
