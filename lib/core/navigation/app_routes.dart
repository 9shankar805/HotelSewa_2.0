import 'package:flutter/material.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/hotel/presentation/hotel_list_screen.dart';
import '../../features/hotel/presentation/hotel_details_screen.dart';
import '../../features/booking/presentation/booking_form_screen.dart';
import '../../features/booking/presentation/payment_screen.dart';
import '../../features/booking/presentation/booking_success_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/personal_info_screen.dart';
import '../../features/profile/presentation/profile_complete_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/payment_methods/presentation/payment_methods_screen.dart';
import '../../features/help/presentation/help_center_screen.dart';
import '../../features/coupons/presentation/coupons_screen.dart';
import '../../features/filters/presentation/filters_screen.dart';
import '../../features/gallery/presentation/gallery_screen.dart';
import '../../features/chat/presentation/chat_screen.dart';
import '../../features/amenities/presentation/amenities_screen.dart';
import '../../features/room_types/presentation/room_types_screen.dart';
import '../../features/pricing/presentation/pricing_breakdown_screen.dart';
import '../../features/reviews/presentation/hotel_reviews_screen.dart';
import '../../features/reviews/presentation/review_submission_screen.dart';
import '../../features/reviews/presentation/pending_reviews_screen.dart';
import '../../features/map/presentation/map_search_screen.dart';
import '../../features/ai_chat/presentation/ai_chat_screen.dart';
import '../../features/advanced/presentation/advanced_features_screen.dart';
import '../../features/location/presentation/location_selector_screen.dart';
import '../../features/booking/presentation/booking_detail_screen.dart';
import '../../features/booking/presentation/booking_cancellation_screen.dart';
import '../../features/booking/presentation/booking_modification_screen.dart';
import '../../features/booking/presentation/online_checkin_screen.dart';
import '../../features/booking/presentation/invoice_screen.dart';
import '../../features/booking/presentation/refund_status_screen.dart';
import '../../features/search/presentation/date_picker_screen.dart';
import '../../features/search/presentation/guest_room_selector_screen.dart';
import '../../features/hotel/presentation/deals_screen.dart';
import '../../features/hotel/presentation/recently_viewed_screen.dart';
import '../../features/hotel/presentation/hotel_policies_screen.dart';
import '../../features/profile/presentation/security_settings_screen.dart';
import '../../features/profile/presentation/travel_preferences_screen.dart';
import '../../features/profile/presentation/loyalty_program_screen.dart';
import '../../features/profile/presentation/delete_account_screen.dart';
import '../../features/payment_methods/presentation/add_card_screen.dart';
import '../../features/payment_methods/presentation/emi_screen.dart';
import '../../features/profile/presentation/address_book_screen.dart';
import '../../features/profile/presentation/linked_accounts_screen.dart';
import '../../features/settings/presentation/language_selector_screen.dart';
import '../../features/settings/presentation/currency_selector_screen.dart';
import '../../features/reviews/presentation/rate_stay_screen.dart';
import '../../features/help/presentation/support_ticket_screen.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/hotel/presentation/nearby_attractions_screen.dart';
import '../../features/hotel/presentation/compare_hotels_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/about/presentation/terms_screen.dart';
import '../../features/settings/presentation/notification_settings_screen.dart';
import '../../features/settings/presentation/accessibility_settings_screen.dart';
import '../../features/invite/presentation/referral_history_screen.dart';
import '../../features/payment_methods/presentation/add_upi_screen.dart';
import '../../features/trips/presentation/my_trips_screen.dart';
import 'main_navigation.dart';
import 'owner_navigation.dart';
// Hotel Owner Screens
import '../../features/role_selection/presentation/role_selection_screen.dart';
import '../../features/bookings/presentation/screens/booking_management_screen.dart' as owner_bookings;
import '../../features/rooms/presentation/screens/manage_rooms_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/amenities/presentation/screens/amenities_management_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/gallery/presentation/screens/gallery_management_screen.dart';
import '../../features/messaging/presentation/screens/guest_messaging_screen.dart';
import '../../features/support/presentation/screens/help_support_screen.dart';
import '../../features/offers/presentation/screens/offers_screen.dart';
import '../../features/pricing/presentation/screens/pricing_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reviews/presentation/screens/reviews_screen.dart' as owner_reviews;
import '../../features/settings/presentation/screens/settings_screen.dart' as owner_settings;
import '../../features/withdrawals/presentation/screens/withdrawals_screen.dart';
import '../../features/orders/presentation/screens/ordering_dashboard_screen.dart';

class AppRoutes {
  static const String splash = '/splash';
  static const String roleSelection = '/role-selection';
  static const String onboarding = '/onboarding';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String otpVerification = '/otp-verification';
  static const String home = '/home';
  static const String search = '/search';
  static const String hotelList = '/hotel-list';
  static const String hotelDetails = '/hotel-details';
  static const String bookingForm = '/booking-form';
  static const String payment = '/payment';
  static const String bookingSuccess = '/booking-success';
  static const String profile = '/profile';
  static const String personalInfo = '/personal-info';
  static const String profileComplete = '/profile-complete';
  static const String notifications = '/notifications';
  static const String wallet = '/wallet';
  static const String paymentMethods = '/payment-methods';
  static const String helpCenter = '/help-center';
  static const String coupons = '/coupons';
  static const String filters = '/filters';
  static const String gallery = '/gallery';
  static const String chat = '/chat';
  static const String amenities = '/amenities';
  static const String roomTypes = '/room-types';
  static const String pricingBreakdown = '/pricing-breakdown';
  static const String hotelReviews = '/hotel-reviews';
  static const String reviewSubmission = '/review-submission';
  static const String pendingReviews = '/pending-reviews';
  static const String mapSearch = '/map-search';
  static const String aiChat = '/ai-chat';
  static const String advancedFeatures = '/advanced-features';
  static const String locationSelector = '/location-selector';
  static const String mainNavigation = '/main-navigation';
  // New screens
  static const String bookingDetail = '/booking-detail';
  static const String bookingCancellation = '/booking-cancellation';
  static const String bookingModification = '/booking-modification';
  static const String onlineCheckin = '/online-checkin';
  static const String invoice = '/invoice';
  static const String refundStatus = '/refund-status';
  static const String datePicker = '/date-picker';
  static const String guestRoomSelector = '/guest-room-selector';
  static const String deals = '/deals';
  static const String recentlyViewed = '/recently-viewed';
  static const String hotelPolicies = '/hotel-policies';
  static const String securitySettings = '/security-settings';
  static const String travelPreferences = '/travel-preferences';
  static const String loyaltyProgram = '/loyalty-program';
  static const String deleteAccount = '/delete-account';
  static const String addCard = '/add-card';
  static const String emi = '/emi';
  static const String addressBook = '/address-book';
  static const String linkedAccounts = '/linked-accounts';
  static const String languageSelector = '/language-selector';
  static const String currencySelector = '/currency-selector';
  static const String rateStay = '/rate-stay';
  static const String supportTicket = '/support-ticket';
  static const String about = '/about';
  static const String nearbyAttractions = '/nearby-attractions';
  static const String compareHotels = '/compare-hotels';
  static const String forgotPassword = '/forgot-password';
  static const String terms = '/terms';
  static const String notificationSettings = '/notification-settings';
  static const String accessibilitySettings = '/accessibility-settings';
  static const String referralHistory = '/referral-history';
  static const String inviteEarn = '/invite-earn';
  static const String addUpi = '/add-upi';
  static const String myTrips = '/my-trips';
  static const String saved = '/saved';
  
  // Hotel Owner Routes
  static const String ownerDashboard = '/owner/dashboard';
  static const String ownerBookings = '/owner/bookings';
  static const String ownerRooms = '/owner/rooms';
  static const String ownerEarnings = '/owner/earnings';
  static const String ownerProfile = '/owner/profile';
  static const String ownerAmenities = '/owner/amenities';
  static const String ownerAnalytics = '/owner/analytics';
  static const String ownerCalendar = '/owner/calendar';
  static const String ownerDocuments = '/owner/documents';
  static const String ownerGallery = '/owner/gallery';
  static const String ownerMessaging = '/owner/messaging';
  static const String ownerSupport = '/owner/support';
  static const String ownerOffers = '/owner/offers';
  static const String ownerPricing = '/owner/pricing';
  static const String ownerReports = '/owner/reports';
  static const String ownerReviews = '/owner/reviews';
  static const String ownerSettings = '/owner/settings';
  static const String ownerWithdrawals = '/owner/withdrawals';
  static const String ownerOrdering = '/owner/ordering';

  // ── New Guest Screens (from endpoint setup) ────────────────────────────
  static const String nearMe = '/near-me';
  static const String nlpSearch = '/nlp-search';
  static const String waitlist = '/waitlist';
  static const String digitalKey = '/digital-key';
  static const String corporateTravel = '/corporate-travel';
  static const String groupBookings = '/group-bookings';
  static const String membership = '/membership';
  static const String concierge = '/concierge';
  static const String preArrival = '/pre-arrival';
  static const String midStayFeedback = '/mid-stay-feedback';
  static const String travelInsurance = '/travel-insurance';
  static const String smartRoom = '/smart-room';
  static const String eco = '/eco';
  static const String splitPayment = '/split-payment';
  static const String idVerification = '/id-verification';
  static const String priceAlerts = '/price-alerts';
  static const String activities = '/activities';
  static const String affiliate = '/affiliate';
  // In-stay ordering
  static const String menu = '/menu';
  static const String cart = '/cart';
  static const String myOrders = '/my-orders';
  static const String orderConfirmation = '/order-confirmation';

  // ── New Owner Screens (from endpoint setup) ────────────────────────────
  static const String housekeeping = '/housekeeping';
  static const String maintenance = '/maintenance';
  static const String staffManagement = '/staff-management';
  static const String frontDesk = '/front-desk';
  static const String revenueDashboard = '/revenue-dashboard';
  static const String multiProperty = '/multi-property';
  static const String inventory = '/inventory';
  static const String reputation = '/reputation';
  static const String pmsIntegration = '/pms-integration';
  static const String longStayRates = '/long-stay-rates';
  static const String postStay = '/post-stay';
  static const String eventSpaces = '/event-spaces';
  static const String flashSales = '/flash-sales';
  static const String packages = '/packages';
  static const String addons = '/addons';
  static const String ownerActivities = '/owner-activities';
  static const String checkinDashboard = '/checkin-dashboard';

  static Map<String, Widget Function(BuildContext)> getRoutes() {
    return {
      splash: (context) => const SplashScreen(),
      roleSelection: (context) => const RoleSelectionScreen(),
      onboarding: (context) => const OnboardingScreen(),
      login: (context) => const LoginScreen(),
      signup: (context) => const SignupScreen(),
      otpVerification: (context) => const OTPVerificationScreen(),
      mainNavigation: (context) => const MainNavigation(),
      search: (context) => const SearchScreen(),
      hotelList: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return HotelListScreen(arguments: args);
      },
      hotelDetails: (context) => const HotelDetailsScreen(),
      bookingForm: (context) => const BookingFormScreen(),
      payment: (context) => const PaymentScreen(),
      bookingSuccess: (context) => const BookingSuccessScreen(),
      profile: (context) => const ProfileScreen(),
      personalInfo: (context) => const PersonalInfoScreen(),
      profileComplete: (context) => const ProfileCompleteScreen(),
      notifications: (context) => const NotificationsScreen(),
      wallet: (context) => const WalletScreen(),
      paymentMethods: (context) => const PaymentMethodsScreen(),
      helpCenter: (context) => const HelpCenterScreen(),
      coupons: (context) => const CouponsScreen(),
      filters: (context) => const FiltersScreen(),
      gallery: (context) => const GalleryScreen(),
      chat: (context) => const ChatScreen(),
      amenities: (context) => const AmenitiesScreen(),
      roomTypes: (context) => const RoomTypesScreen(),
      pricingBreakdown: (context) => const PricingBreakdownScreen(),
      hotelReviews: (context) => const HotelReviewsScreen(),
      reviewSubmission: (context) => const ReviewSubmissionScreen(),
      pendingReviews: (context) => const PendingReviewsScreen(),
      mapSearch: (context) => const MapSearchScreen(),
      aiChat: (context) => const AIChatScreen(),
      advancedFeatures: (context) => const AdvancedFeaturesScreen(),
      locationSelector: (context) => const LocationSelectorScreen(),
      // New screens
      bookingDetail: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return BookingDetailScreen(arguments: args);
      },
      bookingCancellation: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return BookingCancellationScreen(arguments: args);
      },
      bookingModification: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return BookingModificationScreen(arguments: args);
      },
      onlineCheckin: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return OnlineCheckinScreen(arguments: args);
      },
      invoice: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return InvoiceScreen(arguments: args);
      },
      refundStatus: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return RefundStatusScreen(arguments: args);
      },
      datePicker: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return DatePickerScreen(arguments: args);
      },
      guestRoomSelector: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return GuestRoomSelectorScreen(arguments: args);
      },
      deals: (context) => const DealsScreen(),
      recentlyViewed: (context) => const RecentlyViewedScreen(),
      hotelPolicies: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return HotelPoliciesScreen(arguments: args);
      },
      securitySettings: (context) => const SecuritySettingsScreen(),
      travelPreferences: (context) => const TravelPreferencesScreen(),
      loyaltyProgram: (context) => const LoyaltyProgramScreen(),
      deleteAccount: (context) => const DeleteAccountScreen(),
      addCard: (context) => const AddCardScreen(),
      emi: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return EmiScreen(arguments: args);
      },
      addressBook: (context) => const AddressBookScreen(),
      linkedAccounts: (context) => const LinkedAccountsScreen(),
      languageSelector: (context) => const LanguageSelectorScreen(),
      currencySelector: (context) => const CurrencySelectorScreen(),
      rateStay: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return RateStayScreen(arguments: args);
      },
      supportTicket: (context) => const SupportTicketScreen(),
      about: (context) => const AboutScreen(),
      nearbyAttractions: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return NearbyAttractionsScreen(arguments: args);
      },
      compareHotels: (context) {
        final args = ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;
        return CompareHotelsScreen(arguments: args);
      },
      forgotPassword: (context) => const ForgotPasswordScreen(),
      terms: (context) => const TermsScreen(),
      notificationSettings: (context) => const NotificationSettingsScreen(),
      accessibilitySettings: (context) => const AccessibilitySettingsScreen(),
      referralHistory: (context) => const ReferralHistoryScreen(),
      addUpi: (context) => const AddUpiScreen(),
      myTrips: (context) => const MyTripsScreen(),
      
      // Hotel Owner Routes
      ownerDashboard: (context) => const OwnerNavigation(),
      ownerBookings: (context) => const owner_bookings.BookingManagementScreen(),
      ownerRooms: (context) => const ManageRoomsScreen(),
      ownerEarnings: (context) => const EarningsScreen(),
      ownerAmenities: (context) => const AmenitiesManagementScreen(),
      ownerAnalytics: (context) => const AnalyticsScreen(),
      ownerCalendar: (context) => const CalendarScreen(),
      ownerDocuments: (context) => const DocumentsScreen(),
      ownerGallery: (context) => const GalleryManagementScreen(),
      ownerMessaging: (context) => const GuestMessagingScreen(),
      ownerSupport: (context) => const HelpSupportScreen(),
      ownerOffers: (context) => const OffersScreen(),
      ownerPricing: (context) => const PricingScreen(),
      ownerReports: (context) => const ReportsScreen(),
      ownerReviews: (context) => const owner_reviews.ReviewsScreen(),
      ownerSettings: (context) => const owner_settings.SettingsScreen(),
      ownerWithdrawals: (context) => const WithdrawalsScreen(),
      ownerOrdering: (context) => const OrderingDashboardScreen(),
    };
  }

  static Route<dynamic> generateRoute(RouteSettings settings) {
    final routes = getRoutes();
    final screenBuilder = routes[settings.name];

    if (screenBuilder != null) {
      return MaterialPageRoute(
        builder: (context) => screenBuilder(context),
        settings: settings,
      );
    }

    // Default route
    return MaterialPageRoute(
      builder: (context) => const SplashScreen(),
      settings: settings,
    );
  }

  static void navigateTo(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamed(context, routeName, arguments: arguments);
  }

  static void navigateToReplacement(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushReplacementNamed(context, routeName, arguments: arguments);
  }

  static void navigateToAndClearStack(BuildContext context, String routeName, {Object? arguments}) {
    Navigator.pushNamedAndRemoveUntil(
      context,
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  static void goBack(BuildContext context) {
    Navigator.pop(context);
  }
}
