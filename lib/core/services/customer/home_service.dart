import 'package:shared_preferences/shared_preferences.dart';
import '../shared/api_service.dart';

class HomeService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  Future<Map<String, dynamic>> getHomeData() async {
    try {
      final token = await _getToken();
      return await ApiService.get('/get-home-data', token: token);
    } catch (e) {
      return {'success': false, 'message': 'Failed to load home data'};
    }
  }

  Future<Map<String, dynamic>> getSlider() async {
    try {
      return await ApiService.get('/get-slider');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load slider'};
    }
  }

  Future<Map<String, dynamic>> getFeaturedSection() async {
    try {
      return await ApiService.get('/get-featured-section');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load featured section'};
    }
  }

  Future<Map<String, dynamic>> getCategories() async {
    try {
      return await ApiService.get('/get-categories');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load categories'};
    }
  }

  Future<Map<String, dynamic>> getParentCategories() async {
    try {
      return await ApiService.get('/get-parent-categories');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load parent categories'};
    }
  }

  Future<Map<String, dynamic>> getBlogs() async {
    try {
      return await ApiService.get('/blogs');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load blogs'};
    }
  }

  Future<Map<String, dynamic>> getFAQ() async {
    try {
      return await ApiService.get('/faq');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load FAQ'};
    }
  }

  Future<Map<String, dynamic>> getTips() async {
    try {
      return await ApiService.get('/tips');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load tips'};
    }
  }

  Future<Map<String, dynamic>> getRecommendationsForYou() async {
    try {
      final token = await _getToken();
      return await ApiService.get('/recommendations/for-you', token: token);
    } catch (e) {
      return {'success': false, 'message': 'Failed to load recommendations'};
    }
  }

  Future<Map<String, dynamic>> getTrendingRecommendations() async {
    try {
      return await ApiService.get('/recommendations/trending');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load trending'};
    }
  }

  Future<Map<String, dynamic>> getCountries() async {
    try {
      return await ApiService.get('/countries');
    } catch (e) {
      return {'success': false, 'message': 'Failed to load countries'};
    }
  }

  Future<Map<String, dynamic>> getStates(String countryId) async {
    try {
      return await ApiService.get('/states', queryParams: {'country_id': countryId});
    } catch (e) {
      return {'success': false, 'message': 'Failed to load states'};
    }
  }

  Future<Map<String, dynamic>> getCities(String stateId) async {
    try {
      return await ApiService.get('/cities', queryParams: {'state_id': stateId});
    } catch (e) {
      return {'success': false, 'message': 'Failed to load cities'};
    }
  }

  Future<Map<String, dynamic>> getAreas(String cityId) async {
    try {
      return await ApiService.get('/areas', queryParams: {'city_id': cityId});
    } catch (e) {
      return {'success': false, 'message': 'Failed to load areas'};
    }
  }

  Future<Map<String, dynamic>> submitContactForm(Map<String, dynamic> data) async {
    try {
      return await ApiService.post('/contact-us', data: data);
    } catch (e) {
      return {'success': false, 'message': 'Failed to submit form'};
    }
  }
}

