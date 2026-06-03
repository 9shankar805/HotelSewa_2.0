import 'api_service.dart';

/// Earnings, Transactions & Withdrawals for hotel owners.
class EarningsService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /hotel-owner/earnings?hotel_id= (also /earnings)
  static Future<Map<String, dynamic>> getEarnings(String hotelId) async {
    final response = await ApiService.get(
      '/hotel-owner/earnings',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch earnings');
  }

  // GET /hotel-owner/transactions?hotel_id=
  static Future<List<Map<String, dynamic>>> getTransactions(String hotelId) async {
    final response = await ApiService.get(
      '/hotel-owner/transactions',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch transactions');
  }

  // GET /hotel-owner/transactions/filter?from=&to=&type=
  static Future<List<Map<String, dynamic>>> filterTransactions({
    required String hotelId,
    String? from,
    String? to,
    String? type,
  }) async {
    final params = <String, String>{'hotel_id': hotelId};
    if (from != null) params['from'] = from;
    if (to != null) params['to'] = to;
    if (type != null) params['type'] = type;
    final response = await ApiService.get(
      '/hotel-owner/transactions/filter',
      token: _token,
      queryParams: params,
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to filter transactions');
  }

  // GET /hotel-owner/earnings/export?hotel_id=
  static Future<Map<String, dynamic>> exportEarnings(String hotelId) async {
    final response = await ApiService.get(
      '/hotel-owner/earnings/export',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to export earnings');
  }

  // GET /hotel-owner/withdrawals?hotel_id=
  static Future<List<Map<String, dynamic>>> getWithdrawals(String hotelId) async {
    final response = await ApiService.get(
      '/hotel-owner/withdrawals',
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch withdrawals');
  }

  // POST /hotel-owner/withdrawals
  // body: { hotel_id, amount, bank_account_id, note }
  static Future<Map<String, dynamic>> requestWithdrawal(Map<String, dynamic> data) async {
    final response = await ApiService.post('/hotel-owner/withdrawals', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to request withdrawal');
  }
}
