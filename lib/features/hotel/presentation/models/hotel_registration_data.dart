import 'dart:io';

class HotelRegistrationData {
  // Basic Info
  final String hotelName;
  final String propertyType;
  final String totalRooms;
  final String yearOfEstablishment;
  final String priceRangeMin;
  final String priceRangeMax;
  final String hotelDescription;

  // Location
  final String country;
  final String state;
  final String district;
  final String city;
  final String wardNumber;
  final String hotelAddress;
  final String landmark;
  final double? latitude;
  final double? longitude;

  // Contact
  final String hotelPhone;

  // Agreements
  final bool termsAccepted;
  final bool commissionAccepted;
  final bool cancellationPolicyAccepted;

  // Photos
  final File? exteriorPhoto;
  final File? receptionPhoto;
  final List<File> galleryPhotos;

  const HotelRegistrationData({
    this.hotelName = '',
    this.propertyType = 'Hotel',
    this.totalRooms = '',
    this.yearOfEstablishment = '',
    this.priceRangeMin = '',
    this.priceRangeMax = '',
    this.hotelDescription = '',
    this.country = 'Nepal',
    this.state = '',
    this.district = '',
    this.city = '',
    this.wardNumber = '',
    this.hotelAddress = '',
    this.landmark = '',
    this.latitude,
    this.longitude,
    this.hotelPhone = '',
    this.termsAccepted = false,
    this.commissionAccepted = false,
    this.cancellationPolicyAccepted = false,
    this.exteriorPhoto,
    this.receptionPhoto,
    this.galleryPhotos = const [],
  });

  // Copy with method for updating data
  HotelRegistrationData copyWith({
    String? hotelName,
    String? propertyType,
    String? totalRooms,
    String? yearOfEstablishment,
    String? priceRangeMin,
    String? priceRangeMax,
    String? hotelDescription,
    String? country,
    String? state,
    String? district,
    String? city,
    String? wardNumber,
    String? hotelAddress,
    String? landmark,
    double? latitude,
    double? longitude,
    String? hotelPhone,
    bool? termsAccepted,
    bool? commissionAccepted,
    bool? cancellationPolicyAccepted,
    File? exteriorPhoto,
    File? receptionPhoto,
    List<File>? galleryPhotos,
  }) {
    return HotelRegistrationData(
      hotelName: hotelName ?? this.hotelName,
      propertyType: propertyType ?? this.propertyType,
      totalRooms: totalRooms ?? this.totalRooms,
      yearOfEstablishment: yearOfEstablishment ?? this.yearOfEstablishment,
      priceRangeMin: priceRangeMin ?? this.priceRangeMin,
      priceRangeMax: priceRangeMax ?? this.priceRangeMax,
      hotelDescription: hotelDescription ?? this.hotelDescription,
      country: country ?? this.country,
      state: state ?? this.state,
      district: district ?? this.district,
      city: city ?? this.city,
      wardNumber: wardNumber ?? this.wardNumber,
      hotelAddress: hotelAddress ?? this.hotelAddress,
      landmark: landmark ?? this.landmark,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hotelPhone: hotelPhone ?? this.hotelPhone,
      termsAccepted: termsAccepted ?? this.termsAccepted,
      commissionAccepted: commissionAccepted ?? this.commissionAccepted,
      cancellationPolicyAccepted:
          cancellationPolicyAccepted ?? this.cancellationPolicyAccepted,
      exteriorPhoto: exteriorPhoto ?? this.exteriorPhoto,
      receptionPhoto: receptionPhoto ?? this.receptionPhoto,
      galleryPhotos: galleryPhotos ?? this.galleryPhotos,
    );
  }

  // Validation methods for each step
  bool isBasicInfoValid() {
    return hotelName.isNotEmpty &&
        totalRooms.isNotEmpty &&
        hotelDescription.isNotEmpty;
  }

  bool isLocationValid() {
    return hotelAddress.isNotEmpty && city.isNotEmpty && hotelPhone.isNotEmpty;
  }

  bool isPhotosValid() {
    return exteriorPhoto != null;
  }

  bool isAgreementsValid() {
    return termsAccepted && commissionAccepted;
  }

  // Check if all steps are complete
  bool isComplete() {
    return isBasicInfoValid() &&
        isLocationValid() &&
        isPhotosValid() &&
        isAgreementsValid();
  }
}
