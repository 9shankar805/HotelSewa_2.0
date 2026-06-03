import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/shared/api_service.dart';

class RevenueDashboardScreen extends StatefulWidget {
  const RevenueDashboardScreen({Key? key}) : super(key: key);

  @override
  State<RevenueDashboardScreen> createState() => _RevenueDashboardScreenState();
}

class _RevenueDashboardScreenState extends State<RevenueDashboardScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get('/revenue/dashboard', token: token);
      if (response['success'] == true) {
        final data = response['data'];
        _data = data is Map ? Map<String, dynamic>.from(data) : {};
      } else {
        _error = response['message'] ?? 'Failed to load revenue data';
      }
      setState(() => _loading = false);
    } catch (e) {
      setState(() { _error = 'Failed to load revenue dashboard'; _loading = false; });
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
        title: const Text('Revenue Management', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded, color: AppColors.darkGray), onPressed: _load),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.primary,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        _buildKpiRow(),
                        const SizedBox(height: 16),
                        _buildRevenueChart(),
                        const SizedBox(height: 16),
                        _buildOccupancyCard(),
                        const SizedBox(height: 16),
                        _buildForecastCard(),
                        const SizedBox(height: 80),
                      ],
                    ),
                  ),
                ),
    );
  }

  Widget _buildKpiRow() {
    final kpis = [
      {'label': 'RevPAR', 'value': 'NPR ${_data['revpar'] ?? 0}', 'icon': Icons.trending_up_rounded, 'color': AppColors.primary},
      {'label': 'ADR', 'value': 'NPR ${_data['adr'] ?? 0}', 'icon': Icons.hotel_rounded, 'color': AppColors.info},
      {'label': 'Occupancy', 'value': '${_data['occupancy_rate'] ?? 0}%', 'icon': Icons.people_rounded, 'color': AppColors.success},
    ];
    return Row(
      children: kpis.map((kpi) => Expanded(
        child: Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppColors.cardShadow),
          child: Column(
            children: [
              Container(width: 40, height: 40, decoration: BoxDecoration(color: (kpi['color'] as Color).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                child: Icon(kpi['icon'] as IconData, color: kpi['color'] as Color, size: 20)),
              const SizedBox(height: 8),
              Text(kpi['value'] as String, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
              Text(kpi['label'] as String, style: const TextStyle(fontSize: 10, color: AppColors.gray)),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildRevenueChart() {
    final snapshots = List<Map<String, dynamic>>.from(_data['snapshots'] ?? []);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Revenue Trend', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 20),
          SizedBox(
            height: 160,
            child: snapshots.isEmpty
                ? const Center(child: Text('No data available', style: TextStyle(color: AppColors.gray)))
                : LineChart(
                    LineChartData(
                      gridData: FlGridData(show: false),
                      titlesData: FlTitlesData(show: false),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: snapshots.asMap().entries.map((e) => FlSpot(e.key.toDouble(), (e.value['revenue'] as num?)?.toDouble() ?? 0)).toList(),
                          isCurved: true,
                          color: AppColors.primary,
                          barWidth: 3,
                          dotData: FlDotData(show: false),
                          belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                        ),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyCard() {
    final occupancy = (_data['occupancy_rate'] as num?)?.toDouble() ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Occupancy Rate', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
          const SizedBox(height: 16),
          Row(
            children: [
              SizedBox(
                width: 80, height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(value: occupancy / 100, strokeWidth: 8, backgroundColor: AppColors.lightGray, color: AppColors.success),
                    Text('${occupancy.toInt()}%', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.darkGray)),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _occupancyRow('Occupied', '${_data['occupied_rooms'] ?? 0}', AppColors.error),
                const SizedBox(height: 8),
                _occupancyRow('Available', '${_data['available_rooms'] ?? 0}', AppColors.success),
                const SizedBox(height: 8),
                _occupancyRow('Total', '${_data['total_rooms'] ?? 0}', AppColors.gray),
              ])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _occupancyRow(String label, String value, Color color) {
    return Row(children: [
      Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
      const SizedBox(width: 8),
      Text(label, style: const TextStyle(fontSize: 13, color: AppColors.gray)),
      const Spacer(),
      Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: color)),
    ]);
  }

  Widget _buildForecastCard() {
    final forecast = _data['forecast'];
    if (forecast == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [Color(0xFF667EEA), Color(0xFF764BA2)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(children: [
            Icon(Icons.auto_graph_rounded, color: Colors.white, size: 20),
            SizedBox(width: 8),
            Text('Revenue Forecast', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white)),
          ]),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _forecastItem('Next 7 Days', 'NPR ${forecast['next_7_days'] ?? 0}'),
              _forecastItem('Next 30 Days', 'NPR ${forecast['next_30_days'] ?? 0}'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _forecastItem(String label, String value) {
    return Column(children: [
      Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 11, color: Colors.white70)),
    ]);
  }

  Widget _buildError() {
    return Center(child: Padding(padding: const EdgeInsets.all(32), child: Column(mainAxisSize: MainAxisSize.min, children: [
      const Icon(Icons.error_outline_rounded, size: 56, color: AppColors.placeholder),
      const SizedBox(height: 16),
      Text(_error!, style: const TextStyle(fontSize: 15, color: AppColors.gray), textAlign: TextAlign.center),
      const SizedBox(height: 24),
      ElevatedButton(onPressed: _load, style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        child: const Text('Retry', style: TextStyle(color: Colors.white))),
    ])));
  }
}
