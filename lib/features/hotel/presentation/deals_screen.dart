import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/deals_service.dart';

class DealsScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const DealsScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<DealsScreen> createState() => _DealsScreenState();
}

class _DealsScreenState extends State<DealsScreen> {
  final _dealsService = DealsService();
  List _deals = [];
  List _filteredDeals = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  final _searchCtrl = TextEditingController();

  final List<Map<String, dynamic>> _categories = [
    {'label': 'All', 'icon': Icons.local_offer_rounded},
    {'label': 'Hotel', 'icon': Icons.hotel_rounded},
    {'label': 'Spa', 'icon': Icons.spa_rounded},
    {'label': 'Adventure', 'icon': Icons.hiking_rounded},
    {'label': 'Restaurant', 'icon': Icons.restaurant_rounded},
  ];

  @override
  void initState() {
    super.initState();
    _loadDeals();
    _searchCtrl.addListener(_filterDeals);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadDeals() async {
    setState(() => _loading = true);
    final result = await _dealsService.getActiveDeals();
    if (mounted) {
      final raw = result['deals'];
      final list = raw is List ? raw : [];
      setState(() { _deals = list; _filteredDeals = list; _loading = false; });
    }
  }

  void _filterDeals() {
    final query = _searchCtrl.text.toLowerCase();
    setState(() {
      _filteredDeals = _deals.where((d) {
        final title = (d['title'] ?? d['name'] ?? '').toString().toLowerCase();
        final desc = (d['description'] ?? '').toString().toLowerCase();
        final cat = (d['category'] ?? '').toString().toLowerCase();
        final matchesSearch = query.isEmpty || title.contains(query) || desc.contains(query);
        final matchesCat = _selectedCategory == 'All' || cat == _selectedCategory.toLowerCase();
        return matchesSearch && matchesCat;
      }).toList();
    });
  }

  void _selectCategory(String cat) {
    setState(() => _selectedCategory = cat);
    _filterDeals();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Deals & Offers', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchCtrl,
                  decoration: InputDecoration(
                    hintText: 'Search deals...',
                    hintStyle: const TextStyle(color: AppColors.placeholder, fontSize: 14),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.gray, size: 20),
                    filled: true,
                    fillColor: AppColors.background,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  ),
                ),
                const SizedBox(height: 12),
                // Category chips
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final cat = _categories[i];
                      final selected = _selectedCategory == cat['label'];
                      return GestureDetector(
                        onTap: () => _selectCategory(cat['label'] as String),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: selected ? AppColors.primary : AppColors.background,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: selected ? AppColors.primary : AppColors.lightGray),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat['icon'] as IconData, size: 14, color: selected ? Colors.white : AppColors.gray),
                              const SizedBox(width: 4),
                              Text(cat['label'] as String, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: selected ? Colors.white : AppColors.darkGray)),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _filteredDeals.isEmpty
                    ? _buildEmpty()
                    : RefreshIndicator(
                        onRefresh: _loadDeals,
                        color: AppColors.primary,
                        child: ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _filteredDeals.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 14),
                          itemBuilder: (ctx, i) => _buildDealCard(_filteredDeals[i], i),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealCard(Map deal, int index) {
    final title = deal['title'] ?? deal['name'] ?? 'Special Deal';
    final description = deal['description'] ?? '';
    final discount = deal['discount_percentage'] ?? deal['discount'] ?? 0;
    final validUntil = deal['valid_until'] ?? deal['expires_at'] ?? '';
    final hotelName = deal['hotel_name'] ?? deal['hotel']?['name'] ?? '';
    final imageUrl = deal['image'] ?? deal['cover_image'] ?? '';

    return GestureDetector(
      onTap: () => _dealsService.trackDealView(deal['id']?.toString() ?? ''),
      child: Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), boxShadow: AppColors.cardShadow),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                  child: imageUrl.isNotEmpty
                      ? Image.network(imageUrl, height: 160, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _dealImagePlaceholder())
                      : _dealImagePlaceholder(),
                ),
                if (discount > 0)
                  Positioned(
                    top: 12, left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(20)),
                      child: Text('$discount% OFF', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray), maxLines: 1, overflow: TextOverflow.ellipsis),
                  if (description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(description, style: const TextStyle(fontSize: 13, color: AppColors.gray, height: 1.4), maxLines: 2, overflow: TextOverflow.ellipsis),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (hotelName.isNotEmpty) ...[
                        const Icon(Icons.hotel_rounded, size: 13, color: AppColors.gray),
                        const SizedBox(width: 4),
                        Expanded(child: Text(hotelName, style: const TextStyle(fontSize: 12, color: AppColors.gray), overflow: TextOverflow.ellipsis)),
                      ] else const Spacer(),
                      if (validUntil.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppColors.warningLight, borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.schedule_rounded, size: 11, color: AppColors.warning),
                              const SizedBox(width: 4),
                              Text('Ends $validUntil', style: const TextStyle(fontSize: 11, color: AppColors.warning, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: index * 60)).slideY(begin: 0.1),
    );
  }

  Widget _dealImagePlaceholder() {
    return Container(
      height: 160, width: double.infinity,
      color: AppColors.primaryLight.withOpacity(0.1),
      child: const Icon(Icons.local_offer_rounded, color: AppColors.primaryLight, size: 48),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.local_offer_outlined, size: 64, color: AppColors.placeholder),
          const SizedBox(height: 16),
          const Text('No deals available', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
          const SizedBox(height: 8),
          const Text('Check back later for exclusive offers', style: TextStyle(fontSize: 14, color: AppColors.gray)),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _loadDeals,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            child: const Text('Refresh', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
