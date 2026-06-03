import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hotelsewa_app/core/services/shared/auth_service.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AuthService — Session State', () {
    test('isLoggedIn returns false when no token stored', () async {
      final service = AuthService();
      final result = await service.isLoggedIn();
      expect(result, isFalse);
    });

    test('isLoggedIn returns true when token is stored', () async {
      SharedPreferences.setMockInitialValues({'authToken': 'test_token_123'});
      final service = AuthService();
      final result = await service.isLoggedIn();
      expect(result, isTrue);
    });

    test('getCachedUser returns empty strings when nothing stored', () async {
      final service = AuthService();
      final user = await service.getCachedUser();
      expect(user['name'], equals(''));
      expect(user['email'], equals(''));
      expect(user['phone'], equals(''));
    });

    test('getCachedUser returns stored values', () async {
      SharedPreferences.setMockInitialValues({
        'authToken': 'token',
        'userName': 'Ram Bahadur',
        'userEmail': 'ram@example.com',
        'userPhone': '+9779800000000',
      });
      final service = AuthService();
      final user = await service.getCachedUser();
      expect(user['name'], equals('Ram Bahadur'));
      expect(user['email'], equals('ram@example.com'));
    });

    test('isTokenLikelyExpired returns false for fresh token', () async {
      SharedPreferences.setMockInitialValues({
        'authToken': 'token',
        'authTokenSavedAt': DateTime.now().millisecondsSinceEpoch,
      });
      final service = AuthService();
      final expired = await service.isTokenLikelyExpired();
      expect(expired, isFalse);
    });

    test('isTokenLikelyExpired returns true for old token', () async {
      final oldTime = DateTime.now()
          .subtract(const Duration(hours: 25))
          .millisecondsSinceEpoch;
      SharedPreferences.setMockInitialValues({
        'authToken': 'token',
        'authTokenSavedAt': oldTime,
      });
      final service = AuthService();
      final expired = await service.isTokenLikelyExpired();
      expect(expired, isTrue);
    });
  });

  group('AuthService — Logout', () {
    test('logout clears all auth data', () async {
      SharedPreferences.setMockInitialValues({
        'authToken': 'token',
        'userName': 'Test User',
        'userEmail': 'test@example.com',
        'userPhone': '+977123',
        'loginMethod': 'otp',
      });

      final service = AuthService();
      await service.logout();

      final loggedIn = await service.isLoggedIn();
      expect(loggedIn, isFalse);

      final user = await service.getCachedUser();
      expect(user['name'], equals(''));
    });
  });
}
