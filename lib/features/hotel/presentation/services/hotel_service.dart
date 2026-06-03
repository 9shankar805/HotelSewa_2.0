import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';

class HotelService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // POST /store-hotel — register/create a new hotel
  static Future<Map<String, dynamic>> registerHotel(Map<String, dynamic> hotelData) async {
    try {
      debugPrint('🏨 Registering hotel with data: $hotelData');
      final response = await ApiService.post(ApiConfig.storeHotelEndpoint, token: _token, data: hotelData);
      debugPrint('📥 Hotel registration response: $response');
      
      if (response['success'] == true || response['error'] == false) {
        return response;
      }
      throw Exception(response['message'] ?? 'Failed to register hotel');
    } catch (e) {
      debugPrint('❌ Hotel registration error: $e');
      throw Exception('Failed to register hotel: ${e.toString()}');
    }
  }

  // GET /my-hotels — get owner's hotels
  static Future<List<Map<String, dynamic>>> getMyHotels() async {
    final response = await ApiService.get(ApiConfig.myHotelsEndpoint, token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch hotels');
  }

  // POST /update-hotel/{id} — update hotel
  static Future<Map<String, dynamic>> updateHotel(
      String hotelId, Map<String, dynamic> hotelData) async {
    final response =
        await ApiService.post('${ApiConfig.updateHotelEndpoint}/$hotelId', token: _token, data: hotelData);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update hotel');
  }

  // DELETE /delete-hotel/{id} — delete hotel
  static Future<void> deleteHotel(String hotelId) async {
    final response = await ApiService.delete('${ApiConfig.deleteHotelEndpoint}/$hotelId', token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete hotel');
    }
  }

  // POST /update-booking-status/{id} — update a booking's status
  static Future<Map<String, dynamic>> updateBookingStatus(
      String bookingId, String status) async {
    final response = await ApiService.post(
      '${ApiConfig.updateBookingStatusEndpoint}/$bookingId',
      token: _token,
      data: {'status': status},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update booking status');
  }

  // POST /set-dynamic-pricing — set dynamic pricing rules
  static Future<Map<String, dynamic>> setDynamicPricing(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.setDynamicPricingEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to set dynamic pricing');
  }

  // GET /hotel-owner/amenities — list available amenities
  static Future<List<Map<String, dynamic>>> getAmenities() async {
    final response = await ApiService.get(ApiConfig.ownerAmenitiesEndpoint, token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch amenities');
  }

  // POST /hotel-owner/amenities — update hotel amenities
  static Future<Map<String, dynamic>> updateAmenities(List<String> amenityIds) async {
    final response = await ApiService.post(
      ApiConfig.ownerAmenitiesEndpoint,
      token: _token,
      data: {'amenities': amenityIds},
    );
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to update amenities');
  }

  // GET /hotel-owner/gallery — get hotel gallery
  static Future<Map<String, dynamic>> getGallery() async {
    final response = await ApiService.get(ApiConfig.ownerGalleryEndpoint, token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch gallery');
  }

  // GET /hotel-owner/bookings — owner's bookings list
  static Future<List<Map<String, dynamic>>> getBookings(
      {Map<String, String>? filters}) async {
    final response =
        await ApiService.get(ApiConfig.ownerBookingsEndpoint, token: _token, queryParams: filters);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch bookings');
  }

  // POST /hotel-owner/blackout-dates — add single blackout date
  static Future<Map<String, dynamic>> addBlackoutDate(Map<String, dynamic> data) async {
    final response =
        await ApiService.post(ApiConfig.ownerBlackoutDatesEndpoint, token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add blackout date');
  }

  // POST /hotel-owner/blackout-dates/range — add blackout date range
  static Future<Map<String, dynamic>> addBlackoutDateRange(Map<String, dynamic> data) async {
    final response = await ApiService.post(ApiConfig.ownerBlackoutDatesRangeEndpoint,
        token: _token, data: data);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to add blackout date range');
  }

  // DELETE /hotel-owner/blackout-dates — remove blackout dates
  static Future<void> deleteBlackoutDates(Map<String, dynamic> data) async {
    // DELETE with body — use post workaround or pass as query; server may vary
    final response =
        await ApiService.delete(ApiConfig.ownerBlackoutDatesEndpoint, token: _token);
    if (response['success'] != true) {
      throw Exception(response['message'] ?? 'Failed to delete blackout dates');
    }
  }

  // ---- Public endpoints ----

  // GET /hotels — list all hotels
  static Future<List<Map<String, dynamic>>> getHotels() async {
    final response = await ApiService.get(ApiConfig.hotelsEndpoint, token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch hotels');
  }

  // GET /hotel-details/{id}
  static Future<Map<String, dynamic>> getHotelDetails(String hotelId) async {
    final response = await ApiService.get('${ApiConfig.hotelDetailsEndpoint}/$hotelId', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch hotel details');
  }

  // GET /hotel-policies/{id}
  static Future<Map<String, dynamic>> getHotelPolicies(String hotelId) async {
    final response = await ApiService.get('${ApiConfig.hotelPoliciesEndpoint}/$hotelId', token: _token);
    if (response['success'] == true) return response['data'] ?? {};
    throw Exception(response['message'] ?? 'Failed to fetch hotel policies');
  }

  // GET /hotels/nearby
  static Future<List<Map<String, dynamic>>> getNearbyHotels(
      {double? lat, double? lng, double? radius}) async {
    final queryParams = <String, String>{};
    if (lat != null) queryParams['lat'] = lat.toString();
    if (lng != null) queryParams['lng'] = lng.toString();
    if (radius != null) queryParams['radius'] = radius.toString();
    final response = await ApiService.get(ApiConfig.hotelsNearbyEndpoint, queryParams: queryParams);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch nearby hotels');
  }

  // GET /hotels/{hotelId}/blackout-dates (public read)
  static Future<List<Map<String, dynamic>>> getBlackoutDates(String hotelId) async {
    final response = await ApiService.get('${ApiConfig.hotelBlackoutDatesEndpoint}/$hotelId/blackout-dates', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch blackout dates');
  }

  // GET /hotels/{hotelId}/gallery (public read)
  static Future<List<Map<String, dynamic>>> getHotelGallery(String hotelId) async {
    final response = await ApiService.get('${ApiConfig.hotelGalleryEndpoint}/$hotelId/gallery', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch gallery');
  }

  // GET /hotels/{hotelId}/menu
  static Future<List<Map<String, dynamic>>> getHotelMenu(String hotelId) async {
    final response = await ApiService.get('${ApiConfig.hotelMenuEndpoint}/$hotelId/menu', token: _token);
    if (response['success'] == true) {
      return List<Map<String, dynamic>>.from(response['data'] ?? []);
    }
    throw Exception(response['message'] ?? 'Failed to fetch hotel menu');
  }


  // Legacy compat - improved hotel status checking
  Future<Map<String, dynamic>> getHotelStatus() async {
    try {
      debugPrint('🔍 Checking hotel status with token: ${_token?.substring(0, 20)}...');
      
      final response = await ApiService.get(ApiConfig.myHotelsEndpoint, token: _token);
      debugPrint('📥 My hotels response: $response');
      
      if (response['success'] == true) {
        final data = response['data'];
        
        if (data is List && data.isNotEmpty) {
          final hotel = Map<String, dynamic>.from(data.first as Map);
          
          // Normalize status to uppercase to match app expectations
          if (hotel['status'] != null) {
            hotel['status'] = hotel['status'].toString().toUpperCase();
          }
          
          debugPrint('✅ Hotel found: ${hotel['name']} - Status: ${hotel['status']}');
          return {'success': true, 'data': hotel};
        } else {
          // No hotels found - user needs to register
          debugPrint('ℹ️ No hotels found for this user');
          return {'success': false, 'message': 'No hotels found', 'data': null};
        }
      } else {
        // API returned error
        debugPrint('❌ API error: ${response['message']}');
        return response;
      }
    } catch (e) {
      debugPrint('❌ Exception in getHotelStatus: $e');
      return {'success': false, 'message': 'Failed to check hotel status: ${e.toString()}'};
    }
  }

  // Instance wrappers (screens use HotelService().method())
  Future<List<Map<String, dynamic>>> fetchMyHotels() => HotelService.getMyHotels();
  Future<List<Map<String, dynamic>>> fetchHotels() => HotelService.getHotels();
  Future<Map<String, dynamic>> createHotel(Map<String, dynamic> data) =>
      HotelService.registerHotel(data);
}

