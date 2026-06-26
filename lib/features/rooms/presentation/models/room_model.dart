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

  factory Room.fromJson(Map<String, dynamic> j) {
    // Normalize - support both camelCase and snake_case
    final String id = j['id']?.toString() ?? '';

    String? extractString(String key, String altKey) {
      return (j[key] ?? j[altKey])?.toString();
    }

    num? extractNum(String key, String altKey) {
      return (j[key] ?? j[altKey]) as num?;
    }

    List<String> extractList(String key, String altKey) {
      final val = j[key] ?? j[altKey];
      if (val is List) return List<String>.from(val.map((e) => e.toString()));
      return [];
    }

    return Room(
      id: id,
      roomNumber: extractString('room_number', 'roomNumber') ?? '',
      type: extractString('type', 'room_type') ?? '',
      status: extractString('status', 'status') ?? 'available',
      capacity: (extractNum('capacity', 'capacity'))?.toInt() ?? 1,
      pricePerNight: (extractNum('price_per_night', 'price') ?? 0.0).toDouble(),
      hotelId: extractString('hotel_id', 'hotelId'),
      description: extractString('description', 'description'),
      amenities: extractList('amenities', 'amenities'),
      images: extractList('images', 'images'),
    );
  }

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
