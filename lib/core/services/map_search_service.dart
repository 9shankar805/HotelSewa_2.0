import '../constants/api_config.dart';
import 'shared/api_service.dart';

/// Feature 2: Map-based search by geographic bounds
class MapSearchService {

  // GET hotels — search within map bounds (SW + NE corners)
  Future<Map<String, dynamic>> searchByBounds({
    required double latSw,
    required double lngSw,
    required double latNe,
    required double lngNe,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await ApiService.get(ApiConfig.hotelsEndpoint, queryParams: {
        'lat_sw': latSw,
        'lng_sw': lngSw,
        'lat_ne': latNe,
        'lng_ne': lngNe,
        ...?filters,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Map search failed'};
    }
  }

  // GET hotels — search by center point + radius (for map pin clustering)
  Future<Map<String, dynamic>> searchByCenter({
    required double lat,
    required double lng,
    double radiusKm = 10,
    Map<String, dynamic>? filters,
  }) async {
    try {
      final response = await ApiService.get(ApiConfig.hotelsEndpoint, queryParams: {
        'latitude': lat,
        'longitude': lng,
        'radius': radiusKm,
        ...?filters,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Map search failed'};
    }
  }

  // GET hotels/nearby — quick nearby fetch for map initial load
  Future<Map<String, dynamic>> getNearbyForMap({
    required double lat,
    required double lng,
    int? radius,
  }) async {
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
}






