import '../../../../core/services/api_service.dart';

class EarningsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/earnings
  static Future<Map<String, dynamic>> getEarnings({Map<String, String>? filters}) async {
    final response =
        await ApiService.get('/hotel-owner/earnings', token: _token, queryParams: filters);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch earnings');
  }

  // GET /hotel-owner/earnings/export
  static Future<Map<String, dynamic>> exportEarnings({Map<String, String>? filters}) async {
    final response = await ApiService.get('/hotel-owner/earnings/export',
        token: _token, queryParams: filters);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to export earnings');
  }

  // GET /hotel-owner/transactions
  static Future<List<Map<String, dynamic>>> fetchTransactions(
      {Map<String, String>? filters}) async {
    final response = await ApiService.get('/hotel-owner/transactions',
        token: _token, queryParams: filters);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch transactions');
  }

  // GET /hotel-owner/transactions/filter
  static Future<List<Map<String, dynamic>>> filterTransactionsList({
    String? startDate,
    String? endDate,
    String? type,
    String? status,
  }) async {
    final queryParams = <String, String>{};
    // API expects 'from' and 'to' (not startDate/endDate)
    if (startDate != null) queryParams['from'] = startDate;
    if (endDate != null) queryParams['to'] = endDate;
    if (type != null) queryParams['type'] = type;
    if (status != null) queryParams['status'] = status;
    final response = await ApiService.get('/hotel-owner/transactions/filter',
        token: _token, queryParams: queryParams);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to filter transactions');
  }

  // GET /hotel-owner/withdrawals
  static Future<List<Map<String, dynamic>>> fetchWithdrawals() async {
    final response = await ApiService.get('/hotel-owner/withdrawals', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch withdrawals');
  }

  // POST /hotel-owner/withdrawals
  static Future<Map<String, dynamic>> createWithdrawal(Map<String, dynamic> data) async {
    final response =
        await ApiService.post('/hotel-owner/withdrawals', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to request withdrawal');
  }

  // ── Instance wrappers (EarningsProvider uses _earningsService.method()) ──

  Future<List<Map<String, dynamic>>> getEarningsData(String period) async {
    final data = await EarningsService.getEarnings(filters: {'period': period});
    if (data is List) return List<Map<String, dynamic>>.from(data as Iterable);
    return [data];
  }

  Future<List<Map<String, dynamic>>> getTransactions(String period) =>
      EarningsService.fetchTransactions(filters: {'period': period});

  Future<List<Map<String, dynamic>>> getWithdrawals(String period) =>
      EarningsService.fetchWithdrawals();

  Future<Map<String, dynamic>> requestWithdrawal(double amount, String bankAccountId) =>
      EarningsService.createWithdrawal({'amount': amount, 'bankAccountId': bankAccountId});

  Future<void> exportEarningsReport(String period, String format) =>
      EarningsService.exportEarnings(filters: {'period': period, 'format': format});

  Future<Map<String, dynamic>> getTransactionHistory() async {
    final list = await EarningsService.fetchTransactions();
    return {'data': list};
  }

  Future<Map<String, dynamic>> filterTransactions({
    String? type,
    String? status,
    String? startDate,
    String? endDate,
  }) async {
    final list = await EarningsService.filterTransactionsList(
      type: type, status: status, startDate: startDate, endDate: endDate,
    );
    return {'data': list};
  }
}
