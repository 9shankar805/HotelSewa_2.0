import '../../../../core/constants/api_config.dart';
import '../../../../core/services/shared/api_service.dart';

class WithdrawalsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/withdrawals
  static Future<List<Map<String, dynamic>>> getWithdrawals() async {
    final response = await ApiService.get(ApiConfig.ownerWithdrawalsEndpoint, token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch withdrawals');
  }

  // POST /hotel-owner/withdrawals
  static Future<Map<String, dynamic>> requestWithdrawal(Map<String, dynamic> withdrawalData) async {
    final response = await ApiService.post(ApiConfig.ownerWithdrawalsEndpoint, token: _token, data: withdrawalData);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to request withdrawal');
  }

  // POST /bank-transfer-update
  static Future<Map<String, dynamic>> updateBankTransfer(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.bankTransferUpdateEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update bank transfer');
  }

  // Instance wrappers
  Future<List<Map<String, dynamic>>> fetchWithdrawals() => WithdrawalsService.getWithdrawals();
  Future<Map<String, dynamic>> submitWithdrawal(Map<String, dynamic> data) =>
      WithdrawalsService.requestWithdrawal(data);
}

