import 'package:flutter/material.dart';

enum OfferDiscountType { percentage, fixed }

class Offer {
  final String id;
  final String title;
  final String description;
  final double discount;
  final OfferDiscountType discountType;
  final DateTime validFrom;
  final DateTime validTo;
  final int minStay;
  final double? maxDiscount;
  final int? maxUsage;
  final int currentUsage;
  final bool isActive;
  final List<String> applicableRoomTypes;
  final String? couponCode;

  const Offer({
    required this.id,
    required this.title,
    required this.description,
    required this.discount,
    required this.discountType,
    required this.validFrom,
    required this.validTo,
    this.minStay = 1,
    this.maxDiscount,
    this.maxUsage,
    this.currentUsage = 0,
    this.isActive = true,
    this.applicableRoomTypes = const [],
    this.couponCode,
  });

  bool get isExpired => DateTime.now().isAfter(validTo);
  bool get isUpcoming => DateTime.now().isBefore(validFrom);
  bool get isValid => isActive && !isExpired && !isUpcoming;

  String get discountText {
    if (discountType == OfferDiscountType.percentage) {
      return '${discount.toStringAsFixed(0)}% OFF';
    } else {
      return 'NPR ${discount.toStringAsFixed(0)} OFF';
    }
  }

  /// Returns a color key string for UI rendering
  String get statusColor {
    if (!isActive) return 'orange';
    if (isExpired) return 'red';
    if (isUpcoming) return 'blue';
    return 'green';
  }

  String get statusText {
    if (!isActive) return 'Inactive';
    if (isExpired) return 'Expired';
    if (isUpcoming) return 'Upcoming';
    return 'Active';
  }

  factory Offer.fromJson(Map<String, dynamic> j) {
    return Offer(
      id: j['id']?.toString() ?? '',
      title: j['title'] as String? ?? j['name'] as String? ?? '',
      description: j['description'] as String? ?? '',
      discount: (j['discount'] as num?)?.toDouble() ??
          (j['discount_value'] as num?)?.toDouble() ?? 0.0,
      discountType: (j['discount_type'] as String? ?? 'percentage') == 'fixed'
          ? OfferDiscountType.fixed
          : OfferDiscountType.percentage,
      validFrom: j['valid_from'] != null
          ? DateTime.tryParse(j['valid_from'].toString()) ?? DateTime.now()
          : DateTime.now(),
      validTo: j['valid_to'] != null
          ? DateTime.tryParse(j['valid_to'].toString()) ??
              DateTime.now().add(const Duration(days: 30))
          : DateTime.now().add(const Duration(days: 30)),
      minStay: (j['min_stay'] as num?)?.toInt() ?? 1,
      maxDiscount: (j['max_discount'] as num?)?.toDouble(),
      maxUsage: (j['max_usage'] as num?)?.toInt(),
      currentUsage: (j['current_usage'] as num?)?.toInt() ?? 0,
      isActive: j['is_active'] as bool? ?? j['status'] == 'active',
      applicableRoomTypes: j['applicable_room_types'] is List
          ? List<String>.from(j['applicable_room_types'])
          : [],
      couponCode: j['coupon_code'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'discount': discount,
        'discount_type':
            discountType == OfferDiscountType.percentage ? 'percentage' : 'fixed',
        'valid_from': validFrom.toIso8601String(),
        'valid_to': validTo.toIso8601String(),
        'min_stay': minStay,
        if (maxDiscount != null) 'max_discount': maxDiscount,
        if (maxUsage != null) 'max_usage': maxUsage,
        'current_usage': currentUsage,
        'is_active': isActive,
        'applicable_room_types': applicableRoomTypes,
        if (couponCode != null) 'coupon_code': couponCode,
      };

  Offer copyWith({bool? isActive}) => Offer(
        id: id,
        title: title,
        description: description,
        discount: discount,
        discountType: discountType,
        validFrom: validFrom,
        validTo: validTo,
        minStay: minStay,
        maxDiscount: maxDiscount,
        maxUsage: maxUsage,
        currentUsage: currentUsage,
        isActive: isActive ?? this.isActive,
        applicableRoomTypes: applicableRoomTypes,
        couponCode: couponCode,
      );
}

class OfferValidationResult {
  final bool isValid;
  final List<String> errors;

  const OfferValidationResult._({required this.isValid, required this.errors});

  factory OfferValidationResult.success() =>
      const OfferValidationResult._(isValid: true, errors: []);

  factory OfferValidationResult.error(List<String> errors) =>
      OfferValidationResult._(isValid: false, errors: errors);
}
