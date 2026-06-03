import '../shared/api_service.dart';

class WaitlistService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // POST /waitlist/join
  static Future<Map<String, dynamic>> joinWaitlist(Map<String, dynamic> data) async {
    final response = await ApiService.post('/waitlist/join', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to join waitlist');
  }

  // GET /waitlist/my
  static Future<List<Map<String, dynamic>>> getMyWaitlist() async {
    final response = await ApiService.get('/waitlist/my', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch waitlist');
  }

  // DELETE /waitlist/{id}
  static Future<void> removeFromWaitlist(String id) async {
    final response = await ApiService.delete('/waitlist/$id', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to remove from waitlist');
    }
  }
}


