import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class FavoriteService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /get-favourite-item - List favorites
  Future<Map<String, dynamic>> getFavorites() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.getFavouriteItemEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'favorites': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load favorites'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load favorites'};
    }
  }

  // POST /manage-favourite - Add/Remove favorite
  Future<Map<String, dynamic>> toggleFavorite(String hotelId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.manageFavouriteEndpoint, 
          token: token, 
          data: {'hotel_id': hotelId});
      return response['success'] == true
          ? {'success': true, 'is_favorite': response['data']['is_favourite']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update favorite'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update favorite'};
    }
  }

  // Check if hotel is favorite
  Future<bool> isFavorite(String hotelId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.getFavouriteItemEndpoint, 
          token: token, 
          queryParams: {'hotel_id': hotelId});
      if (response['success'] == true) {
        return response['data']['is_favourite'] ?? false;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
