import '../shared/api_service.dart';

/// Multi-Currency support.
class CurrencyService {
  static String? _token;

  static void setToken(String token) => _token = token;

  // GET /currencies — all exchange rates
  static Future<List<Map<String, dynamic>>> getAllRates() async {
    final response = await ApiService.get('/currencies', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch currencies');
  }

  // GET /currencies/rates-map?base=NPR
  static Future<Map<String, dynamic>> getRatesMap({String base = 'NPR'}) async {
    final response = await ApiService.get(
      '/currencies/rates-map',
      token: _token,
      queryParams: {'base': base},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch rates map');
  }

  // POST /currencies/convert
  // body: { amount, from, to }
  static Future<Map<String, dynamic>> convert(Map<String, dynamic> data) async {
    final response = await ApiService.post('/currencies/convert', token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to convert currency');
  }

  // PUT /currencies/preference — set preferred display currency
  static Future<Map<String, dynamic>> setPreference(String currency) async {
    final response = await ApiService.put(
      '/currencies/preference',
      token: _token,
      data: {'currency': currency},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to set currency preference');
  }
}


