import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';
import '../../../features/auth/presentation/models/user_model.dart';
import '../../constants/api_config.dart';

class AuthService {
  // ─── Token refresh lock (prevents concurrent refresh calls) ─────────────────
  static bool _isRefreshing = false;
  static final List<Function(String?)> _refreshCallbacks = [];

  // ─── Session helpers ────────────────────────────────────────────────────────

  Future<void> _saveSession(Map<String, dynamic> data) async {
    final token = data['token'] ?? data['access_token'];
    if (token == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token.toString());

    // Save token timestamp for expiry tracking
    await prefs.setInt('authTokenSavedAt', DateTime.now().millisecondsSinceEpoch);

    // Save as JSON blob (read by profile screen)
    final user = data['user'] ?? data['data'] ?? data;
    if (user is Map) {
      await prefs.setString('user', jsonEncode(user));
      // Also save individual keys as fallback
      if (user['name'] != null) await prefs.setString('userName', user['name'].toString());
      if (user['email'] != null) await prefs.setString('userEmail', user['email'].toString());
      if (user['phone'] != null) await prefs.setString('userPhone', user['phone'].toString());
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // ─── Silent re-auth: re-verify session with server ──────────────────────────
  /// Called automatically when a 401/302 is detected. Tries to silently
  /// re-authenticate using the stored phone number via OTP re-issue.
  /// Returns the new token if successful, null otherwise.
  Future<String?> silentReAuth() async {
    if (_isRefreshing) {
      // Queue up and wait for the in-progress refresh
      final completer = Completer<String?>();
      _refreshCallbacks.add(completer.complete);
      return completer.future;
    }

    _isRefreshing = true;
    debugPrint('[Auth] Attempting silent re-auth...');

    try {
      final prefs = await SharedPreferences.getInstance();
      final phone = prefs.getString('userPhone') ?? '';

      if (phone.isEmpty) {
        debugPrint('[Auth] Silent re-auth failed: no phone stored');
        _isRefreshing = false;
        _notifyRefreshCallbacks(null);
        return null;
      }

      // Request a new OTP
      final otpResult = await ApiService.get(
        ApiConfig.getOtpEndpoint,
        queryParams: {'mobile': phone},
      );

      if (otpResult['success'] != true) {
        debugPrint('[Auth] Silent re-auth: OTP request failed');
        _isRefreshing = false;
        _notifyRefreshCallbacks(null);
        return null;
      }

      // We cannot auto-verify OTP without user input — mark session as expired
      // and return null so callers can redirect to login
      debugPrint('[Auth] Silent re-auth: OTP sent, user must re-login');
      _isRefreshing = false;
      _notifyRefreshCallbacks(null);
      return null;
    } catch (e) {
      debugPrint('[Auth] Silent re-auth error: $e');
      _isRefreshing = false;
      _notifyRefreshCallbacks(null);
      return null;
    }
  }

  void _notifyRefreshCallbacks(String? token) {
    for (final cb in _refreshCallbacks) {
      cb(token);
    }
    _refreshCallbacks.clear();
  }

  /// Checks if the stored token is likely expired (older than 23 hours).
  /// The server uses 24h tokens; we refresh proactively at 23h.
  Future<bool> isTokenLikelyExpired() async {
    final prefs = await SharedPreferences.getInstance();
    final savedAt = prefs.getInt('authTokenSavedAt');
    if (savedAt == null) return false;
    final age = DateTime.now().millisecondsSinceEpoch - savedAt;
    return age > const Duration(hours: 23).inMilliseconds;
  }

  /// Validates the current token against the server by calling a lightweight
  /// authenticated endpoint. Returns true if valid.
  Future<bool> validateToken() async {
    try {
      final token = await _getToken();
      if (token == null || token.isEmpty) return false;
      final response = await ApiService.get(
        ApiConfig.profileStatsEndpoint,
        token: token,
      );
      return response['success'] == true;
    } catch (_) {
      return false;
    }
  }

  // ─── OTP Login ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> requestOtp(String phone) async {
    try {
      final response = await ApiService.get(ApiConfig.getOtpEndpoint, queryParams: {'mobile': phone});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to send OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send OTP'};
    }
  }

  Future<Map<String, dynamic>> verifyOtp(String phone, String otp) async {
    try {
      final response = await ApiService.get(ApiConfig.verifyOtpEndpoint, queryParams: {'mobile': phone, 'otp': otp});
      if (response['success'] == true) {
        final data = (response['data'] ?? response) as Map<String, dynamic>;
        await _saveSession(data);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': response['message'] ?? 'OTP verification failed'};
    } catch (e) {
      return {'success': false, 'message': 'OTP verification failed'};
    }
  }

  // ─── Email / Password Login ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await ApiService.post(ApiConfig.userSignupEndpoint, data: {
        'email': email,
        'password': password,
        'type': 'email',
      });
      if (response['success'] == true) {
        final data = (response['data'] ?? response) as Map<String, dynamic>;
        await _saveSession(data);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': response['message'] ?? 'Login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Login failed: $e'};
    }
  }

  // ─── Signup ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> signup(String name, String email, String password, String phone) async {
    try {
      final response = await ApiService.post(ApiConfig.userSignupEndpoint, data: {
        'name': name,
        'email': email,
        'password': password,
        'phone': phone,
        'type': 'email',
        'role': 'customer',
      });
      if (response['success'] == true) {
        final data = (response['data'] ?? response) as Map<String, dynamic>;
        await _saveSession(data);
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': response['message'] ?? 'Signup failed'};
    } catch (e) {
      return {'success': false, 'message': 'Signup failed: $e'};
    }
  }

  // ─── Google Login ────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> googleLogin(GoogleSignInAccount account) async {
    try {
      final googleAuth = await account.authentication;
      final token = googleAuth.idToken ?? googleAuth.accessToken ?? '';
      if (token.isEmpty) return {'success': false, 'message': 'Could not get Google token'};

      final response = await ApiService.post(ApiConfig.userSignupEndpoint, data: {
        'email': account.email,
        'name': account.displayName ?? '',
        'firebase_id': token,
        'type': 'google',
        'role': 'customer',
      });
      if (response['success'] == true) {
        final data = (response['data'] ?? response) as Map<String, dynamic>;
        await _saveSession(data);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('loginMethod', 'google');
        return {'success': true, 'data': data};
      }
      return {'success': false, 'message': response['message'] ?? 'Google login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Google login failed: $e'};
    }
  }

  // ─── Forgot Password ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> requestPasswordReset(String email) async {
    try {
      final response = await ApiService.get(ApiConfig.getOtpEndpoint, queryParams: {'mobile': email});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to send reset code'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to send reset code'};
    }
  }

  Future<Map<String, dynamic>> verifyResetOtp(String email, String otp) async {
    try {
      final response = await ApiService.get(ApiConfig.verifyOtpEndpoint, queryParams: {'mobile': email, 'otp': otp});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Invalid OTP'};
    }
  }

  // ─── Logout ──────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> logout() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final token = await _getToken();
      await ApiService.post(ApiConfig.logoutEndpoint, token: token);
    } catch (_) {}
    await prefs.remove('authToken');
    await prefs.remove('userName');
    await prefs.remove('userEmail');
    await prefs.remove('userPhone');
    await prefs.remove('loginMethod');
    return {'success': true};
  }

  // ─── Delete Account ──────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> deleteAccount({String? password}) async {
    try {
      final token = await _getToken();
      await ApiService.delete(
        ApiConfig.deleteUserEndpoint,
        token: token,
        data: password != null && password.isNotEmpty ? {'password': password} : null,
      );
      await logout();
      return {'success': true};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete account'};
    }
  }

  // ─── System Settings ─────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getSystemSettings() async {
    try {
      final response = await ApiService.get(ApiConfig.getSystemSettingsEndpoint);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': 'Failed to load settings'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load settings'};
    }
  }

  // ─── State helpers ───────────────────────────────────────────────────────────

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    return token != null && token.isNotEmpty;
  }

  Future<Map<String, String>> getCachedUser() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'name': prefs.getString('userName') ?? '',
      'email': prefs.getString('userEmail') ?? '',
      'phone': prefs.getString('userPhone') ?? '',
    };
  }

  Future<User?> getUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userStr = prefs.getString('user');
    if (userStr != null && userStr.isNotEmpty) {
      try {
        final userData = jsonDecode(userStr);
        return User.fromJson(userData);
      } catch (e) {
        debugPrint('Error parsing user data: $e');
      }
    }
    return null;
  }
}
