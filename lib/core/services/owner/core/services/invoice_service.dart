import 'api_service.dart';

/// Invoice endpoints.
class InvoiceService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /invoice/{bookingId}/preview
  static Future<Map<String, dynamic>> previewInvoice(String bookingId) async {
    final response = await ApiService.get('/invoice/$bookingId/preview', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to preview invoice');
  }

  // GET /invoice/{bookingId}/download — returns download URL or binary
  static Future<Map<String, dynamic>> downloadInvoice(String bookingId) async {
    final response = await ApiService.get('/invoice/$bookingId/download', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to download invoice');
  }

  /// Returns the direct download URL for use in a browser/WebView.
  static String getDownloadUrl(String bookingId) =>
      '${ApiService.baseUrl}/invoice/$bookingId/download';
}
