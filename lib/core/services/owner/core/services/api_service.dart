import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_config.dart';
// Re-export the shared session-expiry handler
import '../../../../shared/api_service.dart' as _shared;

/// Owner-feature ApiService.
/// Delegates all HTTP calls through the shared ApiService so that
/// 401 session-expiry handling (onSessionExpired callback) works consistently.
class ApiService {
  static String get baseUrl => ApiConfig.baseUrl;

  // ── Delegate header building ──────────────────────────────────────────

  static Map<String, String> _headers(String? token) {
    final base = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token == null || token.isEmpty) return base;
    return {...base, 'Authorization': 'Bearer $token'};
  }

  // ── HTTP methods — delegate to shared ApiService ─────────────────────

  static Future<Map<String, dynamic>> get(
    String endpoint, {
    String? token,
    Map<String, String>? queryParams,
  }) async {
    // Convert Map<String, String> to Map<String, dynamic> for shared service
    final params = queryParams?.map((k, v) => MapEntry(k, v as dynamic));
    return _shared.ApiService.get(endpoint, token: token, queryParams: params);
  }

  static Future<Map<String, dynamic>> post(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
    Map<String, String>? queryParams,
  }) async {
    final params = queryParams?.map((k, v) => MapEntry(k, v as dynamic));
    return _shared.ApiService.post(endpoint, token: token, data: data, queryParams: params);
  }

  static Future<Map<String, dynamic>> put(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    return _shared.ApiService.put(endpoint, token: token, data: data);
  }

  static Future<Map<String, dynamic>> patch(
    String endpoint, {
    Map<String, dynamic>? data,
    String? token,
  }) async {
    return _shared.ApiService.patch(endpoint, token: token, data: data);
  }

  static Future<Map<String, dynamic>> delete(
    String endpoint, {
    String? token,
    Map<String, dynamic>? data,
  }) async {
    return _shared.ApiService.delete(endpoint, token: token, data: data);
  }

  static Future<Map<String, dynamic>> uploadFile(
    String endpoint,
    File file, {
    String? token,
    Map<String, String>? fields,
  }) async {
    return _shared.ApiService.uploadFile(endpoint, file, token: token, fields: fields);
  }

  static Future<Map<String, dynamic>> uploadFiles(
    String endpoint,
    List<File> files, {
    String? token,
    Map<String, String>? fields,
  }) async {
    return _shared.ApiService.uploadFiles(endpoint, files, token: token, fields: fields);
  }
}
