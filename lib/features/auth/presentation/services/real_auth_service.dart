import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/services/shared/api_service.dart';

class RealAuthService {
  // Use same keys as AuthProvider / AppConstants
  static const String _tokenKey = 'authToken';
  static const String _userKey = 'user';

  static Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userKey);
    if (userDataString != null) {
      return jsonDecode(userDataString);
    }
    return null;
  }

  static Future<void> clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // Login — POST /user-signup with type=email
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.userSignupEndpoint,
        data: {
          'email': email,
          'password': password,
          'type': 'email',
          'firebase_id': 'email_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
        },
      );

      if (response['success'] == true) {
        final token = response['data']?['token'] ?? response['token'];
        final userData = response['data'] is Map ? Map<String, dynamic>.from(response['data']) : null;
        if (token != null) await _saveToken(token.toString());
        if (userData != null) await _saveUserData(userData);
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Login failed: ${e.toString()}'};
    }
  }

  // Register — POST /user-signup with type=email
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final response = await ApiService.post(
        ApiConfig.userSignupEndpoint,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
          'type': 'email',
          'firebase_id': 'email_${email.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')}',
        },
      );

      if (response['success'] == true) {
        final token = response['data']?['token'] ?? response['token'];
        final userData = response['data'] is Map ? Map<String, dynamic>.from(response['data']) : null;
        if (token != null) await _saveToken(token.toString());
        if (userData != null) await _saveUserData(userData);
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Registration failed: ${e.toString()}'};
    }
  }

  // Send OTP — GET /get-otp
  static Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    try {
      final response = await ApiService.get(
        ApiConfig.getOtpEndpoint,
        queryParams: {'mobile': phoneNumber},
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP: ${e.toString()}'};
    }
  }

  // Verify OTP — GET /verify-otp
  static Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    try {
      final response = await ApiService.get(
        ApiConfig.verifyOtpEndpoint,
        queryParams: {
          'mobile': phoneNumber,
          'otp': otp,
        },
      );

      if (response['success'] == true) {
        final token = response['data']?['token'];
        final userData = response['data']?['user'];
        if (token != null) await _saveToken(token);
        if (userData != null) await _saveUserData(userData);
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'OTP verification failed: ${e.toString()}'};
    }
  }

  // Validate token — GET /get-owner?id={userId}
  // The API requires an 'id' param. We extract it from stored user data.
  static Future<Map<String, dynamic>> validateToken(String token) async {
    try {
      // Get stored user id to pass as required param
      final userData = await getUserData();
      final userId = userData?['id']?.toString();
      final queryParams = userId != null ? {'id': userId} : <String, String>{};
      final response = await ApiService.get(
        ApiConfig.getOwnerEndpoint,
        token: token,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      // get-owner returns data.owner, normalize to data directly
      if (response['success'] == true && response['data'] is Map) {
        final data = response['data'] as Map<String, dynamic>;
        if (data.containsKey('owner')) {
          return {'success': true, 'data': data['owner']};
        }
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Token validation failed: ${e.toString()}'};
    }
  }

  // Get profile — GET /get-owner
  static Future<Map<String, dynamic>> getProfile() async {
    try {
      final token = await getToken();
      final response = await ApiService.get(ApiConfig.getOwnerEndpoint, token: token);
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to get profile: ${e.toString()}'};
    }
  }

  // Update profile — POST /update-profile
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
  }) async {
    try {
      final token = await getToken();
      final data = <String, dynamic>{};
      if (name != null) data['name'] = name;
      if (phone != null) data['phone'] = phone;

      final response = await ApiService.post(
        ApiConfig.updateProfileEndpoint,
        data: data,
        token: token,
      );

      if (response['success'] == true) {
        final currentUserData = await getUserData();
        if (currentUserData != null) {
          final updatedUserData = Map<String, dynamic>.from(currentUserData);
          if (name != null) updatedUserData['name'] = name;
          if (phone != null) updatedUserData['phone'] = phone;
          await _saveUserData(updatedUserData);
        }
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to update profile: ${e.toString()}'};
    }
  }

  // Google Sign-In — POST /user-signup with type=google
  // Uses Firebase Auth to get a proper Firebase ID token (same as website)
  static Future<Map<String, dynamic>> signInWithGoogle(GoogleSignInAccount googleUser) async {
    try {
      debugPrint('🔵 Starting Google Sign-In for: ${googleUser.email}');
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Get Firebase ID token via Firebase Auth credential
      String firebaseId;
      try {
        final credential = firebase_auth.GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final userCredential = await firebase_auth.FirebaseAuth.instance.signInWithCredential(credential);
        firebaseId = await userCredential.user?.getIdToken() ?? googleAuth.idToken ?? 'google_${googleUser.id}';
        debugPrint('🔵 Got Firebase ID token via FirebaseAuth');
      } catch (firebaseError) {
        // Fallback: use Google idToken directly (same as website sends)
        firebaseId = googleAuth.idToken ?? googleAuth.accessToken ?? 'google_${googleUser.id}';
        debugPrint('🔵 Using Google idToken directly: ${firebaseId.substring(0, 20)}...');
      }

      final response = await ApiService.post(
        '/user-signup',
        data: {
          'email': googleUser.email,
          'name': googleUser.displayName ?? googleUser.email.split('@')[0],
          'type': 'google',
          'firebase_id': firebaseId,
        },
      );

      debugPrint('🟢 Google Sign-In response: ${response['success']}, message: ${response['message']}');

      if (response['success'] == true) {
        final token = response['data']?['token'] ?? response['token'];
        final userData = response['data'] is Map ? Map<String, dynamic>.from(response['data']) : null;
        if (token != null) await _saveToken(token.toString());
        if (userData != null) await _saveUserData(userData);
      }

      return response;
    } catch (e) {
      debugPrint('🔴 Google Sign-In error: $e');
      return {'success': false, 'message': 'Google Sign-In failed: ${e.toString()}'};
    }
  }

  // Reset password — POST /user-signup (password reset flow)
  static Future<Map<String, dynamic>> resetPassword(String email) async {
    try {
      final response = await ApiService.get(
        '/get-otp',
        queryParams: {'email': email, 'type': 'reset'},
      );
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Failed to reset password: ${e.toString()}'};
    }
  }

  // POST /logout — server-side session invalidation + clear local data
  // Note: endpoint may vary; falls back gracefully if not available
  static Future<Map<String, dynamic>> logout() async {
    try {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        await ApiService.post('/logout', token: token, data: {});
      }
    } catch (_) {
      // Always proceed with local logout even if server call fails
    }
    await clearAuthData();
    return {'success': true, 'message': 'Logged out successfully'};
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<Map<String, dynamic>?> getCurrentUser() async {
    return await getUserData();
  }
}

