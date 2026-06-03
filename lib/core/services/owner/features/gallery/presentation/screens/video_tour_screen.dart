import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../../../../../core/constants/app_colors.dart';

class VideoTourScreen extends StatefulWidget {
  const VideoTourScreen({super.key});
  @override
  State<VideoTourScreen> createState() => _VideoTourScreenState();
}

class _VideoTourScreenState extends State<VideoTourScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _videos = [
    {'id': '1', 'title': 'Hotel Lobby Tour', 'duration': '1:24', 'size': '45 MB', 'thumbnail': null, 'uploaded': true, 'category': 'Lobby'},
    {'id': '2', 'title': 'Deluxe Room Walkthrough', 'duration': '2:10', 'size': '78 MB', 'thumbnail': null, 'uploaded': true, 'category': 'Rooms'},
    {'id': '3', 'title': 'Rooftop Restaurant', 'duration': '0:58', 'size': '32 MB', 'thumbnail': null, 'uploaded': false, 'category': 'Dining'},
  ];

  final _categories = ['All', 'Lobby', 'Rooms', 'Dining', 'Pool', 'Exterior'];
  String _selectedCategory = 'All';

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
      body: Column(
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
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.add_rounded, size: 16),
                  label: const Text('Add', style: TextStyle(fontSize: 13)),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryRed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
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
                      color: sel ? const Color(AppConstants.primaryRed) : card,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sel ? const Color(AppConstants.primaryRed) : border),
                    ),
                    child: Center(child: Text(_categories[i], style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: sel ? Colors.white : const Color(AppConstants.mediumGray)))),
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
              color: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(Icons.movie_rounded, size: 32, color: isDark ? Colors.white24 : Colors.black12),
                  Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: AppColors.gray, borderRadius: BorderRadius.circular(18)),
                    child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 22),
                  ),
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
                      Text(v['category'] as String, style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                      const Text(' • ', style: TextStyle(color: Color(AppConstants.mediumGray))),
                      Text(v['size'] as String, style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: (uploaded ? const Color(AppConstants.successGreen) : const Color(AppConstants.warningOrange)).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          uploaded ? 'Published' : 'Draft',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: uploaded ? const Color(AppConstants.successGreen) : const Color(AppConstants.warningOrange)),
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => setState(() => v['uploaded'] = !uploaded),
                        child: Icon(uploaded ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: const Color(AppConstants.mediumGray)),
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
            onPressed: _pickVideo,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Upload Video'),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryRed), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
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
            _sourceOption(Icons.videocam_rounded, 'Record Video', 'Use your camera to record a tour', const Color(AppConstants.primaryRed)),
            const SizedBox(height: 10),
            _sourceOption(Icons.photo_library_rounded, 'Choose from Gallery', 'Select an existing video', const Color(0xFF1890FF)),
            const SizedBox(height: 10),
            _sourceOption(Icons.link_rounded, 'Add YouTube/Vimeo Link', 'Paste a video URL', const Color(AppConstants.successGreen)),
            const SizedBox(height: 8),
            const Text('Max file size: 500 MB • Supported: MP4, MOV, AVI', style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
          ],
        ),
      ),
    );
  }

  Widget _sourceOption(IconData icon, String title, String subtitle, Color color) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _simulateUpload();
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
                  Text(subtitle, style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: color, size: 18),
          ],
        ),
      ),
    );
  }

  void _simulateUpload() {
    setState(() => _isLoading = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _videos.add({'id': '${_videos.length + 1}', 'title': 'New Video Tour', 'duration': '1:30', 'size': '55 MB', 'thumbnail': null, 'uploaded': false, 'category': _selectedCategory == 'All' ? 'Lobby' : _selectedCategory});
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Video uploaded successfully'), backgroundColor: Color(AppConstants.successGreen),
          behavior: SnackBarBehavior.floating,
        ));
      }
    });
  }

  void _deleteVideo(Map<String, dynamic> v) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Video?'),
        content: Text('Delete "${v['title']}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { Navigator.pop(context); setState(() => _videos.remove(v)); },
            style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.errorRed)),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
