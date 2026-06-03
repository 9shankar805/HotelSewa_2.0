import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class RecommendationsService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /recommendations/trending - Trending hotels (Public)
  Future<Map<String, dynamic>> getTrendingRecommendations({
    int? limit,
    String? location,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (location != null) queryParams['location'] = location;
      
      final response = await ApiService.get(ApiConfig.recommendationsTrendingEndpoint, queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'hotels': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load trending recommendations'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load trending recommendations'};
    }
  }

  // GET /recommendations/nearby-popular - Nearby popular hotels (Public)
  Future<Map<String, dynamic>> getNearbyPopularRecommendations({
    required double latitude,
    required double longitude,
    int? radius,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
      };
      if (radius != null) queryParams['radius'] = radius.toString();
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final response = await ApiService.get(ApiConfig.recommendationsNearbyPopularEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'hotels': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load nearby popular recommendations'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load nearby popular recommendations'};
    }
  }

  // GET /recommendations/also-booked/{hotelId} - Also booked hotels (Public)
  Future<Map<String, dynamic>> getAlsoBookedRecommendations(String hotelId, {int? limit}) async {
    try {
      final queryParams = limit != null ? {'limit': limit.toString()} : null;
      final response = await ApiService.get('${ApiConfig.recommendationsAlsoBookedEndpoint}/$hotelId', queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'hotels': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load also booked recommendations'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load also booked recommendations'};
    }
  }

  // GET /recommendations/for-you - Personalized recommendations (Auth Required)
  Future<Map<String, dynamic>> getPersonalizedRecommendations({
    int? limit,
    String? category,
    Map<String, dynamic>? preferences,
  }) async {
    try {
      final token = await _getToken();
      final queryParams = <String, String>{};
      if (limit != null) queryParams['limit'] = limit.toString();
      if (category != null) queryParams['category'] = category;
      if (preferences != null) {
        preferences.forEach((key, value) {
          queryParams[key] = value.toString();
        });
      }
      
      final response = await ApiService.get(ApiConfig.recommendationsForYouEndpoint, 
          token: token, 
          queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'hotels': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load personalized recommendations'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load personalized recommendations'};
    }
  }

  // Get all recommendations for home screen
  Future<Map<String, dynamic>> getHomeRecommendations({
    double? latitude,
    double? longitude,
    int? limit = 10,
  }) async {
    try {
      final results = <String, dynamic>{};
      
      // Get trending recommendations
      final trendingResult = await getTrendingRecommendations(limit: limit);
      if (trendingResult['success'] == true) {
        results['trending'] = trendingResult['hotels'];
      }
      
      // Get nearby popular if location is available
      if (latitude != null && longitude != null) {
        final nearbyResult = await getNearbyPopularRecommendations(
          latitude: latitude,
          longitude: longitude,
          limit: limit,
        );
        if (nearbyResult['success'] == true) {
          results['nearby_popular'] = nearbyResult['hotels'];
        }
      }
      
      // Get personalized recommendations if user is logged in
      final token = await _getToken();
      if (token != null) {
        final personalizedResult = await getPersonalizedRecommendations(limit: limit);
        if (personalizedResult['success'] == true) {
          results['for_you'] = personalizedResult['hotels'];
        }
      }
      
      return {'success': true, 'recommendations': results};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load home recommendations'};
    }
  }

  // Get recommendations based on user's booking history
  Future<Map<String, dynamic>> getRecommendationsBasedOnHistory({int? limit}) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }
      
      final queryParams = limit != null ? {'limit': limit.toString(), 'based_on': 'history'} : {'based_on': 'history'};
      final response = await ApiService.get(ApiConfig.recommendationsForYouEndpoint, token: token, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'hotels': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load history-based recommendations'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load history-based recommendations'};
    }
  }

  // Get recommendations for similar hotels
  Future<Map<String, dynamic>> getSimilarHotels(String hotelId, {int? limit}) async {
    try {
      final queryParams = <String, String>{'hotel_id': hotelId};
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final response = await ApiService.get('${ApiConfig.baseUrl}/recommendations/similar', queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'hotels': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load similar hotels'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load similar hotels'};
    }
  }
}