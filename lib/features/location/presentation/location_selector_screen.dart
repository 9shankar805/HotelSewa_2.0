import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/nepal_locations.dart';
import '../../../core/services/location_service.dart';

class LocationSelectorScreen extends StatefulWidget {
  const LocationSelectorScreen({Key? key}) : super(key: key);

  @override
  State<LocationSelectorScreen> createState() => _LocationSelectorScreenState();
}

class _LocationSelectorScreenState extends State<LocationSelectorScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<String> _suggestions = [];
  bool _detectingGps = false;

  static const _popular = [
    'Kathmandu', 'Pokhara', 'Chitwan', 'Lumbini',
    'Bhaktapur', 'Lalitpur', 'Biratnagar', 'Birgunj',
    'Dharan', 'Butwal', 'Nepalgunj', 'Dhangadhi',
  ];

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    LocationService.getSavedCity().then((city) {
      if (city != null && mounted) _searchCtrl.text = city;
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final q = _searchCtrl.text.trim().toLowerCase();
    if (q.isEmpty) { setState(() => _suggestions = []); return; }
    final results = <String>{};
    NepalLocationData.provinces.forEach((_, province) {
      for (final district in province.districts) {
        if (district.name.toLowerCase().contains(q)) results.add(district.name);
        for (final muni in district.municipalities) {
          if (muni.toLowerCase().contains(q)) results.add('$muni, ${district.name}');
        }
      }
    });
    for (final city in _popular) {
      if (city.toLowerCase().contains(q)) results.add(city);
    }
    setState(() => _suggestions = results.take(10).toList());
  }

  void _select(String location) {
    LocationService.saveCity(location);
    Navigator.pop(context, location);
  }

  Future<void> _detectGps() async {
    setState(() => _detectingGps = true);
    try {
      final position = await LocationService.getCurrentPosition();
      if (position == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Enable GPS to detect location'), behavior: SnackBarBehavior.floating));
        return;
      }
      await LocationService.saveCity('Near Me', lat: position.latitude, lng: position.longitude);
      if (mounted) Navigator.pop(context, {'location': 'Near Me', 'lat': position.latitude, 'lng': position.longitude, 'useGps': true});
    } finally {
      if (mounted) setState(() => _detectingGps = false);
    }
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
        title: const Text('Select Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Search + GPS
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search city, district or area...',
                      prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(icon: const Icon(Icons.clear_rounded, size: 18, color: AppColors.gray), onPressed: () { _searchCtrl.clear(); setState(() => _suggestions = []); })
                          : null,
                      filled: true, fillColor: AppColors.background,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _detectingGps ? null : _detectGps,
                  child: Container(
                    width: 46, height: 46,
                    decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.primary.withOpacity(0.3))),
                    child: _detectingGps
                        ? const Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 22),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: _suggestions.isNotEmpty
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: _suggestions.length,
                    itemBuilder: (_, i) => ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: AppColors.primary, size: 20),
                      title: Text(_suggestions[i], style: const TextStyle(fontSize: 14, color: AppColors.darkGray)),
                      onTap: () => _select(_suggestions[i]),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ).animate(delay: (i * 30).ms).fadeIn(),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // GPS option
                        GestureDetector(
                          onTap: _detectGps,
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.primary.withOpacity(0.2))),
                            child: Row(children: [
                              const Icon(Icons.my_location_rounded, color: AppColors.primary, size: 20),
                              const SizedBox(width: 12),
                              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text('Use Current Location', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.primary)),
                                Text('Find hotels near you', style: TextStyle(fontSize: 12, color: AppColors.gray)),
                              ])),
                              const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                            ]),
                          ),
                        ).animate().fadeIn(),
                        const SizedBox(height: 20),
                        const Text('Popular Destinations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.gray, letterSpacing: 0.5)),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8, runSpacing: 8,
                          children: _popular.map((city) => GestureDetector(
                            onTap: () => _select(city),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.lightGray), boxShadow: AppColors.cardShadow),
                              child: Row(mainAxisSize: MainAxisSize.min, children: [
                                const Icon(Icons.location_city_rounded, size: 14, color: AppColors.gray),
                                const SizedBox(width: 5),
                                Text(city, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.darkGray)),
                              ]),
                            ),
                          )).toList(),
                        ).animate().fadeIn(delay: 80.ms),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
