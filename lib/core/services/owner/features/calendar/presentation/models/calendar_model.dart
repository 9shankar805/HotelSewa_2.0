class CalendarData {
  final String hotelId;
  final int month;
  final int year;
  final Map<String, CalendarDailyData> dailyData;
  final CalendarMonthlyStats monthlyStats;

  CalendarData({
    required this.hotelId,
    required this.month,
    required this.year,
    required this.dailyData,
    required this.monthlyStats,
  });

  factory CalendarData.fromJson(Map<String, dynamic> json) {
    final dailyDataMap = <String, CalendarDailyData>{};
    if (json['dailyData'] != null) {
      (json['dailyData'] as Map<String, dynamic>).forEach((key, value) {
        dailyDataMap[key] = CalendarDailyData.fromJson(value);
      });
    }

    return CalendarData(
      hotelId: json['hotelId'] as String,
      month: json['month'] as int,
      year: json['year'] as int,
      dailyData: dailyDataMap,
      monthlyStats: CalendarMonthlyStats.fromJson(json['monthlyStats'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'hotelId': hotelId,
      'month': month,
      'year': year,
      'dailyData': dailyData.map((key, value) => MapEntry(key, value.toJson())),
      'monthlyStats': monthlyStats.toJson(),
    };
  }
}

class CalendarDailyData {
  final String date;
  final int totalRooms;
  final int availableRooms;
  final int occupiedRooms;
  final int blockedRooms;
  final int totalBookings;
  final double totalRevenue;
  final double occupancyRate;
  final List<CalendarBooking> bookings;
  final List<CalendarRoomAvailability> roomAvailability;
  final bool isBlocked;
  final String? blockReason;

  CalendarDailyData({
    required this.date,
    required this.totalRooms,
    required this.availableRooms,
    required this.occupiedRooms,
    required this.blockedRooms,
    required this.totalBookings,
    required this.totalRevenue,
    required this.occupancyRate,
    required this.bookings,
    required this.roomAvailability,
    required this.isBlocked,
    this.blockReason,
  });

  factory CalendarDailyData.fromJson(Map<String, dynamic> json) {
    final bookingsList = <CalendarBooking>[];
    if (json['bookings'] != null) {
      bookingsList.addAll(
        (json['bookings'] as List<dynamic>).map((e) => CalendarBooking.fromJson(e))
      );
    }

    final availabilityList = <CalendarRoomAvailability>[];
    if (json['roomAvailability'] != null) {
      availabilityList.addAll(
        (json['roomAvailability'] as List<dynamic>).map((e) => CalendarRoomAvailability.fromJson(e))
      );
    }

    return CalendarDailyData(
      date: json['date'] as String,
      totalRooms: json['totalRooms'] as int,
      availableRooms: json['availableRooms'] as int,
      occupiedRooms: json['occupiedRooms'] as int,
      blockedRooms: json['blockedRooms'] as int,
      totalBookings: json['totalBookings'] as int,
      totalRevenue: (json['totalRevenue'] as num).toDouble(),
      occupancyRate: (json['occupancyRate'] as num).toDouble(),
      bookings: bookingsList,
      roomAvailability: availabilityList,
      isBlocked: json['isBlocked'] as bool? ?? false,
      blockReason: json['blockReason'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date,
      'totalRooms': totalRooms,
      'availableRooms': availableRooms,
      'occupiedRooms': occupiedRooms,
      'blockedRooms': blockedRooms,
      'totalBookings': totalBookings,
      'totalRevenue': totalRevenue,
      'occupancyRate': occupancyRate,
      'bookings': bookings.map((e) => e.toJson()).toList(),
      'roomAvailability': roomAvailability.map((e) => e.toJson()).toList(),
      'isBlocked': isBlocked,
      'blockReason': blockReason,
    };
  }

  /// Get availability status
  CalendarAvailabilityStatus get availabilityStatus {
    if (isBlocked) return CalendarAvailabilityStatus.blocked;
    if (availableRooms == 0) return CalendarAvailabilityStatus.full;
    if (occupancyRate >= 0.8) return CalendarAvailabilityStatus.limited;
    return CalendarAvailabilityStatus.available;
  }

  /// Get status color
  String get statusColor {
    switch (availabilityStatus) {
      case CalendarAvailabilityStatus.available:
        return 'green';
      case CalendarAvailabilityStatus.limited:
        return 'orange';
      case CalendarAvailabilityStatus.full:
        return 'red';
      case CalendarAvailabilityStatus.blocked:
        return 'grey';
    }
  }
}

class CalendarBooking {
  final String id;
  final String roomId;
  final String roomNumber;
  final String roomType;
  final String guestName;
  final String guestEmail;
  final int guestCount;
  final DateTime checkInDate;
  final DateTime checkOutDate;
  final double totalAmount;
  final String status;
  final DateTime createdAt;

  CalendarBooking({
    required this.id,
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.guestName,
    required this.guestEmail,
    required this.guestCount,
    required this.checkInDate,
    required this.checkOutDate,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
  });

  factory CalendarBooking.fromJson(Map<String, dynamic> json) {
    return CalendarBooking(
      id: json['id'] as String,
      roomId: json['roomId'] as String,
      roomNumber: json['roomNumber'] as String,
      roomType: json['roomType'] as String,
      guestName: json['guestName'] as String,
      guestEmail: json['guestEmail'] as String,
      guestCount: json['guestCount'] as int,
      checkInDate: DateTime.parse(json['checkInDate'] as String),
      checkOutDate: DateTime.parse(json['checkOutDate'] as String),
      totalAmount: (json['totalAmount'] as num).toDouble(),
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'roomId': roomId,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'guestCount': guestCount,
      'checkInDate': checkInDate.toIso8601String(),
      'checkOutDate': checkOutDate.toIso8601String(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

class CalendarRoomAvailability {
  final String roomId;
  final String roomNumber;
  final String roomType;
  final bool isAvailable;
  final double? price;
  final String? bookingId;
  final String? guestName;

  CalendarRoomAvailability({
    required this.roomId,
    required this.roomNumber,
    required this.roomType,
    required this.isAvailable,
    this.price,
    this.bookingId,
    this.guestName,
  });

  factory CalendarRoomAvailability.fromJson(Map<String, dynamic> json) {
    return CalendarRoomAvailability(
      roomId: json['roomId'] as String,
      roomNumber: json['roomNumber'] as String,
      roomType: json['roomType'] as String,
      isAvailable: json['isAvailable'] as bool,
      price: json['price'] != null ? (json['price'] as num).toDouble() : null,
      bookingId: json['bookingId'] as String?,
      guestName: json['guestName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'roomId': roomId,
      'roomNumber': roomNumber,
      'roomType': roomType,
      'isAvailable': isAvailable,
      'price': price,
      'bookingId': bookingId,
      'guestName': guestName,
    };
  }
}

class CalendarMonthlyStats {
  final int totalBookings;
  final double totalRevenue;
  final double averageOccupancy;
  final double averageDailyRate;
  final int totalAvailableRooms;
  final int totalOccupiedRooms;
  final Map<String, int> bookingsByDay;
  final Map<String, double> revenueByDay;

  CalendarMonthlyStats({
    required this.totalBookings,
    required this.totalRevenue,
    required this.averageOccupancy,
    required this.averageDailyRate,
    required this.totalAvailableRooms,
    required this.totalOccupiedRooms,
    required this.bookingsByDay,
    required this.revenueByDay,
  });

  factory CalendarMonthlyStats.fromJson(Map<String, dynamic> json) {
    return CalendarMonthlyStats(
      totalBookings: json['totalBookings'] as int? ?? 0,
      totalRevenue: (json['totalRevenue'] as num?)?.toDouble() ?? 0.0,
      averageOccupancy: (json['averageOccupancy'] as num?)?.toDouble() ?? 0.0,
      averageDailyRate: (json['averageDailyRate'] as num?)?.toDouble() ?? 0.0,
      totalAvailableRooms: json['totalAvailableRooms'] as int? ?? 0,
      totalOccupiedRooms: json['totalOccupiedRooms'] as int? ?? 0,
      bookingsByDay: Map<String, int>.from(json['bookingsByDay'] ?? {}),
      revenueByDay: Map<String, double>.from(
        (json['revenueByDay'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ?? {},
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalBookings': totalBookings,
      'totalRevenue': totalRevenue,
      'averageOccupancy': averageOccupancy,
      'averageDailyRate': averageDailyRate,
      'totalAvailableRooms': totalAvailableRooms,
      'totalOccupiedRooms': totalOccupiedRooms,
      'bookingsByDay': bookingsByDay,
      'revenueByDay': revenueByDay,
    };
  }

  static CalendarMonthlyStats empty() {
    return CalendarMonthlyStats(
      totalBookings: 0,
      totalRevenue: 0.0,
      averageOccupancy: 0.0,
      averageDailyRate: 0.0,
      totalAvailableRooms: 0,
      totalOccupiedRooms: 0,
      bookingsByDay: {},
      revenueByDay: {},
    );
  }
}

class CalendarAnalytics {
  final double occupancyRate;
  final double revenueGrowth;
  final int newBookings;
  final int cancelledBookings;
  final double averageBookingValue;
  final int totalGuests;
  final Map<String, double> roomTypePerformance;
  final List<String> topBookingDates;

  CalendarAnalytics({
    required this.occupancyRate,
    required this.revenueGrowth,
    required this.newBookings,
    required this.cancelledBookings,
    required this.averageBookingValue,
    required this.totalGuests,
    required this.roomTypePerformance,
    required this.topBookingDates,
  });

  factory CalendarAnalytics.fromJson(Map<String, dynamic> json) {
    return CalendarAnalytics(
      occupancyRate: (json['occupancyRate'] as num?)?.toDouble() ?? 0.0,
      revenueGrowth: (json['revenueGrowth'] as num?)?.toDouble() ?? 0.0,
      newBookings: json['newBookings'] as int? ?? 0,
      cancelledBookings: json['cancelledBookings'] as int? ?? 0,
      averageBookingValue: (json['averageBookingValue'] as num?)?.toDouble() ?? 0.0,
      totalGuests: json['totalGuests'] as int? ?? 0,
      roomTypePerformance: Map<String, double>.from(
        (json['roomTypePerformance'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ?? {},
      ),
      topBookingDates: List<String>.from(json['topBookingDates'] ?? []),
    );
  }

  static CalendarAnalytics empty() {
    return CalendarAnalytics(
      occupancyRate: 0.0,
      revenueGrowth: 0.0,
      newBookings: 0,
      cancelledBookings: 0,
      averageBookingValue: 0.0,
      totalGuests: 0,
      roomTypePerformance: {},
      topBookingDates: [],
    );
  }
}

class CalendarPricing {
  final String date;
  final Map<String, double> roomPrices;
  final double averagePrice;
  final double minPrice;
  final double maxPrice;

  CalendarPricing({
    required this.date,
    required this.roomPrices,
    required this.averagePrice,
    required this.minPrice,
    required this.maxPrice,
  });

  factory CalendarPricing.fromJson(Map<String, dynamic> json) {
    return CalendarPricing(
      date: json['date'] as String,
      roomPrices: Map<String, double>.from(
        (json['roomPrices'] as Map<String, dynamic>?)?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ?? {},
      ),
      averagePrice: (json['averagePrice'] as num?)?.toDouble() ?? 0.0,
      minPrice: (json['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (json['maxPrice'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

enum CalendarAvailabilityStatus {
  available,
  limited,
  full,
  blocked,
}
