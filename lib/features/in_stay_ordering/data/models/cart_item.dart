import 'menu_item.dart';

class CartItem {
  final MenuItem menuItem;
  int quantity;
  String? notes;

  CartItem({
    required this.menuItem,
    this.quantity = 1,
    this.notes,
  });

  double get totalPrice => menuItem.price * quantity;

  Map<String, dynamic> toJson() {
    return {
      'menu_item_id': menuItem.id,
      'quantity': quantity,
      'notes': notes,
    };
  }
}
