class Booking {
  final String id;
  final String guestName;
  final String guestEmail;
  final String guestPhone;
  final String roomNumber;
  final DateTime checkIn;
  final DateTime checkOut;
  final double amount;
  final String status;
  final String paymentStatus;
  final int numberOfGuests;
  final String? specialRequests;
  final DateTime createdAt;
  final DateTime updatedAt;

  Booking({
    required this.id,
    required this.guestName,
    required this.guestEmail,
    required this.guestPhone,
    required this.roomNumber,
    required this.checkIn,
    required this.checkOut,
    required this.amount,
    required this.status,
    required this.paymentStatus,
    required this.numberOfGuests,
    this.specialRequests,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    // Support both camelCase and snake_case API responses
    final String id = json['id']?.toString() ?? '';
    final String guestName = (json['guestName'] ?? json['guest_name'] ?? '')
        .toString();
    final String guestEmail = (json['guestEmail'] ?? json['guest_email'] ?? '')
        .toString();
    final String guestPhone =
        (json['guestPhone'] ?? json['guest_phone'] ?? json['phone'] ?? '')
            .toString();
    final String roomNumber = (json['roomNumber'] ?? json['room_number'] ?? '')
        .toString();

    DateTime parseDate(dynamic val) {
      if (val == null) return DateTime.now();
      try {
        return DateTime.parse(val.toString());
      } catch (_) {
        return DateTime.now();
      }
    }

    final DateTime checkIn = parseDate(json['checkIn'] ?? json['check_in']);
    final DateTime checkOut = parseDate(json['checkOut'] ?? json['check_out']);
    final double amount = (json['amount'] ?? 0.0).toDouble();
    final String status = (json['status'] ?? 'pending').toString();
    final String paymentStatus =
        (json['paymentStatus'] ?? json['payment_status'] ?? 'pending')
            .toString();
    final int numberOfGuests =
        (json['numberOfGuests'] ??
                json['number_of_guests'] ??
                json['guests'] ??
                1)
            is int
        ? json['numberOfGuests'] ??
              json['number_of_guests'] ??
              json['guests'] ??
              1
        : int.tryParse(
                (json['numberOfGuests'] ??
                        json['number_of_guests'] ??
                        json['guests'] ??
                        '1')
                    .toString(),
              ) ??
              1;
    final String? specialRequests =
        json['specialRequests']?.toString() ??
        json['special_requests']?.toString();
    final DateTime createdAt = parseDate(
      json['createdAt'] ?? json['created_at'],
    );
    final DateTime updatedAt = parseDate(
      json['updatedAt'] ?? json['updated_at'],
    );

    return Booking(
      id: id,
      guestName: guestName,
      guestEmail: guestEmail,
      guestPhone: guestPhone,
      roomNumber: roomNumber,
      checkIn: checkIn,
      checkOut: checkOut,
      amount: amount,
      status: status,
      paymentStatus: paymentStatus,
      numberOfGuests: numberOfGuests,
      specialRequests: specialRequests,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'guestName': guestName,
      'guestEmail': guestEmail,
      'guestPhone': guestPhone,
      'roomNumber': roomNumber,
      'checkIn': checkIn.toIso8601String(),
      'checkOut': checkOut.toIso8601String(),
      'amount': amount,
      'status': status,
      'paymentStatus': paymentStatus,
      'numberOfGuests': numberOfGuests,
      'specialRequests': specialRequests,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? guestName,
    String? guestEmail,
    String? guestPhone,
    String? roomNumber,
    DateTime? checkIn,
    DateTime? checkOut,
    double? amount,
    String? status,
    String? paymentStatus,
    int? numberOfGuests,
    String? specialRequests,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Booking(
      id: id ?? this.id,
      guestName: guestName ?? this.guestName,
      guestEmail: guestEmail ?? this.guestEmail,
      guestPhone: guestPhone ?? this.guestPhone,
      roomNumber: roomNumber ?? this.roomNumber,
      checkIn: checkIn ?? this.checkIn,
      checkOut: checkOut ?? this.checkOut,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      numberOfGuests: numberOfGuests ?? this.numberOfGuests,
      specialRequests: specialRequests ?? this.specialRequests,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Booking(id: $id, guestName: $guestName, roomNumber: $roomNumber, status: $status)';
  }

  // Helper methods
  bool get isConfirmed => status == 'confirmed';
  bool get isCheckedIn => status == 'checked_in';
  bool get isCheckedOut => status == 'checked_out';
  bool get isCancelled => status == 'cancelled';
  bool get isPending => status == 'pending';

  bool get isPaid => paymentStatus == 'paid';
  bool get isPendingPayment => paymentStatus == 'pending';
  bool get isRefunded => paymentStatus == 'refunded';

  int get nights {
    final difference = checkOut.difference(checkIn);
    return difference.inDays;
  }

  double get amountPerNight => nights > 0 ? amount / nights : amount;
}
