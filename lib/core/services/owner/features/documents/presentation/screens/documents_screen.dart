import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/documents_service.dart';

class _DocCategory {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  const _DocCategory({required this.id, required this.name, required this.icon, required this.description});
}

const _categories = [
  _DocCategory(id: 'identity', name: 'Identity Proof', icon: Icons.badge, description: 'Passport, Aadhaar, PAN Card'),
  _DocCategory(id: 'license', name: 'Hotel License', icon: Icons.business, description: 'Trade license, Registration'),
  _DocCategory(id: 'tax', name: 'Tax Documents', icon: Icons.receipt_long, description: 'GST certificate, Tax returns'),
  _DocCategory(id: 'insurance', name: 'Insurance', icon: Icons.shield, description: 'Property & liability insurance'),
  _DocCategory(id: 'other', name: 'Other Documents', icon: Icons.folder, description: 'Any other relevant documents'),
];

class DocumentsScreen extends StatefulWidget {
  const DocumentsScreen({super.key});
  @override
  State<DocumentsScreen> createState() => _DocumentsScreenState();
}

class _DocumentsScreenState extends State<DocumentsScreen> {
  final DocumentsService _service = DocumentsService();
  List<Map<String, dynamic>> _documents = [];
  bool _isLoading = true;

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
        DocumentsService.setToken(token);
        _documents = await _service.getDocuments();
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  String _statusFor(String catId) {
    final doc = _documents.firstWhere(
      (d) => (d['type'] ?? d['category'] ?? '').toString().toLowerCase() == catId,
      orElse: () => {},
    );
    if (doc.isEmpty) return 'missing';
    return (doc['status'] ?? 'pending').toString().toLowerCase();
  }

  int get _verifiedCount => _categories.where((c) {
    final s = _statusFor(c.id);
    return s == 'verified' || s == 'approved';
  }).length;

  Future<void> _upload(String catId, String catName) async {
    try {
      await _service.uploadDocument({'name': catName, 'type': catId});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('$catName uploaded successfully'),
          backgroundColor: const Color(AppConstants.successGreen),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
        _load();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Upload failed: ${e.toString()}'),
          backgroundColor: const Color(AppConstants.errorRed),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ));
      }
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
        title: const Text('Documents', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w700, fontSize: 18)),
        actions: [IconButton(icon: const Icon(Icons.refresh, color: Colors.black), onPressed: _load)],
      ),
      body: _isLoading
          ? _buildSkeleton()
          : RefreshIndicator(
              onRefresh: _load,
              color: const Color(AppConstants.primaryRed),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildProgress(isDark, cardColor, borderColor),
                    const SizedBox(height: 20),
                    Text('Document Categories', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 12),
                    ..._categories.map((c) => _buildDocCard(c, isDark, cardColor, borderColor)),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildProgress(bool isDark, Color cardColor, Color borderColor) {
    final total = _categories.length;
    final verified = _verifiedCount;
    final progress = total > 0 ? verified / total : 0.0;
    final progressColor = progress == 1.0 ? const Color(AppConstants.successGreen) : const Color(AppConstants.warningOrange);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: const Color(AppConstants.successGreen).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.verified_user, color: Color(AppConstants.successGreen), size: 22),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verification Progress', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                    const SizedBox(height: 2),
                    Text('$verified of $total documents verified', style: const TextStyle(fontSize: 13, color: Color(AppConstants.mediumGray))),
                  ],
                ),
              ),
              Text('${(progress * 100).toInt()}%', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: progressColor)),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress, minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocCard(_DocCategory cat, bool isDark, Color cardColor, Color borderColor) {
    final status = _statusFor(cat.id);
    final cfg = _statusConfig(status);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: cardColor, borderRadius: BorderRadius.circular(16), border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(color: (cfg['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(cat.icon, color: cfg['color'] as Color, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cat.name, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 3),
                Text(cat.description, style: const TextStyle(fontSize: 12, color: Color(AppConstants.mediumGray))),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: (cfg['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(cfg['icon'] as IconData, size: 12, color: cfg['color'] as Color),
                      const SizedBox(width: 4),
                      Text(cfg['label'] as String, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: cfg['color'] as Color)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _upload(cat.id, cat.name),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(color: const Color(AppConstants.primaryRed).withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.cloud_upload_outlined, color: Color(AppConstants.primaryRed), size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'verified':
      case 'approved':
        return {'color': const Color(AppConstants.successGreen), 'label': 'Verified', 'icon': Icons.check_circle};
      case 'pending':
        return {'color': const Color(AppConstants.warningOrange), 'label': 'Pending Review', 'icon': Icons.schedule};
      case 'rejected':
        return {'color': const Color(AppConstants.errorRed), 'label': 'Rejected', 'icon': Icons.cancel};
      default:
        return {'color': const Color(AppConstants.mediumGray), 'label': 'Not Uploaded', 'icon': Icons.upload_file};
    }
  }

  Widget _buildSkeleton() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SkeletonLoader(height: 110, borderRadius: 16),
          const SizedBox(height: 20),
          const SkeletonLoader(width: 160, height: 16, borderRadius: 8),
          const SizedBox(height: 12),
          ...List.generate(5, (_) => const Padding(padding: EdgeInsets.only(bottom: 12), child: SkeletonLoader(height: 100, borderRadius: 16))),
        ],
      ),
    );
  }
}
