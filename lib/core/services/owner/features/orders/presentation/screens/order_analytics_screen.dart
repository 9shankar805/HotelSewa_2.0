import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../../core/services/ordering_service.dart';
import '../../../../../../../core/constants/app_colors.dart';

class OrderAnalyticsScreen extends StatefulWidget {
  const OrderAnalyticsScreen({Key? key}) : super(key: key);

  @override
  State<OrderAnalyticsScreen> createState() => _OrderAnalyticsScreenState();
}

class _OrderAnalyticsScreenState extends State<OrderAnalyticsScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _analytics;
  int _selectedDays = 30;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken') ?? prefs.getString('auth_token');

      if (token == null) {
        _showError('Please login first');
        return;
      }

      final response = await OrderingService.getOrderAnalytics(
        token: token,
        days: _selectedDays,
      );

      if (response['status'] == true) {
        setState(() {
          _analytics = response['data'];
          _isLoading = false;
        });
      } else {
        _showError(response['message'] ?? 'Failed to load analytics');
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError('Error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Analytics'),
        actions: [
          PopupMenuButton<int>(
            initialValue: _selectedDays,
            onSelected: (days) {
              setState(() => _selectedDays = days);
              _loadAnalytics();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 7, child: Text('Last 7 days')),
              const PopupMenuItem(value: 30, child: Text('Last 30 days')),
              const PopupMenuItem(value: 90, child: Text('Last 90 days')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _analytics == null
              ? const Center(child: Text('No data available'))
              : _buildAnalytics(),
    );
  }

  Widget _buildAnalytics() {
    final stats = _analytics!['stats'] as Map<String, dynamic>;
    final topItems = _analytics!['top_items'] as List<dynamic>;
    final dailyRevenue = _analytics!['daily_revenue'] as List<dynamic>;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildStatsGrid(stats),
        const SizedBox(height: 24),
        _buildTopItems(topItems),
        const SizedBox(height: 24),
        _buildRevenueChart(dailyRevenue),
      ],
    );
  }

  Widget _buildStatsGrid(Map<String, dynamic> stats) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        _buildStatCard(
          'Total Orders',
          stats['total_orders'].toString(),
          Icons.receipt_long,
          AppColors.info,
        ),
        _buildStatCard(
          'Delivered',
          stats['delivered'].toString(),
          Icons.check_circle,
          AppColors.success,
        ),
        _buildStatCard(
          'Total Revenue',
          'NPR ${stats['total_revenue']}',
          Icons.attach_money,
          AppColors.warning,
        ),
        _buildStatCard(
          'Avg Order Value',
          'NPR ${stats['avg_order_value'].toStringAsFixed(2)}',
          Icons.trending_up,
          Colors.purple,
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            Text(
              title,
              style: TextStyle(fontSize: 12, color: AppColors.gray[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopItems(List<dynamic> items) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Top Selling Items',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...items.take(5).map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['item_name'],
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                            Text(
                              '${item['total_qty']} sold',
                              style: TextStyle(fontSize: 12, color: AppColors.gray[600]),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        'NPR ${item['revenue']}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildRevenueChart(List<dynamic> data) {
    if (data.isEmpty) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Daily Revenue',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(show: false),
                  titlesData: FlTitlesData(show: false),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: data
                          .asMap()
                          .entries
                          .map((e) => FlSpot(
                                e.key.toDouble(),
                                (e.value['revenue'] as num).toDouble(),
                              ))
                          .toList(),
                      isCurved: true,
                      color: AppColors.info,
                      barWidth: 3,
                      dotData: FlDotData(show: false),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
