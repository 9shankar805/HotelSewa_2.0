import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';
import '../../../../core/constants/api_config.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});
  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _loading = true;
  Map<String, dynamic> _summary = {};
  List<Map<String, dynamic>> _bookingReport = [];
  List<Map<String, dynamic>> _revenueReport = [];
  String _period = 'month';
  String? _token;

  static const _periods = [('week', 'This Week'), ('month', 'This Month'), ('year', 'This Year')];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _load();
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      _token = prefs.getString('authToken');
      final resp = await ApiService.get(ApiConfig.ownerReportsEndpoint, token: _token, queryParams: {'period': _period});
      if (resp['success'] == true) {
        final data = resp['data'] ?? {};
        setState(() {
          _summary = Map<String, dynamic>.from(data['summary'] ?? data);
          _bookingReport = List<Map<String, dynamic>>.from(data['bookings'] ?? []);
          _revenueReport = List<Map<String, dynamic>>.from(data['revenue'] ?? []);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _export(String type) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating report...'), behavior: SnackBarBehavior.floating));
      final resp = await ApiService.get(ApiConfig.ownerReportsEndpoint, token: _token, queryParams: {'period': _period, 'format': type, 'export': '1'});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(resp['success'] == true ? 'Report ready for download' : 'Export failed'),
          backgroundColor: resp['success'] == true ? AppColors.success : AppColors.error,
          behavior: SnackBarBehavior.floating,
        ));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0, foregroundColor: AppColors.darkGray,
        title: const Text('Reports', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download_rounded, color: AppColors.darkGray),
            onSelected: _export,
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'pdf', child: Text('Export PDF')),
              PopupMenuItem(value: 'csv', child: Text('Export CSV')),
              PopupMenuItem(value: 'excel', child: Text('Export Excel')),
            ],
          ),
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              indicatorColor: AppColors.primary,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.gray,
              labelStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
              tabs: const [Tab(text: 'Summary'), Tab(text: 'Bookings'), Tab(text: 'Revenue')],
            ),
          ),
        ),
      ),
      body: Column(children: [
        // Period selector
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(children: _periods.map((p) {
            final sel = _period == p.$1;
            return GestureDetector(
              onTap: () { setState(() => _period = p.$1); _load(); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(color: sel ? AppColors.primary : const Color(0xFFF5F6FA), borderRadius: BorderRadius.circular(20)),
                child: Text(p.$2, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: sel ? Colors.white : AppColors.gray)),
              ),
            );
          }).toList()),
        ),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : TabBarView(controller: _tabController, children: [
                  _buildSummaryTab(),
                  _buildBookingsTab(),
                  _buildRevenueTab(),
                ]),
        ),
      ]),
    );
  }

  Widget _buildSummaryTab() {
    final totalRev = (_summary['total_revenue'] ?? _summary['revenue'] ?? 0).toDouble();
    final totalBook = (_summary['total_bookings'] ?? _summary['bookings'] ?? 0) as int;
    final occupancy = (_summary['occupancy_rate'] ?? _summary['occupancy'] ?? 0).toDouble();
    final adr = (_summary['adr'] ?? _summary['avg_room_rate'] ?? 0).toDouble();
    final cancelled = (_summary['cancelled_bookings'] ?? 0) as int;
    final newGuests = (_summary['new_guests'] ?? 0) as int;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(children: [
        _kpiGrid([
          _KPI('Total Revenue', 'NPR ${_fmt(totalRev)}', Icons.account_balance_wallet_rounded, AppColors.success, AppColors.successLight),
          _KPI('Total Bookings', '$totalBook', Icons.calendar_today_rounded, AppColors.primary, AppColors.infoLight),
          _KPI('Occupancy Rate', '${occupancy.toStringAsFixed(1)}%', Icons.hotel_rounded, AppColors.warning, AppColors.warningLight),
          _KPI('Avg Room Rate', 'NPR ${_fmt(adr)}', Icons.price_change_rounded, AppColors.purple, AppColors.purpleLight),
          _KPI('Cancellations', '$cancelled', Icons.cancel_outlined, AppColors.error, AppColors.errorLight),
          _KPI('New Guests', '$newGuests', Icons.people_rounded, AppColors.info, AppColors.infoLight),
        ]),
        const SizedBox(height: 16),
        _sectionCard('Performance Highlights', Column(children: [
          _highlightRow('Revenue per Available Room', 'NPR ${_fmt(totalRev / 30)}', AppColors.success),
          _highlightRow('Avg Booking Value', totalBook > 0 ? 'NPR ${_fmt(totalRev / totalBook)}' : '–', AppColors.primary),
          _highlightRow('Cancellation Rate', totalBook > 0 ? '${(cancelled / totalBook * 100).toStringAsFixed(1)}%' : '0%', AppColors.error),
        ])),
      ]),
    );
  }

  Widget _buildBookingsTab() => _reportListTab(
    _bookingReport,
    emptyMsg: 'No booking data for this period',
    rowBuilder: (item) => [
      item['confirmation_number']?.toString() ?? item['id']?.toString() ?? '–',
      item['guest_name']?.toString() ?? '–',
      item['room_type']?.toString() ?? '–',
      'NPR ${_fmt((item['total_amount'] ?? 0).toDouble())}',
      _statusBadge(item['status']?.toString() ?? '–'),
    ],
    headers: const ['ID', 'Guest', 'Room', 'Amount', 'Status'],
  );

  Widget _buildRevenueTab() => _reportListTab(
    _revenueReport,
    emptyMsg: 'No revenue data for this period',
    rowBuilder: (item) => [
      item['date']?.toString() ?? '–',
      item['room_type']?.toString() ?? '–',
      '${item['bookings'] ?? 0}',
      'NPR ${_fmt((item['revenue'] ?? 0).toDouble())}',
      '${item['occupancy'] ?? 0}%',
    ],
    headers: const ['Date', 'Room', 'Bookings', 'Revenue', 'Occ.'],
  );

  Widget _reportListTab(List<Map<String, dynamic>> data, {required String emptyMsg, required List<dynamic> Function(Map<String, dynamic>) rowBuilder, required List<String> headers}) {
    if (data.isEmpty) return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      const Icon(Icons.bar_chart_rounded, size: 64, color: AppColors.placeholder),
      const SizedBox(height: 16),
      Text(emptyMsg, style: const TextStyle(fontSize: 15, color: AppColors.gray)),
    ]));
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      scrollDirection: Axis.vertical,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
          child: DataTable(
            headingRowColor: MaterialStateProperty.all(const Color(0xFFF5F6FA)),
            columns: headers.map((h) => DataColumn(label: Text(h, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.darkGray)))).toList(),
            rows: data.map((item) {
              final cells = rowBuilder(item);
              return DataRow(cells: cells.map((c) => DataCell(c is Widget ? c : Text(c.toString(), style: const TextStyle(fontSize: 12, color: AppColors.darkGray)))).toList());
            }).toList(),
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    final colors = {
      'confirmed': AppColors.success, 'completed': AppColors.info,
      'cancelled': AppColors.error, 'pending': AppColors.warning,
    };
    final color = colors[status.toLowerCase()] ?? AppColors.gray;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
      child: Text(status, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  Widget _kpiGrid(List<_KPI> kpis) => GridView.count(
    crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
    childAspectRatio: 1.5, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
    children: kpis.map((k) => Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(10)), child: Icon(k.icon, size: 18, color: k.color)),
        const Spacer(),
        Text(k.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.darkGray)),
        Text(k.label, style: const TextStyle(fontSize: 11, color: AppColors.gray, fontWeight: FontWeight.w500)),
      ]),
    )).toList(),
  );

  Widget _sectionCard(String title, Widget child) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))]),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
      const SizedBox(height: 14),
      child,
    ]),
  );

  Widget _highlightRow(String label, String value, Color color) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
      Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: color)),
    ]),
  );

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }
}

class _KPI {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _KPI(this.label, this.value, this.icon, this.color, this.bg);
}
