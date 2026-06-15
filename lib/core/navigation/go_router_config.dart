import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'dart:io';
import '../../features/splash/presentation/splash_screen.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import '../../features/auth/presentation/login_screen.dart';
import '../../features/auth/presentation/signup_screen.dart';
import '../../features/auth/presentation/otp_verification_screen.dart';
import '../../features/auth/presentation/forgot_password_screen.dart';
import '../../features/role_selection/presentation/role_selection_screen.dart';
import '../../features/search/presentation/search_screen.dart';
import '../../features/hotel/presentation/hotel_list_screen.dart';
import '../../features/hotel/presentation/hotel_details_screen.dart';
import '../../core/services/owner/features/hotel/presentation/screens/hotel_details_screen.dart' as OwnerHotelDetailsScreen;
import '../../features/booking/presentation/booking_form_screen.dart';
import '../../features/booking/presentation/payment_screen.dart';
import '../../features/booking/presentation/booking_success_screen.dart';
import '../../features/booking/presentation/booking_detail_screen.dart';
import '../../features/booking/presentation/booking_cancellation_screen.dart';
import '../../features/booking/presentation/booking_modification_screen.dart';
import '../../features/booking/presentation/online_checkin_screen.dart';
import '../../features/booking/presentation/invoice_screen.dart';
import '../../features/booking/presentation/refund_status_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/profile/presentation/personal_info_screen.dart';
import '../../features/profile/presentation/profile_complete_screen.dart';
import '../../features/profile/presentation/security_settings_screen.dart';
import '../../features/profile/presentation/travel_preferences_screen.dart';
import '../../features/profile/presentation/loyalty_program_screen.dart';
import '../../features/profile/presentation/delete_account_screen.dart';
import '../../features/profile/presentation/address_book_screen.dart';
import '../../features/profile/presentation/linked_accounts_screen.dart';
import '../../features/notifications/presentation/notifications_screen.dart';
import '../../features/wallet/presentation/wallet_screen.dart';
import '../../features/payment_methods/presentation/payment_methods_screen.dart';
import '../../features/payment_methods/presentation/add_card_screen.dart';
import '../../features/payment_methods/presentation/emi_screen.dart';
import '../../features/payment_methods/presentation/add_upi_screen.dart';
import '../../features/help/presentation/help_center_screen.dart';
import '../../features/help/presentation/support_ticket_screen.dart';
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
import '../../features/reviews/presentation/rate_stay_screen.dart';
import '../../features/map/presentation/map_search_screen.dart';
import '../../features/ai_chat/presentation/ai_chat_screen.dart';
import '../../features/advanced/presentation/advanced_features_screen.dart';
import '../../features/location/presentation/location_selector_screen.dart';
import '../../features/search/presentation/date_picker_screen.dart';
import '../../features/search/presentation/guest_room_selector_screen.dart';
import '../../features/hotel/presentation/deals_screen.dart';
import '../../features/hotel/presentation/recently_viewed_screen.dart';
import '../../features/hotel/presentation/hotel_policies_screen.dart';
import '../../features/hotel/presentation/nearby_attractions_screen.dart';
import '../../features/hotel/presentation/compare_hotels_screen.dart';
import '../../features/settings/presentation/language_selector_screen.dart';
import '../../features/settings/presentation/currency_selector_screen.dart';
import '../../features/settings/presentation/notification_settings_screen.dart';
import '../../features/settings/presentation/accessibility_settings_screen.dart';
import '../../features/invite/presentation/referral_history_screen.dart';
import '../../features/invite/presentation/invite_earn_screen.dart';
import '../../features/trips/presentation/my_trips_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/about/presentation/about_screen.dart';
import '../../features/about/presentation/terms_screen.dart';
// Owner screens
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/bookings/presentation/screens/booking_management_screen.dart';
import '../../features/rooms/presentation/screens/manage_rooms_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/amenities/presentation/screens/amenities_management_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/gallery/presentation/screens/gallery_management_screen.dart';
import '../../features/debug/hotel_registration_debug.dart';
import '../../features/debug/hotel_auth_debug.dart';
import '../../features/debug/room_images_debug.dart';
import '../../features/messaging/presentation/screens/guest_messaging_screen.dart';
import '../../features/support/presentation/screens/help_support_screen.dart';
import '../../features/offers/presentation/screens/offers_screen.dart';
import '../../features/pricing/presentation/screens/pricing_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reviews/presentation/screens/reviews_screen.dart' as owner_reviews;
import '../../features/settings/presentation/screens/settings_screen.dart' as owner_settings;
import '../../features/withdrawals/presentation/screens/withdrawals_screen.dart';
import '../../features/orders/presentation/screens/ordering_dashboard_screen.dart';
import '../../features/orders/presentation/screens/menu_management_screen.dart';
import '../../features/orders/presentation/screens/order_management_screen.dart';
import '../../features/orders/presentation/screens/order_analytics_screen.dart';
import '../../features/orders/presentation/screens/add_menu_item_screen.dart';
import '../../features/checkin/presentation/screens/qr_checkin_screen.dart';
import '../../features/pricing/presentation/screens/dynamic_pricing_screen.dart';
import '../../features/pricing/presentation/screens/competitor_benchmarking_screen.dart';
import '../../features/reports/presentation/screens/tax_report_screen.dart';
import '../../features/calendar/presentation/screens/ical_sync_screen.dart';
import '../../features/calendar/presentation/screens/yearly_calendar_screen.dart';
import '../../features/settings/presentation/screens/multi_currency_screen.dart';
import '../../features/messaging/presentation/screens/automated_messaging_screen.dart';
import '../../features/auth/presentation/screens/biometric_2fa_screen.dart';
import '../../features/hotel/presentation/screens/hotel_registration_screen_updated.dart';
import '../../features/hotel/presentation/screens/hotel_registration_step1.dart';
import '../../features/hotel/presentation/screens/hotel_registration_step2.dart';
import '../../features/hotel/presentation/screens/hotel_registration_step3.dart';
import '../../features/hotel/presentation/screens/hotel_registration_step4.dart';
import '../../features/hotel/presentation/screens/registration_review_screen.dart';
import '../../features/hotel/presentation/models/hotel_registration_data.dart';
import '../../features/hotel/presentation/screens/hotel_pending_approval_screen.dart';
// ── New screens from endpoint setup ───────────────────────────────────────
import '../../features/waitlist/presentation/screens/waitlist_screen.dart';
import '../../features/digital_key/presentation/screens/digital_key_screen.dart';
import '../../features/corporate/presentation/screens/corporate_travel_screen.dart';
import '../../features/group_bookings/presentation/screens/group_bookings_screen.dart';
import '../../features/membership/presentation/screens/membership_screen.dart';
import '../../features/concierge/presentation/screens/concierge_screen.dart';
import '../../features/pre_arrival/presentation/screens/pre_arrival_screen.dart';
import '../../features/mid_stay_feedback/presentation/screens/mid_stay_feedback_screen.dart';
import '../../features/insurance/presentation/screens/travel_insurance_screen.dart';
import '../../features/smart_room/presentation/screens/smart_room_screen.dart';
import '../../features/eco/presentation/screens/eco_screen.dart';
import '../../features/split_payment/presentation/screens/split_payment_screen.dart';
import '../../features/id_verification/presentation/screens/id_verification_screen.dart';
import '../../features/housekeeping/presentation/screens/housekeeping_screen.dart';
import '../../features/maintenance/presentation/screens/maintenance_screen.dart';
import '../../features/staff/presentation/screens/staff_management_screen.dart';
import '../../features/front_desk/presentation/screens/front_desk_screen.dart';
import '../../features/revenue/presentation/screens/revenue_dashboard_screen.dart';
import '../../features/chains/presentation/screens/multi_property_screen.dart';
import '../../features/inventory/presentation/screens/inventory_screen.dart';
import '../../features/reputation/presentation/screens/reputation_screen.dart';
import '../../features/affiliate/presentation/screens/affiliate_screen.dart';
import '../../features/pms/presentation/screens/pms_integration_screen.dart';
import '../../features/long_stay/presentation/screens/long_stay_rates_screen.dart';
import '../../features/post_stay/presentation/screens/post_stay_screen.dart';
import '../../features/post_stay/presentation/screens/post_stay_survey_screen.dart';
import '../../features/about/presentation/guest_protection_screen.dart';
import '../../features/support/presentation/screens/guest_complaint_screen.dart';
import '../../features/search/presentation/nlp_search_screen.dart';
import '../../features/events/presentation/screens/event_spaces_screen.dart';
import '../../features/flash_sales/presentation/screens/flash_sales_screen.dart';
import '../../features/packages/presentation/screens/packages_screen.dart';
import '../../features/addons/presentation/screens/addons_screen.dart';
import '../../features/activities/presentation/screens/activities_screen.dart';
import '../../features/price_alerts/presentation/screens/price_alerts_screen.dart';
import '../../features/hotel/presentation/near_me_screen.dart';
// In-stay ordering (guest)
import '../../features/in_stay_ordering/presentation/screens/menu_screen.dart';
import '../../features/in_stay_ordering/presentation/screens/cart_screen.dart';
import '../../features/in_stay_ordering/presentation/screens/my_orders_screen.dart';
import '../../features/in_stay_ordering/presentation/screens/order_confirmation_screen.dart';
import '../../features/in_stay_ordering/presentation/screens/order_details_screen.dart';
// Checkin dashboard (owner)
import '../../features/checkin/presentation/screens/checkin_dashboard_screen.dart';
// In-Stay mode
import '../../features/instay/presentation/in_stay_dashboard_screen.dart';
import 'main_navigation.dart';
import 'owner_navigation.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final GoRouter appRouter = GoRouter(
  navigatorKey: navigatorKey,
  initialLocation: '/splash',
  routes: [
    // ── Splash / Auth ──────────────────────────────────────────────────────
    GoRoute(path: '/splash', builder: (_, __) => const SplashScreen()),
    GoRoute(path: '/role-selection', builder: (_, __) => const RoleSelectionScreen()),
    GoRoute(path: '/onboarding', builder: (_, __) => const OnboardingScreen()),
    GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
    GoRoute(path: '/signup', builder: (_, __) => const SignupScreen()),
    GoRoute(path: '/otp-verification', builder: (_, __) => const OTPVerificationScreen()),
    GoRoute(path: '/forgot-password', builder: (_, __) => const ForgotPasswordScreen()),

    // ── Customer Shell ─────────────────────────────────────────────────────
    GoRoute(path: '/home', builder: (_, __) => const MainNavigation()),
    GoRoute(path: '/main-navigation', builder: (_, __) => const MainNavigation()),
    GoRoute(path: '/search', builder: (_, __) => const SearchScreen()),
    GoRoute(path: '/hotel-list', builder: (_, s) => HotelListScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/hotel-details', builder: (_, s) => HotelDetailsScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/my-hotel-details', builder: (_, __) => const OwnerHotelDetailsScreen.HotelDetailsScreen()),
    GoRoute(path: '/booking-form', builder: (_, s) => BookingFormScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/payment', builder: (_, s) => PaymentScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/booking-success', builder: (_, __) => const BookingSuccessScreen()),
    GoRoute(path: '/booking-detail', builder: (_, s) => BookingDetailScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/booking-cancellation', builder: (_, s) => BookingCancellationScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/booking-modification', builder: (_, s) => BookingModificationScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/online-checkin', builder: (_, s) => OnlineCheckinScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/invoice', builder: (_, s) => InvoiceScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/refund-status', builder: (_, s) => RefundStatusScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
    GoRoute(path: '/personal-info', builder: (_, __) => const PersonalInfoScreen()),
    GoRoute(path: '/profile-complete', builder: (_, __) => const ProfileCompleteScreen()),
    GoRoute(path: '/security-settings', builder: (_, __) => const SecuritySettingsScreen()),
    GoRoute(path: '/travel-preferences', builder: (_, __) => const TravelPreferencesScreen()),
    GoRoute(path: '/loyalty-program', builder: (_, __) => const LoyaltyProgramScreen()),
    GoRoute(path: '/delete-account', builder: (_, __) => const DeleteAccountScreen()),
    GoRoute(path: '/address-book', builder: (_, __) => const AddressBookScreen()),
    GoRoute(path: '/linked-accounts', builder: (_, __) => const LinkedAccountsScreen()),
    GoRoute(path: '/notifications', builder: (_, __) => const NotificationsScreen()),
    GoRoute(path: '/wallet', builder: (_, __) => const WalletScreen()),
    GoRoute(path: '/payment-methods', builder: (_, __) => const PaymentMethodsScreen()),
    GoRoute(path: '/add-card', builder: (_, __) => const AddCardScreen()),
    GoRoute(path: '/emi', builder: (_, s) => EmiScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/add-upi', builder: (_, __) => const AddUpiScreen()),
    GoRoute(path: '/help-center', builder: (_, __) => const HelpCenterScreen()),
    GoRoute(path: '/support-ticket', builder: (_, __) => const SupportTicketScreen()),
    GoRoute(path: '/coupons', builder: (_, __) => const CouponsScreen()),
    GoRoute(path: '/filters', builder: (_, __) => const FiltersScreen()),
    GoRoute(path: '/gallery', builder: (_, __) => const GalleryScreen()),
    GoRoute(path: '/chat', builder: (_, __) => const ChatScreen()),
    GoRoute(path: '/amenities', builder: (_, __) => const AmenitiesScreen()),
    GoRoute(path: '/room-types', builder: (_, __) => const RoomTypesScreen()),
    GoRoute(path: '/pricing-breakdown', builder: (_, s) => PricingBreakdownScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/hotel-reviews', builder: (_, s) => HotelReviewsScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/review-submission', builder: (_, s) => ReviewSubmissionScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/pending-reviews', builder: (_, __) => const PendingReviewsScreen()),
    GoRoute(path: '/rate-stay', builder: (_, s) => RateStayScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/map-search', builder: (_, __) => const MapSearchScreen()),
    GoRoute(path: '/ai-chat', builder: (_, __) => const AIChatScreen()),
    GoRoute(path: '/advanced-features', builder: (_, __) => const AdvancedFeaturesScreen()),
    GoRoute(path: '/location-selector', builder: (_, __) => const LocationSelectorScreen()),
    GoRoute(path: '/date-picker', builder: (_, s) => DatePickerScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/guest-room-selector', builder: (_, s) => GuestRoomSelectorScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/deals', builder: (_, __) => const DealsScreen()),
    GoRoute(path: '/recently-viewed', builder: (_, __) => const RecentlyViewedScreen()),
    GoRoute(path: '/hotel-policies', builder: (_, s) => HotelPoliciesScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/nearby-attractions', builder: (_, s) => NearbyAttractionsScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/compare-hotels', builder: (_, s) => CompareHotelsScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/language-selector', builder: (_, __) => const LanguageSelectorScreen()),
    GoRoute(path: '/currency-selector', builder: (_, __) => const CurrencySelectorScreen()),
    GoRoute(path: '/notification-settings', builder: (_, __) => const NotificationSettingsScreen()),
    GoRoute(path: '/accessibility-settings', builder: (_, __) => const AccessibilitySettingsScreen()),
    GoRoute(path: '/referral-history', builder: (_, __) => const ReferralHistoryScreen()),
    GoRoute(path: '/invite-earn', builder: (_, __) => const InviteEarnScreen()),
    GoRoute(path: '/my-trips', builder: (_, __) => const MyTripsScreen()),
    GoRoute(path: '/saved', builder: (_, __) => const SavedScreen()),
    GoRoute(path: '/about', builder: (_, __) => const AboutScreen()),
    GoRoute(path: '/terms', builder: (_, __) => const TermsScreen()),

    // ── Owner Shell ────────────────────────────────────────────────────────
    GoRoute(path: '/owner/dashboard', builder: (_, __) => const OwnerNavigation()),
    GoRoute(path: '/dashboard', builder: (_, __) => const DashboardScreen()),
    GoRoute(path: '/bookings', builder: (_, __) => const BookingManagementScreen()),
    GoRoute(path: '/rooms', builder: (_, __) => const ManageRoomsScreen()),
    GoRoute(path: '/earnings', builder: (_, __) => const EarningsScreen()),
    GoRoute(path: '/amenities-management', builder: (_, __) => const AmenitiesManagementScreen()),
    GoRoute(path: '/analytics', builder: (_, __) => const AnalyticsScreen()),
    GoRoute(path: '/calendar', builder: (_, __) => const CalendarScreen()),
    GoRoute(path: '/documents', builder: (_, __) => const DocumentsScreen()),
    GoRoute(path: '/gallery-management', builder: (_, __) => const GalleryManagementScreen()),
    GoRoute(path: '/guest-messaging', builder: (_, __) => const GuestMessagingScreen()),
    GoRoute(path: '/help', builder: (_, __) => const HelpSupportScreen()),
    GoRoute(path: '/offers', builder: (_, __) => const OffersScreen()),
    GoRoute(path: '/pricing', builder: (_, __) => const PricingScreen()),
    GoRoute(path: '/reports', builder: (_, __) => const ReportsScreen()),
    GoRoute(path: '/reviews', builder: (_, __) => const owner_reviews.ReviewsScreen()),
    GoRoute(path: '/settings', builder: (_, __) => const owner_settings.SettingsScreen()),
    GoRoute(path: '/withdrawals', builder: (_, __) => const WithdrawalsScreen()),
    GoRoute(path: '/ordering', builder: (_, __) => const OrderingDashboardScreen()),
    GoRoute(path: '/menu-management', builder: (_, __) => const MenuManagementScreen()),
    GoRoute(path: '/order-management', builder: (_, __) => const OrderManagementScreen()),
    GoRoute(path: '/order-analytics', builder: (_, __) => const OrderAnalyticsScreen()),
    GoRoute(path: '/add-menu-item', builder: (_, s) => AddMenuItemScreen(item: s.extra as dynamic)),
    GoRoute(path: '/qr-checkin', builder: (_, __) => const QrCheckinScreen()),
    GoRoute(path: '/dynamic-pricing', builder: (_, __) => const DynamicPricingScreen()),
    GoRoute(path: '/competitor-benchmarking', builder: (_, __) => const CompetitorBenchmarkingScreen()),
    GoRoute(path: '/tax-report', builder: (_, __) => const TaxReportScreen()),
    GoRoute(path: '/ical-sync', builder: (_, __) => const ICalSyncScreen()),
    GoRoute(path: '/yearly-calendar', builder: (_, __) => const YearlyCalendarScreen()),
    GoRoute(path: '/multi-currency', builder: (_, __) => const MultiCurrencyScreen()),
    GoRoute(path: '/automated-messaging', builder: (_, __) => const AutomatedMessagingScreen()),
    GoRoute(path: '/security-2fa', builder: (_, __) => const Biometric2FAScreen()),
    GoRoute(path: '/hotel-registration', builder: (_, s) => const HotelRegistrationScreenUpdated()),
    GoRoute(path: '/hotel-registration/step-1', builder: (_, s) {
      final data = s.extra is HotelRegistrationData ? s.extra as HotelRegistrationData : const HotelRegistrationData();
      return HotelRegistrationStep1(registrationData: data);
    }),
    GoRoute(path: '/hotel-registration/step-2', builder: (_, s) {
      final data = s.extra is HotelRegistrationData ? s.extra as HotelRegistrationData : const HotelRegistrationData();
      return HotelRegistrationStep2(registrationData: data);
    }),
    GoRoute(path: '/hotel-registration/step-3', builder: (_, s) {
      final data = s.extra is HotelRegistrationData ? s.extra as HotelRegistrationData : const HotelRegistrationData();
      return HotelRegistrationStep3(registrationData: data);
    }),
    GoRoute(path: '/hotel-registration/step-4', builder: (_, s) {
      final data = s.extra is HotelRegistrationData ? s.extra as HotelRegistrationData : const HotelRegistrationData();
      return HotelRegistrationStep4(registrationData: data);
    }),
    GoRoute(path: '/registration-review', builder: (_, s) {
      HotelRegistrationData d;
      
      if (s.extra is HotelRegistrationData) {
        // Handle HotelRegistrationData object (from step-by-step flow)
        d = s.extra as HotelRegistrationData;
        debugPrint('📋 Router: Received HotelRegistrationData object');
      } else if (s.extra is Map<String, dynamic>) {
        // Handle Map data (from single-screen registration)
        final mapData = s.extra as Map<String, dynamic>;
        debugPrint('📋 Router: Received Map data with keys: ${mapData.keys.toList()}');
        debugPrint('📋 Router: Hotel Name from Map: ${mapData['hotelName']}');
        d = HotelRegistrationData(
          hotelName: mapData['hotelName'] ?? '',
          propertyType: mapData['propertyType'] ?? 'Hotel',
          totalRooms: mapData['totalRooms']?.toString() ?? '',
          yearOfEstablishment: mapData['yearOfEstablishment']?.toString() ?? '',
          priceRangeMin: mapData['priceRangeMin']?.toString() ?? '',
          priceRangeMax: mapData['priceRangeMax']?.toString() ?? '',
          hotelDescription: mapData['hotelDescription'] ?? '',
          country: mapData['country'] ?? '',
          state: mapData['state'] ?? '',
          district: mapData['district'] ?? '',
          city: mapData['city'] ?? '',
          wardNumber: mapData['wardNumber'] ?? '',
          hotelAddress: mapData['hotelAddress'] ?? '',
          landmark: mapData['landmark'] ?? '',
          latitude: mapData['latitude'],
          longitude: mapData['longitude'],
          hotelPhone: mapData['hotelPhone'] ?? '',
          termsAccepted: mapData['termsAccepted'] ?? false,
          commissionAccepted: mapData['commissionAccepted'] ?? false,
          cancellationPolicyAccepted: mapData['cancellationPolicyAccepted'] ?? false,
          exteriorPhoto: mapData['exteriorPhoto'] as File?,
          receptionPhoto: mapData['receptionPhoto'] as File?,
          galleryPhotos: (mapData['galleryPhotos'] as List<File>?) ?? [],
        );
      } else {
        // Default empty data
        debugPrint('📋 Router: No data received, using empty HotelRegistrationData');
        d = const HotelRegistrationData();
      }
      
      debugPrint('📋 Router: Final hotel name: ${d.hotelName}');
      
      return HotelRegistrationReviewScreen(
        hotelName: d.hotelName,
        propertyType: d.propertyType,
        totalRooms: d.totalRooms,
        yearOfEstablishment: d.yearOfEstablishment,
        priceRangeMin: d.priceRangeMin,
        priceRangeMax: d.priceRangeMax,
        hotelDescription: d.hotelDescription,
        country: d.country,
        state: d.state,
        district: d.district,
        city: d.city,
        wardNumber: d.wardNumber,
        hotelAddress: d.hotelAddress,
        landmark: d.landmark,
        latitude: d.latitude,
        longitude: d.longitude,
        hotelPhone: d.hotelPhone,
        termsAccepted: d.termsAccepted,
        commissionAccepted: d.commissionAccepted,
        cancellationPolicyAccepted: d.cancellationPolicyAccepted,
        exteriorPhoto: d.exteriorPhoto,
        receptionPhoto: d.receptionPhoto,
        galleryPhotos: d.galleryPhotos,
      );
    }),
    GoRoute(path: '/hotel-pending-approval', builder: (_, __) => const HotelPendingApprovalScreen()),
    // Debug routes — only available in debug builds
    if (kDebugMode) ...[
      GoRoute(path: '/debug/hotel-registration', builder: (_, __) => const HotelRegistrationDebugScreen()),
      GoRoute(path: '/debug/hotel-auth', builder: (_, __) => const HotelAuthDebugScreen()),
      GoRoute(path: '/debug/room-images', builder: (_, __) => const RoomImagesDebugScreen()),
    ],

    // ── New Guest Screens ──────────────────────────────────────────────────
    GoRoute(path: '/waitlist', builder: (_, __) => const WaitlistScreen()),
    GoRoute(path: '/digital-key', builder: (_, __) => const DigitalKeyScreen()),
    GoRoute(path: '/corporate-travel', builder: (_, __) => const CorporateTravelScreen()),
    GoRoute(path: '/group-bookings', builder: (_, __) => const GroupBookingsScreen()),
    GoRoute(path: '/membership', builder: (_, __) => const MembershipScreen()),
    GoRoute(path: '/concierge', builder: (_, __) => const ConciergeScreen()),
    GoRoute(path: '/pre-arrival', builder: (_, s) => PreArrivalScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/mid-stay-feedback', builder: (_, s) => MidStayFeedbackScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/travel-insurance', builder: (_, __) => const TravelInsuranceScreen()),
    GoRoute(path: '/smart-room', builder: (_, s) => SmartRoomScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/eco', builder: (_, s) => EcoScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/split-payment', builder: (_, s) => SplitPaymentScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/id-verification', builder: (_, __) => const IdVerificationScreen()),
    GoRoute(path: '/price-alerts', builder: (_, __) => const PriceAlertsScreen()),
    GoRoute(path: '/activities', builder: (_, s) => ActivitiesScreen(arguments: s.extra as Map<String, dynamic>?)),
    GoRoute(path: '/affiliate', builder: (_, __) => const AffiliateScreen()),
    GoRoute(path: '/near-me', builder: (_, __) => const NearMeScreen()),
    GoRoute(path: '/nlp-search', builder: (_, __) => const NlpSearchScreen()),
    // ── In-Stay Mode ──────────────────────────────────────────────────────
    GoRoute(path: '/in-stay', builder: (_, s) =>
        InStayDashboardScreen(booking: s.extra as Map<String, dynamic>?)),
    // In-stay ordering (guest)
    GoRoute(path: '/menu', builder: (_, s) {
      final args = s.extra as Map<String, dynamic>?;
      return MenuScreen(
        hotelId: args?['hotel_id'] ?? 0,
        hotelName: args?['hotel_name'] ?? 'Hotel',
        bookingId: args?['booking_id'],
      );
    }),
    GoRoute(path: '/cart', builder: (_, s) {
      final args = s.extra as Map<String, dynamic>?;
      return CartScreen(
        hotelId: args?['hotel_id'] ?? 0,
        bookingId: args?['booking_id'],
      );
    }),
    GoRoute(path: '/my-orders', builder: (_, s) {
      final args = s.extra as Map<String, dynamic>?;
      return MyOrdersScreen(bookingId: args?['booking_id']);
    }),
    GoRoute(path: '/order-confirmation', builder: (_, s) {
      final args = s.extra as Map<String, dynamic>? ?? {};
      return OrderConfirmationScreen(orderData: args);
    }),
    // Checkin dashboard (owner)
    GoRoute(path: '/checkin-dashboard', builder: (_, __) => const CheckinDashboardScreen()),

    // ── New Owner Screens ──────────────────────────────────────────────────
    GoRoute(path: '/housekeeping', builder: (_, __) => const HousekeepingScreen()),
    GoRoute(path: '/maintenance', builder: (_, __) => const MaintenanceScreen()),
    GoRoute(path: '/staff-management', builder: (_, __) => const StaffManagementScreen()),
    GoRoute(path: '/front-desk', builder: (_, __) => const FrontDeskScreen()),
    GoRoute(path: '/revenue-dashboard', builder: (_, __) => const RevenueDashboardScreen()),
    GoRoute(path: '/multi-property', builder: (_, __) => const MultiPropertyScreen()),
    GoRoute(path: '/inventory', builder: (_, __) => const InventoryScreen()),
    GoRoute(path: '/reputation', builder: (_, __) => const ReputationScreen()),
    GoRoute(path: '/pms-integration', builder: (_, __) => const PmsIntegrationScreen()),
    GoRoute(path: '/long-stay-rates', builder: (_, __) => const LongStayRatesScreen()),
    GoRoute(path: '/post-stay', builder: (_, __) => const PostStayScreen()),
    // ── Brand Trust Routes ─────────────────────────────────────────────────
    GoRoute(path: '/guest-protection', builder: (_, __) => const GuestProtectionScreen()),
    GoRoute(path: '/raise-complaint', builder: (_, s) {
      final args = s.extra as Map<String, dynamic>?;
      return GuestComplaintScreen(
        bookingId: args?['bookingId'],
        hotelName: args?['hotelName'],
      );
    }),
    GoRoute(path: '/post-stay-survey', builder: (_, s) {
      final args = s.extra as Map<String, dynamic>? ?? {};
      return PostStaySurveyScreen(
        bookingId: args['bookingId'] ?? '',
        hotelName: args['hotelName'] ?? 'Hotel',
      );
    }),
    GoRoute(path: '/event-spaces', builder: (_, __) => const EventSpacesScreen()),
    GoRoute(path: '/flash-sales', builder: (_, __) => const FlashSalesScreen()),
    GoRoute(path: '/packages', builder: (_, __) => const PackagesScreen()),
    GoRoute(path: '/addons', builder: (_, __) => const AddonsScreen()),
    GoRoute(path: '/owner-activities', builder: (_, __) => const ActivitiesScreen(isOwner: true)),
  ],
);
