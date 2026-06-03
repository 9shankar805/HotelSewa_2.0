import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/api_config.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class FlashSalesScreen extends StatefulWidget {
  const FlashSalesScreen({Key? key}) : super(key: key);

  @override
  State<FlashSalesScreen> createState() => _FlashSalesScreenState();
}

class _FlashSalesScreenState extends State<FlashSalesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _sales = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(
          ApiConfig.ownerFlashSalesEndpoint,
          token: token);
      if (response['success'] == true) {
        final data = response['data'];
        List raw = data is List
            ? data
            : (data is Map ? (data['data'] ?? data['sales'] ?? []) : []);
        setState(() {
          _sales = List<Map<String, dynamic>>.from(raw);
          _loading = false;
        });
      } else {
        setState(() {
          _error = response['message'] ?? 'Failed to load';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load flash sales';
        _loading = false;
      });
    }
  }

  Future<void> _delete(int id) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('authToken');
    await ApiService.delete(
        '${ApiConfig.ownerFlashSalesEndpoint}/$id',
        token: token);
    _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Flash Sales',
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(
              icon:
                  const Icon(Icons.add_rounded, color: AppColors.primary),
              onPressed: _showCreateDialog),
          IconButton(
              icon: const Icon(Icons.refresh_rounded,
                  color: AppColors.darkGray),
              onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: _sales.isEmpty
                      ? _buildEmpty()
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: _sales.length,
                          itemBuilder: (_, i) =>
                              _buildCard(_sales[i]),
                        ),
                ),
    );
  }

  Widget _buildCard(Map<String, dynamic> sale) {
    final discount = sale['discount_percentage'] ?? 0;
    final startsAt = sale['starts_at'] ?? '';
    final endsAt = sale['ends_at'] ?? '';
    final maxBookings = sale['max_bookings'] ?? 0;

    // Determine if active
    final now = DateTime.now();
    bool isActive = false;
    try {
      final start = DateTime.parse(startsAt);
      final end = DateTime.parse(endsAt);
      isActive = now.isAfter(start) && now.isBefore(end);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isActive
                    ? [const Color(0xFFE60023), const Color(0xFFFF4D6A)]
                    : [const Color(0xFF6B7280), const Color(0xFF9CA3AF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('$discount%',
                          style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: Colors.white)),
                      const Text('OFF',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white70,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'Room Type #${sale['room_type_id'] ?? ''}',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                      Text('Max $maxBookings bookings',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.white70)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20)),
                      child: Text(
                          isActive ? 'LIVE' : 'SCHEDULED',
                          style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                    const SizedBox(height: 4),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded,
                          color: Colors.white70, size: 20),
                      onPressed: () => _delete(sale['id']),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.schedule_rounded,
                    size: 14, color: AppColors.gray),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                      'Start: $startsAt\nEnd: $endsAt',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.gray,
                          height: 1.5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateDialog() {
    final roomTypeCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final startsCtrl = TextEditingController();
    final endsCtrl = TextEditingController();
    final maxCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.9,
        minChildSize: 0.5,
        builder: (_, scrollCtrl) => Container(
          decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24))),
          child: ListView(
            controller: scrollCtrl,
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.lightGray,
                      borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text('Create Flash Sale',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkGray)),
              const SizedBox(height: 16),
              _field('Room Type ID', roomTypeCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _field('Discount %', discountCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _field('Max Bookings', maxCtrl,
                  keyboardType: TextInputType.number),
              const SizedBox(height: 10),
              _field('Starts At (YYYY-MM-DDTHH:MM:SS)', startsCtrl),
              const SizedBox(height: 10),
              _field('Ends At (YYYY-MM-DDTHH:MM:SS)', endsCtrl),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final prefs =
                      await SharedPreferences.getInstance();
                  final token = prefs.getString('authToken');
                  await ApiService.post(
                    ApiConfig.ownerFlashSalesEndpoint,
                    data: {
                      'room_type_id':
                          int.tryParse(roomTypeCtrl.text) ?? 0,
                      'discount_percentage':
                          int.tryParse(discountCtrl.text) ?? 0,
                      'starts_at': startsCtrl.text,
                      'ends_at': endsCtrl.text,
                      'max_bookings':
                          int.tryParse(maxCtrl.text) ?? 5,
                    },
                    token: token,
                  );
                  _load();
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding:
                        const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                child: const Text('Create Flash Sale',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field(String hint, TextEditingController ctrl,
      {TextInputType? keyboardType}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.lightGray)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: AppColors.primary)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 56, color: AppColors.placeholder),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.gray),
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _load,
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12))),
              child: const Text('Retry',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                  color: AppColors.errorLight,
                  borderRadius: BorderRadius.circular(24)),
              child: const Icon(Icons.flash_on_rounded,
                  size: 40, color: AppColors.error),
            ),
            const SizedBox(height: 20),
            const Text('No Flash Sales',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkGray)),
            const SizedBox(height: 8),
            const Text(
                'Create time-limited flash sales to fill rooms quickly.',
                style: TextStyle(
                    fontSize: 14, color: AppColors.gray, height: 1.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
