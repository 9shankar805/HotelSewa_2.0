import 'package:flutter/foundation.dart';
import 'shared/api_service.dart';
import 'shared/cache_service.dart';
import '../constants/api_config.dart';

class HotelService {
  Future<Map<String, dynamic>> getHotels({Map<String, dynamic>? filters}) async {
    try {
      // Return cached data immediately if available (no filters applied)
      if (filters == null || filters.isEmpty) {
        final cached = CacheService.getHotels();
        if (cached != null) {
          debugPrint('[HotelService] Returning ${cached.length} hotels from cache');
          return {'success': true, 'data': cached, 'fromCache': true};
        }
      }

      final response = await ApiService.get(ApiConfig.hotelsEndpoint, queryParams: filters);
      dynamic raw = response['data'] is Map ? response['data']['data'] : response['data'];

      // Cache the result for offline use
      if (raw is List && (filters == null || filters.isEmpty)) {
        final hotels = raw.whereType<Map<String, dynamic>>().toList();
        await CacheService.saveHotels(hotels);
      }

      return {'success': true, 'data': raw};
    } catch (e) {
      // Offline fallback
      final cached = CacheService.getHotels();
      if (cached != null) {
        debugPrint('[HotelService] Network error, returning cached hotels');
        return {'success': true, 'data': cached, 'fromCache': true};
      }
      return {'success': false, 'message': 'Failed to load hotels', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getHotelDetails(String id) async {
    try {
      // Check cache first
      final cached = CacheService.getHotelDetails(id);
      if (cached != null) {
        debugPrint('[HotelService] Returning hotel $id details from cache');
        return {'success': true, 'data': cached, 'fromCache': true};
      }

      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelDetailsEndpoint, id));
      debugPrint('[HotelService] getHotelDetails raw response keys: ${response.keys}');
      // Handle both { data: { ... } } and { data: { data: { ... } } }
      dynamic raw = response['data'];
      if (raw is Map && raw.containsKey('data')) raw = raw['data'];
      if (raw is Map<String, dynamic>) {
        await CacheService.saveHotelDetails(id, raw);
        return {'success': true, 'data': raw};
      }
      return {'success': false, 'message': 'Unexpected response format', 'raw': response};
    } catch (e) {
      debugPrint('[HotelService] getHotelDetails error: $e');
      // Offline fallback
      final cached = CacheService.getHotelDetails(id);
      if (cached != null) return {'success': true, 'data': cached, 'fromCache': true};
      return {'success': false, 'message': 'Failed to load hotel details', 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getHotelPolicies(String id) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelPoliciesEndpoint, id));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load hotel policies'};
    }
  }

  Future<Map<String, dynamic>> getNearbyHotels({required double lat, required double lng, int? radius}) async {
    try {
      final response = await ApiService.get(ApiConfig.hotelsNearbyEndpoint, queryParams: {
        'latitude': lat,
        'longitude': lng,
        if (radius != null) 'radius': radius,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load nearby hotels'};
    }
  }

  Future<Map<String, dynamic>> getHotelMenu(String hotelId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelMenuEndpoint, '$hotelId/menu'));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load menu'};
    }
  }

  Future<Map<String, dynamic>> getHotelGallery(String hotelId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelGalleryEndpoint, '$hotelId/gallery'));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load gallery'};
    }
  }

  Future<Map<String, dynamic>> getBlackoutDates(String hotelId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelBlackoutDatesEndpoint, '$hotelId/blackout-dates'));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load blackout dates'};
    }
  }
}
