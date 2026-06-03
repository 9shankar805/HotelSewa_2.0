import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import 'shared/api_service.dart';

class SearchHistoryService {
  static const _localHistoryKey = 'local_search_history';
  static const _maxLocalHistory = 10;

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> saveSearch(Map<String, dynamic> searchParams) async {
    await _saveLocally(searchParams);
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.searchHistoryEndpoint, data: searchParams, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': true, 'message': 'Saved locally only'};
    } catch (e) {
      return {'success': true, 'message': 'Saved locally only'};
    }
  }

  Future<Map<String, dynamic>> getSearchHistory() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.searchHistoryEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': true, 'data': await getLocalHistory(), 'source': 'local'};
    } catch (e) {
      return {'success': true, 'data': await getLocalHistory(), 'source': 'local'};
    }
  }

  Future<Map<String, dynamic>> deleteSearch(String id) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete(ApiConfig.buildPath(ApiConfig.searchHistoryEndpoint, id), token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete'};
    }
  }

  Future<Map<String, dynamic>> clearHistory() async {
    await _clearLocally();
    try {
      final token = await _getToken();
      final response = await ApiService.delete(ApiConfig.searchHistoryEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to clear history'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to clear history'};
    }
  }

  Future<void> _saveLocally(Map<String, dynamic> params) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localHistoryKey);
    final List<dynamic> history = raw != null ? jsonDecode(raw) : [];
    history.insert(0, {...params, 'saved_at': DateTime.now().toIso8601String()});
    if (history.length > _maxLocalHistory) history.removeLast();
    await prefs.setString(_localHistoryKey, jsonEncode(history));
  }

  Future<List<dynamic>> getLocalHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_localHistoryKey);
    return raw != null ? jsonDecode(raw) : [];
  }

  Future<void> _clearLocally() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_localHistoryKey);
  }
}

