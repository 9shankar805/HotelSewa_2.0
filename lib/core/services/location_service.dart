import 'shared/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/api_config.dart';

class LocationService {
  // GET /countries - Countries list
  Future<Map<String, dynamic>> getCountries() async {
    try {
      final response = await ApiService.get(ApiConfig.countriesEndpoint);
      return response['success'] == true
          ? {'success': true, 'countries': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load countries'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load countries'};
    }
  }

  // GET /states - States list
  Future<Map<String, dynamic>> getStates({String? countryId}) async {
    try {
      final queryParams = countryId != null ? {'country_id': countryId} : null;
      final response = await ApiService.get(ApiConfig.statesEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'states': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load states'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load states'};
    }
  }

  // GET /cities - Cities list
  Future<Map<String, dynamic>> getCities({String? stateId, String? countryId}) async {
    try {
      final queryParams = <String, String>{};
      if (stateId != null) queryParams['state_id'] = stateId;
      if (countryId != null) queryParams['country_id'] = countryId;
      
      final response = await ApiService.get(ApiConfig.citiesEndpoint, queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'cities': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load cities'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load cities'};
    }
  }

  // GET /areas - Areas list
  Future<Map<String, dynamic>> getAreas({String? cityId}) async {
    try {
      final queryParams = cityId != null ? {'city_id': cityId} : null;
      final response = await ApiService.get(ApiConfig.areasEndpoint, queryParams: queryParams);
      return response['success'] == true
          ? {'success': true, 'areas': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load areas'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load areas'};
    }
  }

  // GET /get-location - Location data
  Future<Map<String, dynamic>> getLocation({
    double? latitude,
    double? longitude,
    String? address,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (latitude != null) queryParams['latitude'] = latitude.toString();
      if (longitude != null) queryParams['longitude'] = longitude.toString();
      if (address != null) queryParams['address'] = address;
      
      final response = await ApiService.get(ApiConfig.getLocationEndpoint, queryParams: queryParams.isNotEmpty ? queryParams : null);
      return response['success'] == true
          ? {'success': true, 'location': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to get location'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to get location'};
    }
  }

  // Helper method to get full location hierarchy
  Future<Map<String, dynamic>> getLocationHierarchy({
    String? countryId,
    String? stateId,
    String? cityId,
  }) async {
    try {
      final results = <String, dynamic>{};
      
      // Get countries
      final countriesResult = await getCountries();
      if (countriesResult['success'] == true) {
        results['countries'] = countriesResult['countries'];
      }
      
      // Get states if country is selected
      if (countryId != null) {
        final statesResult = await getStates(countryId: countryId);
        if (statesResult['success'] == true) {
          results['states'] = statesResult['states'];
        }
      }
      
      // Get cities if state is selected
      if (stateId != null) {
        final citiesResult = await getCities(stateId: stateId, countryId: countryId);
        if (citiesResult['success'] == true) {
          results['cities'] = citiesResult['cities'];
        }
      }
      
      // Get areas if city is selected
      if (cityId != null) {
        final areasResult = await getAreas(cityId: cityId);
        if (areasResult['success'] == true) {
          results['areas'] = areasResult['areas'];
        }
      }
      
      return {'success': true, 'data': results};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load location hierarchy'};
    }
  }

  // Search locations by name
  Future<Map<String, dynamic>> searchLocations(String query) async {
    try {
      final response = await ApiService.get(ApiConfig.getLocationEndpoint, queryParams: {'search': query});
      return response['success'] == true
          ? {'success': true, 'locations': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to search locations'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to search locations'};
    }
  }


  // Local storage methods for saved city/location
  static Future<String?> getSavedCity() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString('saved_city');
    } catch (e) {
      return null;
    }
  }

  static Future<Map<String, double>?> getSavedCoords() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble('saved_lat');
      final lng = prefs.getDouble('saved_lng');
      
      if (lat != null && lng != null) {
        return {'lat': lat, 'lng': lng};
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  static Future<void> saveCity(String city, {double? lat, double? lng}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('saved_city', city);
      
      if (lat != null && lng != null) {
        await prefs.setDouble('saved_lat', lat);
        await prefs.setDouble('saved_lng', lng);
      }
    } catch (e) {
      // Handle error silently
    }
  }

  // GPS/Location methods
  static Future<Position> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied, we cannot request permissions.');
    } 

    return await Geolocator.getCurrentPosition();
  }
}