import '../constants/api_config.dart';
import 'shared/api_service.dart';

class FilterService {

  Future<Map<String, dynamic>> getFilterOptions() async {
    try {
      final response = await ApiService.get(ApiConfig.filterOptionsEndpoint);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load filter options'};
    }
  }

  Future<Map<String, dynamic>> getAdvancedFilters() async {
    try {
      final response = await ApiService.get(ApiConfig.filterAdvancedEndpoint);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load advanced filters'};
    }
  }

  Future<Map<String, dynamic>> searchWithFilters(Map<String, dynamic> filters) async {
    try {
      final response = await ApiService.get(ApiConfig.filterSearchEndpoint, queryParams: filters);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Search failed'};
    }
  }
}






