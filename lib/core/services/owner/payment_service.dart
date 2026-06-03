import '../shared/api_service.dart';

class PaymentService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // POST /payment/khalti/initiate
  static Future<Map<String, dynamic>> initiateKhalti(Map<String, dynamic> data) async {
    final response = await ApiService.post('/payment/khalti/initiate', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to initiate Khalti payment');
  }

  // POST /payment/esewa/initiate
  static Future<Map<String, dynamic>> initiateEsewa(Map<String, dynamic> data) async {
    final response = await ApiService.post('/payment/esewa/initiate', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to initiate eSewa payment');
  }

  // GET /payment-transactions
  static Future<List<Map<String, dynamic>>> getTransactions({Map<String, String>? filters}) async {
    final response = await ApiService.get('/payment-transactions', token: _token, queryParams: filters);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch transactions');
  }

  // GET /get-payment-settings
  static Future<Map<String, dynamic>> getPaymentSettings() async {
    final response = await ApiService.get('/get-payment-settings', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch payment settings');
  }

  // POST /payment-intent
  static Future<Map<String, dynamic>> createPaymentIntent(Map<String, dynamic> data) async {
    final response = await ApiService.post('/payment-intent', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create payment intent');
  }

  // POST /in-app-purchase
  static Future<Map<String, dynamic>> inAppPurchase(Map<String, dynamic> data) async {
    final response = await ApiService.post('/in-app-purchase', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to process in-app purchase');
  }
}


