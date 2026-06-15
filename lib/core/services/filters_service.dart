import 'shared/api_service.dart';
import '../constants/api_config.dart';

class FiltersService {
  // GET /filters/options - Filter options
  Future<Map<String, dynamic>> getFilterOptions() async {
    try {
      final response = await ApiService.get(ApiConfig.filtersOptionsEndpoint);
      return response['success'] == true
          ? {'success': true, 'options': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load filter options'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load filter options'};
    }
  }

  // GET /filters/advanced - Advanced filters
  Future<Map<String, dynamic>> getAdvancedFilters() async {
    try {
      final response = await ApiService.get(ApiConfig.filtersAdvancedEndpoint);
      return response['success'] == true
          ? {'success': true, 'filters': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load advanced filters'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load advanced filters'};
    }
  }

  // GET /filters/search - Search with filters (backend fixed: POST was 405, use GET)
  Future<Map<String, dynamic>> getSearchFilters({
    String? query,
    String? location,
    String? category,
    String? checkIn,
    String? checkOut,
    int? minPrice,
    int? maxPrice,
    double? minRating,
    List<String>? amenities,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (query != null) queryParams['query'] = query;
      if (location != null) queryParams['location'] = location;
      if (category != null) queryParams['category'] = category;
      if (checkIn != null) queryParams['check_in'] = checkIn;
      if (checkOut != null) queryParams['check_out'] = checkOut;
      if (minPrice != null) queryParams['min_price'] = minPrice.toString();
      if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
      if (minRating != null) queryParams['min_rating'] = minRating.toString();
      if (amenities != null && amenities.isNotEmpty) queryParams['amenities'] = amenities.join(',');

      final response = await ApiService.get(
        ApiConfig.filtersSearchEndpoint,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );
      return response['success'] == true || response['error'] == false
          ? {'success': true, 'results': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Search failed'};
    } catch (e) {
      return {'success': false, 'message': 'Search failed'};
    }
  }

  // Apply filters to hotel search
  Future<Map<String, dynamic>> applyFilters(Map<String, dynamic> filters) async {
    try {
      final response = await ApiService.get(ApiConfig.hotelsEndpoint, queryParams: filters.map((k, v) => MapEntry(k, v.toString())));
      return response['success'] == true
          ? {'success': true, 'hotels': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to apply filters'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to apply filters'};
    }
  }

  // Get price range for filters
  Future<Map<String, dynamic>> getPriceRange({
    String? location,
    String? checkIn,
    String? checkOut,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (location != null) queryParams['location'] = location;
      if (checkIn != null) queryParams['check_in'] = checkIn;
      if (checkOut != null) queryParams['check_out'] = checkOut;
      queryParams['get_price_range'] = 'true';
      
      final response = await ApiService.get(ApiConfig.filtersOptionsEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'price_range': response['data']['price_range']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get price range'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get price range'};
    }
  }

  // Get amenities for filters
  Future<Map<String, dynamic>> getAmenitiesFilter() async {
    try {
      final response = await ApiService.get(ApiConfig.filtersOptionsEndpoint);
      if (response['success'] == true && response['data'] != null) {
        final amenities = response['data']['amenities'] ?? [];
        return {'success': true, 'amenities': amenities};
      }
      return {'success': false, 'message': 'Failed to load amenities'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load amenities'};
    }
  }

  // Get hotel types for filters
  Future<Map<String, dynamic>> getHotelTypesFilter() async {
    try {
      final response = await ApiService.get(ApiConfig.filtersOptionsEndpoint);
      if (response['success'] == true && response['data'] != null) {
        final hotelTypes = response['data']['hotel_types'] ?? [];
        return {'success': true, 'hotel_types': hotelTypes};
      }
      return {'success': false, 'message': 'Failed to load hotel types'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load hotel types'};
    }
  }

  // Get star ratings for filters
  Future<Map<String, dynamic>> getStarRatingsFilter() async {
    try {
      final response = await ApiService.get(ApiConfig.filtersOptionsEndpoint);
      if (response['success'] == true && response['data'] != null) {
        final starRatings = response['data']['star_ratings'] ?? [1, 2, 3, 4, 5];
        return {'success': true, 'star_ratings': starRatings};
      }
      return {'success': false, 'message': 'Failed to load star ratings'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load star ratings'};
    }
  }

  // Get all filter data at once
  Future<Map<String, dynamic>> getAllFilters() async {
    try {
      final results = <String, dynamic>{};
      
      // Get basic filter options
      final optionsResult = await getFilterOptions();
      if (optionsResult['success'] == true) {
        results.addAll(optionsResult['options'] ?? {});
      }
      
      // Get advanced filters
      final advancedResult = await getAdvancedFilters();
      if (advancedResult['success'] == true) {
        results['advanced'] = advancedResult['filters'];
      }
      
      return {'success': true, 'filters': results};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load all filters'};
    }
  }

  // Save user filter preferences
  Future<Map<String, dynamic>> saveFilterPreferences(Map<String, dynamic> preferences) async {
    try {
      // This would typically save to local storage or user preferences
      // For now, we'll just return success
      return {'success': true, 'message': 'Filter preferences saved'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to save filter preferences'};
    }
  }

  // Get saved filter preferences
  Future<Map<String, dynamic>> getFilterPreferences() async {
    try {
      // This would typically load from local storage or user preferences
      // For now, we'll return empty preferences
      return {'success': true, 'preferences': {}};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load filter preferences'};
    }
  }
}