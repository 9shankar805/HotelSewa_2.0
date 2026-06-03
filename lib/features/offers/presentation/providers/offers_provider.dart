import 'package:flutter/foundation.dart';
import '../models/offer_model.dart';
import '../services/offers_api_service.dart';

class OffersProvider extends ChangeNotifier {
  List<Offer> _offers = [];
  bool _isLoading = false;
  String? _error;
  Offer? _selectedOffer;
  Map<String, OfferValidationResult> _validationResults = {};

  // Getters
  List<Offer> get offers => _offers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Offer? get selectedOffer => _selectedOffer;
  Map<String, OfferValidationResult> get validationResults =>
      _validationResults;

  // Filtered offers
  List<Offer> get activeOffers =>
      _offers.where((offer) => offer.isValid).toList();
  List<Offer> get inactiveOffers =>
      _offers.where((offer) => !offer.isActive).toList();
  List<Offer> get expiredOffers =>
      _offers.where((offer) => offer.isExpired).toList();
  List<Offer> get upcomingOffers =>
      _offers.where((offer) => offer.isUpcoming).toList();

  /// Set authentication token
  void setToken(String token) {
    OffersApiService.setToken(token);
  }

  /// Load all offers
  Future<void> loadOffers() async {
    _setLoading(true);
    _clearError();

    try {
      final offers = await OffersApiService.getOffers();
      _offers = offers;
      notifyListeners();
    } catch (e) {
      _setError('Failed to load offers: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new offer
  Future<bool> createOffer(Offer offer) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate offer first
      final validationResult = await validateOffer(offer);
      if (!validationResult.isValid) {
        _setError(validationResult.errors.join(', '));
        return false;
      }

      final result = await OffersApiService.createOffer(offer);

      if (result['success'] == true) {
        await loadOffers(); // Refresh the list
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to create offer: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update an existing offer
  Future<bool> updateOffer(Offer offer) async {
    _setLoading(true);
    _clearError();

    try {
      // Validate offer first
      final validationResult = await validateOffer(offer);
      if (!validationResult.isValid) {
        _setError(validationResult.errors.join(', '));
        return false;
      }

      final result = await OffersApiService.updateOffer(offer.id, offer);

      if (result['success'] == true) {
        await loadOffers(); // Refresh the list
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to update offer: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete an offer
  Future<bool> deleteOffer(String offerId) async {
    _setLoading(true);
    _clearError();

    try {
      final result = await OffersApiService.deleteOffer(offerId);

      if (result['success'] == true) {
        await loadOffers(); // Refresh the list
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to delete offer: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle offer status
  Future<bool> toggleOfferStatus(String offerId, bool isActive) async {
    _setLoading(true);
    _clearError();

    try {
      final result =
          await OffersApiService.toggleOfferStatus(offerId, isActive);

      if (result['success'] == true) {
        await loadOffers(); // Refresh the list
        return true;
      } else {
        _setError(result['message'] as String);
        return false;
      }
    } catch (e) {
      _setError('Failed to update offer status: ${e.toString()}');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Validate offer locally and on server
  Future<OfferValidationResult> validateOffer(Offer offer) async {
    // Local validation first
    final localErrors = _validateOfferLocally(offer);
    if (localErrors.isNotEmpty) {
      return OfferValidationResult.error(localErrors);
    }

    try {
      final result = await OffersApiService.validateOffer(offer);

      if (result['success'] == true) {
        return OfferValidationResult.success();
      } else {
        return OfferValidationResult.error([result['message'] as String]);
      }
    } catch (e) {
      // If server validation fails, fall back to local validation
      return OfferValidationResult.success();
    }
  }

  /// Local offer validation
  List<String> _validateOfferLocally(Offer offer) {
    final errors = <String>[];

    // Title validation
    if (offer.title.trim().isEmpty) {
      errors.add('Offer title is required');
    }

    // Description validation
    if (offer.description.trim().isEmpty) {
      errors.add('Offer description is required');
    }

    // Discount validation
    if (offer.discount <= 0) {
      errors.add('Discount must be greater than 0');
    }

    if (offer.discountType == OfferDiscountType.percentage &&
        offer.discount > 100) {
      errors.add('Percentage discount cannot exceed 100%');
    }

    // Date validation
    if (offer.validTo.isBefore(offer.validFrom)) {
      errors.add('Valid to date must be after valid from date');
    }

    if (offer.validFrom
        .isBefore(DateTime.now().subtract(const Duration(days: 1)))) {
      errors.add('Valid from date cannot be in the past');
    }

    // Min stay validation
    if (offer.minStay < 1) {
      errors.add('Minimum stay must be at least 1 day');
    }

    // Max discount validation for percentage
    if (offer.discountType == OfferDiscountType.percentage &&
        offer.maxDiscount != null &&
        offer.maxDiscount! <= 0) {
      errors.add('Maximum discount must be greater than 0');
    }

    return errors;
  }

  /// Get offer analytics
  Future<Map<String, dynamic>?> getOfferAnalytics(String offerId) async {
    try {
      final result = await OffersApiService.getOfferAnalytics(offerId);

      if (result['success'] == true) {
        return result['data'] as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error fetching offer analytics: $e');
    }

    return null;
  }

  /// Select an offer for editing/viewing
  void selectOffer(Offer? offer) {
    _selectedOffer = offer;
    notifyListeners();
  }

  /// Clear selected offer
  void clearSelectedOffer() {
    _selectedOffer = null;
    notifyListeners();
  }

  /// Refresh offers
  Future<void> refreshOffers() async {
    await loadOffers();
  }

  /// Get offers by status
  List<Offer> getOffersByStatus(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return activeOffers;
      case 'inactive':
        return inactiveOffers;
      case 'expired':
        return expiredOffers;
      case 'upcoming':
        return upcomingOffers;
      default:
        return _offers;
    }
  }

  /// Search offers
  List<Offer> searchOffers(String query) {
    if (query.trim().isEmpty) return _offers;

    final lowercaseQuery = query.toLowerCase();
    return _offers.where((offer) {
      return offer.title.toLowerCase().contains(lowercaseQuery) ||
          offer.description.toLowerCase().contains(lowercaseQuery) ||
          offer.discountText.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  /// Get offer statistics
  Map<String, int> getOfferStatistics() {
    return {
      'total': _offers.length,
      'active': activeOffers.length,
      'inactive': inactiveOffers.length,
      'expired': expiredOffers.length,
      'upcoming': upcomingOffers.length,
    };
  }

  // Private helper methods
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
    notifyListeners();
  }
}
