import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// Hive-based offline cache for hotels, bookings, and home data.
/// All entries are stored with a TTL; stale entries are ignored.
class CacheService {
  static const String _hotelsBox = 'hotels_cache';
  static const String _bookingsBox = 'bookings_cache';
  static const String _homeBox = 'home_cache';
  static const String _generalBox = 'general_cache';

  static bool _initialized = false;

  // ─── Init ────────────────────────────────────────────────────────────────────

  static Future<void> init() async {
    if (_initialized) return;
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(_hotelsBox),
      Hive.openBox(_bookingsBox),
      Hive.openBox(_homeBox),
      Hive.openBox(_generalBox),
    ]);
    _initialized = true;
    debugPrint('[Cache] Hive initialized');
  }

  // ─── Hotels ──────────────────────────────────────────────────────────────────

  /// Cache the full hotel list. TTL: 30 minutes.
  static Future<void> saveHotels(List<Map<String, dynamic>> hotels) async {
    final box = Hive.box(_hotelsBox);
    await box.put('all', _wrap(hotels, ttlMinutes: 30));
    debugPrint('[Cache] Saved ${hotels.length} hotels');
  }

  /// Returns cached hotel list, or null if missing/stale.
  static List<Map<String, dynamic>>? getHotels() {
    final box = Hive.box(_hotelsBox);
    return _unwrapList(box.get('all'));
  }

  /// Cache a single hotel's details. TTL: 60 minutes.
  static Future<void> saveHotelDetails(String hotelId, Map<String, dynamic> data) async {
    final box = Hive.box(_hotelsBox);
    await box.put('detail_$hotelId', _wrap(data, ttlMinutes: 60));
  }

  static Map<String, dynamic>? getHotelDetails(String hotelId) {
    final box = Hive.box(_hotelsBox);
    return _unwrapMap(box.get('detail_$hotelId'));
  }

  // ─── Bookings ────────────────────────────────────────────────────────────────

  /// Cache the user's booking list. TTL: 5 minutes (bookings change often).
  static Future<void> saveBookings(List<Map<String, dynamic>> bookings) async {
    final box = Hive.box(_bookingsBox);
    await box.put('my_bookings', _wrap(bookings, ttlMinutes: 5));
    debugPrint('[Cache] Saved ${bookings.length} bookings');
  }

  static List<Map<String, dynamic>>? getBookings() {
    final box = Hive.box(_bookingsBox);
    return _unwrapList(box.get('my_bookings'));
  }

  /// Invalidate bookings cache (call after create/cancel).
  static Future<void> invalidateBookings() async {
    final box = Hive.box(_bookingsBox);
    await box.delete('my_bookings');
  }

  // ─── Home data ───────────────────────────────────────────────────────────────

  /// Cache home screen data (offers, sliders, etc.). TTL: 60 minutes.
  static Future<void> saveHomeData(Map<String, dynamic> data) async {
    final box = Hive.box(_homeBox);
    await box.put('home_data', _wrap(data, ttlMinutes: 60));
  }

  static Map<String, dynamic>? getHomeData() {
    final box = Hive.box(_homeBox);
    return _unwrapMap(box.get('home_data'));
  }

  /// Cache deals/offers. TTL: 2 hours.
  static Future<void> saveDeals(List<Map<String, dynamic>> deals) async {
    final box = Hive.box(_homeBox);
    await box.put('deals', _wrap(deals, ttlMinutes: 120));
  }

  static List<Map<String, dynamic>>? getDeals() {
    final box = Hive.box(_homeBox);
    return _unwrapList(box.get('deals'));
  }

  // ─── General key-value ───────────────────────────────────────────────────────

  static Future<void> save(String key, dynamic value, {int ttlMinutes = 60}) async {
    final box = Hive.box(_generalBox);
    await box.put(key, _wrap(value, ttlMinutes: ttlMinutes));
  }

  static T? get<T>(String key) {
    final box = Hive.box(_generalBox);
    final raw = box.get(key);
    if (raw == null) return null;
    final entry = _parseEntry(raw);
    if (entry == null || _isExpired(entry)) return null;
    return entry['data'] as T?;
  }

  static Future<void> delete(String key) async {
    final box = Hive.box(_generalBox);
    await box.delete(key);
  }

  // ─── Clear all ───────────────────────────────────────────────────────────────

  static Future<void> clearAll() async {
    await Future.wait([
      Hive.box(_hotelsBox).clear(),
      Hive.box(_bookingsBox).clear(),
      Hive.box(_homeBox).clear(),
      Hive.box(_generalBox).clear(),
    ]);
    debugPrint('[Cache] All caches cleared');
  }

  // ─── Internal helpers ────────────────────────────────────────────────────────

  static String _wrap(dynamic data, {required int ttlMinutes}) {
    return jsonEncode({
      'data': data,
      'expiresAt': DateTime.now()
          .add(Duration(minutes: ttlMinutes))
          .millisecondsSinceEpoch,
    });
  }

  static Map<String, dynamic>? _parseEntry(dynamic raw) {
    try {
      if (raw is String) return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {}
    return null;
  }

  static bool _isExpired(Map<String, dynamic> entry) {
    final expiresAt = entry['expiresAt'] as int?;
    if (expiresAt == null) return true;
    return DateTime.now().millisecondsSinceEpoch > expiresAt;
  }

  static Map<String, dynamic>? _unwrapMap(dynamic raw) {
    final entry = _parseEntry(raw);
    if (entry == null || _isExpired(entry)) return null;
    final data = entry['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  static List<Map<String, dynamic>>? _unwrapList(dynamic raw) {
    final entry = _parseEntry(raw);
    if (entry == null || _isExpired(entry)) return null;
    final data = entry['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().toList();
    }
    return null;
  }
}
