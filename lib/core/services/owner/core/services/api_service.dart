import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';

class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  static const Map<String, String> _baseHeaders = {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
  };

  static Map<String, String> _getHeaders(String? token) {
    if (token == null || token.isEmpty) return _baseHeaders;
    return {..._baseHeaders, 'Authorization': 'Bearer $token'};
  }

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) uri = uri.replace(queryParameters: queryParams);
      final response = await http
          .get(uri, headers: _getHeaders(token))
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));
      return _handleResponse(response);
    } catch (e) {
      return {'success': false, 'message': 'Network error: $e'};
    }
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    try {
      var uri = Uri.parse('$baseUrl$endpoint');
      if (queryParams != null) uri = uri.replace(queryParameters: queryParams);
      final response = await http
          .post(uri, headers: _getHeaders(token), body: data != null ? jsonEncode(data) : null)
          .timeout(Duration(seconds: ApiConfig.connectionTimeout));
      return _handleResponse(response);
    } catch (e) {
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
  }) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      request.headers.addAll(_getHeaders(token));
      if (fields != null) request.fields.addAll(fields);
      request.files.add(await http.MultipartFile.fromPath('image', file.path));
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
    try {
      final jsonData = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonData.containsKey('error')) {
        final isError = jsonData['error'] == true;
        jsonData['success'] = !isError;
        if (!isError && jsonData.containsKey('token')) {
          final data = jsonData['data'];
          if (data is Map<String, dynamic>) {
            data['token'] = jsonData['token'];
          } else {
            jsonData['data'] = {'token': jsonData['token']};
          }
        }
      }
      return jsonData;
    } catch (_) {
      return {
        'success': response.statusCode >= 200 && response.statusCode < 300,
        'message': response.body,
        'statusCode': response.statusCode,
      };
    }
  }
}
