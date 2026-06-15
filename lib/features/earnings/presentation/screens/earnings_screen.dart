import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/earnings_provider.dart';
import '../models/earnings_model.dart';

class EarningsScreen extends StatefulWidget {
  const EarningsScreen({super.key});
  @override
  State<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends State<EarningsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  String _period = 'month';

  static const _periods = ['today', 'week', 'month', 'year'];
  static const _periodLabels = {
    'today': 'Today', 'week': 'Week', 'month': 'Month', 'year': 'Year',
  };

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  void _load() =>
      context.read<EarningsProvider>().loadEarningsData(period: _period);

  String _fmt(double v) {
    if (v >= 100000) return 'Rs.${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000) return 'Rs.${(v / 1000).toStringAsFixed(1)}K';
    return 'Rs.${v.toStringAsFixed(0)}';
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<EarningsProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1A1A2E),
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text('Earnings',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        actions: [
          IconButton(
            icon: const Icon(Icons.ios_share_rounded, size: 20),
            onPressed: () {},
            tooltip: 'Export',
          ),
        ],
        bottom: TabBar(
          controller: _tabs,
          indicatorColor: AppColors.primary,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          tabs: const [Tab(text: 'Overview'), Tab(text: 'Transactions')],
        ),
      ),
      body: p.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : TabBarView(controller: _tabs, children: [
              _overviewTab(p),
              _transactionsTab(p),
            ]),
    );
  }

  // ── Overview Tab ─────────────────────────────────────────────────────────
  Widget _overviewTab(EarningsProvider p) {
    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: AppColors.primary,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          // Period selector
          _periodSelector(),
          const SizedBox(height: 16),
          // Revenue hero card
          _heroCard(p),
          const SizedBox(height: 14),
          // 4 KPI cards
          _kpiGrid(p),
          const SizedBox(height: 20),
          // Earnings chart
          _chartSection(p),
          const SizedBox(height: 20),
          // Withdraw button
          _withdrawButton(p),
          const SizedBox(height: 32),
        ]),
      ),
    );
  }

  Widget _periodSelector() {
    return Row(
      children: _periods.map((period) {
        final on = _period == period;
        return Expanded(child: GestureDetector(
          onTap: () { setState(() => _period = period); _load(); },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            margin: const EdgeInsets.symmetric(horizontal: 3),
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: on ? AppColors.primary : Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: on ? AppColors.primary : const Color(0xFFE5E7EB)),
            ),
            child: Text(_periodLabels[period]!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700,
                  color: on ? Colors.white : const Color(0xFF374151),
                )),
          ),
        ));
      }).toList(),
    );
  }

  Widget _heroCard(EarningsProvider p) {
    final isPos = p.revenueChange.startsWith('+');
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(
            color: const Color(0xFF1A1A2E).withOpacity(0.3),
            blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Total Revenue',
              style: TextStyle(color: Colors.white60, fontSize: 13, fontWeight: FontWeight.w600)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: isPos ? const Color(0xFF10B981).withOpacity(0.2) : const Color(0xFFEF4444).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(
                isPos ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                size: 12,
                color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Text(p.revenueChange,
                  style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w800,
                    color: isPos ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                  )),
            ]),
          ),
        ]),
        const SizedBox(height: 8),
        Text(_fmt(p.totalRevenue),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900,
                letterSpacing: -0.5)),
        const SizedBox(height: 4),
        Text('${_periodLabels[_period]} earnings',
            style: const TextStyle(color: Colors.white54, fontSize: 12)),
        const SizedBox(height: 16),
        Row(children: [
          _heroStat('Net Earnings',    _fmt(p.netEarnings),    const Color(0xFF10B981)),
          const SizedBox(width: 16),
          _heroStat('Pending',         _fmt(p.pendingAmount),  const Color(0xFFFBBF24)),
          const SizedBox(width: 16),
          _heroStat('Withdrawn',       _fmt(p.withdrawnAmount), Colors.white60),
        ]),
      ]),
    );
  }

  Widget _heroStat(String label, String value, Color color) {
    return Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(color: Colors.white54, fontSize: 10, fontWeight: FontWeight.w600)),
      const SizedBox(height: 3),
      Text(value, style: TextStyle(color: color, fontSize: 14, fontWeight: FontWeight.w800)),
    ]));
  }

  Widget _kpiGrid(EarningsProvider p) {
    final kpis = [
      _KPI('Bookings',      '${p.totalBookings}',                            Icons.calendar_today_rounded,       const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
      _KPI('Occupancy',     '${p.occupancyRate.toStringAsFixed(0)}%',        Icons.hotel_rounded,                const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _KPI('Avg/Day',       _fmt(p.averageDailyRevenue),                     Icons.show_chart_rounded,           const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      _KPI('Avg Booking',   _fmt(p.averageBookingValue),                     Icons.account_balance_wallet_rounded, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
    ];
    return GridView.count(
      crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
      childAspectRatio: 1.6, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      children: kpis.map((k) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(width: 34, height: 34,
              decoration: BoxDecoration(color: k.bg, borderRadius: BorderRadius.circular(10)),
              child: Icon(k.icon, size: 17, color: k.color)),
          const Spacer(),
          Text(k.value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
          Text(k.label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
        ]),
      )).toList(),
    );
  }

  Widget _chartSection(EarningsProvider p) {
    if (p.earningsData.isEmpty) return const SizedBox.shrink();

    final maxAmt = p.earningsData.map((e) => e.amount).reduce((a, b) => a > b ? a : b);
    if (maxAmt == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Revenue Trend',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 16),
        SizedBox(
          height: 120,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: p.earningsData.take(14).map((e) {
              final ratio = maxAmt > 0 ? (e.amount / maxAmt) : 0.0;
              return Expanded(child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 2),
                child: Column(mainAxisAlignment: MainAxisAlignment.end, children: [
                  Container(
                    height: 100 * ratio,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.7 + ratio * 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ]),
              ));
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text('${p.earningsData.first.date.day}/${p.earningsData.first.date.month}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
          Text('${p.earningsData.last.date.day}/${p.earningsData.last.date.month}',
              style: const TextStyle(fontSize: 10, color: Color(0xFF9CA3AF))),
        ]),
      ]),
    );
  }

  Widget _withdrawButton(EarningsProvider p) {
    final available = p.netEarnings - p.withdrawnAmount;
    if (available <= 0) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF10B981).withOpacity(0.3)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))]),
      child: Row(children: [
        Container(
          width: 46, height: 46,
          decoration: BoxDecoration(color: const Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(13)),
          child: const Icon(Icons.account_balance_rounded, color: Color(0xFF10B981), size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Available to Withdraw',
              style: TextStyle(fontSize: 12, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
          Text(_fmt(available),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: Color(0xFF10B981))),
        ])),
        ElevatedButton(
          onPressed: () {},
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF10B981), elevation: 0,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Withdraw', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
        ),
      ]),
    );
  }

  // ── Transactions Tab ─────────────────────────────────────────────────────
  Widget _transactionsTab(EarningsProvider p) {
    final all = [...p.transactions, ...p.withdrawals]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    if (all.isEmpty) {
      return Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.receipt_long_outlined, size: 56, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 12),
        const Text('No transactions yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF9CA3AF))),
      ]));
    }

    return RefreshIndicator(
      onRefresh: () async => _load(),
      color: AppColors.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: all.length,
        itemBuilder: (_, i) => _txRow(all[i]),
      ),
    );
  }

  Widget _txRow(Transaction t) {
    final isIncome  = t.type == 'booking_payment' || t.type == 'payment';
    final statusColor = t.status == 'completed'
        ? const Color(0xFF10B981) : t.status == 'pending'
        ? const Color(0xFFF59E0B) : const Color(0xFFEF4444);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Row(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: isIncome
                ? const Color(0xFF10B981).withOpacity(0.1)
                : const Color(0xFFEF4444).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            isIncome ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
            size: 20,
            color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            t.description.isNotEmpty ? t.description : _txLabel(t.type),
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Row(children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
              child: Text(t.status.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: statusColor)),
            ),
            const SizedBox(width: 6),
            Text(
              '${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}',
              style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF)),
            ),
          ]),
        ])),
        Text(
          '${isIncome ? '+' : '-'} ${_fmt(t.amount)}',
          style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w900,
            color: isIncome ? const Color(0xFF10B981) : const Color(0xFFEF4444),
          ),
        ),
      ]),
    );
  }

  String _txLabel(String type) {
    switch (type) {
      case 'booking_payment': return 'Booking Payment';
      case 'withdrawal':      return 'Withdrawal';
      case 'refund':          return 'Refund';
      case 'commission':      return 'Platform Commission';
      default:                return type.replaceAll('_', ' ').toUpperCase();
    }
  }
}

class _KPI {
  final String label, value;
  final IconData icon;
  final Color color, bg;
  const _KPI(this.label, this.value, this.icon, this.color, this.bg);
}
