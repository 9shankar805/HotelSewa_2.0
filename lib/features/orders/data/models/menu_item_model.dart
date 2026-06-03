class MenuItemModel {
  final int id;
  final int hotelId;
  final String category;
  final String name;
  final String? description;
  final double price;
  final String currency;
  final String? image;
  final int preparationTime;
  final bool isAvailable;
  final int sortOrder;

  MenuItemModel({
    required this.id,
    required this.hotelId,
    required this.category,
    required this.name,
    this.description,
    required this.price,
    required this.currency,
    this.image,
    required this.preparationTime,
    required this.isAvailable,
    required this.sortOrder,
  });

  factory MenuItemModel.fromJson(Map<String, dynamic> json) {
    return MenuItemModel(
      id: json['id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      category: json['category'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      price: (json['price'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NPR',
      image: json['image'],
      preparationTime: json['preparation_time'] ?? 15,
      isAvailable: json['is_available'] ?? true,
      sortOrder: json['sort_order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'hotel_id': hotelId,
      'category': category,
      'name': name,
      'description': description,
      'price': price,
      'currency': currency,
      'image': image,
      'preparation_time': preparationTime,
      'is_available': isAvailable,
      'sort_order': sortOrder,
    };
  }

  String get categoryLabel {
    switch (category) {
      case 'food':
        return '🍽️ Food';
      case 'drinks':
        return '🥤 Drinks';
      case 'spa':
        return '💆 Spa & Wellness';
      case 'laundry':
        return '👕 Laundry';
      case 'transport':
        return '🚗 Transport';
      case 'other':
        return '📦 Other Services';
      default:
        return category;
    }
  }
}
