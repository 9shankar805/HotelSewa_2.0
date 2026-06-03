import 'dart:io';
import '../../constants/api_config.dart';
import '../shared/api_service.dart';

class OrderingService {
  // ==================== HOTEL OWNER ENDPOINTS ====================

  /// Get my menu
  static Future<Map<String, dynamic>> getMyMenu(String token) async {
    return await ApiService.get(
      ApiConfig.ownerMenuEndpoint,
      token: token,
    );
  }

  /// Create menu item
  static Future<Map<String, dynamic>> createMenuItem({
    required String token,
    required int hotelId,
    required String category,
    required String name,
    String? description,
    required double price,
    int? preparationTime,
    File? image,
  }) async {
    if (image != null) {
      return await ApiService.uploadFile(
        ApiConfig.ownerMenuEndpoint,
        image,
        token: token,
        fields: {
          'hotel_id': hotelId.toString(),
          'category': category,
          'name': name,
          if (description != null) 'description': description,
          'price': price.toString(),
          if (preparationTime != null) 'preparation_time': preparationTime.toString(),
        },
      );
    } else {
      return await ApiService.post(
        ApiConfig.ownerMenuEndpoint,
        token: token,
        data: {
          'hotel_id': hotelId,
          'category': category,
          'name': name,
          if (description != null) 'description': description,
          'price': price,
          if (preparationTime != null) 'preparation_time': preparationTime,
        },
      );
    }
  }

  /// Update menu item
  static Future<Map<String, dynamic>> updateMenuItem({
    required String token,
    required int itemId,
    String? category,
    String? name,
    String? description,
    double? price,
    int? preparationTime,
    bool? isAvailable,
    File? image,
  }) async {
    if (image != null) {
      return await ApiService.uploadFile(
        '${ApiConfig.ownerMenuEndpoint}/$itemId',
        image,
        token: token,
        fields: {
          if (category != null) 'category': category,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (price != null) 'price': price.toString(),
          if (preparationTime != null) 'preparation_time': preparationTime.toString(),
          if (isAvailable != null) 'is_available': isAvailable ? '1' : '0',
        },
      );
    } else {
      return await ApiService.post(
        '${ApiConfig.ownerMenuEndpoint}/$itemId',
        token: token,
        data: {
          if (category != null) 'category': category,
          if (name != null) 'name': name,
          if (description != null) 'description': description,
          if (price != null) 'price': price,
          if (preparationTime != null) 'preparation_time': preparationTime,
          if (isAvailable != null) 'is_available': isAvailable,
        },
      );
    }
  }

  /// Delete menu item
  static Future<Map<String, dynamic>> deleteMenuItem({
    required String token,
    required int itemId,
  }) async {
    return await ApiService.delete(
      '${ApiConfig.ownerMenuEndpoint}/$itemId',
      token: token,
    );
  }

  /// Get hotel orders
  static Future<Map<String, dynamic>> getHotelOrders({
    required String token,
    String? status,
    String? date,
    int? page,
    int? perPage,
  }) async {
    final queryParams = <String, String>{};
    if (status != null) queryParams['status'] = status;
    if (date != null) queryParams['date'] = date;
    if (page != null) queryParams['page'] = page.toString();
    if (perPage != null) queryParams['per_page'] = perPage.toString();

    return await ApiService.get(
      ApiConfig.ownerOrdersEndpoint,
      token: token,
      queryParams: queryParams.isNotEmpty ? queryParams : null,
    );
  }

  /// Update order status
  static Future<Map<String, dynamic>> updateOrderStatus({
    required String token,
    required int orderId,
    required String status,
  }) async {
    return await ApiService.post(
      '${ApiConfig.ownerOrderStatusEndpoint}/$orderId/status',
      token: token,
      data: {'status': status},
    );
  }

  /// Get order analytics
  static Future<Map<String, dynamic>> getOrderAnalytics({
    required String token,
    int? days,
  }) async {
    return await ApiService.get(
      ApiConfig.ownerOrderAnalyticsEndpoint,
      token: token,
      queryParams: days != null ? {'days': days.toString()} : null,
    );
  }
}



