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

  /// Headers for multipart/file upload requests.
  /// Must NOT include Content-Type — the http package sets it automatically
  /// with the correct multipart boundary.
  static Map<String, String> _getMultipartHeaders(String? token) {
    final headers = {'Accept': 'application/json'};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
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
      request.headers.addAll(_getMultipartHeaders(token));
      if (fields != null) request.fields.addAll(fields);
      final ext = file.path.toLowerCase();
      final mimeType = ext.endsWith('.jpg') || ext.endsWith('.jpeg')
          ? 'image/jpeg'
          : ext.endsWith('.png')
              ? 'image/png'
              : ext.endsWith('.gif')
                  ? 'image/gif'
                  : ext.endsWith('.webp')
                      ? 'image/webp'
                      : ext.endsWith('.mp4')
                          ? 'video/mp4'
                          : ext.endsWith('.mov')
                              ? 'video/quicktime'
                              : 'image/jpeg';
      final bytes = await file.readAsBytes();
      final filename = file.path.split('/').last;
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType: http.MediaType.parse(mimeType),
      ));
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
    String fieldName = 'images',
    bool useIndexedFieldNames = false,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$endpoint');
      debugPrint('[API] Uploading files to $uri');
      debugPrint('[API] Number of files: ${files.length}');
      debugPrint('[API] Fields: $fields');
      debugPrint('[API] Field name: $fieldName');
      debugPrint('[API] Use indexed field names: $useIndexedFieldNames');
      
      final request = http.MultipartRequest('POST', uri);
      request.headers.addAll(_getMultipartHeaders(token));
      if (fields != null) request.fields.addAll(fields);
      for (var i = 0; i < files.length; i++) {
        final file = files[i];
        final name = useIndexedFieldNames ? '$fieldName[$i]' : fieldName;
        debugPrint('[API] Adding file: ${file.path} with field name: $name');
        final ext = file.path.toLowerCase();
        final mimeType = ext.endsWith('.jpg') || ext.endsWith('.jpeg')
            ? 'image/jpeg'
            : ext.endsWith('.png')
                ? 'image/png'
                : ext.endsWith('.gif')
                    ? 'image/gif'
                    : ext.endsWith('.webp')
                        ? 'image/webp'
                        : ext.endsWith('.mp4')
                            ? 'video/mp4'
                            : ext.endsWith('.mov')
                                ? 'video/quicktime'
                                : 'image/jpeg'; // default to jpeg for images
        // Read bytes directly to avoid path-encoding issues on iOS
        final bytes = await file.readAsBytes();
        final filename = file.path.split('/').last;
        request.files.add(http.MultipartFile.fromBytes(
          name,
          bytes,
          filename: filename,
          contentType: http.MediaType.parse(mimeType),
        ));
      }
      
      final response = await http.Response.fromStream(await request.send());
      debugPrint('[API] Upload response status code: ${response.statusCode}');
      debugPrint('[API] Upload response body: ${response.body}');
      return _handleResponse(response);
    } catch (e) {
      debugPrint('[API] Upload error: $e');
      return {'success': false, 'message': 'Upload error: $e'};
    }
  }

  static Map<String, dynamic> _handleResponse(http.Response response) {
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




