import '../../../../core/services/shared/api_service.dart';

class AmenitiesService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /hotel-owner/amenities — list available amenities
  Future<List<Map<String, dynamic>>> getAmenities() async {
    final response = await ApiService.get('/hotel-owner/amenities', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch amenities');
  }

  // POST /hotel-owner/amenities — update hotel amenities
  Future<void> updateAmenities(List<String> selectedIds) async {
    final response = await ApiService.post(
      '/hotel-owner/amenities',
      data: {'amenities': selectedIds},
      token: _token,
    );
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to update amenities');
    }
  }
}

