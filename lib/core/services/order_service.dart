import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_config.dart';
import 'shared/api_service.dart';

class OrderService {
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  // ─── Guest: Browse & Order ───────────────────────────────────────────────────

  // GET hotels/{hotelId}/menu - Public endpoint
  Future<Map<String, dynamic>> getHotelMenu(int hotelId) async {
    try {
      final response = await ApiService.get(ApiConfig.buildPath(ApiConfig.hotelsEndpoint, '$hotelId/menu'));
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load menu'};
    }
  }

  // POST orders/place
  Future<Map<String, dynamic>> placeOrder(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.ordersPlaceEndpoint, data: data, token: token);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to place order'};
    }
  }

  // GET orders/my-orders
  Future<Map<String, dynamic>> getMyOrders({int? bookingId}) async {
    try {
      final token = await _getToken();
      final queryParams = bookingId != null ? {'booking_id': bookingId} : null;
      final response = await ApiService.get(ApiConfig.myOrdersEndpoint, token: token, queryParams: queryParams);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load orders'};
    }
  }

  // POST orders/{id}/cancel
  Future<Map<String, dynamic>> cancelOrder(int id) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.orderCancelEndpoint, '$id/cancel'),
        token: token,
      );
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to cancel order'};
    }
  }

  // ─── Owner: Menu Management ──────────────────────────────────────────────────

  /// GET /hotel-owner/menu — Get all menu items for the owner's hotel.
  Future<Map<String, dynamic>> getOwnerMenu() async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(ApiConfig.ownerMenuEndpoint, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load menu'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load menu: $e'};
    }
  }

  /// POST /hotel-owner/menu — Add a new menu item.
  /// [data] should include: name, price, category, description, is_available
  Future<Map<String, dynamic>> addMenuItem(Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(ApiConfig.ownerMenuEndpoint, data: data, token: token);
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to add menu item'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to add menu item: $e'};
    }
  }

  /// POST /hotel-owner/menu/{id} — Update a menu item.
  Future<Map<String, dynamic>> updateMenuItem(String itemId, Map<String, dynamic> data) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.ownerMenuDetailEndpoint, itemId),
        data: data,
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update menu item'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update menu item: $e'};
    }
  }

  /// DELETE /hotel-owner/menu/{id} — Delete a menu item.
  Future<Map<String, dynamic>> deleteMenuItem(String itemId) async {
    try {
      final token = await _getToken();
      final response = await ApiService.delete(
        ApiConfig.buildPath(ApiConfig.ownerMenuDetailEndpoint, itemId),
        token: token,
      );
      return response['success'] == true
          ? {'success': true}
          : {'success': false, 'message': response['message'] ?? 'Failed to delete menu item'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete menu item: $e'};
    }
  }

  // ─── Owner: Order Management ─────────────────────────────────────────────────

  /// GET /hotel-owner/orders — Get all orders for the owner's hotel.
  Future<Map<String, dynamic>> getOwnerOrders({String? status, int page = 1}) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.ownerOrdersEndpoint,
        token: token,
        queryParams: {
          'page': page.toString(),
          if (status != null) 'status': status,
        },
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load orders'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load orders: $e'};
    }
  }

  /// POST /hotel-owner/orders/{id}/status — Update an order's status.
  /// [status] should be one of: accepted, preparing, ready, delivered, cancelled
  Future<Map<String, dynamic>> updateOrderStatus(String orderId, String status) async {
    try {
      final token = await _getToken();
      final response = await ApiService.post(
        ApiConfig.buildPath(ApiConfig.ownerOrderStatusEndpoint, '$orderId/status'),
        data: {'status': status},
        token: token,
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to update order status'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update order status: $e'};
    }
  }

  /// GET /hotel-owner/order-analytics — Get order analytics for the owner.
  Future<Map<String, dynamic>> getOrderAnalytics({String? period}) async {
    try {
      final token = await _getToken();
      final response = await ApiService.get(
        ApiConfig.ownerOrderAnalyticsEndpoint,
        token: token,
        queryParams: {if (period != null) 'period': period},
      );
      return response['success'] == true
          ? {'success': true, 'data': response['data']}
          : {'success': false, 'message': response['message'] ?? 'Failed to load analytics'};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load analytics: $e'};
    }
  }
}





