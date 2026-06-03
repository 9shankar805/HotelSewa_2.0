import 'package:google_sign_in/google_sign_in.dart';
import '../../../../core/services/shared/api_service.dart';
import '../services/real_auth_service.dart';

class AuthService {
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    return await RealAuthService.login(email: email, password: password);
  }

  Future<Map<String, dynamic>> signInWithGoogle(GoogleSignInAccount googleUser) async {
    return await RealAuthService.signInWithGoogle(googleUser);
  }

  Future<Map<String, dynamic>> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    return await RealAuthService.verifyOTP(phoneNumber: phoneNumber, otp: otp);
  }

  Future<Map<String, dynamic>> validateToken(String token) async {
    return await RealAuthService.validateToken(token);
  }

  Future<void> logout() async {
    await RealAuthService.logout();
  }

  Future<Map<String, dynamic>> sendOTP(String phoneNumber) async {
    return await RealAuthService.sendOTP(phoneNumber);
  }

  Future<Map<String, dynamic>> resetPassword(String email) async {
    return await RealAuthService.resetPassword(email);
  }
}

