import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../hotel/presentation/services/hotel_service.dart';
import '../services/gallery_service.dart';
import 'video_tour_screen.dart';
import '../../../../../../../core/constants/app_colors.dart';

class _PhotoCategory {
  final String id;
  final String name;
  final IconData icon;
  const _PhotoCategory({required this.id, required this.name, required this.icon});
}

const _photoCategories = [
  _PhotoCategory(id: 'all', name: 'All Photos', icon: Icons.photo_library),
  _PhotoCategory(id: 'exterior', name: 'Exterior', icon: Icons.apartment),
  _PhotoCategory(id: 'rooms', name: 'Rooms', icon: Icons.bed),
  _PhotoCategory(id: 'restaurant', name: 'Restaurant', icon: Icons.restaurant),
  _PhotoCategory(id: 'pool', name: 'Pool', icon: Icons.pool),
  _PhotoCategory(id: 'common', name: 'Common Areas', icon: Icons.chair),
];

class GalleryManagementScreen extends StatefulWidget {
  const GalleryManagementScreen({super.key});
  @override
  State<GalleryManagementScreen> createState() => _GalleryManagementScreenState();
}

class _GalleryManagementScreenState extends State<GalleryManagementScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _photos = [];
  String? _hotelId;
  String _selectedCategory = 'all';
  final Set<int> _selectedForDelete = {};
  bool _isDeleteMode = false;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _isLoading = true);
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        GalleryService.setToken(token);
        HotelService.setToken(token);
        
        // Get hotel ID first
        final hotelService = HotelService();
        final hotelResponse = await hotelService.getHotelStatus();
        if (hotelResponse['success'] == true && hotelResponse['data'] != null) {
          _hotelId = hotelResponse['data']['id']?.toString();
        }
        
        // Use the media endpoint instead
        final mediaData = await GalleryService.getMedia();
        
        final List<Map<String, dynamic>> photosList = [];
        
        // Handle images from media endpoint
        if (mediaData['images'] != null) {
          final images = mediaData['images'];
          if (images is List) {
            for (var i = 0; i < images.length; i++) {
              final img = images[i];
              photosList.add({
                'url': img['url'] ?? img['path'] ?? img.toString(),
                'category': _assignCategory(i),
                'index': i,
                'id': img['id'],
              });
            }
          }
        }
        
        _photos = photosList;
      }
    } catch (e) {
      debugPrint('Gallery load error: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  String _assignCategory(int index) {
    const cats = ['exterior', 'rooms', 'restaurant', 'pool', 'common'];
    return cats[index % cats.length];
  }

  List<Map<String, dynamic>> get _filtered =>
      _selectedCategory == 'all' ? _photos : _photos.where((p) => p['category'] == _selectedCategory).toList();

  int _countFor(String catId) => catId == 'all' ? _photos.length : _photos.where((p) => p['category'] == catId).length;

  void _toggleDeleteMode() => setState(() { _isDeleteMode = !_isDeleteMode; _selectedForDelete.clear(); });

  void _deleteSelected() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Photos', style: TextStyle(fontWeight: FontWeight.w700)),
        content: Text('Delete ${_selectedForDelete.length} selected photo(s)?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() { _photos.removeWhere((p) => _selectedForDelete.contains(p['index'])); _selectedForDelete.clear(); _isDeleteMode = false; });
            },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.errorRed), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickAndUploadPhotos() async {
    try {
      // Check if hotel ID is available
      if (_hotelId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Hotel ID not found. Please try again.'),
              backgroundColor: Color(AppConstants.errorRed),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      // Pick multiple images
      final List<XFile> pickedFiles = await _picker.pickMultiImage(
        imageQuality: 85,
      );

      if (pickedFiles.isEmpty) return;

      setState(() => _isUploading = true);

      // Convert XFile to File
      final List<File> imageFiles = pickedFiles.map((xFile) => File(xFile.path)).toList();

      // Upload images with hotel_id
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      if (token != null) {
        GalleryService.setToken(token);
        await GalleryService.uploadImages(imageFiles, hotelId: _hotelId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${imageFiles.length} photo(s) uploaded successfully'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
          // Reload gallery
          await _load();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Upload failed: ${e.toString()}'),
            backgroundColor: const Color(AppConstants.errorRed),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: Colors.black,
        title: const Text('Photo Gallery', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [
          IconButton(icon: const Icon(Icons.videocam_rounded, color: Colors.black), onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const VideoTourScreen())), tooltip: 'Video Tour'),
          if (!_isLoading && _photos.isNotEmpty) ...[
            if (_isDeleteMode && _selectedForDelete.isNotEmpty)
              TextButton(
                onPressed: _deleteSelected,
                child: Text('Delete (${_selectedForDelete.length})', style: const TextStyle(color: Color(AppConstants.errorRed), fontWeight: FontWeight.w600)),
              ),
            IconButton(icon: Icon(_isDeleteMode ? Icons.close : Icons.edit_outlined, color: Colors.black), onPressed: _toggleDeleteMode),
          ],
        ],
      ),
      floatingActionButton: _isLoading ? null : FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUploadPhotos,
        backgroundColor: _isUploading ? AppColors.gray : const Color(AppConstants.primaryRed),
        icon: _isUploading 
            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Icon(Icons.add_a_photo, color: Colors.white),
        label: Text(
          _isUploading ? 'Uploading...' : 'Add Photo',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
      ),
      body: _isLoading
          ? _buildSkeleton()
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(AppConstants.primaryRed),
              child: Column(
                children: [
                  _buildCategoryTabs(isDark, cardColor),
                  Expanded(child: _filtered.isEmpty ? _buildEmpty(isDark) : _buildGrid(isDark)),
                ],
              ),
            ),
    );
  }

  Widget _buildCategoryTabs(bool isDark, Color cardColor) {
    return Container(
      color: cardColor,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _photoCategories.map((cat) {
            final isSelected = _selectedCategory == cat.id;
            final count = _countFor(cat.id);
            return GestureDetector(
              onTap: () => setState(() => _selectedCategory = cat.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.only(right: 10),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(AppConstants.primaryRed) : (isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray)),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 14, color: isSelected ? Colors.white : const Color(AppConstants.mediumGray)),
                    const SizedBox(width: 6),
                    Text(cat.name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isSelected ? Colors.white : const Color(AppConstants.mediumGray))),
                    if (count > 0) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: isSelected ? Colors.white.withOpacity(0.3) : const Color(AppConstants.mediumGray).withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                        child: Text('$count', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : const Color(AppConstants.mediumGray))),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildGrid(bool isDark) {
    final photos = _filtered;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
      itemCount: photos.length,
      itemBuilder: (context, index) {
        final photo = photos[index];
        final photoIndex = photo['index'] as int;
        final isSelected = _selectedForDelete.contains(photoIndex);
        return GestureDetector(
          onTap: () {
            if (_isDeleteMode) setState(() { if (isSelected) _selectedForDelete.remove(photoIndex); else _selectedForDelete.add(photoIndex); });
          },
          onLongPress: () {
            if (!_isDeleteMode) setState(() { _isDeleteMode = true; _selectedForDelete.add(photoIndex); });
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Stack(
              fit: StackFit.expand,
              children: [
                photo['url'].toString().startsWith('http')
                    ? Image.network(photo['url'], fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray), child: const Icon(Icons.broken_image, color: Color(AppConstants.mediumGray))))
                    : Container(color: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray), child: const Icon(Icons.image, color: Color(AppConstants.mediumGray))),
                if (_isDeleteMode)
                  Container(
                    color: isSelected ? Colors.black.withOpacity(0.5) : Colors.transparent,
                    child: isSelected ? const Center(child: Icon(Icons.check_circle, color: Colors.white, size: 28)) : null,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100, height: 100,
            decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray), shape: BoxShape.circle),
            child: const Icon(Icons.photo_library_outlined, size: 48, color: Color(AppConstants.mediumGray)),
          ),
          const SizedBox(height: 20),
          Text('No photos yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
          const SizedBox(height: 8),
          const Text('Add photos to showcase your property\nto potential guests', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Color(AppConstants.mediumGray))),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickAndUploadPhotos,
            icon: _isUploading 
                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.add_a_photo, size: 18),
            label: Text(_isUploading ? 'Uploading...' : 'Add First Photo'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _isUploading ? AppColors.gray : const Color(AppConstants.primaryRed),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return Column(
      children: [
        Container(
          height: 56, color: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: ListView.builder(
            scrollDirection: Axis.horizontal, itemCount: 5,
            itemBuilder: (_, __) => const Padding(padding: EdgeInsets.only(right: 10), child: SkeletonLoader(width: 90, height: 36, borderRadius: 20)),
          ),
        ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 8, mainAxisSpacing: 8),
            itemCount: 12,
            itemBuilder: (_, __) => const SkeletonLoader(height: double.infinity, borderRadius: 10),
          ),
        ),
      ],
    );
  }
}
