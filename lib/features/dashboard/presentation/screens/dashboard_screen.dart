import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String _period = 'today';

  static const _periods = ['today', 'week', 'month', 'year'];
  static const _periodLabels = {'today': 'Today', 'week': 'This Week', 'month': 'This Month', 'year': 'This Year'};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  void _load() {
    final auth = context.read<AuthProvider>();
    context.read<DashboardProvider>().loadDashboardData(period: _period, authProvider: auth);
  }

  @override
  Widget build(BuildContext context) {
    final auth      = context.watch<AuthProvider>();
    final provider  = context.watch<DashboardProvider>();
    final name      = auth.user?.name ?? 'Owner';
    final ini       = name.isNotEmpty ? name[0].toUpperCase() : 'O';
    final data      = provider.dashboardData;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      body: RefreshIndicator(
        onRefresh: () async => _load(),
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            // ── App Bar ────────────────────────────────────────────────
            SliverAppBar(
              pinned: true,
              expandedHeight: 110,
              backgroundColor: AppColors.primary,
              surfaceTintColor: Colors.transparent,
              automaticallyImplyLeading: false,
              elevation: 0,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFFE60023), Color(0xFFB8001C)],
                      begin: Alignment.topLeft, end: Alignment.bottomRight,
                    ),
                  ),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            // Avatar with white ring
                            Container(
                              width: 42, height: 42,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.25),
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white.withOpacity(0.6), width: 2),
                              ),
                              child: Center(child: Text(ini,
                                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18))),
                            ),
                            const SizedBox(width: 12),
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              const Text('HOTELSEWA',
                                  style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                              Text(name, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                  maxLines: 1, overflow: TextOverflow.ellipsis),
                            ])),
                            // Notifications bell
                            _iconBtn(Icons.notifications_outlined, () => context.push('/notifications'), badge: true),
                            const SizedBox(width: 8),
                            // Settings
                            _iconBtn(Icons.settings_outlined, () => context.push('/settings')),
                          ]),
                          const SizedBox(height: 10),
                          // Period filter tabs
                          SizedBox(
                            height: 30,
                            child: ListView(
                              scrollDirection: Axis.horizontal,
                              children: _periods.map((p) {
                                final on = _period == p;
                                return GestureDetector(
                                  onTap: () { setState(() => _period = p); _load(); },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    margin: const EdgeInsets.only(right: 8),
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: on ? Colors.white : Colors.white.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: on ? Colors.white : Colors.white.withOpacity(0.3)),
                                    ),
                                    child: Text(_periodLabels[p]!,
                                        style: TextStyle(
                                          fontSize: 12, fontWeight: FontWeight.w700,
                                          color: on ? AppColors.primary : Colors.white,
                                        )),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            if (provider.isLoading)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator(color: AppColors.primary)))
            else ...[
              // ── KPI Stats ──────────────────────────────────────────────
              SliverToBoxAdapter(child: _kpiSection(data)),
              // ── Today's Activity ───────────────────────────────────────
              SliverToBoxAdapter(child: _todayActivity(data)),
              // ── Quick Actions ──────────────────────────────────────────
              SliverToBoxAdapter(child: _quickActions()),
              // ── Recent Bookings ────────────────────────────────────────
              SliverToBoxAdapter(child: _recentBookings(provider.recentBookings)),
              // ── Management Tools ───────────────────────────────────────
              SliverToBoxAdapter(child: _managementTools()),
              // ── Analytics & Reports ────────────────────────────────────
              SliverToBoxAdapter(child: _analyticsSection()),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ],
        ),
      ),
    );
  }

  // ── Icon button helper ────────────────────────────────────────────────────
  Widget _iconBtn(IconData ic, VoidCallback fn, {bool badge = false}) {
    return GestureDetector(
      onTap: fn,
      child: Stack(children: [
        Container(
          width: 42, height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.3)),
          ),
          child: Icon(ic, size: 22, color: Colors.white),
        ),
        if (badge)
          Positioned(
            top: 9, right: 9,
            child: Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.5),
              ),
            )),
      ]),
    );
  }

  // ── KPI Stats Grid ────────────────────────────────────────────────────────
  Widget _kpiSection(DashboardData? d) {
    final stats = [
      _Stat('Total Bookings', '${d?.totalBookings ?? 0}', d?.bookingsChange ?? '+0%',
          Icons.calendar_today_rounded, const Color(0xFF3B82F6), const Color(0xFFEFF6FF)),
      _Stat('Revenue', 'Rs.${_fmt(d?.revenue ?? 0)}', d?.revenueChange ?? '+0%',
          Icons.account_balance_wallet_rounded, const Color(0xFF10B981), const Color(0xFFECFDF5)),
      _Stat('Occupancy', '${(d?.occupancyRate ?? 0).toStringAsFixed(0)}%', d?.occupancyChange ?? '+0%',
          Icons.hotel_rounded, const Color(0xFFF59E0B), const Color(0xFFFFFBEB)),
      _Stat('Active Rooms', '${d?.activeRooms ?? 0}/${d?.totalRooms ?? 0}', d?.roomsChange ?? '+0%',
          Icons.meeting_room_rounded, const Color(0xFF8B5CF6), const Color(0xFFF5F3FF)),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: GridView.count(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12,
        childAspectRatio: 1.5, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
        children: stats.map((s) => _kpiCard(s)).toList(),
      ),
    );
  }

  Widget _kpiCard(_Stat s) {
    final isPositive = s.change.startsWith('+') || s.change.startsWith('↑');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(10)),
            child: Icon(s.icon, size: 18, color: s.color),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isPositive ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(s.change,
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800,
                    color: isPositive ? const Color(0xFF10B981) : const Color(0xFFEF4444))),
          ),
        ]),
        const Spacer(),
        Text(s.value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Color(0xFF1A1A2E))),
        const SizedBox(height: 2),
        Text(s.label, style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
      ]),
    );
  }

  // ── Today's Activity Row ──────────────────────────────────────────────────
  Widget _todayActivity(DashboardData? d) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A1A2E), Color(0xFF2D2D44)],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(children: [
          _actStat(Icons.login_rounded,  'Check-Ins',   '${d?.checkInsToday ?? 0}',  const Color(0xFF4ADE80)),
          _divider(),
          _actStat(Icons.logout_rounded, 'Check-Outs',  '${d?.checkOutsToday ?? 0}', const Color(0xFFFBBF24)),
          _divider(),
          _actStat(Icons.pending_actions_rounded, 'Pending', '${d?.pendingRequests ?? 0}', AppColors.primary),
          _divider(),
          _actStat(Icons.message_rounded, 'Messages', '${d?.unreadMessages ?? 0}', const Color(0xFF60A5FA)),
        ]),
      ),
    );
  }

  Widget _actStat(IconData ic, String label, String val, Color color) {
    return Expanded(child: Column(children: [
      Icon(ic, size: 20, color: color),
      const SizedBox(height: 4),
      Text(val, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: Colors.white)),
      Text(label, style: const TextStyle(fontSize: 9, color: Colors.white54, fontWeight: FontWeight.w600)),
    ]));
  }

  Widget _divider() => Container(width: 1, height: 40, color: Colors.white.withOpacity(0.15));

  // ── Quick Actions ─────────────────────────────────────────────────────────
  Widget _quickActions() {
    final actions = [
      _Action('QR Check-in',   Icons.qr_code_scanner_rounded,  AppColors.primary,        '/qr-checkin'),
      _Action('Add Booking',   Icons.add_circle_rounded,        const Color(0xFF10B981),  '/bookings'),
      _Action('Manage Rooms',  Icons.meeting_room_rounded,      const Color(0xFF3B82F6),  '/rooms'),
      _Action('Pricing',       Icons.attach_money_rounded,      const Color(0xFFF59E0B),  '/pricing'),
      _Action('Offers',        Icons.local_offer_rounded,       const Color(0xFF8B5CF6),  '/offers'),
      _Action('Messages',      Icons.chat_rounded,              const Color(0xFF06B6D4),  '/guest-messaging'),
      _Action('Calendar',      Icons.calendar_month_rounded,    const Color(0xFFEC4899),  '/calendar'),
      _Action('Reports',       Icons.bar_chart_rounded,         const Color(0xFFEF4444),  '/reports'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Text('Quick Actions', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
      ),
      SizedBox(
        height: 95,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: actions.length,
          itemBuilder: (_, i) {
            final a = actions[i];
            return GestureDetector(
              onTap: () => context.push(a.route),
              child: Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Container(
                    width: 54, height: 54,
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: a.color.withOpacity(0.2)),
                    ),
                    child: Icon(a.icon, size: 24, color: a.color),
                  ),
                  const SizedBox(height: 6),
                  Text(a.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                      textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
                ]),
              ),
            );
          },
        ),
      ),
    ]);
  }

  // ── Recent Bookings ───────────────────────────────────────────────────────
  Widget _recentBookings(List<Booking> bookings) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          const Text('Recent Bookings', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          GestureDetector(onTap: () => context.push('/bookings'),
            child: const Text('View all', style: TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w700))),
        ]),
      ),
      if (bookings.isEmpty)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Container(
            width: double.infinity, padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
            child: const Column(children: [
              Icon(Icons.calendar_today_rounded, size: 40, color: Color(0xFFD1D5DB)),
              SizedBox(height: 8),
              Text('No bookings yet', style: TextStyle(color: Color(0xFF9CA3AF), fontWeight: FontWeight.w600)),
            ]),
          ),
        )
      else
        ...bookings.take(5).map((b) => _bookingRow(b)),
    ]);
  }

  Widget _bookingRow(Booking b) {
    final statusColor = _statusColor(b.status);
    final ini = b.guestName.isNotEmpty ? b.guestName[0].toUpperCase() : '?';
    return GestureDetector(
      onTap: () => context.push('/bookings'),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          CircleAvatar(radius: 20, backgroundColor: AppColors.primary.withOpacity(0.1),
            child: Text(ini, style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 16))),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.guestName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1A1A2E)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 3),
            Text('Room ${b.roomNumber} • ${_fmtDate(b.checkIn)} – ${_fmtDate(b.checkOut)}',
                style: const TextStyle(fontSize: 11, color: Color(0xFF9CA3AF), fontWeight: FontWeight.w500)),
          ])),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
              child: Text(b.status.toUpperCase(),
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w900, color: statusColor)),
            ),
            const SizedBox(height: 4),
            Text('Rs.${_fmt(b.amount)}',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
          ]),
        ]),
      ),
    );
  }

  // ── Management Tools Grid ─────────────────────────────────────────────────
  Widget _managementTools() {
    final tools = [
      _Tool('Rooms',           Icons.meeting_room_rounded,    const Color(0xFF3B82F6),  '/rooms'),
      _Tool('Bookings',        Icons.receipt_long_rounded,    AppColors.primary,        '/bookings'),
      _Tool('Earnings',        Icons.account_balance_wallet_rounded, const Color(0xFF10B981), '/earnings'),
      _Tool('Calendar',        Icons.calendar_month_rounded,  const Color(0xFFEC4899),  '/calendar'),
      _Tool('Amenities',       Icons.spa_rounded,             const Color(0xFF8B5CF6),  '/amenities-management'),
      _Tool('Gallery',         Icons.photo_library_rounded,   const Color(0xFFF59E0B),  '/gallery-management'),
      _Tool('Offers',          Icons.local_offer_rounded,     const Color(0xFFEF4444),  '/offers'),
      _Tool('Pricing',         Icons.price_change_rounded,    const Color(0xFF06B6D4),  '/pricing'),
      _Tool('Reviews',         Icons.star_rounded,            const Color(0xFFFBBF24),  '/reviews'),
      _Tool('Analytics',       Icons.bar_chart_rounded,       const Color(0xFF6366F1),  '/analytics'),
      _Tool('Staff',           Icons.people_rounded,          const Color(0xFF0EA5E9),  '/staff-management'),
      _Tool('Housekeeping',    Icons.cleaning_services_rounded, const Color(0xFF84CC16), '/housekeeping'),
      _Tool('Maintenance',     Icons.build_rounded,           const Color(0xFF94A3B8),  '/maintenance'),
      _Tool('Front Desk',      Icons.desk_rounded,            const Color(0xFFD97706),  '/front-desk'),
      _Tool('Documents',       Icons.description_rounded,     const Color(0xFF6B7280),  '/documents'),
      _Tool('Settings',        Icons.settings_rounded,        const Color(0xFF374151),  '/settings'),
      // Previously missing tools — now linked
      _Tool('Ordering',        Icons.restaurant_rounded,      const Color(0xFFEF4444),  '/ordering'),
      _Tool('Check-In',        Icons.how_to_reg_rounded,      const Color(0xFF10B981),  '/checkin-dashboard'),
      _Tool('Inventory',       Icons.inventory_2_rounded,     const Color(0xFF6366F1),  '/inventory'),
      _Tool('Multi-Property',  Icons.business_rounded,        const Color(0xFF0EA5E9),  '/multi-property'),
      _Tool('PMS',             Icons.integration_instructions_rounded, const Color(0xFF8B5CF6), '/pms-integration'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Text('Management', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 4, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 0.85, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: tools.map((t) => GestureDetector(
            onTap: () => context.push(t.route),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: t.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(t.icon, size: 20, color: t.color),
                ),
                const SizedBox(height: 6),
                Text(t.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                    textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
              ]),
            ),
          )).toList(),
        ),
      ),
    ]);
  }

  // ── Analytics Section ─────────────────────────────────────────────────────
  Widget _analyticsSection() {
    final items = [
      _Tool('Analytics',        Icons.bar_chart_rounded,      const Color(0xFF6366F1), '/analytics'),
      _Tool('Reports',          Icons.summarize_rounded,       const Color(0xFF3B82F6), '/reports'),
      _Tool('Tax Report',       Icons.receipt_rounded,         const Color(0xFFEF4444), '/tax-report'),
      _Tool('Revenue',          Icons.trending_up_rounded,     const Color(0xFF10B981), '/revenue-dashboard'),
      _Tool('Reputation',       Icons.star_outline_rounded,    const Color(0xFFFBBF24), '/reputation'),
      _Tool('Withdrawals',      Icons.south_rounded,           const Color(0xFF8B5CF6), '/withdrawals'),
    ];
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 12),
        child: Text('Analytics & Finance', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: Color(0xFF1A1A2E))),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.count(
          crossAxisCount: 3, crossAxisSpacing: 10, mainAxisSpacing: 10,
          childAspectRatio: 1.1, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: items.map((t) => GestureDetector(
            onTap: () => context.push(t.route),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white, borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
              ),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(color: t.color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(t.icon, size: 22, color: t.color),
                ),
                const SizedBox(height: 6),
                Text(t.label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF374151)),
                    textAlign: TextAlign.center),
              ]),
            ),
          )).toList(),
        ),
      ),
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _fmt(double v) {
    if (v >= 100000) return '${(v / 100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '${(v / 1000).toStringAsFixed(1)}K';
    return v.toStringAsFixed(0);
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}';

  Color _statusColor(String s) {
    switch (s.toLowerCase()) {
      case 'confirmed':  return const Color(0xFF10B981);
      case 'checked_in': return const Color(0xFF3B82F6);
      case 'checked_out':return const Color(0xFF6B7280);
      case 'cancelled':  return const Color(0xFFEF4444);
      default:           return const Color(0xFFF59E0B);
    }
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────
class _Stat {
  final String label, value, change;
  final IconData icon;
  final Color color, bg;
  const _Stat(this.label, this.value, this.change, this.icon, this.color, this.bg);
}

class _Action {
  final String label, route;
  final IconData icon;
  final Color color;
  const _Action(this.label, this.icon, this.color, this.route);
}

class _Tool {
  final String label, route;
  final IconData icon;
  final Color color;
  const _Tool(this.label, this.icon, this.color, this.route);
}
