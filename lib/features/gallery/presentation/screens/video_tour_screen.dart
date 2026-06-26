import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../features/hotel/presentation/services/hotel_service.dart';
import '../services/gallery_service.dart';

class VideoTourScreen extends StatefulWidget {
  const VideoTourScreen({super.key});
  @override
  State<VideoTourScreen> createState() => _VideoTourScreenState();
}

class _VideoTourScreenState extends State<VideoTourScreen> {
  bool _isLoading = false;
  bool _isUploading = false;
  List<Map<String, dynamic>> _videos = [];
  String? _hotelId;

  final _categories = ['All', 'Lobby', 'Rooms', 'Dining', 'Pool', 'Exterior'];
  String _selectedCategory = 'All';

  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadVideos();
  }

  Future<void> _loadVideos() async {
    setState(() => _isLoading = true);
    try {
      final token = await _getToken();
      if (token != null) {
        GalleryService.setToken(token);

        // Load hotel ID if not yet fetched
        if (_hotelId == null) {
          HotelService.setToken(token);
          final hotelResp = await HotelService().getHotelStatus();
          if (hotelResp['success'] == true && hotelResp['data'] != null) {
            _hotelId = hotelResp['data']['id']?.toString();
            debugPrint('[VideoTour] Hotel ID: $_hotelId');
          }
        }
        final mediaData = await GalleryService.getMedia();
        final List<Map<String, dynamic>> videosList = [];

        if (mediaData['videos'] != null) {
          final videos = mediaData['videos'];
          if (videos is List) {
            for (var i = 0; i < videos.length; i++) {
              final vid = videos[i];
              videosList.add({
                'id': vid['id']?.toString() ?? i.toString(),
                'title': vid['title'] ?? vid['name'] ?? 'Untitled Video',
                'duration': vid['duration'] ?? '0:00',
                'size': vid['size'] ?? '0 MB',
                'thumbnail': vid['thumbnail'] ?? vid['url'],
                'uploaded': vid['published'] ?? vid['uploaded'] ?? true,
                'category': vid['category'] ?? 'Lobby',
                'url': vid['url'],
              });
            }
          }
        }
        if (mounted) setState(() => _videos = videosList);
      }
    } catch (e) {
      debugPrint('Error loading videos: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('authToken');
  }

  List<Map<String, dynamic>> get _filtered => _selectedCategory == 'All'
      ? _videos
      : _videos.where((v) => v['category'] == _selectedCategory).toList();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      appBar: AppBar(title: const Text('Video & Virtual Tour')),
      body: _isLoading
          ? _buildSkeleton()
          : Column(
              children: [
                // Upload banner
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48, height: 48,
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.videocam_rounded, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Virtual Tour', style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
                            Text('Videos increase bookings by up to 40%', style: TextStyle(color: Colors.white60, fontSize: 11)),
                          ],
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _isUploading ? null : _pickVideo,
                        icon: const Icon(Icons.add_rounded, size: 16),
                        label: const Text('Add', style: TextStyle(fontSize: 13)),
                        style: ElevatedButton.styleFrom(backgroundColor: Color(AppConstants.primaryRed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
                      ),
                    ],
                  ),
                ),

                // Category filter
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    scrollDirection: Axis.horizontal,
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final sel = _selectedCategory == _categories[i];
                      return GestureDetector(
                        onTap: () => setState(() => _selectedCategory = _categories[i]),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: sel ? Color(AppConstants.primaryRed) : card,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: sel ? Color(AppConstants.primaryRed) : border),
                          ),
                          child: Center(child: Text(_categories[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : Color(AppConstants.mediumGray)))),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),

                // Video list
                Expanded(
                  child: _filtered.isEmpty
                      ? _emptyState(isDark)
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          itemCount: _filtered.length,
                          itemBuilder: (_, i) => _videoCard(_filtered[i], isDark, card, border),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, __) => SkeletonLoader(
        height: 104,
        borderRadius: 16,
      ),
    );
  }

  Widget _videoCard(Map<String, dynamic> v, bool isDark, Color card, Color border) {
    final uploaded = v['uploaded'] as bool;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
      child: Row(
        children: [
          // Thumbnail
          ClipRRect(
            borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
            child: Container(
              width: 100, height: 80,
              decoration: v['thumbnail']?.toString().startsWith('http') ?? false
                  ? BoxDecoration(
                      image: DecorationImage(
                        image: NetworkImage(v['thumbnail']!),
                        fit: BoxFit.cover,
                      ),
                    )
                  : BoxDecoration(
                      color: isDark ? const Color(0xFF2C2C2C) : Color(AppConstants.lightGray),
                    ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (!(v['thumbnail']?.toString().startsWith('http') ?? false))
                    Icon(Icons.movie_rounded, size: 32, color: isDark ? Colors.white24 : Colors.black12),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
                  if (v['duration'] != null)
                    Positioned(
                      bottom: 4, right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.gray, borderRadius: BorderRadius.circular(4)),
                        child: Text(v['duration'] as String, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                      ),
                    ),
                ],
              ),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v['title'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(v['category'] as String, style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                      const Text(' • ', style: TextStyle(color: Color(AppConstants.mediumGray))),
                      Text(v['size'] as String, style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (uploaded ? Color(AppConstants.successGreen) : Color(AppConstants.warningOrange)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          uploaded ? 'Published' : 'Draft',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: uploaded ? Color(AppConstants.successGreen) : Color(AppConstants.warningOrange)),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => _togglePublished(v),
                        child: Icon(uploaded ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Color(AppConstants.mediumGray)),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => _deleteVideo(v),
                        child: const Icon(Icons.delete_outline_rounded, size: 18, color: Color(AppConstants.errorRed)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.videocam_off_rounded, size: 64, color: AppColors.lightGray),
          const SizedBox(height: 16),
          Text('No videos in this category', style: TextStyle(fontSize: 16, color: AppColors.gray[400])),
          const SizedBox(height: 8),
          ElevatedButton.icon(
            onPressed: _isUploading ? null : _pickVideo,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Upload Video'),
            style: ElevatedButton.styleFrom(backgroundColor: Color(AppConstants.primaryRed), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
          ),
        ],
      ),
    );
  }

  void _pickVideo() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Add Video', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 16),
            _sourceOption(Icons.videocam_rounded, 'Record Video', 'Use your camera to record a tour', Color(AppConstants.primaryRed), ImageSource.camera),
            const SizedBox(height: 10),
            _sourceOption(Icons.photo_library_rounded, 'Choose from Gallery', 'Select an existing video', const Color(0xFF1890FF), ImageSource.gallery),
            const SizedBox(height: 10),
            _sourceOption(Icons.link_rounded, 'Add YouTube/Vimeo Link', 'Paste a video URL', Color(AppConstants.successGreen), null),
            const SizedBox(height: 8),
            const Text('Max file size: 500 MB • Supported: MP4, MOV, AVI', style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(IconData icon, String title, String subtitle, Color color, ImageSource? source) {
    return GestureDetector(
      onTap: () async {
        Navigator.pop(context);
        if (source != null) {
          await _pickAndUploadVideo(source);
        } else {
          await _addVideoLink();
        }
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: color)),
                  Text(subtitle, style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadVideo(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(source: source);
      if (pickedFile == null) return;

      if (_hotelId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Hotel ID not found. Please try again.'),
            backgroundColor: Color(AppConstants.errorRed),
            behavior: SnackBarBehavior.floating,
          ));
        }
        return;
      }

      setState(() => _isUploading = true);

      final token = await _getToken();
      if (token != null) {
        GalleryService.setToken(token);
        await GalleryService.uploadVideo(File(pickedFile.path), hotelId: _hotelId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Video uploaded successfully'),
            backgroundColor: Color(AppConstants.successGreen),
            behavior: SnackBarBehavior.floating,
          ));
          await _loadVideos();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: $e'),
          backgroundColor: Color(AppConstants.errorRed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  Future<void> _addVideoLink() async {
    final TextEditingController urlController = TextEditingController();
    bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Video Link'),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(hintText: 'Enter YouTube/Vimeo URL'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(AppConstants.primaryRed)),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    
    if (confirmed == true && urlController.text.trim().isNotEmpty) {
      try {
        if (_hotelId == null) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Hotel ID not found. Please try again.'),
            backgroundColor: Color(AppConstants.errorRed),
            behavior: SnackBarBehavior.floating,
          ));
          return;
        }
        setState(() => _isUploading = true);
        final token = await _getToken();
        if (token != null) {
          GalleryService.setToken(token);
          await GalleryService.addVideoLink(
            urlController.text.trim(),
            hotelId: _hotelId!,
          );
          
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Video link added successfully'),
              backgroundColor: Color(AppConstants.successGreen),
              behavior: SnackBarBehavior.floating,
            ));
            await _loadVideos();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to add link: $e'),
            backgroundColor: Color(AppConstants.errorRed),
            behavior: SnackBarBehavior.floating,
          ));
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }

  Future<void> _togglePublished(Map<String, dynamic> v) async {
    try {
      final token = await _getToken();
      if (token != null) {
        GalleryService.setToken(token);
        await GalleryService.updateMedia(
          v['id']!.toString(),
          {'published': !(v['uploaded'] as bool)},
        );
        
        if (mounted) {
          setState(() => v['uploaded'] = !v['uploaded']);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Failed to update video: $e'),
          backgroundColor: Color(AppConstants.errorRed),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  Future<void> _deleteVideo(Map<String, dynamic> v) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Video?'),
        content: Text('Delete "${v['title']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Color(AppConstants.errorRed)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        final token = await _getToken();
        if (token != null) {
          GalleryService.setToken(token);
          await GalleryService.deleteMedia(v['id']!.toString());
          
          if (mounted) {
            setState(() => _videos.removeWhere((vid) => vid['id'] == v['id']));
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text('Failed to delete video: $e'),
            backgroundColor: Color(AppConstants.errorRed),
            behavior: SnackBarBehavior.floating,
          ));
        }
      }
    }
  }
}
