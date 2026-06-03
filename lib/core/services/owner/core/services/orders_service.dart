import 'dart:io';
import '../constants/api_config.dart';
import 'api_service.dart';

class OrdersService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // POST /orders/place (guest)
  static Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.ordersPlaceEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to place order');
  }

  // GET /orders/my-orders (guest)
  static Future<List<Map<String, dynamic>>> getMyOrders() async {
    final response = await ApiService.get(ApiConfig.ordersMyOrdersEndpoint, token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch orders');
  }

  // POST /orders/{id}/cancel (guest)
  static Future<Map<String, dynamic>> cancelOrder(String orderId) async {
    final response = await ApiService.post(ApiConfig.buildPath(ApiConfig.ordersCancelEndpoint, '$orderId/cancel'), token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to cancel order');
  }

  // GET /hotel-owner/orders?hotel_id= — owner: all orders
  static Future<List<Map<String, dynamic>>> getOwnerOrders({
    required String hotelId,
    Map<String, String>? filters,
  }) async {
    final params = {'hotel_id': hotelId, ...?filters};
    final response =
        await ApiService.get(ApiConfig.ownerOrdersEndpoint, token: _token, queryParams: params);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch owner orders');
  }

  // POST /hotel-owner/orders/{id}/status — owner: update order status
  static Future<Map<String, dynamic>> updateOrderStatus(
      String orderId, String status) async {
    final response = await ApiService.post(
      ApiConfig.buildPath(ApiConfig.ownerOrderStatusEndpoint, '$orderId/status'),
      token: _token,
      data: {'status': status},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update order status');
  }

  // GET /hotel-owner/order-analytics?hotel_id=
  static Future<Map<String, dynamic>> getOrderAnalytics(String hotelId) async {
    final response = await ApiService.get(
      ApiConfig.ownerOrderAnalyticsEndpoint,
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch order analytics');
  }

  // GET /hotel-owner/menu?hotel_id= — owner: get menu
  static Future<List<Map<String, dynamic>>> getMenu(String hotelId) async {
    final response = await ApiService.get(
      ApiConfig.ownerMenuEndpoint,
      token: _token,
      queryParams: {'hotel_id': hotelId},
    );
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch menu');
  }

  // POST /hotel-owner/menu — owner: add menu item (supports image upload)
  static Future<Map<String, dynamic>> createMenuItem(
    Map<String, dynamic> data, {
    File? image,
  }) async {
    if (image != null) {
      final fields = data.map((k, v) => MapEntry(k, v.toString()));
      return ApiService.uploadFile(ApiConfig.ownerMenuEndpoint, image, token: _token, fields: fields);
    }
    final response =
        await ApiService.post(ApiConfig.ownerMenuEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to create menu item');
  }

  // POST /hotel-owner/menu/{id} — owner: update menu item
  static Future<Map<String, dynamic>> updateMenuItem(
    String itemId,
    Map<String, dynamic> data, {
    File? image,
  }) async {
    if (image != null) {
      final fields = data.map((k, v) => MapEntry(k, v.toString()));
      return ApiService.uploadFile(ApiConfig.buildPath(ApiConfig.ownerMenuEndpoint, itemId), image, token: _token, fields: fields);
    }
    final response =
        await ApiService.post(ApiConfig.buildPath(ApiConfig.ownerMenuEndpoint, itemId), token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update menu item');
  }

  // DELETE /hotel-owner/menu/{id} — owner: delete menu item
  static Future<void> deleteMenuItem(String itemId) async {
    final response = await ApiService.delete(ApiConfig.buildPath(ApiConfig.ownerMenuEndpoint, itemId), token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete menu item');
    }
  }
}
