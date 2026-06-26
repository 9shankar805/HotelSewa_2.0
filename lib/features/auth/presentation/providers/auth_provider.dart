import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../dashboard/presentation/services/dashboard_service.dart';
import '../../../bookings/presentation/services/booking_service.dart';
import '../../../rooms/presentation/services/room_service.dart';
import '../../../earnings/presentation/services/earnings_service.dart';
import '../../../hotel/presentation/services/hotel_service.dart';
import '../../../messaging/presentation/services/messaging_service.dart';
import '../../../notifications/presentation/services/notification_service.dart';
import '../../../gallery/presentation/services/gallery_service.dart';
import '../../../profile/presentation/services/profile_service.dart';
import '../../../offers/presentation/services/offers_service.dart';
import '../../../amenities/presentation/services/amenities_service.dart';
import '../../../analytics/presentation/services/analytics_service.dart';
import '../../../calendar/presentation/services/calendar_service.dart';
import '../../../documents/presentation/services/documents_service.dart';
import '../../../support/presentation/services/support_service.dart';
import '../../../withdrawals/presentation/services/withdrawals_service.dart';
import '../../../settings/presentation/services/settings_service.dart';
import '../../../pricing/presentation/services/pricing_service.dart';
import '../../../reviews/presentation/services/reviews_service.dart';
import '../../../reports/presentation/services/reports_service.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../../../../core/services/owner/loyalty_service.dart';
import '../../../../core/services/owner/waitlist_service.dart';
import '../../../../core/services/owner/booking_requests_service.dart';
import '../../../../core/services/owner/price_alerts_service.dart';
import '../../../../core/services/owner/payment_service.dart';
import '../../../../core/services/owner/orders_service.dart';
import '../../../chat/presentation/services/chat_api_service.dart';
// Top-level canonical owner services
import '../../../../core/services/owner/bookings_management_service.dart';
import '../../../../core/services/owner/media_service.dart';
import '../../../../core/services/owner/checkin_service.dart';
import '../../../../core/services/owner/tax_service.dart';
import '../../../../core/services/owner/ical_service.dart';
import '../../../../core/services/owner/guest_messaging_service.dart';
import '../../../../core/services/owner/competitor_service.dart';
import '../../../../core/services/owner/blackout_dates_service.dart';
import '../../../../core/services/owner/reviews_service.dart' as owner_reviews;
import '../../../../core/services/owner/offers_service.dart' as owner_offers;
import '../../../../core/services/owner/pricing_service.dart' as owner_pricing;
import '../../../../core/services/owner/hotel_management_service.dart';
import '../../../../core/services/owner/auth_account_service.dart';
import '../../../../core/services/owner/invoice_service.dart';
import '../../../../core/services/owner/dashboard_service.dart'
    as owner_dashboard;
import '../../../../core/services/owner/earnings_service.dart'
    as owner_earnings;
import '../../../../core/services/owner/currency_service.dart';
import '../../../../core/services/shared/api_service.dart' as shared_api;

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  bool _isHotelApproved = false;

  AuthProvider(this._authService);

  // Getters
  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  bool get isHotelApproved => _isHotelApproved;
  bool get hasHotel => _user?.hasHotel ?? false;

  Future<void> login({required String email, required String password}) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.login(
        email: email,
        password: password,
      );

      if (response['success'] == true) {
        final token = response['data']?['token'] ?? response['token'];
        final rawData = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'])
            : <String, dynamic>{};
        // API returns user fields directly in data (no nested 'user' key)
        final userData = rawData.containsKey('user')
            ? rawData['user'] as Map<String, dynamic>
            : rawData;
        _user = User.fromJson(userData);
        _token = token?.toString();
        _isAuthenticated = true;

        // Save to local storage
        await _saveUserSession(_token ?? '', userData);

        // Set token for other services
        _setTokenForServices(_token ?? '');
      } else {
        _setError(response['message'] ?? 'Login failed');
        throw Exception(response['message'] ?? 'Login failed');
      }
    } catch (e) {
      _setError('Login failed: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    _clearError();

    try {
      // Web client ID (type 3) from google-services.json — needed to get idToken
      final GoogleSignInAccount? googleUser = await GoogleSignIn(
        serverClientId:
            '664870792174-akgpqfbgcddbfn936e531lnjo52fqc61.apps.googleusercontent.com',
        scopes: ['email', 'profile'],
      ).signIn();

      if (googleUser == null) {
        _setError('Google Sign-In was cancelled');
        throw Exception('cancelled');
      }

      final response = await _authService.signInWithGoogle(googleUser);

      if (response['success'] == true) {
        final token = response['data']?['token'] ?? response['token'];
        final rawData = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'])
            : <String, dynamic>{};
        final userData = rawData.containsKey('user')
            ? rawData['user'] as Map<String, dynamic>
            : rawData;
        _user = User.fromJson(userData);
        _token = token?.toString();
        _isAuthenticated = true;
        await _saveUserSession(_token ?? '', userData);
        _setTokenForServices(_token ?? '');
      } else {
        final msg = response['message'] ?? 'Google Sign-In failed';
        _setError(msg);
        throw Exception(msg);
      }
    } catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      if (!msg.contains('cancelled')) {
        _setError('Google Sign-In failed: $msg');
      }
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendOTP(String phoneNumber) async {
    await _authService.sendOTP(phoneNumber);
  }

  Future<void> verifyOTP({
    required String phoneNumber,
    required String otp,
  }) async {
    _setLoading(true);
    _clearError();

    try {
      final response = await _authService.verifyOTP(
        phoneNumber: phoneNumber,
        otp: otp,
      );

      if (response['success'] == true) {
        final token = response['data']?['token'] ?? response['token'];
        final rawData = response['data'] is Map
            ? Map<String, dynamic>.from(response['data'])
            : <String, dynamic>{};
        final userData = rawData.containsKey('user')
            ? rawData['user'] as Map<String, dynamic>
            : rawData;
        _user = User.fromJson(userData);
        _token = token?.toString();
        _isAuthenticated = true;

        // Save to local storage
        await _saveUserSession(_token ?? '', userData);

        // Set token for other services
        _setTokenForServices(_token ?? '');
      } else {
        _setError(response['message'] ?? 'OTP verification failed');
        throw Exception(response['message'] ?? 'OTP verification failed');
      }
    } catch (e) {
      _setError('OTP verification failed: ${e.toString()}');
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> updateHotelStatus(bool hasHotel) async {
    if (_user != null) {
      _user = _user!.copyWith(hasHotel: hasHotel);
      // Save user data with existing token
      await _saveUserSession(_token ?? '', _user!.toJson());
      notifyListeners();
    }
  }

  Future<void> setHotelApproved(bool isApproved) async {
    _isHotelApproved = isApproved;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.isHotelApprovedKey, isApproved);
    notifyListeners();
  }

  /// Check hotel status and return the appropriate navigation route
  /// Returns:
  /// - 'registration' if no hotel found or status is REJECTED
  /// - 'pending' if hotel status is PENDING
  /// - 'dashboard' if hotel status is APPROVED
  Future<String> checkHotelStatusAndNavigate() async {
    if (_token == null || _token!.isEmpty) {
      debugPrint('No token found, redirecting to registration');
      return 'registration';
    }

    try {
      HotelService.setToken(_token!);
      final hotelService = HotelService();
      final response = await hotelService.getHotelStatus();

      debugPrint('Hotel status response: $response');

      // Check if response is successful and contains valid hotel data
      if (response['success'] == true &&
          response['data'] != null &&
          response['data'] is Map &&
          (response['data'] as Map).isNotEmpty &&
          (response['data'] as Map).containsKey('status')) {
        final status = response['data']['status'] as String?;

        // Validate status is a known value
        if (status == null || status.isEmpty) {
          debugPrint('Empty status, redirecting to registration');
          await updateHotelStatus(false);
          await setHotelApproved(false);
          return 'registration';
        }

        debugPrint('Hotel status found: $status');

        // Update user hasHotel status
        if (status == 'APPROVED' || status == 'ACTIVE' || status == 'PENDING') {
          await updateHotelStatus(true);
        } else {
          await updateHotelStatus(false);
        }

        // Update hotel approval status
        await setHotelApproved(status == 'APPROVED' || status == 'ACTIVE');

        // Persist hotelId and role for services / splash restore
        final prefs = await SharedPreferences.getInstance();
        final hotelId = response['data']['id']?.toString() ?? '';
        if (hotelId.isNotEmpty) {
          await prefs.setString('hotelId', hotelId);
          await prefs.setString('hotel_id', hotelId);
        }
        await prefs.setString('user_role', 'hotel_owner');

        // Return appropriate route based on status
        if (status == 'APPROVED' || status == 'ACTIVE') {
          debugPrint('Hotel approved, redirecting to dashboard');
          return 'dashboard';
        } else if (status == 'PENDING') {
          debugPrint('Hotel pending, redirecting to pending screen');
          return 'pending';
        } else {
          // REJECTED - allow re-registration
          debugPrint('Hotel status $status, redirecting to registration');
          return 'registration';
        }
      } else {
        // No hotel found (success=false or data is null/empty) - redirect to registration
        debugPrint(
          'No hotel found or invalid response, redirecting to registration',
        );
        debugPrint('Response success: ${response['success']}');
        debugPrint('Response data: ${response['data']}');
        debugPrint('Response message: ${response['message']}');
        await updateHotelStatus(false);
        await setHotelApproved(false);
        return 'registration';
      }
    } catch (e) {
      debugPrint('Error checking hotel status: $e');
      // On error, default to registration (safer default)
      await updateHotelStatus(false);
      await setHotelApproved(false);
      return 'registration';
    }
  }

  /// Validate if user can access pending approval screen
  /// Returns true if user has a hotel with PENDING status
  /// Returns false and redirects to appropriate screen if not valid
  Future<bool> validatePendingScreenAccess() async {
    // Check if user is authenticated
    if (_token == null || _token!.isEmpty) {
      return false;
    }

    // Check if user exists
    if (_user == null) {
      return false;
    }

    try {
      HotelService.setToken(_token!);
      final hotelService = HotelService();
      final response = await hotelService.getHotelStatus();

      if (response['success'] == true) {
        final status = response['data']['status'] ?? 'PENDING';

        // Only allow access if hotel is PENDING
        return status == 'PENDING';
      }

      // No hotel found
      return false;
    } catch (e) {
      debugPrint('Error validating pending screen access: $e');
      return false;
    }
  }

  Future<void> logout() async {
    try {
      await _authService.logout();
      await _clearUserSession();

      _user = null;
      _isAuthenticated = false;

      // Clear tokens from other services
      _clearTokensFromServices();
    } catch (e) {
      _setError('Logout failed: ${e.toString()}');
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AppConstants.authTokenKey);
      final userJson = prefs.getString(AppConstants.userKey);

      if (token != null && userJson != null) {
        _token = token;

        // Restore user from local storage immediately so UI doesn't flash
        final savedUserData = jsonDecode(userJson) as Map<String, dynamic>;
        _user = User.fromJson(savedUserData);
        _isAuthenticated = true;
        _isHotelApproved =
            prefs.getBool(AppConstants.isHotelApprovedKey) ?? false;
        _setTokenForServices(token);
        notifyListeners();

        // Validate token with server and refresh user data
        // Suppress onSessionExpired during startup validation to avoid
        // redirect loops while the splash/auth flow is still running
        try {
          final savedCallback = shared_api.ApiService.onSessionExpired;
          shared_api.ApiService.onSessionExpired = null; // mute during validation
          final response = await _authService.validateToken(token);
          shared_api.ApiService.onSessionExpired = savedCallback; // restore

          if (response['success'] == true) {
            // /get-owner returns user data in response['data']
            final rawData = response['data'];
            if (rawData is Map<String, dynamic> && rawData.containsKey('id')) {
              _user = User.fromJson(rawData);
              await _saveUserSession(token, rawData);
              notifyListeners();
            }
          } else if (response['sessionExpired'] == true) {
            // Token genuinely expired — clear session, caller will redirect
            await _clearUserSession();
            _user = null;
            _isAuthenticated = false;
            _isHotelApproved = false;
            notifyListeners();
          }
          // Any other non-success (network error, server down) → keep cached data
        } catch (_) {
          // Network error — keep using cached user data, don't log out
        }
      }
    } catch (e) {
      await _clearUserSession();
    }
  }

  void _setTokenForServices(String token) {
    _token = token;
    // ── Feature-scoped inner services ──
    DashboardService.setToken(token);
    BookingService.setToken(token);
    RoomService.setToken(token);
    EarningsService.setToken(token);
    HotelService.setToken(token);
    MessagingService.setToken(token);
    NotificationService.setToken(token);
    GalleryService.setToken(token);
    ProfileService.setToken(token);
    OffersService.setToken(token);
    AmenitiesService.setToken(token);
    AnalyticsService.setToken(token);
    CalendarService.setToken(token);
    DocumentsService.setToken(token);
    SupportService.setToken(token);
    WithdrawalsService.setToken(token);
    SettingsService.setToken(token);
    PricingService.setToken(token);
    ReviewsService.setToken(token);
    ReportsService.setToken(token);
    LoyaltyService.setToken(token);
    WaitlistService.setToken(token);
    BookingRequestsService.setToken(token);
    PriceAlertsService.setToken(token);
    PaymentService.setToken(token);
    OrdersService.setToken(token);
    ChatApiService.setToken(token);
    // ── Top-level canonical owner services ──
    BookingsManagementService.setToken(token);
    MediaService.setToken(token);
    CheckinService.setToken(token);
    TaxService.setToken(token);
    ICalService.setToken(token);
    GuestMessagingService.setToken(token);
    CompetitorService.setToken(token);
    BlackoutDatesService.setToken(token);
    owner_reviews.ReviewsService.setToken(token);
    owner_offers.OffersService.setToken(token);
    owner_pricing.PricingService.setToken(token);
    HotelManagementService.setToken(token);
    AuthAccountService.setToken(token);
    InvoiceService.setToken(token);
    owner_dashboard.DashboardService.setToken(token);
    owner_earnings.EarningsService.setToken(token);
    CurrencyService.setToken(token);
  }

  /// Public method to refresh tokens for all services
  /// Useful when switching to owner mode or after token refresh
  void refreshAllServiceTokens() {
    if (_token != null && _token!.isNotEmpty) {
      debugPrint('🔄 Refreshing tokens for all services...');
      _setTokenForServices(_token!);
      debugPrint('✅ All service tokens refreshed');
    } else {
      debugPrint('❌ Cannot refresh tokens - no valid token available');
    }
  }

  void _clearTokensFromServices() {
    _token = null;
    // ── Feature-scoped inner services ──
    DashboardService.setToken('');
    BookingService.setToken('');
    RoomService.setToken('');
    EarningsService.setToken('');
    HotelService.setToken('');
    MessagingService.setToken('');
    NotificationService.setToken('');
    GalleryService.setToken('');
    ProfileService.setToken('');
    OffersService.setToken('');
    AmenitiesService.setToken('');
    AnalyticsService.setToken('');
    CalendarService.setToken('');
    DocumentsService.setToken('');
    SupportService.setToken('');
    WithdrawalsService.setToken('');
    SettingsService.setToken('');
    PricingService.setToken('');
    ReviewsService.setToken('');
    ReportsService.setToken('');
    LoyaltyService.setToken('');
    WaitlistService.setToken('');
    BookingRequestsService.setToken('');
    PriceAlertsService.setToken('');
    PaymentService.setToken('');
    OrdersService.setToken('');
    ChatApiService.setToken('');
    // ── Top-level canonical owner services ──
    BookingsManagementService.setToken('');
    MediaService.setToken('');
    CheckinService.setToken('');
    TaxService.setToken('');
    ICalService.setToken('');
    GuestMessagingService.setToken('');
    CompetitorService.setToken('');
    BlackoutDatesService.setToken('');
    owner_reviews.ReviewsService.setToken('');
    owner_offers.OffersService.setToken('');
    owner_pricing.PricingService.setToken('');
    HotelManagementService.setToken('');
    AuthAccountService.setToken('');
    InvoiceService.setToken('');
    owner_dashboard.DashboardService.setToken('');
    owner_earnings.EarningsService.setToken('');
    CurrencyService.setToken('');
  }

  Future<void> _saveUserSession(
    String token,
    Map<String, dynamic> userData,
  ) async {
    try {
      _token = token; // Store token in provider
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(AppConstants.authTokenKey, token);
      await prefs.setString(AppConstants.userKey, jsonEncode(userData));
      // Persist user_role so splash screen can restore the correct mode
      final role = userData['role']?.toString() ??
          userData['user_role']?.toString() ??
          userData['type']?.toString() ??
          '';
      if (role.isNotEmpty) {
        await prefs.setString('user_role', role);
      }
    } catch (e) {
      debugPrint('Error saving user session: $e');
    }
  }

  Future<void> _clearUserSession() async {
    try {
      _token = null;
      _isHotelApproved = false;
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(AppConstants.authTokenKey);
      await prefs.remove(AppConstants.userKey);
      await prefs.remove(AppConstants.hotelKey);
      await prefs.remove(AppConstants.isHotelApprovedKey);
      await prefs.remove('user_role');
      await prefs.remove('hotelId');
      await prefs.remove('hotel_id');
    } catch (e) {
      debugPrint('Error clearing user session: $e');
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
