import '../../../../core/services/api_service.dart';

class ProfileService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /get-owner
  Future<Map<String, dynamic>> getUserProfile() async {
    final response = await ApiService.get(
      '/get-owner',
      token: _token,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to fetch profile');
  }

  // POST /update-profile
  Future<Map<String, dynamic>> updateProfile(Map<String, dynamic> profileData) async {
    final response = await ApiService.post(
      '/update-profile',
      token: _token,
      data: profileData,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to update profile');
  }

  // POST /update-profile with image
  Future<Map<String, dynamic>> uploadProfilePicture(String imagePath, String userName) async {
    final response = await ApiService.post(
      '/update-profile',
      token: _token,
      data: {'profileImage': imagePath, 'name': userName},
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to upload avatar');
  }

  // POST /update-profile — remove image
  Future<void> removeProfilePicture() async {
    final response = await ApiService.post(
      '/update-profile',
      token: _token,
      data: {'profileImage': null},
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to remove profile picture');
    }
  }

  // DELETE /delete-user
  Future<void> deleteAccount() async {
    final response = await ApiService.delete(
      '/delete-user',
      token: _token,
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete account');
    }
  }

  // GET /verification-fields
  Future<Map<String, dynamic>> getVerificationFields() async {
    final response = await ApiService.get(
      '/verification-fields',
      token: _token,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to fetch verification fields');
  }

  // POST /send-verification-request
  Future<Map<String, dynamic>> sendVerificationRequest(Map<String, dynamic> data) async {
    final response = await ApiService.post(
      '/send-verification-request',
      token: _token,
      data: data,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to send verification request');
  }

  // GET /verification-request
  Future<Map<String, dynamic>> getVerificationRequest() async {
    final response = await ApiService.get(
      '/verification-request',
      token: _token,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to fetch verification request');
  }

  // No dedicated logout endpoint — handled locally
  Future<void> logout() async {
    _token = null;
  }
}
