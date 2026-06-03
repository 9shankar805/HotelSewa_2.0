import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';
import '../constants/api_config.dart';

class DealsService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // GET /deals - Get deals/offers (Public)
  Future<Map<String, dynamic>> getDeals({
    String? location,
    String? category,
    String? hotelId,
    int? limit,
    int? page,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (location != null) queryParams['location'] = location;
      if (category != null) queryParams['category'] = category;
      if (hotelId != null) queryParams['hotel_id'] = hotelId;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (page != null) queryParams['page'] = page.toString();
      
      final response = await ApiService.get(ApiConfig.dealsEndpoint, queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'deals': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load deals'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load deals'};
    }
  }

  // Get featured deals
  Future<Map<String, dynamic>> getFeaturedDeals({int? limit}) async {
    try {
      final queryParams = <String, String>{'featured': 'true'};
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final response = await ApiService.get(ApiConfig.dealsEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'deals': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load featured deals'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load featured deals'};
    }
  }

  // Get deals by category
  Future<Map<String, dynamic>> getDealsByCategory(String category, {int? limit}) async {
    try {
      return await getDeals(category: category, limit: limit);
    } catch (e) {
      return {'success': false, 'message': 'Failed to load deals by category'};
    }
  }

  // Get deals by location
  Future<Map<String, dynamic>> getDealsByLocation(String location, {int? limit}) async {
    try {
      return await getDeals(location: location, limit: limit);
    } catch (e) {
      return {'success': false, 'message': 'Failed to load deals by location'};
    }
  }

  // Get hotel-specific deals
  Future<Map<String, dynamic>> getHotelDeals(String hotelId, {int? limit}) async {
    try {
      return await getDeals(hotelId: hotelId, limit: limit);
    } catch (e) {
      return {'success': false, 'message': 'Failed to load hotel deals'};
    }
  }

  // Get active deals (not expired)
  Future<Map<String, dynamic>> getActiveDeals({
    String? location,
    String? category,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{'status': 'active'};
      if (location != null) queryParams['location'] = location;
      if (category != null) queryParams['category'] = category;
      if (limit != null) queryParams['limit'] = limit.toString();
      
      final response = await ApiService.get(ApiConfig.dealsEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'deals': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load active deals'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load active deals'};
    }
  }

  // Get deal details
  Future<Map<String, dynamic>> getDealDetails(String dealId) async {
    try {
      final response = await ApiService.get('${ApiConfig.dealsEndpoint}/$dealId');
      return response['success'] == true
          ? {'success': true, 'deal': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load deal details'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load deal details'};
    }
  }

  // Apply deal to booking
  Future<Map<String, dynamic>> applyDealToBooking({
    required String dealId,
    required String bookingId,
  }) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post('${ApiConfig.dealsEndpoint}/$dealId/apply',
          token: token,
          data: {'booking_id': bookingId});
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to apply deal'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to apply deal'};
    }
  }

  // Check deal eligibility
  Future<Map<String, dynamic>> checkDealEligibility({
    required String dealId,
    String? hotelId,
    String? checkIn,
    String? checkOut,
    int? guests,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (hotelId != null) queryParams['hotel_id'] = hotelId;
      if (checkIn != null) queryParams['check_in'] = checkIn;
      if (checkOut != null) queryParams['check_out'] = checkOut;
      if (guests != null) queryParams['guests'] = guests.toString();
      
      final response = await ApiService.get('${ApiConfig.dealsEndpoint}/$dealId/eligibility', queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'eligible': response['data']['eligible'], 'details': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to check deal eligibility'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to check deal eligibility'};
    }
  }

  // Get deals for home screen
  Future<Map<String, dynamic>> getHomeDeals({
    double? latitude,
    double? longitude,
    int? limit = 5,
  }) async {
    try {
      final results = <String, dynamic>{};
      
      // Get featured deals
      final featuredResult = await getFeaturedDeals(limit: limit);
      if (featuredResult['success'] == true) {
        results['featured'] = featuredResult['deals'];
      }
      
      // Get location-based deals if coordinates are available
      if (latitude != null && longitude != null) {
        // You might need to convert coordinates to location name or use a different endpoint
        final locationDeals = await getActiveDeals(limit: limit);
        if (locationDeals['success'] == true) {
          results['location_based'] = locationDeals['deals'];
        }
      }
      
      // Get category-wise deals
      final categories = ['hotel', 'restaurant', 'spa', 'adventure'];
      for (final category in categories) {
        final categoryDeals = await getDealsByCategory(category, limit: 3);
        if (categoryDeals['success'] == true) {
          results[category] = categoryDeals['deals'];
        }
      }
      
      return {'success': true, 'deals': results};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load home deals'};
    }
  }

  // Search deals
  Future<Map<String, dynamic>> searchDeals({
    String? query,
    String? location,
    String? category,
    double? minDiscount,
    double? maxPrice,
    String? validFrom,
    String? validTo,
    int? limit,
    int? page,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (query != null) queryParams['search'] = query;
      if (location != null) queryParams['location'] = location;
      if (category != null) queryParams['category'] = category;
      if (minDiscount != null) queryParams['min_discount'] = minDiscount.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (validFrom != null) queryParams['valid_from'] = validFrom;
      if (validTo != null) queryParams['valid_to'] = validTo;
      if (limit != null) queryParams['limit'] = limit.toString();
      if (page != null) queryParams['page'] = page.toString();
      
      final response = await ApiService.get('${ApiConfig.dealsEndpoint}/search', queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'deals': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to search deals'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to search deals'};
    }
  }

  // Get deal categories
  Future<Map<String, dynamic>> getDealCategories() async {
    try {
      final response = await ApiService.get('${ApiConfig.dealsEndpoint}/categories');
      return response['success'] == true
          ? {'success': true, 'categories': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load deal categories'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load deal categories'};
    }
  }

  // Track deal view
  Future<Map<String, dynamic>> trackDealView(String dealId) async {
    try {
      final response = await ApiService.post('${ApiConfig.dealsEndpoint}/$dealId/view');
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to track deal view'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to track deal view'};
    }
  }

  // Get user's saved deals (if authenticated)
  Future<Map<String, dynamic>> getSavedDeals() async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }
      
      final response = await ApiService.get('${ApiConfig.dealsEndpoint}/saved', token: token);
      return response['success'] == true
          ? {'success': true, 'deals': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load saved deals'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load saved deals'};
    }
  }

  // Save/unsave deal
  Future<Map<String, dynamic>> toggleSaveDeal(String dealId) async {
    try {
      final token = await _getToken();
      if (token == null) {
        return {'success': false, 'message': 'Authentication required'};
      }
      
      final response = await ApiService.post('${ApiConfig.dealsEndpoint}/$dealId/toggle-save', token: token);
      return response['success'] == true
          ? {'success': true, 'saved': response['data']['saved']}
          : {'success': false, 'message': response['message'] ?? 'Failed to save/unsave deal'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to save/unsave deal'};
    }
  }
}