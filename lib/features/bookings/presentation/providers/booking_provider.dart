import 'package:flutter/foundation.dart';
import '../../../../core/constants/app_constants.dart';
import '../models/booking_model.dart';
import '../services/booking_service.dart';

class BookingProvider extends ChangeNotifier {
  final BookingService _bookingService;

  BookingProvider(this._bookingService);

  List<Booking> _bookings = [];
  List<Booking> _filteredBookings = [];
  bool _isLoading = false;
  String? _errorMessage;
  String _currentFilter = 'all';

  // Getters
  List<Booking> get bookings => _filteredBookings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String get currentFilter => _currentFilter;

  Future<void> loadBookings({String filter = 'all'}) async {
    _setLoading(true);
    _clearError();
    _currentFilter = filter;

    try {
      final bookingsData = await _bookingService.getBookings(filter: filter);
      _bookings = bookingsData.map((json) => Booking.fromJson(json)).toList();
      _filteredBookings = List.from(_bookings);
    } catch (e) {
      _setError('Failed to load bookings: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchBookings(String query) async {
    if (query.isEmpty) {
      _filteredBookings = List.from(_bookings);
    } else {
      _filteredBookings = _bookings.where((booking) {
        return booking.guestName.toLowerCase().contains(query.toLowerCase()) ||
            booking.roomNumber.toLowerCase().contains(query.toLowerCase()) ||
            booking.status.toLowerCase().contains(query.toLowerCase());
      }).toList();
    }
    notifyListeners();
  }

  void clearSearch() {
    _filteredBookings = List.from(_bookings);
    notifyListeners();
  }

  Future<void> filterByDateRange(DateTime startDate, DateTime endDate) async {
    _setLoading(true);
    _clearError();

    try {
      final bookingsData = await _bookingService.getBookingsByDateRange(
        startDate: startDate,
        endDate: endDate,
      );
      _bookings = bookingsData.map((json) => Booking.fromJson(json)).toList();
      _filteredBookings = List.from(_bookings);
    } catch (e) {
      _setError('Failed to filter bookings: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    _clearError();

    try {
      await _bookingService.updateBookingStatus(bookingId, newStatus);
      
      // Update local booking
      final bookingIndex = _bookings.indexWhere((b) => b.id == bookingId);
      if (bookingIndex != -1) {
        _bookings[bookingIndex] = _bookings[bookingIndex].copyWith(status: newStatus);
        
        // Update filtered bookings as well
        final filteredIndex = _filteredBookings.indexWhere((b) => b.id == bookingId);
        if (filteredIndex != -1) {
          _filteredBookings[filteredIndex] = _filteredBookings[filteredIndex].copyWith(status: newStatus);
        }
      }
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to update booking status: ${e.toString()}');
    }
  }

  Future<void> cancelBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'cancelled');
  }

  Future<void> checkInBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'checked_in');
  }

  Future<void> checkOutBooking(String bookingId) async {
    await updateBookingStatus(bookingId, 'checked_out');
  }

  Future<void> createBooking(Booking booking) async {
    _setLoading(true);
    _clearError();

    try {
      final bookingData = await _bookingService.createBooking(booking.toJson());
      final newBooking = Booking.fromJson(bookingData);
      
      _bookings.insert(0, newBooking);
      _filteredBookings.insert(0, newBooking);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to create booking: ${e.toString()}');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> deleteBooking(String bookingId) async {
    _clearError();

    try {
      await _bookingService.deleteBooking(bookingId);
      
      _bookings.removeWhere((b) => b.id == bookingId);
      _filteredBookings.removeWhere((b) => b.id == bookingId);
      
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete booking: ${e.toString()}');
    }
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void _setError(String error) {
    _errorMessage = error;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
