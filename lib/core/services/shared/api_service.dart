import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../constants/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  // Callback set by main.dart to navigate to login on session expiry
  static void Function()? onSessionExpired;

  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> _getHeaders(String? token) {
    if (token == null || token.isEmpty) {
      debugPrint('[API] No token provided for request');
      return _baseHeaders;
    }
    debugPrint('[API] Using token: ${token.substring(0, 20)}...');
    return {..._baseHeaders, 'Authorization': 'Bearer $token'};
  }

  /// Returns the stored auth token from SharedPreferences.
  static Future<String?> getStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  /// Clears the stored auth token (called on session expiry).
  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('authTokenSavedAt');
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) uri = uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
      debugPrint('[API] GET $uri');
      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));
      debugPrint('[API] GET $endpoint → ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('[API] GET $endpoint ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
    Map<String, dynamic>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) uri = uri.replace(queryParameters: queryParams.map((k, v) => MapEntry(k, v.toString())));
      debugPrint('[API] POST $uri');
      debugPrint('[API] POST data: $data');
      final response = await http
          .post(uri, headers: _getHeaders(token), body: data != null ? jsonEncode(data) : null)
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));
      debugPrint('[API] POST $endpoint → ${response.statusCode}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('[API] POST $endpoint ERROR: $e');
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      final response = await http
          .put(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders(token),
              body: data != null ? jsonEncode(data) : null)
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    try {
      final response = await http
          .patch(Uri.parse('$baseUrl$endpoint'), headers: _getHeaders(token),
              body: data != null ? jsonEncode(data) : null)
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
    Map<String, dynamic>? data,
  }) async {
    try {
      final request = http.Request('DELETE', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_getHeaders(token));
      if (data != null) request.body = jsonEncode(data);
      final streamed = await request.send()
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));
      final response = await http.Response.fromStream(streamed);
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    String? token,
    Map<String, String>? fields,
    String fieldName = 'image',
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_getHeaders(token));
      if (fields != null) request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath(fieldName, file.path));
      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  static Future<Map<String, dynamic>> uploadFiles(
    String endpoint,
    List<File> files, {
    String? token,
    Map<String, String>? fields,
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_getHeaders(token));
      if (fields != null) request.fields.addAll(fields);
      for (final file in files) {
        request.files.add(await http.MultipartFile.fromPath('images[]', file.path));
      }
      final response = await http.Response.fromStream(await request.send());
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
    debugPrint('[API] Response body: ${response.body}');
    // Detect session expiry (401 Unauthorized)
    // IMPORTANT: Only trigger re-auth if we actually had a token in the request.
    // A 401 on a request made WITHOUT a token is a coding error, not session expiry.
    // We guard this with a cooldown so rapid parallel 401s don't fire the callback multiple times.
    if (response.statusCode == 401) {
      debugPrint('[API] 401 Unauthorized → ${response.request?.url}');
      final now = DateTime.now().millisecondsSinceEpoch;
      // Debounce: only fire once per 3 seconds to avoid redirect loops
      if (now - _lastSessionExpiredMs > 3000) {
        _lastSessionExpiredMs = now;
        debugPrint('[API] Session expired — triggering re-auth');
        Future.microtask(() => onSessionExpired?.call());
      }
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
        'statusCode': response.statusCode,
        'sessionExpired': true,
      };
    }

    // 302 redirect to login page — treat as session expiry but don't debounce
    if (response.statusCode == 302) {
      debugPrint('[API] 302 redirect — treating as session expiry');
      Future.microtask(() => onSessionExpired?.call());
      return {
        'success': false,
        'message': 'Session expired. Please login again.',
        'statusCode': response.statusCode,
        'sessionExpired': true,
      };
    }

    try {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      // If API explicitly sets success field, trust it
      if (jsonData.containsKey('success')) {
        return jsonData;
      }
      // Handle error field pattern
      if (jsonData.containsKey('error')) {
        final isError = jsonData['error'] == true;
        jsonData['success'] = !isError;
        return jsonData;
      }
      // Infer from status code
      jsonData['success'] = response.statusCode >= 200 && response.statusCode < 300;
      return jsonData;
    } catch (_) {
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': response.body,
        'statusCode': response.statusCode,
      };
    }
  }

  // Debounce timestamp for session-expiry callback
  static int _lastSessionExpiredMs = 0;
}




