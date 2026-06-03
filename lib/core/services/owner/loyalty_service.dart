import '../../constants/api_config.dart';
import '../shared/api_service.dart';

class LoyaltyService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /loyalty/balance
  static Future<Map<String, dynamic>> getBalance() async {
    final response = await ApiService.get(ApiConfig.loyaltyBalanceEndpoint, token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch loyalty balance');
  }

  // GET /loyalty/referral-code
  static Future<Map<String, dynamic>> getReferralCode() async {
    final response = await ApiService.get(ApiConfig.loyaltyReferralCodeEndpoint, token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch referral code');
  }

  // POST /loyalty/apply-referral
  static Future<Map<String, dynamic>> applyReferral(String referralCode) async {
    final response = await ApiService.post(
      ApiConfig.loyaltyApplyReferralEndpoint,
      token: _token,
      data: {'referralCode': referralCode},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to apply referral');
  }
}


