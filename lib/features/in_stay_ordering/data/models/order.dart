import 'order_item.dart';

class Order {
  final int id;
  final String orderNumber;
  final int bookingId;
  final int hotelId;
  final int userId;
  final String roomNumber;
  final double subtotal;
  final double tax;
  final double totalAmount;
  final String currency;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? specialInstructions;
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? deliveredAt;
  final List<OrderItem> items;
  final Map<String, dynamic>? hotel;
  final String? estimatedReadyAt;

  Order({
    required this.id,
    required this.orderNumber,
    required this.bookingId,
    required this.hotelId,
    required this.userId,
    required this.roomNumber,
    required this.subtotal,
    required this.tax,
    required this.totalAmount,
    required this.currency,
    required this.status,
    required this.paymentStatus,
    required this.paymentMethod,
    this.specialInstructions,
    required this.createdAt,
    this.confirmedAt,
    this.deliveredAt,
    required this.items,
    this.hotel,
    this.estimatedReadyAt,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] ?? 0,
      orderNumber: json['order_number'] ?? '',
      bookingId: json['booking_id'] ?? 0,
      hotelId: json['hotel_id'] ?? 0,
      userId: json['user_id'] ?? 0,
      roomNumber: json['room_number'] ?? '',
      subtotal: (json['subtotal'] ?? 0).toDouble(),
      tax: (json['tax'] ?? 0).toDouble(),
      totalAmount: (json['total_amount'] ?? 0).toDouble(),
      currency: json['currency'] ?? 'NPR',
      status: json['status'] ?? 'pending',
      paymentStatus: json['payment_status'] ?? 'unpaid',
      paymentMethod: json['payment_method'] ?? 'room_charge',
      specialInstructions: json['special_instructions'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      confirmedAt: json['confirmed_at'] != null ? DateTime.parse(json['confirmed_at']) : null,
      deliveredAt: json['delivered_at'] != null ? DateTime.parse(json['delivered_at']) : null,
      items: (json['items'] as List?)?.map((item) => OrderItem.fromJson(item)).toList() ?? [],
      hotel: json['hotel'],
      estimatedReadyAt: json['estimated_ready_at'],
    );
  }

  String get statusIcon {
    switch (status) {
      case 'pending':
        return '⏳';
      case 'confirmed':
        return '✅';
      case 'preparing':
        return '👨‍🍳';
      case 'ready':
        return '🔔';
      case 'delivered':
        return '✅';
      case 'cancelled':
        return '❌';
      default:
        return '🛎️';
    }
  }

  String get statusLabel {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'confirmed':
        return 'Confirmed';
      case 'preparing':
        return 'Preparing';
      case 'ready':
        return 'Ready';
      case 'delivered':
        return 'Delivered';
      case 'cancelled':
        return 'Cancelled';
      default:
        return 'Unknown';
    }
  }

  bool get canCancel => status == 'pending' || status == 'confirmed';
}
