import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/pricing_service.dart';

class CompetitorBenchmarkingScreen extends StatefulWidget {
  const CompetitorBenchmarkingScreen({super.key});
  @override
  State<CompetitorBenchmarkingScreen> createState() => _CompetitorBenchmarkingScreenState();
}

class _CompetitorBenchmarkingScreenState extends State<CompetitorBenchmarkingScreen> {
  bool _isLoading = true;
  String _selectedRoomType = 'Deluxe Room';
  final _roomTypes = ['Standard Room', 'Deluxe Room', 'Suite', 'Economy Room'];
  String? _error;

  double _myPrice = 0;
  double _avgCompetitor = 0;
  String _marketPosition = '';
  List<Map<String, dynamic>> _competitors = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final data = await PricingService.getCompetitorBenchmark(token: token);
      if (mounted) {
        setState(() {
          _myPrice = (data['my_avg_price'] as num?)?.toDouble() ?? 0;
          _avgCompetitor = (data['avg_competitor'] as num?)?.toDouble() ?? 0;
          _marketPosition = data['market_position']?.toString() ?? '';
          _competitors = List<Map<String, dynamic>>.from(data['competitors'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  double get _avgCompetitorPrice => _avgCompetitor > 0 ? _avgCompetitor
      : _competitors.isEmpty ? 0
      : _competitors.fold(0.0, (s, c) => s + ((c['price'] as num?)?.toDouble() ?? 0)) / _competitors.length;
  double get _minPrice => _competitors.isEmpty ? 0 : _competitors.map((c) => (c['price'] as num?)?.toDouble() ?? 0).reduce((a, b) => a < b ? a : b);
  double get _maxPrice => _competitors.isEmpty ? 0 : _competitors.map((c) => (c['price'] as num?)?.toDouble() ?? 0).reduce((a, b) => a > b ? a : b);
  int get _cheaperCount => _competitors.where((c) => ((c['price'] as num?)?.toDouble() ?? 0) < _myPrice).length;
  int get _pricierCount => _competitors.where((c) => ((c['price'] as num?)?.toDouble() ?? 0) > _myPrice).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Competitor Benchmarking'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: _load),
        ],
      ),
      body: _isLoading ? _skeleton() : _error != null ? Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.gray),
          const SizedBox(height: 12),
          Text(_error!, style: const TextStyle(color: AppColors.gray)),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: _load, child: const Text('Retry')),
        ]),
      ) : RefreshIndicator(
        onRefresh: _load,
        color: Color(AppConstants.primaryRed),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Room type selector
              SizedBox(
                height: 38,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _roomTypes.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final selected = _selectedRoomType == _roomTypes[i];
                    return GestureDetector(
                      onTap: () => setState(() => _selectedRoomType = _roomTypes[i]),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: selected ? Color(AppConstants.primaryRed) : card,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? Color(AppConstants.primaryRed) : border),
                        ),
                        child: Center(child: Text(_roomTypes[i], style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: selected ? Colors.white : Color(AppConstants.mediumGray)))),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // My price vs market
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF1A1A2E), Color(0xFF16213E)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Price vs Market', style: TextStyle(color: Colors.white70, fontSize: 13)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _priceBox('Your Price', 'Rs. ${_myPrice.toInt()}', Colors.white, Colors.white70)),
                        Container(width: 1, height: 50, color: Colors.white24),
                        Expanded(child: _priceBox('Market Avg', 'Rs. ${_avgCompetitorPrice.toInt()}', const Color(0xFFFFBF00), Colors.white70)),
                        Container(width: 1, height: 50, color: Colors.white24),
                        Expanded(child: _priceBox(
                          _myPrice < _avgCompetitorPrice ? 'Below Avg' : 'Above Avg',
                          '${((_myPrice - _avgCompetitorPrice) / _avgCompetitorPrice * 100).abs().toStringAsFixed(0)}%',
                          _myPrice < _avgCompetitorPrice ? Color(AppConstants.successGreen) : Color(AppConstants.errorRed),
                          Colors.white70,
                        )),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Price position bar
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Rs. ${_minPrice.toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                            Text('Rs. ${_maxPrice.toInt()}', style: const TextStyle(color: Colors.white54, fontSize: 10)),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Stack(
                          children: [
                            Container(height: 8, decoration: BoxDecoration(color: Colors.white12, borderRadius: BorderRadius.circular(4))),
                            FractionallySizedBox(
                              widthFactor: (_myPrice - _minPrice) / (_maxPrice - _minPrice),
                              child: Container(height: 8, decoration: BoxDecoration(color: Color(AppConstants.primaryRed), borderRadius: BorderRadius.circular(4))),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text('You are cheaper than $_pricierCount and pricier than $_cheaperCount competitors', style: const TextStyle(color: Colors.white60, fontSize: 11)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Competitor list
              Text('Nearby Competitors', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 10),
              ..._competitors.map((c) => _competitorCard(c, isDark, card, border)),
              const SizedBox(height: 16),

              // Recommendation
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(AppConstants.successGreen).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Color(AppConstants.successGreen).withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.lightbulb_outline_rounded, color: Color(AppConstants.successGreen), size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _myPrice < _avgCompetitorPrice
                            ? 'Your price is ${((_avgCompetitorPrice - _myPrice) / _avgCompetitorPrice * 100).toStringAsFixed(0)}% below market average. Consider raising it by Rs. ${(_avgCompetitorPrice - _myPrice).toInt()} to increase revenue.'
                            : 'Your price is competitive. Monitor competitors weekly to stay ahead.',
                        style: TextStyle(fontSize: 12, color: Color(AppConstants.successGreen), height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _priceBox(String label, String value, Color valueColor, Color labelColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 16, fontWeight: FontWeight.w800)),
        const SizedBox(height: 2),
        Text(label, style: TextStyle(color: labelColor, fontSize: 10)),
      ],
    );
  }

  Widget _competitorCard(Map<String, dynamic> c, bool isDark, Color card, Color border) {
    final price = (c['price'] as num?)?.toDouble() ?? 0;
    final myDiff = price - _myPrice;
    final isHigher = myDiff > 0;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Row(
        children: [
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(color: Color(AppConstants.primaryRed).withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.hotel_rounded, color: Color(AppConstants.primaryRed), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c['name'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: isDark ? Colors.white : Colors.black)),
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 12, color: Color(0xFFFFBF00)),
                    const SizedBox(width: 2),
                    Text('${c['rating']}', style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                    const SizedBox(width: 8),
                    const Icon(Icons.location_on_outlined, size: 11, color: Color(AppConstants.mediumGray)),
                    Text(c['distance'] as String, style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Rs. ${price.toInt()}', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: (isHigher ? Color(AppConstants.successGreen) : Color(AppConstants.errorRed)).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isHigher ? '+Rs. ${myDiff.toInt()}' : 'Rs. ${myDiff.toInt()}',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: isHigher ? Color(AppConstants.successGreen) : Color(AppConstants.errorRed)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _skeleton() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
    const SkeletonLoader(height: 38, borderRadius: 20), const SizedBox(height: 16),
    const SkeletonLoader(height: 160, borderRadius: 16), const SizedBox(height: 20),
    ...List.generate(4, (_) => const Padding(padding: EdgeInsets.only(bottom: 10), child: SkeletonLoader(height: 76, borderRadius: 14))),
  ]));
}
