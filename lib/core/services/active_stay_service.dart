import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'booking_service.dart';

/// Singleton that tracks whether the user has an active checked-in stay.
/// Polls the bookings API every 60 s and notifies listeners on change.
class ActiveStayService extends ChangeNotifier {
  static final ActiveStayService _instance = ActiveStayService._();
  factory ActiveStayService() => _instance;
  ActiveStayService._();

  final _bookingService = BookingService();

  Map<String, dynamic>? _activeBooking;
  bool _loading = false;
  Timer? _pollTimer;
  bool _initialized = false;

  Map<String, dynamic>? get activeBooking => _activeBooking;
  bool get hasActiveStay => _activeBooking != null;
  bool get loading => _loading;

  // ── Public API ─────────────────────────────────────────────────────────

  /// Call once after login. Starts polling.
  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;
    await refresh();
    // Poll every 60 seconds
    _pollTimer = Timer.periodic(const Duration(seconds: 60), (_) => refresh());
  }

  /// Force a refresh (called after QR check-in, app resume, etc.)
  Future<void> refresh() async {
    if (_loading) return;
    _loading = true;
    try {
      final result = await _bookingService.getMyBookings();
      if (result['success'] == true) {
        final bookings = (result['bookings'] as List? ?? []).cast<Map<String, dynamic>>();

        // Find a booking with status == 'checked_in' (or 'checkin')
        final checkedIn = bookings.where((b) {
          final status = (b['status'] ?? '').toString().toLowerCase();
          return status == 'checked_in' || status == 'checkin' || status == 'check_in';
        }).toList();

        final prev = _activeBooking;
        _activeBooking = checkedIn.isNotEmpty ? checkedIn.first : null;

        // Notify if state changed
        if (prev == null && _activeBooking != null) {
          await _persistStay(_activeBooking!);
          notifyListeners();
        } else if (prev != null && _activeBooking == null) {
          await _clearPersistedStay();
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('[ActiveStay] refresh error: $e');
    } finally {
      _loading = false;
    }
  }

  /// Called when booking status update is detected locally (e.g. after QR scan)
  void setActiveBooking(Map<String, dynamic> booking) {
    _activeBooking = booking;
    _persistStay(booking);
    notifyListeners();
  }

  void clearActiveStay() {
    _activeBooking = null;
    _clearPersistedStay();
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  // ── Persistence (survive app restart during a stay) ────────────────────

  Future<void> _persistStay(Map<String, dynamic> booking) async {
    final prefs = await SharedPreferences.getInstance();
    final id = booking['id']?.toString() ?? '';
    await prefs.setString('active_stay_booking_id', id);
    await prefs.setString('active_stay_hotel', booking['hotel_name']?.toString() ?? booking['hotel']?['name']?.toString() ?? '');
    await prefs.setString('active_stay_room', booking['room_type']?.toString() ?? booking['room_number']?.toString() ?? '');
    await prefs.setString('active_stay_checkout', booking['check_out']?.toString() ?? booking['check_out_date']?.toString() ?? '');
  }

  Future<void> _clearPersistedStay() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_stay_booking_id');
    await prefs.remove('active_stay_hotel');
    await prefs.remove('active_stay_room');
    await prefs.remove('active_stay_checkout');
  }

  /// Load any persisted stay on cold start (before first API call resolves)
  Future<void> loadPersistedStay() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString('active_stay_booking_id');
    if (id != null && id.isNotEmpty) {
      _activeBooking = {
        'id': id,
        'hotel_name': prefs.getString('active_stay_hotel') ?? '',
        'room_type': prefs.getString('active_stay_room') ?? '',
        'check_out': prefs.getString('active_stay_checkout') ?? '',
        '_from_cache': true,
      };
      notifyListeners();
    }
  }
}
