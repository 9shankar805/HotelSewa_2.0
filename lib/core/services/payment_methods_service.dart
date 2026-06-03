import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class PaymentMethodsService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /get-payment-settings - Payment settings
  Future<Map<String, dynamic>> getPaymentSettings() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.getPaymentSettingsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'settings': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load payment settings'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load payment settings'};
    }
  }

  // POST /payment-intent - Create payment intent
  Future<Map<String, dynamic>> createPaymentIntent({
    required double amount,
    required String currency,
    String? paymentMethodId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.paymentIntentEndpoint, 
          token: token, 
          data: {
            'amount': amount,
            'currency': currency,
            if (paymentMethodId != null) 'payment_method_id': paymentMethodId,
            if (metadata != null) 'metadata': metadata,
          });
      return response['success'] == true
          ? {'success': true, 'payment_intent': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to create payment intent'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create payment intent'};
    }
  }

  // GET /payment-transactions - Payment transactions
  Future<Map<String, dynamic>> getPaymentTransactions({
    int? page,
    int? limit,
    String? status,
    String? fromDate,
    String? toDate,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      if (status != null) queryParams['status'] = status;
      if (fromDate != null) queryParams['from_date'] = fromDate;
      if (toDate != null) queryParams['to_date'] = toDate;
      
      final response = await ApiService.get(ApiConfig.paymentTransactionsEndpoint, 
          token: token, 
          queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'transactions': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load payment transactions'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load payment transactions'};
    }
  }

  // GET /payment-methods - Get saved payment methods
  Future<Map<String, dynamic>> getPaymentMethods() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.paymentMethodsEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'payment_methods': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load payment methods'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load payment methods'};
    }
  }

  // POST /payment-methods - Add payment method
  Future<Map<String, dynamic>> addPaymentMethod({
    required String type, // 'card', 'bank_account', 'wallet'
    required Map<String, dynamic> details,
    bool setAsDefault = false,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.paymentMethodsEndpoint, 
          token: token, 
          data: {
            'type': type,
            'details': details,
            'set_as_default': setAsDefault,
          });
      return response['success'] == true
          ? {'success': true, 'payment_method': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add payment method'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add payment method'};
    }
  }

  // DELETE /payment-methods/{id} - Delete payment method
  Future<Map<String, dynamic>> deletePaymentMethod(String paymentMethodId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete('${ApiConfig.paymentMethodsEndpoint}/$paymentMethodId', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Payment method deleted successfully'}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete payment method'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete payment method'};
    }
  }

  // POST /payment/khalti/initiate - Initiate Khalti payment
  Future<Map<String, dynamic>> initiateKhaltiPayment({
    required double amount,
    required String productIdentity,
    required String productName,
    String? returnUrl,
    String? websiteUrl,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.khaltiInitiateEndpoint, 
          token: token, 
          data: {
            'amount': (amount * 100).toInt(), // Khalti expects amount in paisa
            'product_identity': productIdentity,
            'product_name': productName,
            if (returnUrl != null) 'return_url': returnUrl,
            if (websiteUrl != null) 'website_url': websiteUrl,
          });
      return response['success'] == true
          ? {'success': true, 'payment_data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to initiate Khalti payment'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to initiate Khalti payment'};
    }
  }

  // POST /payment/esewa/initiate - Initiate eSewa payment
  Future<Map<String, dynamic>> initiateEsewaPayment({
    required double amount,
    required String productCode,
    required String productServiceCharge,
    required String productDeliveryCharge,
    required String taxAmount,
    required String totalAmount,
    String? successUrl,
    String? failureUrl,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.esewaInitiateEndpoint, 
          token: token, 
          data: {
            'amount': amount,
            'product_code': productCode,
            'product_service_charge': productServiceCharge,
            'product_delivery_charge': productDeliveryCharge,
            'tax_amount': taxAmount,
            'total_amount': totalAmount,
            if (successUrl != null) 'success_url': successUrl,
            if (failureUrl != null) 'failure_url': failureUrl,
          });
      return response['success'] == true
          ? {'success': true, 'payment_data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to initiate eSewa payment'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to initiate eSewa payment'};
    }
  }

  // Verify payment status
  Future<Map<String, dynamic>> verifyPaymentStatus(String transactionId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.paymentTransactionsEndpoint, 
          token: token, 
          queryParams: {'transaction_id': transactionId});
      return response['success'] == true
          ? {'success': true, 'transaction': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to verify payment status'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to verify payment status'};
    }
  }

  // Get available payment gateways
  Future<Map<String, dynamic>> getAvailablePaymentGateways() async {
    try {
      final settingsResult = await getPaymentSettings();
      if (settingsResult['success'] == true) {
        final settings = settingsResult['settings'];
        final gateways = settings['available_gateways'] ?? [];
        return {'success': true, 'gateways': gateways};
      }
      return {'success': false, 'message': 'Failed to load payment gateways'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load payment gateways'};
    }
  }

  // Set default payment method
  Future<Map<String, dynamic>> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post('${ApiConfig.paymentMethodsEndpoint}/$paymentMethodId/set-default', token: token);
      return response['success'] == true
          ? {'success': true, 'message': 'Default payment method updated'}
          : {'success': false, 'message': response['message'] ?? 'Failed to set default payment method'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to set default payment method'};
    }
  }

  // Get payment method by ID
  Future<Map<String, dynamic>> getPaymentMethod(String paymentMethodId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get('${ApiConfig.paymentMethodsEndpoint}/$paymentMethodId', token: token);
      return response['success'] == true
          ? {'success': true, 'payment_method': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load payment method'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load payment method'};
    }
  }
}