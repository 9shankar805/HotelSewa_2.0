import 'package:flutter/foundation.dart';
import '../../../../core/services/shared/api_service.dart';
import '../models/offer_model.dart';

class OffersApiService {
  static String? _token;

  static void setToken(String token) {
    _token = token;
  }

  // GET /get-featured-section — public offers/promotions
  static Future<List<Offer>> getOffers() async {
    try {
      final response = await ApiService.get('/get-featured-section', token: _token);
      if (response['success'] == true && response['data'] != null) {
        final List<dynamic> offersJson = response['data'];
        return offersJson.map((json) => Offer.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching offers: $e');
      return [];
    }
  }

  // POST /validate-coupon — create/validate offer
  static Future<Map<String, dynamic>> createOffer(Offer offer) async {
    try {
      final response = await ApiService.post(
        '/validate-coupon',
        data: offer.toJson(),
        token: _token,
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data'], 'message': 'Offer created successfully'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to create offer'};
    } catch (e) {
      debugPrint('Error creating offer: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // POST /update-profile — update offer
  static Future<Map<String, dynamic>> updateOffer(String offerId, Offer offer) async {
    try {
      final response = await ApiService.post(
        '/update-profile',
        data: {'offerId': offerId, ...offer.toJson()},
        token: _token,
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data'], 'message': 'Offer updated successfully'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to update offer'};
    } catch (e) {
      debugPrint('Error updating offer: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // No delete offer endpoint — handled via update-profile
  static Future<Map<String, dynamic>> deleteOffer(String offerId) async {
    try {
      final response = await ApiService.post(
        '/update-profile',
        data: {'offerId': offerId, 'status': 'DELETED'},
        token: _token,
      );
      if (response['success'] == true) {
        return {'success': true, 'message': 'Offer deleted successfully'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to delete offer'};
    } catch (e) {
      debugPrint('Error deleting offer: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // POST /update-profile — toggle offer status
  static Future<Map<String, dynamic>> toggleOfferStatus(String offerId, bool isActive) async {
    try {
      final response = await ApiService.post(
        '/update-profile',
        data: {'offerId': offerId, 'isActive': isActive},
        token: _token,
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data'], 'message': 'Offer status updated'};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to update offer status'};
    } catch (e) {
      debugPrint('Error toggling offer status: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // GET /payment-transactions — offer analytics
  static Future<Map<String, dynamic>> getOfferAnalytics(String offerId) async {
    try {
      final response = await ApiService.get(
        '/payment-transactions',
        token: _token,
        queryParams: {'offerId': offerId},
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data']};
      }
      return {'success': false, 'message': response['message'] ?? 'Failed to fetch offer analytics'};
    } catch (e) {
      debugPrint('Error fetching offer analytics: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }

  // POST /validate-coupon — validate offer
  static Future<Map<String, dynamic>> validateOffer(Offer offer) async {
    try {
      final response = await ApiService.post(
        '/validate-coupon',
        data: offer.toJson(),
        token: _token,
      );
      if (response['success'] == true) {
        return {'success': true, 'data': response['data'], 'message': 'Offer is valid'};
      }
      return {'success': false, 'message': response['message'] ?? 'Offer validation failed'};
    } catch (e) {
      debugPrint('Error validating offer: $e');
      return {'success': false, 'message': 'Network error: ${e.toString()}'};
    }
  }
}

