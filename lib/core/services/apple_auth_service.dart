import 'package:shared_preferences/shared_preferences.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../constants/api_config.dart';
import 'shared/api_service.dart';

/// Feature 9: Apple Sign-In (required for iOS App Store compliance)
class AppleAuthService {

  /// Check if Apple Sign-In is available on this device
  Future<bool> isAvailable() async {
    return await SignInWithApple.isAvailable();
  }

  /// Full Apple Sign-In flow — gets credential then authenticates with backend
  Future<Map<String, dynamic>> signInWithApple() async {
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      // Build display name from Apple credential (only provided on first sign-in)
      final fullName = [
        credential.givenName ?? '',
        credential.familyName ?? '',
      ].where((s) => s.isNotEmpty).join(' ');

      // POST user-signup — same endpoint used for Google login
      final response = await ApiService.post(ApiConfig.userSignupEndpoint, data: {
        'apple_id': credential.userIdentifier,
        'identity_token': credential.identityToken,
        'authorization_code': credential.authorizationCode,
        if (credential.email != null) 'email': credential.email,
        if (fullName.isNotEmpty) 'name': fullName,
        'role': 'customer',
        'provider': 'apple',
      });

      if (response['data']['access_token'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('authToken', response['data']['access_token']);
        await prefs.setString('userData', response['data'].toString());
      }

      return {'success': true, 'data': response['data']};
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) {
        return {'success': false, 'message': 'Sign in cancelled'};
      }
      return {'success': false, 'message': 'Apple Sign-In failed: ${e.toString()}'};
    } catch (e) {
      return {'success': false, 'message': null?.data['error'] ?? 'Apple login failed'};
    } catch (e) {
      return {'success': false, 'message': 'Apple Sign-In failed: $e'};
    }
  }
}






