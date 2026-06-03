import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../../core/services/api_service.dart';

/// Concrete implementation of the authentication service.
/// All endpoints mapped to 209.50.241.46:2000/api spec.
class RealAuthService {
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'user_data';

  // POST /user-signup — login
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await ApiService.post(
      '/user-signup',
      data: {'email': email, 'password': password},
    );
    if (response['success'] == true) {
      final token = response['data']?['token'];
      final userData = response['data']?['user'];
      if (token != null) await _saveToken(token);
      if (userData != null) await _saveUserData(userData);
    }
    return response;
  }

  // POST /user-signup — Google sign-in
  Future<Map<String, dynamic>> signInWithGoogle(GoogleSignInAccount googleUser) async {
    debugPrint('🔵 Starting Google Sign-In for: ${googleUser.email}');
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    final response = await ApiService.post(
      '/user-signup',
      data: {
        'email': googleUser.email,
        'name': googleUser.displayName ?? googleUser.email.split('@')[0],
        'photoUrl': googleUser.photoUrl,
        'idToken': googleAuth.idToken,
        'accessToken': googleAuth.accessToken,
        'loginType': 'google',
      },
    );
    debugPrint('🟢 Google Sign-In response: ${response['success']}');
    if (response['success'] == true) {
      final token = response['data']?['token'];
      final userData = response['data']?['user'];
      if (token != null) await _saveToken(token);
      if (userData != null) await _saveUserData(userData);
    }
    return response;
  }

  // GET /verify-otp
  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    final response = await ApiService.get(
      '/verify-otp',
      queryParams: {'phone': phoneNumber, 'otp': otp},
    );
    if (response['success'] == true) {
      final token = response['data']?['token'];
      final userData = response['data']?['user'];
      if (token != null) await _saveToken(token);
      if (userData != null) await _saveUserData(userData);
    }
    return response;
  }

  // GET /get-system-settings — token validation
  Future<Map<String, dynamic>> validateToken(String token) async {
    return await ApiService.get('/get-system-settings', token: token);
  }

  // Logout — clear local session
  Future<void> logout() async {
    await GoogleSignIn().signOut();
    await _clearAuthData();
  }

  // GET /get-otp — send OTP
  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    return await ApiService.get('/get-otp', queryParams: {'phone': phoneNumber});
  }

  // GET /get-otp — reset password via OTP
  Future<Map<String, dynamic>> resetPassword(String email) async {
    return await ApiService.get('/get-otp', queryParams: {'email': email, 'type': 'reset'});
  }

  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  Future<void> _saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(userData));
  }

  Future<void> _clearAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }
}
