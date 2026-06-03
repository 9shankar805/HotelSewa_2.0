import 'package:flutter/foundation.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../services/dashboard_service.dart';
import '../../../../core/constants/app_constants.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _dashboardService;
  DashboardProvider(this._dashboardService);

  DashboardData? _dashboardData;
  List<Booking> _recentBookings = [];
  List<EarningsData> _earningsData = [];
  bool _isLoading = false;
  String? _errorMessage;

  // New: demand insights, forecast, booking sources
  List<DemandInsight> _demandInsights = [];
  RevenueForecast? _forecast;
  List<BookingSource> _bookingSources = [];
  List<StaffActivity> _staffActivity = [];

  // Getters
  DashboardData? get dashboardData => _dashboardData;
  List<Booking> get recentBookings => _recentBookings;
  List<EarningsData> get earningsData => _earningsData;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<DemandInsight> get demandInsights => _demandInsights;
  RevenueForecast? get forecast => _forecast;
  List<BookingSource> get bookingSources => _bookingSources;
  List<StaffActivity> get staffActivity => _staffActivity;

  double get totalRevenue => _dashboardData?.revenue ?? 0.0;
  int get activeRooms => _dashboardData?.activeRooms ?? 0;
  int get totalRooms => _dashboardData?.totalRooms ?? 0;
  String get roomsChange => _dashboardData?.roomsChange ?? '+0%';
  int get checkInsToday => _dashboardData?.checkInsToday ?? 0;
  int get checkOutsToday => _dashboardData?.checkOutsToday ?? 0;
  int get pendingRequests => _dashboardData?.pendingRequests ?? 0;
  int get unreadMessages => _dashboardData?.unreadMessages ?? 0;

  Future<void> loadDashboardData({required String period, AuthProvider? authProvider}) async {
    _setLoading(true);
    _clearError();
    try {
      final token = authProvider?.token;

      // Run all data loading concurrently
      final results = await Future.wait([
        _dashboardService.getDashboardData(period: period, token: token),
        _dashboardService.getRecentBookings(limit: 5, token: token),
        _dashboardService.getEarningsData(period: period, token: token),
      ]);

      final dashboardResponse = results[0];
      final bookingsResponse = results[1];
      final earningsResponse = results[2];

      _dashboardData = dashboardResponse['success'] == true
          ? DashboardData.fromJson(dashboardResponse['data'] ?? {})
          : null;

      _recentBookings = (bookingsResponse['success'] == true && bookingsResponse['data'] != null)
          ? (bookingsResponse['data'] as List).map((j) => Booking.fromJson(j)).toList()
          : [];

      _earningsData = (earningsResponse['success'] == true && earningsResponse['data'] != null)
          ? (earningsResponse['data'] as List).map((j) => EarningsData.fromJson(j)).toList()
          : [];

      _demandInsights = [];
      _forecast = null;
      _bookingSources = [];
      _staffActivity = [];

    } catch (e) {
      _setError('Failed to load dashboard: ${e.toString()}');
      _dashboardData = null;
      _recentBookings = [];
      _earningsData = [];
      _demandInsights = [];
      _forecast = null;
      _bookingSources = [];
      _staffActivity = [];
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshData({AuthProvider? authProvider}) async {
    await loadDashboardData(period: 'today', authProvider: authProvider);
  }

  void _setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void _setError(String e) { _errorMessage = e; notifyListeners(); }
  void _clearError() { _errorMessage = null; }
}

// ── Models ──────────────────────────────────────────────────────────────────

class DashboardData {
  final int totalBookings;
  final double occupancyRate;
  final double revenue;
  final int activeRooms;
  final int totalRooms;
  final String bookingsChange, occupancyChange, revenueChange, roomsChange;
  final int checkInsToday, checkOutsToday, pendingRequests, unreadMessages;
  final double avgRating;
  final int totalGuests;

  DashboardData({
    required this.totalBookings, required this.occupancyRate, required this.revenue,
    required this.activeRooms, required this.totalRooms,
    required this.bookingsChange, required this.occupancyChange,
    required this.revenueChange, required this.roomsChange,
    this.checkInsToday = 0, this.checkOutsToday = 0,
    this.pendingRequests = 0, this.unreadMessages = 0,
    this.avgRating = 0.0, this.totalGuests = 0,
  });

  factory DashboardData.fromJson(Map<String, dynamic> j) => DashboardData(
    totalBookings: j['totalBookings'] ?? 0,
    occupancyRate: (j['occupancyRate'] ?? 0.0).toDouble(),
    revenue: (j['revenue'] ?? 0.0).toDouble(),
    activeRooms: j['activeRooms'] ?? 0,
    totalRooms: j['totalRooms'] ?? 0,
    bookingsChange: j['bookingsChange'] ?? '+0%',
    occupancyChange: j['occupancyChange'] ?? '+0%',
    revenueChange: j['revenueChange'] ?? '+0%',
    roomsChange: j['roomsChange'] ?? '+0%',
    checkInsToday: j['checkInsToday'] ?? 0,
    checkOutsToday: j['checkOutsToday'] ?? 0,
    pendingRequests: j['pendingRequests'] ?? 0,
    unreadMessages: j['unreadMessages'] ?? 0,
    avgRating: (j['avgRating'] ?? 0.0).toDouble(),
    totalGuests: j['totalGuests'] ?? 0,
  );
}

class Booking {
  final String id, guestName, roomNumber, status;
  final DateTime checkIn, checkOut;
  final double amount;
  Booking({required this.id, required this.guestName, required this.roomNumber,
    required this.checkIn, required this.checkOut, required this.amount, required this.status});
  factory Booking.fromJson(Map<String, dynamic> j) => Booking(
    id: j['id'] ?? '', guestName: j['guestName'] ?? j['guest_name'] ?? '',
    roomNumber: j['roomNumber'] ?? j['room_number'] ?? '',
    checkIn: DateTime.parse(j['checkIn'] ?? j['check_in'] ?? DateTime.now().toIso8601String()),
    checkOut: DateTime.parse(j['checkOut'] ?? j['check_out'] ?? DateTime.now().toIso8601String()),
    amount: (j['amount'] ?? 0.0).toDouble(), status: j['status'] ?? 'confirmed',
  );
  Booking copyWith({String? status}) => Booking(
    id: id, guestName: guestName, roomNumber: roomNumber,
    checkIn: checkIn, checkOut: checkOut, amount: amount, status: status ?? this.status,
  );
}

class EarningsData {
  final DateTime date;
  final double amount;
  EarningsData({required this.date, required this.amount});
  factory EarningsData.fromJson(Map<String, dynamic> j) => EarningsData(
    date: DateTime.parse(j['date'] ?? DateTime.now().toIso8601String()),
    amount: (j['amount'] ?? 0.0).toDouble(),
  );
}

class DemandInsight {
  final String label, demand, change;
  final int color, icon;
  DemandInsight({required this.label, required this.demand, required this.change, required this.color, required this.icon});
}

class RevenueForecast {
  final double thisMonth, nextMonth, growthPercent;
  final String thisMonthLabel, nextMonthLabel;
  final List<double> weeklyForecast;
  RevenueForecast({required this.thisMonth, required this.nextMonth, required this.growthPercent,
    required this.thisMonthLabel, required this.nextMonthLabel, required this.weeklyForecast});
}

class BookingSource {
  final String name;
  final int count;
  final double percent;
  final int color;
  BookingSource({required this.name, required this.count, required this.percent, required this.color});
}

class StaffActivity {
  final String name, role, action, time, avatar;
  StaffActivity({required this.name, required this.role, required this.action, required this.time, required this.avatar});
}
