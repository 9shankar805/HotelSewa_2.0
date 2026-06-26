import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../constants/api_config.dart';
import 'shared/api_service.dart';

/// Apple Sign-In service — required for iOS App Store compliance.
/// Authenticates via Apple ID, then sends credentials to the backend.
class AppleAuthService {
  static const String _tokenKey = 'authToken';
  static const String _userKey = 'user';

  /// Returns true if Apple Sign-In is available (iOS 13+, macOS 10.15+).
  static Future<bool> isAvailable() async {
    try {
      return await SignInWithApple.isAvailable();
    } catch (_) {
      return false;
    }
  }

  /// Full Apple Sign-In flow:
  /// 1. Gets Apple ID credential
  /// 2. Signs into Firebase with Apple credential to get a Firebase ID token
  /// 3. Posts to backend /user-signup with type=apple
  static Future<Map<String, dynamic>> signInWithApple() async {
    try {
      // Step 1 — Request Apple ID credential
      final appleCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      debugPrint('🍎 Apple Sign-In: got credential for ${appleCredential.userIdentifier}');

      // Build display name (Apple only provides this on the FIRST sign-in)
      final fullName = [
        appleCredential.givenName ?? '',
        appleCredential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ');

      // Step 2 — Sign into Firebase to get a Firebase ID token
      String firebaseId;
      try {
        final oauthCredential = firebase_auth.OAuthProvider('apple.com').credential(
          idToken: appleCredential.identityToken,
          accessToken: appleCredential.authorizationCode,
        );
        final userCredential = await firebase_auth.FirebaseAuth.instance
            .signInWithCredential(oauthCredential);
        firebaseId = await userCredential.user?.getIdToken() ??
            appleCredential.identityToken ??
            'apple_${appleCredential.userIdentifier}';
        debugPrint('🍎 Got Firebase ID token via FirebaseAuth');
      } catch (firebaseError) {
        // Fallback: use Apple identity token directly
        firebaseId = appleCredential.identityToken ??
            'apple_${appleCredential.userIdentifier}';
        debugPrint('🍎 Using Apple identity token directly (Firebase fallback): $firebaseError');
      }

      // Step 3 — Authenticate with backend
      final response = await ApiService.post(
        ApiConfig.userSignupEndpoint,
        data: {
          'type': 'apple',
          'firebase_id': firebaseId,
          'apple_id': appleCredential.userIdentifier,
          if (appleCredential.email != null && appleCredential.email!.isNotEmpty)
            'email': appleCredential.email,
          if (fullName.isNotEmpty) 'name': fullName,
        },
      );

      debugPrint('🍎 Backend response: success=${response['success']}, message=${response['message']}');

      if (response['success'] == true) {
        final token = response['data']?['token'] ?? response['token'];
        final userData = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'])
            : null;

        if (token != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_tokenKey, token.toString());
          if (userData != null) {
            await prefs.setString(_userKey, jsonEncode(userData));
          }
        }
      }

      return response;
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return {'success': false, 'message': 'cancelled'};
      }
      debugPrint('🍎 Apple auth error: ${e.code} — ${e.message}');
      return {'success': false, 'message': 'Apple Sign-In failed: ${e.message}'};
    } catch (e) {
      debugPrint('🍎 Apple Sign-In unexpected error: $e');
      return {'success': false, 'message': 'Apple Sign-In failed: $e'};
    }
  }
}
