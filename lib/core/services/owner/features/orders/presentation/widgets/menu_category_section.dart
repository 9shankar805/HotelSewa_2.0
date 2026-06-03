import 'package:flutter/material.dart';
import '../../data/models/menu_item_model.dart';
import 'menu_item_card.dart';

class MenuCategorySection extends StatelessWidget {
  final String category;
  final List<MenuItemModel> items;
  final Function(MenuItemModel) onEdit;
  final Function(MenuItemModel) onDelete;
  final Function(MenuItemModel) onToggleAvailability;

  const MenuCategorySection({
    Key? key,
    required this.category,
    required this.items,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleAvailability,
  }) : super(key: key);

  String get _categoryLabel {
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

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _categoryLabel,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (context, index) {
            return MenuItemCard(
              item: items[index],
              onEdit: () => onEdit(items[index]),
              onDelete: () => onDelete(items[index]),
              onToggleAvailability: () => onToggleAvailability(items[index]),
            );
          },
        ),
      ],
    );
  }
}
