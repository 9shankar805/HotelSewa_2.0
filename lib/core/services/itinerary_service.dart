import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

/// Feature 10: Itinerary / trip planner
class ItineraryService {
  // GET itinerary — full trip view (all bookings + orders + requests)
  Future<Map<String, dynamic>> getItinerary({String? tripId}) async {
    try {
      final response = await ApiService.get('/itinerary', queryParams: {
        if (tripId != null) 'trip_id': tripId,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load itinerary'};
    }
  }

  // GET itinerary/{bookingId} — single booking trip view
  Future<Map<String, dynamic>> getBookingItinerary(String bookingId) async {
    try {
      final response = await ApiService.get('/itinerary/$bookingId');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load trip details'};
    }
  }

  // POST itinerary/trips — create a named trip (group multiple bookings)
  Future<Map<String, dynamic>> createTrip({
    required String name,
    String? description,
    List<String>? bookingIds,
  }) async {
    try {
      final response = await ApiService.post('/itinerary/trips', data: {
        'name': name,
        if (description != null) 'description': description,
        if (bookingIds != null) 'booking_ids': bookingIds,
      });
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to create trip'};
    }
  }

  // GET itinerary/trips — list all named trips
  Future<Map<String, dynamic>> getTrips() async {
    try {
      final response = await ApiService.get('/itinerary/trips');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load trips'};
    }
  }

  // DELETE itinerary/trips/{id}
  Future<Map<String, dynamic>> deleteTrip(String tripId) async {
    try {
      final response = await ApiService.delete('/itinerary/trips/$tripId');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to delete trip'};
    }
  }
}





