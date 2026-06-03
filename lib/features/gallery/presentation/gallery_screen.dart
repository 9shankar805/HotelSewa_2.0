import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class GalleryScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const GalleryScreen({Key? key, this.arguments}) : super(key: key);

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  List<Map<String, dynamic>> _images = [];
  bool _loading = true;
  String _selectedCategory = 'All';
  int _selectedIndex = 0;
  bool _showViewer = false;

  final _categories = ['All', 'Exterior', 'Rooms', 'Restaurant', 'Pool', 'Lobby'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Use passed images first
    final passedImages = widget.arguments?['hotelImages'] as List?;
    if (passedImages != null && passedImages.isNotEmpty) {
      setState(() {
        _images = passedImages.map<Map<String, dynamic>>((img) => {
          'url': img is Map ? (img['url'] ?? img['uri'] ?? img.toString()) : img.toString(),
          'category': img is Map ? (img['category'] ?? img['type'] ?? 'Exterior') : 'Exterior',
        }).toList();
        _loading = false;
      });
      return;
    }

    // Fetch from API
    final hotelId = widget.arguments?['hotelId']?.toString();
    if (hotelId != null) {
      try {
        final response = await ApiService.get(
          ApiConfig.buildPath(ApiConfig.hotelGalleryEndpoint, '$hotelId/gallery'),
        );
        if (response['success'] == true) {
          final raw = response['data'];
          List imgs = raw is List ? raw : (raw is Map ? (raw['images'] ?? raw['data'] ?? []) : []);
          setState(() {
            _images = imgs.map<Map<String, dynamic>>((img) => {
              'url': img is Map ? (img['url'] ?? img['uri'] ?? '') : img.toString(),
              'category': img is Map ? (img['category'] ?? img['type'] ?? 'Exterior') : 'Exterior',
            }).where((img) => img['url'].toString().isNotEmpty).toList();
          });
        }
      } catch (_) {}
    }
    setState(() => _loading = false);
  }

  List<Map<String, dynamic>> get _filtered => _selectedCategory == 'All'
      ? _images
      : _images.where((img) => img['category'].toString().toLowerCase() == _selectedCategory.toLowerCase()).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(widget.arguments?['hotelName'] ?? 'Gallery', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white)),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                // Category filter
                Container(
                  color: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: SizedBox(
                    height: 36,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _categories.length,
                      itemBuilder: (_, i) {
                        final cat = _categories[i];
                        final sel = _selectedCategory == cat;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedCategory = cat),
                          child: Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: sel ? AppColors.primary : Colors.white.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: sel ? AppColors.primary : Colors.white.withOpacity(0.2)),
                            ),
                            child: Center(child: Text(cat, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: sel ? Colors.white : Colors.white70))),
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // Grid
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                          const Icon(Icons.photo_library_outlined, size: 48, color: Colors.white30),
                          const SizedBox(height: 12),
                          Text('No $_selectedCategory photos', style: const TextStyle(color: Colors.white54, fontSize: 14)),
                        ]))
                      : GridView.builder(
                          padding: const EdgeInsets.all(2),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3, crossAxisSpacing: 2, mainAxisSpacing: 2,
                          ),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => GestureDetector(
                            onTap: () => setState(() { _selectedIndex = i; _showViewer = true; }),
                            child: CachedNetworkImage(
                              imageUrl: _filtered[i]['url'],
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(color: Colors.white10),
                              errorWidget: (_, __, ___) => Container(color: Colors.white10, child: const Icon(Icons.broken_image_outlined, color: Colors.white30)),
                            ).animate(delay: (i * 20).ms).fadeIn(),
                          ),
                        ),
                ),
              ],
            ),

      // Full-screen viewer
      bottomSheet: _showViewer && _filtered.isNotEmpty
          ? GestureDetector(
              onTap: () => setState(() => _showViewer = false),
              child: Container(
                color: Colors.black.withOpacity(0.95),
                height: MediaQuery.of(context).size.height * 0.6,
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: PageController(initialPage: _selectedIndex),
                      onPageChanged: (i) => setState(() => _selectedIndex = i),
                      itemCount: _filtered.length,
                      itemBuilder: (_, i) => CachedNetworkImage(
                        imageUrl: _filtered[i]['url'],
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, color: Colors.white30, size: 48),
                      ),
                    ),
                    Positioned(
                      top: 12, right: 12,
                      child: GestureDetector(
                        onTap: () => setState(() => _showViewer = false),
                        child: Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(color: AppColors.gray, shape: BoxShape.circle),
                          child: const Icon(Icons.close_rounded, color: Colors.white, size: 18),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 12, left: 0, right: 0,
                      child: Center(child: Text('${_selectedIndex + 1} / ${_filtered.length}', style: const TextStyle(color: Colors.white70, fontSize: 13))),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
