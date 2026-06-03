import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

class PriceAlertService {
  // POST /price-alerts - Create price alert
  Future<Map<String, dynamic>> create({
    required String hotelId,
    required String roomTypeId,
    required double targetPrice,
  }) async {
    try {
      final response = await ApiService.post('/price-alerts', data: {
        'hotel_id': hotelId,
        'room_type_id': roomTypeId,
        'target_price': targetPrice,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create price alert'};
    }
  }

  // GET /price-alerts/my - My price alerts
  Future<Map<String, dynamic>> getMyAlerts() async {
    try {
      final response = await ApiService.get('/price-alerts/my');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load price alerts'};
    }
  }

  // DELETE /price-alerts/{id} - Delete alert
  Future<Map<String, dynamic>> delete(String alertId) async {
    try {
      final response = await ApiService.delete('/price-alerts/$alertId');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete price alert'};
    }
  }
}





