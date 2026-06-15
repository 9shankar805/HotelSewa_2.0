import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../data/models/menu_item_model.dart';
import '../../../../core/services/owner/ordering_service.dart';
import '../widgets/menu_item_card.dart';
import 'add_menu_item_screen.dart';
import '../../../../core/constants/app_colors.dart';

class MenuManagementScreen extends StatefulWidget {
  const MenuManagementScreen({Key? key}) : super(key: key);

  @override
  State<MenuManagementScreen> createState() => _MenuManagementScreenState();
}

class _MenuManagementScreenState extends State<MenuManagementScreen> {
  bool _isLoading = true;
  Map<String, List<MenuItemModel>> _menuByCategory = {};
  String? _selectedCategory;

  final List<Map<String, dynamic>> _categories = [
    {'value': 'food', 'label': '🍽️ Food', 'icon': Icons.restaurant},
    {'value': 'drinks', 'label': '🥤 Drinks', 'icon': Icons.local_bar},
    {'value': 'spa', 'label': '💆 Spa & Wellness', 'icon': Icons.spa},
    {'value': 'laundry', 'label': '👕 Laundry', 'icon': Icons.local_laundry_service},
    {'value': 'transport', 'label': '🚗 Transport', 'icon': Icons.directions_car},
    {'value': 'other', 'label': '📦 Other Services', 'icon': Icons.room_service},
  ];

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  Future<void> _loadMenu() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? prefs.getString('auth_token');

      if (token == null) {
        _showError('Please login first');
        return;
      }

      final response = await OrderingService.getMyMenu(token);

      // API returns success:true OR status:true depending on endpoint
      final isOk = response['success'] == true || response['status'] == true;

      if (isOk) {
        final rawData = response['data'];
        // Handle both {menu: [...]} and flat list
        List<dynamic> menu = [];
        if (rawData is Map) {
          menu = rawData['menu'] as List<dynamic>? ??
              rawData['items'] as List<dynamic>? ??
              rawData['data'] as List<dynamic>? ?? [];
        } else if (rawData is List) {
          menu = rawData;
        }

        final Map<String, List<MenuItemModel>> grouped = {};
        for (var category in menu) {
          if (category is Map) {
            final categoryName = (category['category'] ?? category['name'] ?? 'other').toString();
            final items = (category['items'] as List<dynamic>? ?? [])
                .map((item) => MenuItemModel.fromJson(item as Map<String, dynamic>))
                .toList();
            grouped[categoryName] = items;
          }
        }

        // If flat list (no categories), group by item.category field
        if (grouped.isEmpty && rawData is List) {
          for (var item in rawData) {
            final m = MenuItemModel.fromJson(item as Map<String, dynamic>);
            grouped.putIfAbsent(m.category, () => []).add(m);
          }
        }

        setState(() {
          _menuByCategory = grouped;
          _isLoading = false;
        });
      } else {
        _showError(response['message'] ?? 'Failed to load menu');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  void _showSuccess(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.success),
      );
    }
  }

  Future<void> _deleteItem(MenuItemModel item) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Menu Item'),
        content: Text('Are you sure you want to delete "${item.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? prefs.getString('auth_token');

      final response = await OrderingService.deleteMenuItem(
        token: token!,
        itemId: item.id,
      );

      if (response['status'] == true) {
        _showSuccess('Menu item deleted');
        _loadMenu();
      } else {
        _showError(response['message'] ?? 'Failed to delete');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  Future<void> _toggleAvailability(MenuItemModel item) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? prefs.getString('auth_token');

      final response = await OrderingService.updateMenuItem(
        token: token!,
        itemId: item.id,
        isAvailable: !item.isAvailable,
      );

      if (response['status'] == true) {
        _showSuccess(item.isAvailable ? 'Item marked unavailable' : 'Item marked available');
        _loadMenu();
      } else {
        _showError(response['message'] ?? 'Failed to update');
      }
    } catch (e) {
      _showError('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMenu,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildCategoryFilter(),
                Expanded(child: _buildMenuList()),
              ],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push('/add-menu-item');
          _loadMenu();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _buildCategoryChip('All', null),
          const SizedBox(width: 8),
          ..._categories.map((cat) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildCategoryChip(cat['label'], cat['value']),
              )),
        ],
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? value) {
    final isSelected = _selectedCategory == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() => _selectedCategory = selected ? value : null);
      },
      backgroundColor: AppColors.gray[200],
      selectedColor: Theme.of(context).primaryColor.withOpacity(0.2),
    );
  }

  Widget _buildMenuList() {
    if (_menuByCategory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.restaurant_menu, size: 64, color: AppColors.gray[400]),
            const SizedBox(height: 16),
            Text(
              'No menu items yet',
              style: TextStyle(fontSize: 18, color: AppColors.gray[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first item',
              style: TextStyle(color: AppColors.gray),
            ),
          ],
        ),
      );
    }

    final filteredCategories = _selectedCategory == null
        ? _menuByCategory.entries.toList()
        : _menuByCategory.entries
            .where((entry) => entry.key == _selectedCategory)
            .toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: filteredCategories.length,
      itemBuilder: (context, index) {
        final entry = filteredCategories[index];
        final category = entry.key;
        final items = entry.value;

        final categoryInfo = _categories.firstWhere(
          (cat) => cat['value'] == category,
          orElse: () => {'label': category, 'icon': Icons.category},
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  Icon(categoryInfo['icon'] as IconData, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    categoryInfo['label'] as String,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${items.length}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),
            ...items.map((item) => MenuItemCard(
                  item: item,
                  onEdit: () async {
                    await context.push('/edit-menu-item/${item.id}', extra: item);
                    _loadMenu();
                  },
                  onDelete: () => _deleteItem(item),
                  onToggleAvailability: () => _toggleAvailability(item),
                )),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }
}
