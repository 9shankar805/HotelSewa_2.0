import '../../../../core/services/shared/api_service.dart';

class DocumentsService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /verification-request — fetch submitted documents
  Future<List<Map<String, dynamic>>> getDocuments() async {
    final response = await ApiService.get('/verification-request', token: _token);
    if (response['success'] == true) {
      final data = response['data'];
      if (data is List) return List<Map<String, dynamic>>.from(data);
      if (data is Map) return [Map<String, dynamic>.from(data)];
      return [];
    }
    throw Exception(response['message'] ?? 'Failed to fetch documents');
  }

  // POST /send-verification-request — upload/submit document
  Future<Map<String, dynamic>> uploadDocument(Map<String, dynamic> documentData) async {
    final response = await ApiService.post(
      '/send-verification-request',
      token: _token,
      data: documentData,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to upload document');
  }

  // POST /bank-transfer-update — bank document update
  Future<Map<String, dynamic>> updateBankTransfer(Map<String, dynamic> data) async {
    final response = await ApiService.post(
      '/bank-transfer-update',
      token: _token,
      data: data,
    );
    if (response['success'] == true) {
      return response['data'] ?? {};
    }
    throw Exception(response['message'] ?? 'Failed to update bank transfer');
  }
}

