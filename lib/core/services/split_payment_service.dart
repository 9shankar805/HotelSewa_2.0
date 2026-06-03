import '../constants/api_config.dart';
import 'shared/api_service.dart';

/// Feature 8: Split payment / pay later
class SplitPaymentService {
  // POST payment/pay-later — reserve now, pay at property
  Future<Map<String, dynamic>> payLater({
    required String bookingId,
    String? note,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.payLaterEndpoint, data: {
        'booking_id': bookingId,
        if (note != null) 'note': note,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Pay later request failed'};
    }
  }

  // POST payment/split — split payment across multiple methods
  Future<Map<String, dynamic>> splitPayment({
    required String bookingId,
    required List<Map<String, dynamic>> splits,
    // splits: [{method: 'khalti', amount: 500}, {method: 'esewa', amount: 500}]
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.splitPaymentLegacyEndpoint, data: {
        'booking_id': bookingId,
        'splits': splits,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Split payment failed'};
    }
  }

  // POST payment/installment — pay in installments
  Future<Map<String, dynamic>> payInstallment({
    required String bookingId,
    required int installments, // 2 or 3
    required String firstPaymentMethod,
  }) async {
    try {
      final response = await ApiService.post(ApiConfig.installmentEndpoint, data: {
        'booking_id': bookingId,
        'installments': installments,
        'first_payment_method': firstPaymentMethod,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Installment setup failed'};
    }
  }

  // GET payment/pay-later/status/{bookingId}
  Future<Map<String, dynamic>> getPayLaterStatus(String bookingId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.payLaterStatusEndpoint, bookingId));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get pay later status'};
    }
  }

  // New methods for Feature 45
  Future<Map<String, dynamic>> createSplitPayment(Map<String, dynamic> data) async {
    try {
      final response = await ApiService.post(ApiConfig.splitPaymentCreateEndpoint, data: data);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create split payment'};
    }
  }

  Future<Map<String, dynamic>> getMySplits() async {
    try {
      final response = await ApiService.get(ApiConfig.splitPaymentMySplitsEndpoint);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load splits'};
    }
  }
}





