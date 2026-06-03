import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class WalletService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /wallet - Get wallet balance and details
  Future<Map<String, dynamic>> getWallet() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.walletEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'wallet': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load wallet'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load wallet'};
    }
  }

  // Get wallet balance
  Future<Map<String, dynamic>> getWalletBalance() async {
    try {
      final walletResult = await getWallet();
      if (walletResult['success'] == true) {
        final wallet = walletResult['wallet'];
        final balance = wallet['balance'] ?? 0.0;
        return {'success': true, 'balance': balance};
      }
      return walletResult;
    } catch (e) {
      return {'success': false, 'message': 'Failed to get wallet balance'};
    }
  }

  // Add money to wallet
  Future<Map<String, dynamic>> addMoneyToWallet({
    required double amount,
    required String paymentMethod,
    String? paymentMethodId,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.walletAddMoneyEndpoint,
          token: token,
          data: {
            'amount': amount,
            'payment_method': paymentMethod,
            if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
          });
      return response['success'] == true
          ? {'success': true, 'transaction': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add money to wallet'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add money to wallet'};
    }
  }

  // Use wallet for payment
  Future<Map<String, dynamic>> useWalletForPayment({
    required double amount,
    required String bookingId,
    String? description,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.walletUseEndpoint,
          token: token,
          data: {
            'amount': amount,
            'booking_id': bookingId,
            'type': 'booking_payment',
            if (description != null) 'description': description,
          });
      return response['success'] == true
          ? {'success': true, 'transaction': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to use wallet for payment'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to use wallet for payment'};
    }
  }

  // Get wallet transactions
  Future<Map<String, dynamic>> getWalletTransactions({
    int? page,
    int? limit,
    String? type, // 'credit', 'debit', 'all'
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (type != null) queryParams['type'] = type;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;
      
      final response = await ApiService.get(ApiConfig.walletTransactionsEndpoint,
          token: token,
          queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'transactions': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load wallet transactions'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load wallet transactions'};
    }
  }

  // Transfer money to another user
  Future<Map<String, dynamic>> transferMoney({
    required double amount,
    required String recipientId,
    String? message,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.walletTransferEndpoint,
          token: token,
          data: {
            'amount': amount,
            'recipient_id': recipientId,
            if (message != null) 'message': message,
          });
      return response['success'] == true
          ? {'success': true, 'transaction': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to transfer money'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to transfer money'};
    }
  }

  // Withdraw money from wallet
  Future<Map<String, dynamic>> withdrawMoney({
    required double amount,
    required String bankAccountId,
    String? note,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.walletWithdrawEndpoint,
          token: token,
          data: {
            'amount': amount,
            'bank_account_id': bankAccountId,
            if (note != null) 'note': note,
          });
      return response['success'] == true
          ? {'success': true, 'withdrawal': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to withdraw money'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to withdraw money'};
    }
  }

  // Get wallet transaction details
  Future<Map<String, dynamic>> getTransactionDetails(String transactionId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get('${ApiConfig.walletTransactionsEndpoint}/$transactionId', token: token);
      return response['success'] == true
          ? {'success': true, 'transaction': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load transaction details'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load transaction details'};
    }
  }

  // Check if wallet has sufficient balance
  Future<Map<String, dynamic>> checkSufficientBalance(double requiredAmount) async {
    try {
      final balanceResult = await getWalletBalance();
      if (balanceResult['success'] == true) {
        final balance = balanceResult['balance'] as double;
        final hasSufficientBalance = balance >= requiredAmount;
        return {
          'success': true,
          'has_sufficient_balance': hasSufficientBalance,
          'current_balance': balance,
          'required_amount': requiredAmount,
          'shortfall': hasSufficientBalance ? 0.0 : (requiredAmount - balance),
        };
      }
      return balanceResult;
    } catch (e) {
      return {'success': false, 'message': 'Failed to check wallet balance'};
    }
  }

  // Get wallet settings
  Future<Map<String, dynamic>> getWalletSettings() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.walletSettingsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'settings': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load wallet settings'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load wallet settings'};
    }
  }

  // Update wallet settings
  Future<Map<String, dynamic>> updateWalletSettings(Map<String, dynamic> settings) async {
    try {
      final token = await _getToken();
      final response = await ApiService.put(ApiConfig.walletSettingsEndpoint, token: token, data: settings);
      return response['success'] == true
          ? {'success': true, 'settings': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update wallet settings'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update wallet settings'};
    }
  }

  // Get wallet statistics
  Future<Map<String, dynamic>> getWalletStatistics({
    String? period, // 'week', 'month', 'year'
  }) async {
    try {
      final token = await _getToken();
      final queryParams = period != null ? {'period': period} : null;
      final response = await ApiService.get(ApiConfig.walletStatisticsEndpoint,
          token: token,
          queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'statistics': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load wallet statistics'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load wallet statistics'};
    }
  }

  // Set wallet PIN
  Future<Map<String, dynamic>> setWalletPin(String pin) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.walletSetPinEndpoint,
          token: token,
          data: {'pin': pin});
      return response['success'] == true
          ? {'success': true, 'message': 'Wallet PIN set successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to set wallet PIN'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to set wallet PIN'};
    }
  }

  // Verify wallet PIN
  Future<Map<String, dynamic>> verifyWalletPin(String pin) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.walletVerifyPinEndpoint,
          token: token,
          data: {'pin': pin});
      return response['success'] == true
          ? {'success': true, 'verified': true}
          : {'success': false, 'message': response['message'] ?? 'Invalid PIN'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify PIN'};
    }
  }


  // Get cashback offers
  Future<Map<String, dynamic>> getCashbackOffers() async {
    try {
      final response = await ApiService.get(ApiConfig.walletCashbackOffersEndpoint);
      return response['success'] == true
          ? {'success': true, 'offers': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load cashback offers'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load cashback offers'};
    }
  }
}