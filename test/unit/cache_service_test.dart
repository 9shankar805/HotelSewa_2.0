import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:hotelsewa_app/core/services/shared/cache_service.dart';

void main() {
  setUpAll(() async {
    // Use in-memory Hive for tests
    Hive.init('test_hive');
    await CacheService.init();
  });

  tearDown(() async {
    await CacheService.clearAll();
  });

  group('CacheService — Hotels', () {
    test('saves and retrieves hotel list', () async {
      final hotels = [
        {'id': 1, 'name': 'Test Hotel', 'city': 'Kathmandu'},
        {'id': 2, 'name': 'Another Hotel', 'city': 'Pokhara'},
      ];

      await CacheService.saveHotels(hotels);
      final retrieved = CacheService.getHotels();

      expect(retrieved, isNotNull);
      expect(retrieved!.length, equals(2));
      expect(retrieved[0]['name'], equals('Test Hotel'));
    });

    test('returns null when cache is empty', () {
      final result = CacheService.getHotels();
      expect(result, isNull);
    });

    test('saves and retrieves hotel details', () async {
      final details = {'id': 42, 'name': 'Grand Hotel', 'rating': 4.8};
      await CacheService.saveHotelDetails('42', details);

      final retrieved = CacheService.getHotelDetails('42');
      expect(retrieved, isNotNull);
      expect(retrieved!['name'], equals('Grand Hotel'));
    });

    test('returns null for unknown hotel id', () {
      final result = CacheService.getHotelDetails('999');
      expect(result, isNull);
    });
  });

  group('CacheService — Bookings', () {
    test('saves and retrieves bookings', () async {
      final bookings = [
        {'id': 1, 'hotel_name': 'Test Hotel', 'status': 'confirmed'},
      ];

      await CacheService.saveBookings(bookings);
      final retrieved = CacheService.getBookings();

      expect(retrieved, isNotNull);
      expect(retrieved!.length, equals(1));
      expect(retrieved[0]['status'], equals('confirmed'));
    });

    test('invalidateBookings clears the cache', () async {
      await CacheService.saveBookings([{'id': 1}]);
      await CacheService.invalidateBookings();

      final result = CacheService.getBookings();
      expect(result, isNull);
    });
  });

  group('CacheService — General', () {
    test('saves and retrieves string value', () async {
      await CacheService.save('test_key', 'hello world');
      final result = CacheService.get<String>('test_key');
      expect(result, equals('hello world'));
    });

    test('saves and retrieves map value', () async {
      await CacheService.save('user_prefs', {'theme': 'dark', 'lang': 'en'});
      final result = CacheService.get<Map<String, dynamic>>('user_prefs');
      expect(result, isNotNull);
      expect(result!['theme'], equals('dark'));
    });

    test('returns null for missing key', () {
      final result = CacheService.get<String>('nonexistent');
      expect(result, isNull);
    });

    test('delete removes a key', () async {
      await CacheService.save('to_delete', 'value');
      await CacheService.delete('to_delete');
      final result = CacheService.get<String>('to_delete');
      expect(result, isNull);
    });

    test('clearAll removes all cached data', () async {
      await CacheService.saveHotels([{'id': 1}]);
      await CacheService.saveBookings([{'id': 1}]);
      await CacheService.save('key', 'value');

      await CacheService.clearAll();

      expect(CacheService.getHotels(), isNull);
      expect(CacheService.getBookings(), isNull);
      expect(CacheService.get<String>('key'), isNull);
    });
  });
}
