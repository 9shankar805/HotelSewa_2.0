class AppConstants {
  // App Info
  static const String appName = 'HotelSewa Owner';
  static const String appVersion = '1.0.0';

  // API Configuration
  static const String baseUrl = 'https://api.hotelsewa.com';
  static const String apiVersion = '/v1';

  // Storage Keys
  static const String authTokenKey = 'authToken';
  static const String userKey = 'user';
  static const String hotelKey = 'hotel';
  static const String onboardingCompleteKey = 'onboardingComplete';

  // UI Constants
  static const double defaultPadding = 16.0;
  static const double smallPadding = 8.0;
  static const double largePadding = 24.0;
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;

  // Colors
  static const int primaryRed = 0xFFE60023;
  static const int secondaryRed = 0xFFCC041F;
  static const int lightGray = 0xFFF5F5F5;
  static const int mediumGray = 0xFF757575;
  static const int darkGray = 0xFF424242;
  static const int successGreen = 0xFF4CAF50;
  static const int warningOrange = 0xFFFF9800;
  static const int errorRed = 0xFFF44336;
  static const int white = 0xFFFFFFFF;
  static const int black = 0xFF000000;

  // Animation Durations
  static const int defaultAnimationDuration = 300;
  static const int shortAnimationDuration = 150;
  static const int longAnimationDuration = 500;

  // Screen Names
  static const String loginScreen = '/login';
  static const String otpScreen = '/otp';
  static const String onboardingScreen = '/onboarding';
  static const String dashboardScreen = '/dashboard';
  static const String bookingsScreen = '/bookings';
  static const String roomsScreen = '/rooms';
  static const String earningsScreen = '/earnings';
  static const String profileScreen = '/profile';
  static const String hotelRegistrationScreen = '/hotel-registration';
  static const String hotelPendingApprovalScreen = '/hotel-pending-approval';
  static const String galleryManagementScreen = '/gallery-management';
  static const String amenitiesManagementScreen = '/amenities-management';
  static const String guestMessagingScreen = '/guest-messaging';
  static const String notificationsScreen = '/notifications';
  static const String analyticsScreen = '/analytics';
  static const String reportsScreen = '/reports';
  static const String settingsScreen = '/settings';
  static const String helpSupportScreen = '/help-support';
  static const String documentsScreen = '/documents';
  static const String offersScreen = '/offers';
  static const String calendarScreen = '/calendar';
  static const String ownerChatScreen = '/owner-chat';
  static const String pricingScreen = '/pricing';
  static const String reviewsScreen = '/reviews';
  static const String roomStatusScreen = '/room-status';
  static const String withdrawalsScreen = '/withdrawals';
  static const String hotelDetailsScreen = '/hotel-details';
  static const String registrationReviewScreen = '/registration-review';
  static const String hotelLocationMapScreen = '/hotel-location-map';

  // New feature screens
  static const String yearlyCalendarScreen = '/yearly-calendar';
  static const String icalSyncScreen = '/ical-sync';
  static const String security2FAScreen = '/security-2fa';
  static const String automatedMessagingScreen = '/automated-messaging';
  static const String dynamicPricingScreen = '/dynamic-pricing';
  static const String competitorBenchmarkingScreen = '/competitor-benchmarking';
  static const String multiCurrencyScreen = '/multi-currency';
  static const String taxReportScreen = '/tax-report';
  static const String videoTourScreen = '/video-tour';
  static const String reviewRequestsScreen = '/review-requests';
  static const String qrCheckinScreen = '/qr-checkin';
  static const String checkinDashboardScreen = '/checkin-dashboard';
}
