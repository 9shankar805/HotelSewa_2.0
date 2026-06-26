import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized token manager — single source of truth for auth tokens.
/// Eliminates the pattern of calling setToken() on 40+ services manually.
class TokenManager {
  static String? _cachedToken;

  // ─── Callbacks ──────────────────────────────────────────────────────────
  /// List of callbacks invoked when the token is set/changed.
  /// Services register callbacks here instead of requiring manual setToken().
  static final List<void Function(String token)> _onTokenSetCallbacks = [];

  /// Register a callback that will be called whenever the token is set/refreshed.
  static void onTokenSet(void Function(String token) callback) {
    _onTokenSetCallbacks.add(callback);
  }

  /// Unregister a previously registered callback.
  static void removeOnTokenSet(void Function(String token) callback) {
    _onTokenSetCallbacks.remove(callback);
  }

  // ─── Token Management ───────────────────────────────────────────────────

  /// Returns the cached token or loads from SharedPreferences.
  static Future<String?> getToken() async {
    if (_cachedToken != null) return _cachedToken;
    final prefs = await SharedPreferences.getInstance();
    _cachedToken = prefs.getString('authToken');
    return _cachedToken;
  }

  /// Sets the token in memory and SharedPreferences, then notifies all callbacks.
  static Future<void> setToken(String token) async {
    _cachedToken = token;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('authToken', token);
    await prefs.setString('authTokenSavedAt', DateTime.now().toIso8601String());

    debugPrint('[TokenManager] Token set (${token.substring(0, 20)}...)');
    debugPrint(
      '[TokenManager] Notifying ${_onTokenSetCallbacks.length} callbacks',
    );

    for (final callback in _onTokenSetCallbacks) {
      try {
        callback(token);
      } catch (e) {
        debugPrint('[TokenManager] Callback error: $e');
      }
    }
  }

  /// Clears the token from memory and SharedPreferences.
  static Future<void> clearToken() async {
    _cachedToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('authToken');
    await prefs.remove('authTokenSavedAt');
    debugPrint('[TokenManager] Token cleared');
  }
}
