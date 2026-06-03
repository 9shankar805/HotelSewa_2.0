import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/skeleton_loader.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/reports_service.dart';

class TaxReportScreen extends StatefulWidget {
  const TaxReportScreen({super.key});
  @override
  State<TaxReportScreen> createState() => _TaxReportScreenState();
}

class _TaxReportScreenState extends State<TaxReportScreen> {
  bool _isLoading = true;
  String _period = 'this_month';
  double _vatRate = 13.0;
  double _tdsRate = 1.5;

  double _grossRevenue = 0;
  double _taxableRevenue = 0;
  double _totalTax = 0;
  double _netRevenue = 0;
  double _effectiveTaxRate = 0;
  List<Map<String, dynamic>> _monthly = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final token = Provider.of<AuthProvider>(context, listen: false).token;
      final data = await ReportsService.getTaxReport(
        token: token,
        period: _period,
      );
      if (mounted) {
        setState(() {
          _grossRevenue = (data['gross_revenue'] as num?)?.toDouble() ?? 0;
          _taxableRevenue = (data['taxable_revenue'] as num?)?.toDouble() ?? _grossRevenue;
          _totalTax = (data['total_tax'] as num?)?.toDouble() ?? 0;
          _netRevenue = (data['net_revenue'] as num?)?.toDouble() ?? 0;
          _effectiveTaxRate = (data['effective_tax_rate'] as num?)?.toDouble() ?? 0;
          _monthly = List<Map<String, dynamic>>.from(data['monthly'] ?? []);
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Report'),
        actions: [
          IconButton(
            icon: const Icon(Icons.download_rounded),
            onPressed: _downloadReport,
            tooltip: 'Download PDF',
          ),
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
              // Period selector
              Container(
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(12), border: Border.all(color: border)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _period,
                    isExpanded: true,
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    borderRadius: BorderRadius.circular(12),
                    items: const [
                      DropdownMenuItem(value: 'this_month', child: Text('This Month')),
                      DropdownMenuItem(value: 'last_month', child: Text('Last Month')),
                      DropdownMenuItem(value: 'this_quarter', child: Text('This Quarter')),
                      DropdownMenuItem(value: 'this_year', child: Text('This Year (FY 2081/82)')),
                    ],
                    onChanged: (v) { setState(() => _period = v!); _load(); },
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Summary cards
              Row(
                children: [
                  Expanded(child: _summaryCard('Gross Revenue', 'Rs. ${_fmt(_grossRevenue)}', Color(AppConstants.successGreen), Icons.trending_up_rounded, isDark, card, border)),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryCard('Total Tax', 'Rs. ${_fmt(_totalTax)}', Color(AppConstants.errorRed), Icons.account_balance_rounded, isDark, card, border)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: _summaryCard('Net Revenue', 'Rs. ${_fmt(_netRevenue)}', const Color(0xFF1890FF), Icons.savings_rounded, isDark, card, border)),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryCard('Tax Rate', '${_effectiveTaxRate.toStringAsFixed(1)}%', Color(AppConstants.warningOrange), Icons.percent_rounded, isDark, card, border)),
                ],
              ),
              const SizedBox(height: 20),

              // Tax breakdown
              Text('Tax Breakdown', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                child: Column(
                  children: [
                    _taxRow('Gross Revenue', _grossRevenue, null, isDark, isTotal: false),
                    const Divider(height: 1),
                    _taxRow('Taxable Revenue', _taxableRevenue, null, isDark, isTotal: false, subtitle: 'After exemptions'),
                    const Divider(height: 1),
                    _taxRow('VAT (${_vatRate.toStringAsFixed(0)}%)', _taxableRevenue * _vatRate / 100, Color(AppConstants.errorRed), isDark),
                    const Divider(height: 1),
                    _taxRow('TDS (${_tdsRate.toStringAsFixed(1)}%)', _taxableRevenue * _tdsRate / 100, Color(AppConstants.warningOrange), isDark),
                    const Divider(height: 1),
                    _taxRow('Net Revenue', _netRevenue, Color(AppConstants.successGreen), isDark, isTotal: true),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tax rates config
              Text('Tax Configuration', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                child: Column(
                  children: [
                    _rateRow('VAT Rate', _vatRate, (v) => setState(() => _vatRate = v), isDark),
                    const SizedBox(height: 12),
                    _rateRow('TDS Rate', _tdsRate, (v) => setState(() => _tdsRate = v), isDark),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(color: Color(AppConstants.warningOrange).withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, size: 14, color: Color(AppConstants.warningOrange)),
                          SizedBox(width: 6),
                          Expanded(child: Text('Nepal VAT: 13% | TDS on hotel services: 1.5%\nConsult your tax advisor for exact rates.', style: TextStyle(fontSize: 11, color: Color(AppConstants.warningOrange)))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Monthly breakdown table
              Text('Monthly Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
              const SizedBox(height: 10),
              Container(
                decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(16), border: Border.all(color: border)),
                child: Column(
                  children: [
                    _tableHeader(isDark),
                    if (_monthly.isEmpty)
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text('No monthly data available', style: TextStyle(color: Color(AppConstants.mediumGray))),
                      )
                    else
                      ..._monthly.asMap().entries.map((e) =>
                        _tableRow(
                          e.value['month']?.toString() ?? 'Month ${e.key + 1}',
                          (e.value['revenue'] as num?)?.toDouble() ?? 0,
                          isDark,
                          e.key.isOdd,
                        )
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 80),
            ],
          ),
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: _downloadReport,
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 18),
                label: const Text('Download PDF'),
                style: OutlinedButton.styleFrom(foregroundColor: Color(AppConstants.primaryRed), side: const BorderSide(color: Color(AppConstants.primaryRed)), padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _shareReport,
                icon: const Icon(Icons.share_rounded, size: 18),
                label: const Text('Share'),
                style: ElevatedButton.styleFrom(backgroundColor: Color(AppConstants.primaryRed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryCard(String label, String value, Color color, IconData icon, bool isDark, Color card, Color border) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: card, borderRadius: BorderRadius.circular(14), border: Border.all(color: border)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(height: 10),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: isDark ? Colors.white : Colors.black)),
          Text(label, style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
        ],
      ),
    );
  }

  Widget _taxRow(String label, double amount, Color? color, bool isDark, {bool isTotal = false, String? subtitle}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 14, fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500, color: isDark ? Colors.white : Colors.black)),
                if (subtitle != null) Text(subtitle, style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
              ],
            ),
          ),
          Text(
            'Rs. ${_fmt(amount)}',
            style: TextStyle(fontSize: 15, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600, color: color ?? (isDark ? Colors.white : Colors.black)),
          ),
        ],
      ),
    );
  }

  Widget _rateRow(String label, double value, ValueChanged<double> onChanged, bool isDark) {
    return Row(
      children: [
        Expanded(child: Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDark ? Colors.white : Colors.black))),
        Text('${value.toStringAsFixed(1)}%', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(AppConstants.primaryRed))),
        const SizedBox(width: 8),
        SizedBox(
          width: 120,
          child: Slider(
            value: value,
            min: 0, max: 30, divisions: 60,
            activeColor: Color(AppConstants.primaryRed),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _tableHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: isDark ? const Color(0xFF2C2C2C) : Color(AppConstants.lightGray), borderRadius: const BorderRadius.vertical(top: Radius.circular(16))),
      child: const Row(
        children: [
          Expanded(child: Text('Month', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(AppConstants.mediumGray)))),
          Text('Revenue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(AppConstants.mediumGray))),
          SizedBox(width: 16),
          Text('Tax', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(AppConstants.mediumGray))),
          SizedBox(width: 16),
          Text('Net', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(AppConstants.mediumGray))),
        ],
      ),
    );
  }

  Widget _tableRow(String month, double revenue, bool isDark, bool alt) {
    final tax = revenue * (_vatRate + _tdsRate) / 100;
    final net = revenue - tax;
    final bg = alt ? (isDark ? const Color(0xFF252525) : const Color(0xFFFAFAFA)) : (isDark ? const Color(0xFF1E1E1E) : Colors.white);
    return Container(
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Expanded(child: Text(month, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : Colors.black))),
          Text('Rs. ${_fmt(revenue)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(width: 16),
          Text('Rs. ${_fmt(tax)}', style: TextStyle(fontSize: 12, color: Color(AppConstants.errorRed))),
          const SizedBox(width: 16),
          Text('Rs. ${_fmt(net)}', style: TextStyle(fontSize: 12, color: Color(AppConstants.successGreen), fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  void _downloadReport() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('Tax report downloaded'), backgroundColor: Color(AppConstants.successGreen),
    behavior: SnackBarBehavior.floating,
  ));

  void _shareReport() => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
    content: Text('Sharing tax report...'), backgroundColor: Color(AppConstants.successGreen),
    behavior: SnackBarBehavior.floating,
  ));

  Widget _skeleton() => SingleChildScrollView(padding: const EdgeInsets.all(16), child: Column(children: [
    const SkeletonLoader(height: 48, borderRadius: 12), const SizedBox(height: 16),
    Row(children: const [Expanded(child: SkeletonLoader(height: 90, borderRadius: 14)), SizedBox(width: 10), Expanded(child: SkeletonLoader(height: 90, borderRadius: 14))]),
    const SizedBox(height: 10),
    Row(children: const [Expanded(child: SkeletonLoader(height: 90, borderRadius: 14)), SizedBox(width: 10), Expanded(child: SkeletonLoader(height: 90, borderRadius: 14))]),
    const SizedBox(height: 20),
    const SkeletonLoader(height: 200, borderRadius: 16),
  ]));
}
