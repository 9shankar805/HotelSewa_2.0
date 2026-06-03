import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/order_service.dart';
import '../../../../core/widgets/cached_image.dart';
import '../../data/models/menu_item.dart';
import '../providers/cart_provider.dart';
import '../widgets/menu_item_card.dart';
import '../widgets/cart_fab.dart';
import 'cart_screen.dart';

class MenuScreen extends StatefulWidget {
  final int hotelId;
  final String hotelName;
  final int? bookingId;

  const MenuScreen({
    super.key,
    required this.hotelId,
    required this.hotelName,
    this.bookingId,
  });

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  final OrderService _orderService = OrderService();
  bool _isLoading = true;
  String? _error;
  Map<String, List<MenuItem>> _menuByCategory = {};
  List<String> _categories = [];
  String _selectedCategory = 'all';
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _loadMenu();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMenu() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final result = await _orderService.getHotelMenu(widget.hotelId);

    if (result['success']) {
      final data = result['data']['data'];
      final menu = data['menu'] as List;

      final Map<String, List<MenuItem>> categoryMap = {};
      final List<String> cats = ['all'];

      for (var categoryData in menu) {
        final category = categoryData['category'] as String;
        final items = (categoryData['items'] as List)
            .map((item) => MenuItem.fromJson(item))
            .where((item) => item.isAvailable)
            .toList();

        if (items.isNotEmpty) {
          categoryMap[category] = items;
          cats.add(category);
        }
      }

      setState(() {
        _menuByCategory = categoryMap;
        _categories = cats;
        _isLoading = false;
      });

      _tabController = TabController(length: _categories.length, vsync: this);
      _tabController.addListener(() {
        if (!_tabController.indexIsChanging) {
          setState(() {
            _selectedCategory = _categories[_tabController.index];
          });
        }
      });
    } else {
      setState(() {
        _error = result['message'];
        _isLoading = false;
      });
    }
  }

  List<MenuItem> get _filteredItems {
    if (_selectedCategory == 'all') {
      return _menuByCategory.values.expand((items) => items).toList();
    }
    return _menuByCategory[_selectedCategory] ?? [];
  }

  String _getCategoryLabel(String category) {
    if (category == 'all') return 'All';
    switch (category) {
      case 'food':
        return '🍽️ Food';
      case 'drinks':
        return '🥤 Drinks';
      case 'spa':
        return '💆 Spa';
      case 'laundry':
        return '👕 Laundry';
      case 'transport':
        return '🚗 Transport';
      case 'other':
        return '📦 Other';
      default:
        return category;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 200,
            pinned: true,
            backgroundColor: AppColors.primary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                widget.hotelName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 18,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppColors.primary,
                      AppColors.primaryDark,
                    ],
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -50,
                      top: -50,
                      child: Icon(
                        Icons.restaurant_menu,
                        size: 200,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: 60,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              '🛎️ In-Stay Ordering',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (_isLoading)
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            SliverFillRemaining(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, size: 64, color: AppColors.error),
                    const SizedBox(height: 16),
                    Text(_error!, style: const TextStyle(color: AppColors.gray)),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadMenu,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            SliverPersistentHeader(
              pinned: true,
              delegate: _CategoryTabBarDelegate(
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  indicatorColor: AppColors.primary,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.gray,
                  labelStyle: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                  tabs: _categories
                      .map((cat) => Tab(text: _getCategoryLabel(cat)))
                      .toList(),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _filteredItems[index];
                    return MenuItemCard(
                      menuItem: item,
                      onAddToCart: () => _showItemDetails(item),
                    );
                  },
                  childCount: _filteredItems.length,
                ),
              ),
            ),
          ],
        ],
      ),
      floatingActionButton: CartFAB(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CartScreen(
                hotelId: widget.hotelId,
                bookingId: widget.bookingId,
              ),
            ),
          );
        },
      ),
    );
  }

  void _showItemDetails(MenuItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ItemDetailsSheet(
        menuItem: item,
        onAddToCart: (notes) {
          Provider.of<CartProvider>(context, listen: false).addItem(item, notes: notes);
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} added to cart'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppColors.success,
            ),
          );
        },
      ),
    );
  }
}

class _CategoryTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _CategoryTabBarDelegate(this.tabBar);

  @override
  double get minExtent => 50;

  @override
  double get maxExtent => 50;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.white,
      child: tabBar,
    );
  }

  @override
  bool shouldRebuild(_CategoryTabBarDelegate oldDelegate) => false;
}

class _ItemDetailsSheet extends StatefulWidget {
  final MenuItem menuItem;
  final Function(String?) onAddToCart;

  const _ItemDetailsSheet({
    required this.menuItem,
    required this.onAddToCart,
  });

  @override
  State<_ItemDetailsSheet> createState() => _ItemDetailsSheetState();
}

class _ItemDetailsSheetState extends State<_ItemDetailsSheet> {
  final TextEditingController _notesController = TextEditingController();

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.menuItem.image != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: AppCachedImage(
                  url: widget.menuItem.image!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        widget.menuItem.categoryIcon,
                        style: const TextStyle(fontSize: 24),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          widget.menuItem.name,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.menuItem.description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.gray,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Text(
                        '${widget.menuItem.currency} ${widget.menuItem.price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.infoLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppColors.info,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${widget.menuItem.preparationTime} min',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.info,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: _notesController,
                    decoration: const InputDecoration(
                      labelText: 'Special Instructions (Optional)',
                      hintText: 'e.g., Extra spicy, No onions',
                      prefixIcon: Icon(Icons.edit_note),
                    ),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        widget.onAddToCart(_notesController.text.trim().isEmpty
                            ? null
                            : _notesController.text.trim());
                      },
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


