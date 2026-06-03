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
    return Booking(
      id: json['id'] ?? '',
      guestName: json['guestName'] ?? '',
      guestEmail: json['guestEmail'] ?? '',
      guestPhone: json['guestPhone'] ?? '',
      roomNumber: json['roomNumber'] ?? '',
      checkIn: DateTime.parse(json['checkIn'] ?? DateTime.now().toIso8601String()),
      checkOut: DateTime.parse(json['checkOut'] ?? DateTime.now().toIso8601String()),
      amount: (json['amount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      paymentStatus: json['paymentStatus'] ?? 'pending',
      numberOfGuests: json['numberOfGuests'] ?? 1,
      specialRequests: json['specialRequests'],
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updatedAt'] ?? DateTime.now().toIso8601String()),
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
