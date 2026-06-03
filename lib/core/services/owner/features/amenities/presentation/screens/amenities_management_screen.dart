import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../services/amenities_service.dart';

class _AmenityItem {
  final String id;
  final String name;
  final IconData icon;
  final String category;
  const _AmenityItem({required this.id, required this.name, required this.icon, required this.category});
}

const _amenities = [
  _AmenityItem(id: 'wifi', name: 'Free WiFi', icon: Icons.wifi, category: 'Connectivity'),
  _AmenityItem(id: 'pool', name: 'Swimming Pool', icon: Icons.pool, category: 'Recreation'),
  _AmenityItem(id: 'parking', name: 'Parking', icon: Icons.local_parking, category: 'Facilities'),
  _AmenityItem(id: 'restaurant', name: 'Restaurant', icon: Icons.restaurant, category: 'Dining'),
  _AmenityItem(id: 'gym', name: 'Gym', icon: Icons.fitness_center, category: 'Recreation'),
  _AmenityItem(id: 'spa', name: 'Spa', icon: Icons.spa, category: 'Recreation'),
  _AmenityItem(id: 'ac', name: 'Air Conditioning', icon: Icons.ac_unit, category: 'Room'),
  _AmenityItem(id: 'room_service', name: 'Room Service', icon: Icons.room_service, category: 'Services'),
  _AmenityItem(id: 'laundry', name: 'Laundry', icon: Icons.local_laundry_service, category: 'Services'),
  _AmenityItem(id: 'bar', name: 'Bar / Lounge', icon: Icons.local_bar, category: 'Dining'),
  _AmenityItem(id: 'conference', name: 'Conference Room', icon: Icons.meeting_room, category: 'Business'),
  _AmenityItem(id: 'shuttle', name: 'Airport Shuttle', icon: Icons.airport_shuttle, category: 'Transport'),
  _AmenityItem(id: 'pet', name: 'Pet Friendly', icon: Icons.pets, category: 'Policies'),
  _AmenityItem(id: 'breakfast', name: 'Breakfast', icon: Icons.free_breakfast, category: 'Dining'),
  _AmenityItem(id: 'reception', name: '24hr Reception', icon: Icons.support_agent, category: 'Services'),
  _AmenityItem(id: 'security', name: 'Security', icon: Icons.security, category: 'Safety'),
];

class AmenitiesManagementScreen extends StatefulWidget {
  const AmenitiesManagementScreen({super.key});
  @override
  State<AmenitiesManagementScreen> createState() => _AmenitiesManagementScreenState();
}

class _AmenitiesManagementScreenState extends State<AmenitiesManagementScreen> {
  final AmenitiesService _service = AmenitiesService();
  final Map<String, bool> _selected = {};
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    for (final a in _amenities) _selected[a.id] = false;
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getAmenities();
      for (final a in data) {
        final id = a['id']?.toString() ?? a['name']?.toString().toLowerCase().replaceAll(' ', '_') ?? '';
        if (id.isNotEmpty) _selected[id] = true;
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final selected = _selected.entries.where((e) => e.value).map((e) => e.key).toList();
    try {
      await _service.updateAmenities(selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Text('Amenities saved successfully'),
          backgroundColor: const Color(AppConstants.successGreen),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed: ${e.toString()}'),
          backgroundColor: const Color(AppConstants.errorRed),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
    }
    if (mounted) setState(() => _isSaving = false);
  }

  int get _selectedCount => _selected.values.where((v) => v).length;

  Map<String, List<_AmenityItem>> get _grouped {
    final map = <String, List<_AmenityItem>>{};
    for (final a in _amenities) map.putIfAbsent(a.category, () => []).add(a);
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black,
        title: const Text('Amenities', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          if (_selectedCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 16),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(color: const Color(AppConstants.primaryRed), borderRadius: BorderRadius.circular(20)),
              child: Text('$_selectedCount selected', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
      body: _isLoading ? _buildSkeleton() : _buildContent(isDark, cardColor, borderColor),
      bottomNavigationBar: _isLoading ? null : Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(color: cardColor, border: Border(top: BorderSide(color: borderColor))),
        child: ElevatedButton(
          onPressed: _isSaving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(AppConstants.primaryRed),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: _isSaving
              ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Save Amenities', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, Color cardColor, Color borderColor) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(AppConstants.primaryRed).withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(AppConstants.primaryRed).withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: Color(AppConstants.primaryRed), size: 18),
                const SizedBox(width: 10),
                Expanded(child: Text('Select all amenities available at your property. These will be shown to guests.',
                  style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : const Color(AppConstants.darkGray)))),
              ],
            ),
          ),
          const SizedBox(height: 20),
          ..._grouped.entries.map((e) => _buildCategory(e.key, e.value, isDark, cardColor, borderColor)),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _buildCategory(String category, List<_AmenityItem> items, bool isDark, Color cardColor, Color borderColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(category, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
            color: isDark ? Colors.white54 : const Color(AppConstants.mediumGray), letterSpacing: 0.5)),
        ),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.95),
          itemCount: items.length,
          itemBuilder: (_, i) => _buildTile(items[i], isDark, cardColor, borderColor),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildTile(_AmenityItem a, bool isDark, Color cardColor, Color borderColor) {
    final isSelected = _selected[a.id] ?? false;
    return GestureDetector(
      onTap: () => setState(() => _selected[a.id] = !isSelected),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isSelected ? const Color(AppConstants.primaryRed).withOpacity(0.08) : cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(AppConstants.primaryRed) : borderColor, width: isSelected ? 1.5 : 1),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(
                color: isSelected ? const Color(AppConstants.primaryRed).withOpacity(0.12) : (isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(a.icon, size: 22, color: isSelected ? const Color(AppConstants.primaryRed) : const Color(AppConstants.mediumGray)),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(a.name, textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 11, fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? const Color(AppConstants.primaryRed) : (isDark ? Colors.white70 : const Color(AppConstants.darkGray)))),
            ),
            if (isSelected) ...[const SizedBox(height: 4), const Icon(Icons.check_circle, size: 14, color: Color(AppConstants.primaryRed))],
          ],
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SkeletonLoader(height: 60, borderRadius: 12),
          const SizedBox(height: 24),
          ...List.generate(3, (_) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SkeletonLoader(width: 100, height: 14, borderRadius: 7),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.95),
                itemCount: 6,
                itemBuilder: (_, __) => const SkeletonLoader(height: double.infinity, borderRadius: 12),
              ),
              const SizedBox(height: 24),
            ],
          )),
        ],
      ),
    );
  }
}
