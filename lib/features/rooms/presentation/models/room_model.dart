class Room {
  final String id;
  final String roomNumber;
  final String type;
  final String status;
  final int capacity;
  final double pricePerNight;
  final String? hotelId;
  final String? description;
  final List<String> amenities;
  final List<String> images;

  const Room({
    required this.id,
    required this.roomNumber,
    required this.type,
    required this.status,
    required this.capacity,
    required this.pricePerNight,
    this.hotelId,
    this.description,
    this.amenities = const [],
    this.images = const [],
  });

  factory Room.fromJson(Map<String, dynamic> j) => Room(
        id: j['id']?.toString() ?? '',
        roomNumber: j['room_number'] as String? ?? j['roomNumber'] as String? ?? '',
        type: j['type'] as String? ?? j['room_type'] as String? ?? '',
        status: j['status'] as String? ?? 'available',
        capacity: (j['capacity'] as num?)?.toInt() ?? 1,
        pricePerNight: (j['price_per_night'] as num?)?.toDouble() ??
            (j['price'] as num?)?.toDouble() ?? 0.0,
        hotelId: j['hotel_id']?.toString() ?? j['hotelId']?.toString(),
        description: j['description'] as String?,
        amenities: j['amenities'] is List
            ? List<String>.from(j['amenities'])
            : [],
        images: j['images'] is List
            ? List<String>.from(j['images'])
            : [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'room_number': roomNumber,
        'type': type,
        'status': status,
        'capacity': capacity,
        'price_per_night': pricePerNight,
        if (hotelId != null) 'hotel_id': hotelId,
        if (description != null) 'description': description,
        'amenities': amenities,
        'images': images,
      };

  Room copyWith({String? status}) => Room(
        id: id,
        roomNumber: roomNumber,
        type: type,
        status: status ?? this.status,
        capacity: capacity,
        pricePerNight: pricePerNight,
        hotelId: hotelId,
        description: description,
        amenities: amenities,
        images: images,
      );
}
