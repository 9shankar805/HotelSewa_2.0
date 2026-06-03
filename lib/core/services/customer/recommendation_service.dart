import 'package:shared_preferences/shared_preferences.dart';
import '../shared/api_service.dart';

class RecommendationService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> getTrending() async {
    try {
      return await ApiService.get('/recommendations/trending');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load trending'};
    }
  }

  Future<Map<String, dynamic>> getNearbyPopular(double latitude, double longitude) async {
    try {
      return await ApiService.get('/recommendations/nearby-popular', queryParams: {
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      });
    } catch (e) {
      return {'success': false, 'message': 'Failed to load nearby popular'};
    }
  }

  Future<Map<String, dynamic>> getAlsoBooked(String hotelId) async {
    try {
      return await ApiService.get('/recommendations/also-booked/$hotelId');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load also booked'};
    }
  }

  Future<Map<String, dynamic>> getForYou() async {
    try {
      final token = await _getToken();
      return await ApiService.get('/recommendations/for-you', token: token);
    } catch (e) {
      return {'success': false, 'message': 'Failed to load recommendations'};
    }
  }
}

