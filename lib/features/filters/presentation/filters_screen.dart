import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Standalone filters screen — navigated to from hotel list.
/// Returns a Map<String,dynamic> with the selected filters via Navigator.pop().
class FiltersScreen extends StatefulWidget {
  final Map<String, dynamic>? initialFilters;
  const FiltersScreen({super.key, this.initialFilters});

  @override
  State<FiltersScreen> createState() => _FiltersScreenState();
}

class _FiltersScreenState extends State<FiltersScreen> {
  RangeValues _priceRange = const RangeValues(0, 20000);
  double _minRating = 0;
  List<String> _selectedAmenities = [];
  String _sortBy = 'price_asc';

  static const _amenities = ['WiFi', 'AC', 'Parking', 'Breakfast', 'Pool', 'Gym', 'Spa', 'Restaurant'];
  static const _sortOptions = [
    ('price_asc', 'Price: Low to High'),
    ('price_desc', 'Price: High to Low'),
    ('rating', 'Top Rated'),
    ('distance', 'Nearest First'),
  ];

  @override
  void initState() {
    super.initState();
    final f = widget.initialFilters ?? {};
    _sortBy = f['sortBy'] ?? 'price_asc';
    _minRating = (f['minRating'] ?? 0).toDouble();
    _selectedAmenities = List<String>.from(f['amenities'] ?? []);
    final minP = (f['minPrice'] ?? 0).toDouble();
    final maxP = (f['maxPrice'] ?? 20000).toDouble();
    _priceRange = RangeValues(minP, maxP);
  }

  void _reset() => setState(() {
    _priceRange = const RangeValues(0, 20000);
    _minRating = 0;
    _selectedAmenities = [];
    _sortBy = 'price_asc';
  });

  void _apply() => Navigator.pop(context, {
    'sortBy': _sortBy,
    'minRating': _minRating,
    'amenities': _selectedAmenities,
    'minPrice': _priceRange.start,
    'maxPrice': _priceRange.end,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray), onPressed: () => Navigator.pop(context)),
        title: const Text('Filters', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [TextButton(onPressed: _reset, child: const Text('Reset', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)))],
      ),
      body: Column(children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _section('Sort By'),
              ...(_sortOptions.map((opt) => RadioListTile<String>(
                value: opt.$1, groupValue: _sortBy,
                title: Text(opt.$2, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.darkGray)),
                activeColor: AppColors.primary,
                contentPadding: EdgeInsets.zero,
                onChanged: (v) => setState(() => _sortBy = v!),
              ))),
              const SizedBox(height: 8),
              _section('Price Range (per night)'),
              const SizedBox(height: 8),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('NPR ${_priceRange.start.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                Text('NPR ${_priceRange.end.toInt()}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ]),
              RangeSlider(
                values: _priceRange, min: 0, max: 20000, divisions: 40,
                activeColor: AppColors.primary, inactiveColor: AppColors.lightGray,
                onChanged: (v) => setState(() => _priceRange = v),
              ),
              const SizedBox(height: 16),
              _section('Minimum Rating'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                ...[0.0, 3.0, 3.5, 4.0, 4.5].map((r) {
                  final sel = _minRating == r;
                  return GestureDetector(
                    onTap: () => setState(() => _minRating = r),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: sel ? AppColors.primary : Colors.white,
                        border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        if (r > 0) ...[const Icon(Icons.star_rounded, size: 13, color: AppColors.gold), const SizedBox(width: 3)],
                        Text(r == 0 ? 'Any' : '$r+', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : AppColors.darkGray)),
                      ]),
                    ),
                  );
                }),
              ]),
              const SizedBox(height: 20),
              _section('Amenities'),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: _amenities.map((a) {
                final sel = _selectedAmenities.contains(a);
                return GestureDetector(
                  onTap: () => setState(() { if (sel) _selectedAmenities.remove(a); else _selectedAmenities.add(a); }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: sel ? AppColors.primary.withOpacity(0.1) : Colors.white,
                      border: Border.all(color: sel ? AppColors.primary : AppColors.lightGray),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(a, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? AppColors.primary : AppColors.gray)),
                  ),
                );
              }).toList()),
            ]),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
          decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x10000000), blurRadius: 12, offset: Offset(0, -4))]),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _apply,
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
              child: const Text('Apply Filters', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _section(String title) => Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray));
}
