import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/signup_screen.dart';
import '../../features/auth/presentation/screens/otp_verification_screen.dart';
import '../../features/auth/presentation/screens/onboarding_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/bookings/presentation/screens/booking_management_screen.dart';
import '../../features/rooms/presentation/screens/manage_rooms_screen.dart';
import '../../features/rooms/presentation/screens/room_status_screen.dart';
import '../../features/earnings/presentation/screens/earnings_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/amenities/presentation/screens/amenities_management_screen.dart';
import '../../features/analytics/presentation/screens/analytics_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/documents/presentation/screens/documents_screen.dart';
import '../../features/gallery/presentation/screens/gallery_management_screen.dart';
import '../../features/messaging/presentation/screens/guest_messaging_screen.dart';
import '../../features/messaging/presentation/screens/owner_chat_screen.dart';
import '../../features/support/presentation/screens/help_support_screen.dart';
import '../../features/hotel/presentation/screens/hotel_registration_screen_updated.dart';
import '../../features/hotel/presentation/screens/hotel_registration_step1.dart';
import '../../features/hotel/presentation/screens/hotel_registration_step2.dart';
import '../../features/hotel/presentation/screens/hotel_registration_step3.dart';
import '../../features/hotel/presentation/screens/hotel_registration_step4.dart';
import '../../features/hotel/presentation/screens/hotel_pending_approval_screen.dart';
import '../../features/hotel/presentation/screens/hotel_details_screen.dart';
import '../../features/hotel/presentation/screens/registration_review_screen.dart';
import '../../features/hotel/presentation/screens/hotel_list_screen.dart';
import '../../features/hotel/presentation/screens/hotel_location_map_screen.dart';
import '../../features/hotel/presentation/models/hotel_registration_data.dart';
import '../../features/notifications/presentation/screens/notifications_screen.dart';
import '../../features/offers/presentation/screens/offers_screen.dart';
import '../../features/pricing/presentation/screens/pricing_screen.dart';
import '../../features/reports/presentation/screens/reports_screen.dart';
import '../../features/reviews/presentation/screens/reviews_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';
import '../../features/withdrawals/presentation/screens/withdrawals_screen.dart';
import '../../features/chat/presentation/screens/chat_screen.dart';
import '../../features/loyalty/presentation/screens/loyalty_screen.dart';
import '../../features/orders/presentation/screens/orders_screen.dart';
import '../../features/price_alerts/presentation/screens/price_alerts_screen.dart';
import '../../features/calendar/presentation/screens/yearly_calendar_screen.dart';
import '../../features/calendar/presentation/screens/ical_sync_screen.dart';
import '../../features/auth/presentation/screens/biometric_2fa_screen.dart';
import '../../features/messaging/presentation/screens/automated_messaging_screen.dart';
import '../../features/pricing/presentation/screens/dynamic_pricing_screen.dart';
import '../../features/pricing/presentation/screens/competitor_benchmarking_screen.dart';
import '../../features/settings/presentation/screens/multi_currency_screen.dart';
import '../../features/reports/presentation/screens/tax_report_screen.dart';
import '../../features/gallery/presentation/screens/video_tour_screen.dart';
import '../../features/reviews/presentation/screens/review_request_screen.dart';
import '../../features/checkin/presentation/screens/qr_checkin_screen.dart';
import '../../features/checkin/presentation/screens/checkin_dashboard_screen.dart';
import '../../features/orders/presentation/screens/ordering_dashboard_screen.dart';
import '../../features/orders/presentation/screens/menu_management_screen.dart';
import '../../features/orders/presentation/screens/add_menu_item_screen.dart';
import '../../features/orders/presentation/screens/order_management_screen.dart';
import '../../features/orders/presentation/screens/order_analytics_screen.dart';
import '../../features/orders/data/models/menu_item_model.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../constants/app_constants.dart';
import '../../features/hotel/presentation/services/hotel_service.dart';

class AppRouter {
  static Future<String?> _checkHotelStatus(AuthProvider authProvider) async {
    // Don't check if no token or user is null
    if (authProvider.token == null || authProvider.token!.isEmpty) {
      return null;
    }

    if (authProvider.user == null) {
      return null;
    }

    try {
      HotelService.setToken(authProvider.token ?? '');
      final hotelService = HotelService();
      final response = await hotelService.getHotelStatus();

      debugPrint('AppRouter _checkHotelStatus response: $response');

      // Check if response is successful and contains valid hotel data
      if (response['success'] == true &&
          response['data'] != null &&
          response['data'] is Map &&
          (response['data'] as Map).isNotEmpty &&
          (response['data'] as Map).containsKey('status')) {
        final status = response['data']['status'] as String?;

        // Validate status is a known value
        if (status == null || status.isEmpty) {
          debugPrint('Empty status in _checkHotelStatus, returning null');
          await authProvider.updateHotelStatus(false);
          await authProvider.setHotelApproved(false);
          return null;
        }

        // Update user's hotel status based on backend
        if ((status == 'APPROVED' || status == 'ACTIVE') && !authProvider.user!.hasHotel) {
          await authProvider.updateHotelStatus(true);
        } else if (status != 'APPROVED' && status != 'ACTIVE' && authProvider.user!.hasHotel) {
          await authProvider.updateHotelStatus(false);
        }

        // Update hotel approval status
        await authProvider.setHotelApproved(status == 'APPROVED' || status == 'ACTIVE');

        return status;
      } else {
        // No hotel found - return null to indicate no hotel
        debugPrint('No hotel found in _checkHotelStatus, returning null');
        await authProvider.updateHotelStatus(false);
        await authProvider.setHotelApproved(false);
        return null;
      }
    } catch (e) {
      debugPrint('Error checking hotel status: $e');
    }
    return null;
  }

  /// Simplified redirect function that avoids context issues
  /// Returns null to allow navigation, or path to redirect to
  static String? _redirectToValidRoute(
    BuildContext context,
    GoRouterState state,
  ) {
    // Skip redirect for login and other auth routes
    final publicRoutes = [
      '/login',
      '/signup',
      '/forgot-password',
      '/otp',
      '/onboarding',
    ];

    if (publicRoutes.contains(state.uri.path)) {
      return null;
    }

    // Try to get auth provider from context - this is safe here because
    // this redirect is called after the widget tree is built
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Check if user is authenticated
      if (authProvider.token == null || authProvider.token!.isEmpty) {
        return '/login';
      }

      // Check if user exists
      if (authProvider.user == null) {
        return '/login';
      }
    } catch (e) {
      // If we can't get the provider (context issue), redirect to login
      debugPrint('Error in redirect: $e');
      return '/login';
    }

    return null;
  }

  static final GoRouter router = GoRouter(
    initialLocation: AppConstants.loginScreen,
    redirect: (context, state) => _redirectToValidRoute(context, state),
    routes: [
      // Authentication Routes
      GoRoute(
        path: AppConstants.loginScreen,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignUpScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        name: 'forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppConstants.otpScreen,
        name: 'otp',
        builder: (context, state) {
          final phoneNumber = state.uri.queryParameters['phone'] ?? '';
          return OTPVerificationScreen(phoneNumber: phoneNumber);
        },
      ),
      GoRoute(
        path: AppConstants.onboardingScreen,
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main App Routes with Bottom Navigation
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationScreen(child: child!);
        },
        routes: [
          GoRoute(
            path: AppConstants.dashboardScreen,
            name: 'dashboard',
            builder: (context, state) {
              return Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.isHotelApproved) {
                    return const DashboardScreen();
                  }
                  // hasHotel but not yet approved → pending
                  if (authProvider.user?.hasHotel == true) {
                    return const HotelPendingApprovalScreen();
                  }
                  // No hotel at all → registration
                  return HotelRegistrationStep1(
                    registrationData: HotelRegistrationData(),
                  );
                },
              );
            },
          ),
          GoRoute(
            path: AppConstants.bookingsScreen,
            name: 'bookings',
            builder: (context, state) => const BookingManagementScreen(),
          ),
          GoRoute(
            path: AppConstants.roomsScreen,
            name: 'rooms',
            builder: (context, state) => const ManageRoomsScreen(),
          ),
          GoRoute(
            path: AppConstants.earningsScreen,
            name: 'earnings',
            builder: (context, state) => const EarningsScreen(),
          ),
          GoRoute(
            path: AppConstants.profileScreen,
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Additional Feature Routes
      GoRoute(
          path: '/amenities-management',
          name: 'amenities-management',
          builder: (context, state) => const AmenitiesManagementScreen()),
      GoRoute(
          path: '/analytics',
          name: 'analytics',
          builder: (context, state) => const AnalyticsScreen()),
      GoRoute(
          path: '/calendar',
          name: 'calendar',
          builder: (context, state) => const CalendarScreen()),
      GoRoute(
          path: '/documents',
          name: 'documents',
          builder: (context, state) => const DocumentsScreen()),
      GoRoute(
          path: '/gallery-management',
          name: 'gallery-management',
          builder: (context, state) => const GalleryManagementScreen()),
      GoRoute(
          path: '/guest-messaging',
          name: 'guest-messaging',
          builder: (context, state) => const GuestMessagingScreen()),
      GoRoute(
          path: '/owner-chat',
          name: 'owner-chat',
          builder: (context, state) => const OwnerChatScreen()),
      GoRoute(
          path: '/chat',
          name: 'chat',
          builder: (context, state) => const ChatScreen()),
      GoRoute(
          path: '/help',
          name: 'help',
          builder: (context, state) => const HelpSupportScreen()),
      GoRoute(
          path: '/help-support',
          name: 'help-support',
          builder: (context, state) => const HelpSupportScreen()),
      GoRoute(
          path: '/hotel-registration',
          name: 'hotel-registration',
          builder: (context, state) => const HotelRegistrationStep1(
                registrationData: HotelRegistrationData(),
              )),

      // Step-by-step registration routes
      GoRoute(
        path: '/hotel-registration/step-1',
        name: 'hotel-registration-step-1',
        builder: (context, state) {
          final extra = state.extra as HotelRegistrationData?;
          return HotelRegistrationStep1(
            registrationData: extra ?? HotelRegistrationData(),
          );
        },
      ),
      GoRoute(
        path: '/hotel-registration/step-2',
        name: 'hotel-registration-step-2',
        builder: (context, state) {
          final extra = state.extra as HotelRegistrationData?;
          return HotelRegistrationStep2(
            registrationData: extra ?? HotelRegistrationData(),
          );
        },
      ),
      GoRoute(
        path: '/hotel-registration/step-3',
        name: 'hotel-registration-step-3',
        builder: (context, state) {
          final extra = state.extra as HotelRegistrationData?;
          return HotelRegistrationStep3(
            registrationData: extra ?? HotelRegistrationData(),
          );
        },
      ),
      GoRoute(
        path: '/hotel-registration/step-4',
        name: 'hotel-registration-step-4',
        builder: (context, state) {
          final extra = state.extra as HotelRegistrationData?;
          return HotelRegistrationStep4(
            registrationData: extra ?? HotelRegistrationData(),
          );
        },
      ),
      GoRoute(
        path: '/hotel-pending-approval',
        name: 'hotel-pending-approval',
        builder: (context, state) => const HotelPendingApprovalScreen(),
      ),
      GoRoute(
          path: '/hotel-details',
          name: 'hotel-details',
          builder: (context, state) => const HotelDetailsScreen()),
      GoRoute(
          path: '/hotel-list',
          name: 'hotel-list',
          builder: (context, state) => const HotelListScreen()),
      GoRoute(
          path: '/registration-review',
          name: 'registration-review',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is HotelRegistrationData) {
              // Handle new step-by-step registration data
              return HotelRegistrationReviewScreen(
                hotelName: extra.hotelName,
                hotelAddress: extra.hotelAddress,
                propertyType: extra.propertyType,
                totalRooms: extra.totalRooms,
                yearOfEstablishment: extra.yearOfEstablishment,
                priceRangeMin: extra.priceRangeMin,
                priceRangeMax: extra.priceRangeMax,
                // Section 2: Location
                country: extra.country,
                state: extra.state,
                district: extra.district,
                city: extra.city,
                wardNumber: extra.wardNumber,
                landmark: extra.landmark,
                latitude: extra.latitude,
                longitude: extra.longitude,
                // Section 3: Contact
                hotelPhone: extra.hotelPhone,
                // Section 4: Agreements
                termsAccepted: extra.termsAccepted,
                commissionAccepted: extra.commissionAccepted,
                cancellationPolicyAccepted: extra.cancellationPolicyAccepted,
                hotelDescription: extra.hotelDescription,
                // Section 5: Photos
                exteriorPhoto: extra.exteriorPhoto,
                receptionPhoto: extra.receptionPhoto,
                galleryPhotos: extra.galleryPhotos,
              );
            } else {
              // Handle legacy Map<String, dynamic> data
              final mapData = extra as Map<String, dynamic>?;
              return HotelRegistrationReviewScreen(
                hotelName: mapData?['hotelName'] ?? '',
                hotelAddress: mapData?['hotelAddress'] ?? '',
                propertyType: mapData?['propertyType'] ?? 'Hotel',
                totalRooms: mapData?['totalRooms'] ?? '',
                yearOfEstablishment: mapData?['yearOfEstablishment'] ?? '',
                priceRangeMin: mapData?['priceRangeMin'] ?? '',
                priceRangeMax: mapData?['priceRangeMax'] ?? '',
                // Section 2: Location
                country: mapData?['country'] ?? 'Nepal',
                state: mapData?['state'] ?? '',
                district: mapData?['district'] ?? '',
                city: mapData?['city'] ?? '',
                wardNumber: mapData?['wardNumber'] ?? '',
                landmark: mapData?['landmark'] ?? '',
                latitude: mapData?['latitude'],
                longitude: mapData?['longitude'],
                // Section 3: Contact
                hotelPhone: mapData?['hotelPhone'] ?? '',
                // Section 4: Agreements
                termsAccepted: mapData?['termsAccepted'] ?? false,
                commissionAccepted: mapData?['commissionAccepted'] ?? false,
                cancellationPolicyAccepted:
                    mapData?['cancellationPolicyAccepted'] ?? false,
                hotelDescription: mapData?['hotelDescription'] ?? '',
                // Section 5: Photos
                exteriorPhoto: mapData?['exteriorPhoto'],
                receptionPhoto: mapData?['receptionPhoto'],
                galleryPhotos: mapData?['galleryPhotos'] ?? [],
              );
            }
          }),
      GoRoute(
          path: '/notifications',
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen()),
      GoRoute(
          path: '/offers',
          name: 'offers',
          builder: (context, state) => const OffersScreen()),
      GoRoute(
          path: '/pricing',
          name: 'pricing',
          builder: (context, state) => const PricingScreen()),
      GoRoute(
          path: '/reports',
          name: 'reports',
          builder: (context, state) => const ReportsScreen()),
      GoRoute(
          path: '/reviews',
          name: 'reviews',
          builder: (context, state) => const ReviewsScreen()),
      GoRoute(
          path: '/room-status',
          name: 'room-status',
          builder: (context, state) => const RoomStatusScreen()),
      GoRoute(
          path: '/settings',
          name: 'settings',
          builder: (context, state) => const SettingsScreen()),
      GoRoute(
          path: '/withdrawals',
          name: 'withdrawals',
          builder: (context, state) => const WithdrawalsScreen()),
      GoRoute(
          path: '/loyalty',
          name: 'loyalty',
          builder: (context, state) => const LoyaltyScreen()),
      GoRoute(
          path: '/orders',
          name: 'orders',
          builder: (context, state) => const OrdersScreen()),
      GoRoute(
          path: '/price-alerts',
          name: 'price-alerts',
          builder: (context, state) => const PriceAlertsScreen()),
      GoRoute(
          path: '/yearly-calendar',
          name: 'yearly-calendar',
          builder: (context, state) => const YearlyCalendarScreen()),
      GoRoute(
          path: '/ical-sync',
          name: 'ical-sync',
          builder: (context, state) => const ICalSyncScreen()),
      GoRoute(
          path: '/security-2fa',
          name: 'security-2fa',
          builder: (context, state) => const Biometric2FAScreen()),
      GoRoute(
          path: '/automated-messaging',
          name: 'automated-messaging',
          builder: (context, state) => const AutomatedMessagingScreen()),
      GoRoute(
          path: '/dynamic-pricing',
          name: 'dynamic-pricing',
          builder: (context, state) => const DynamicPricingScreen()),
      GoRoute(
          path: '/competitor-benchmarking',
          name: 'competitor-benchmarking',
          builder: (context, state) => const CompetitorBenchmarkingScreen()),
      GoRoute(
          path: '/multi-currency',
          name: 'multi-currency',
          builder: (context, state) => const MultiCurrencyScreen()),
      GoRoute(
          path: '/tax-report',
          name: 'tax-report',
          builder: (context, state) => const TaxReportScreen()),
      GoRoute(
          path: '/video-tour',
          name: 'video-tour',
          builder: (context, state) => const VideoTourScreen()),
      GoRoute(
          path: '/review-requests',
          name: 'review-requests',
          builder: (context, state) => const ReviewRequestScreen()),
      GoRoute(
          path: '/checkin-dashboard',
          name: 'checkin-dashboard',
          builder: (context, state) => const CheckinDashboardScreen()),
      GoRoute(
          path: '/qr-checkin',
          name: 'qr-checkin',
          builder: (context, state) => const QrCheckinScreen()),
      GoRoute(
          path: '/ordering',
          name: 'ordering',
          builder: (context, state) => const OrderingDashboardScreen()),
      GoRoute(
          path: '/menu-management',
          name: 'menu-management',
          builder: (context, state) => const MenuManagementScreen()),
      GoRoute(
          path: '/add-menu-item',
          name: 'add-menu-item',
          builder: (context, state) => const AddMenuItemScreen()),
      GoRoute(
          path: '/edit-menu-item/:id',
          name: 'edit-menu-item',
          builder: (context, state) {
            final item = state.extra as MenuItemModel?;
            return AddMenuItemScreen(item: item);
          }),
      GoRoute(
          path: '/order-management',
          name: 'order-management',
          builder: (context, state) => const OrderManagementScreen()),
      GoRoute(
          path: '/order-analytics',
          name: 'order-analytics',
          builder: (context, state) => const OrderAnalyticsScreen()),
      GoRoute(
          path: '/hotel-location-map',
          name: 'hotel-location-map',
          builder: (context, state) => HotelLocationMapScreen(
                initialLatitude: state.extra is LatLng
                    ? (state.extra as LatLng).latitude
                    : null,
                initialLongitude: state.extra is LatLng
                    ? (state.extra as LatLng).longitude
                    : null,
                hotelName: state.extra is Map
                    ? (state.extra as Map)['hotelName'] ?? 'Your Hotel'
                    : 'Your Hotel',
              )),
    ],
  );
}

class MainNavigationScreen extends StatefulWidget {
  final Widget child;

  const MainNavigationScreen({Key? key, required this.child}) : super(key: key);

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  static const _routes = [
    AppConstants.dashboardScreen,
    AppConstants.bookingsScreen,
    AppConstants.roomsScreen,
    AppConstants.profileScreen,
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _updateCurrentIndex();
  }

  void _updateCurrentIndex() {
    final location = GoRouterState.of(context).uri.toString();
    if (location == AppConstants.dashboardScreen) {
      _currentIndex = 0;
    } else if (location == AppConstants.bookingsScreen) {
      _currentIndex = 1;
    } else if (location == AppConstants.roomsScreen) {
      _currentIndex = 2;
    } else if (location == AppConstants.profileScreen) {
      _currentIndex = 3;
    }
  }

  void _onTap(int index) {
    setState(() => _currentIndex = index);
    context.go(_routes[index]);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        final bool showBottomNav = authProvider.isHotelApproved;
        // Navbar height: 64px container + 12px bottom gap + system bottom inset
        final bottomInset = MediaQuery.of(context).padding.bottom;
        final navbarClearance = showBottomNav ? (64.0 + 12.0 + bottomInset + 16.0) : 0.0;

        return Scaffold(
          // Do NOT extendBody — let the scaffold handle safe area normally
          body: MediaQuery(
            // Inject extra bottom padding so every child screen's
            // scroll view / list naturally stops above the floating bar
            data: MediaQuery.of(context).copyWith(
              padding: MediaQuery.of(context).padding.copyWith(
                bottom: navbarClearance,
              ),
              viewPadding: MediaQuery.of(context).viewPadding.copyWith(
                bottom: navbarClearance,
              ),
            ),
            child: widget.child,
          ),
          bottomNavigationBar: showBottomNav ? _FloatingNavBar(this) : null,
        );
      },
    );
  }

  Widget _FloatingNavBar(_MainNavigationScreenState s) {
    final isDark = Theme.of(s.context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(s.context).padding.bottom;
    final activeColor = const Color(AppConstants.primaryRed);

    final items = [
      _NavItem(Icons.grid_view_rounded, Icons.grid_view_rounded, 'Home', 0),
      _NavItem(Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Bookings', 1),
      _NavItem(Icons.bed_outlined, Icons.bed_rounded, 'Rooms', 2),
      _NavItem(Icons.person_outline_rounded, Icons.person_rounded, 'Profile', 3),
    ];

    return Container(
      padding: EdgeInsets.fromLTRB(16, 0, 16, bottomPadding + 12),
      color: Colors.transparent,
      child: Container(
        height: 64,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1E) : Colors.white,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.5 : 0.12),
              blurRadius: 24,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            // Left two items
            ...items.take(2).map((item) => _buildNavItem(s, item, activeColor, isDark)),
            // Center QR button
            _buildCenterQR(s.context),
            // Right two items
            ...items.skip(2).map((item) => _buildNavItem(s, item, activeColor, isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(_MainNavigationScreenState s, _NavItem item, Color activeColor, bool isDark) {
    final selected = s._currentIndex == item.index;
    final inactiveColor = isDark ? const Color(0xFF6B6B6B) : const Color(0xFFB0B0B0);
    final color = selected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: () => s._onTap(item.index),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: selected ? 40 : 28,
              height: 3,
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: selected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Icon(selected ? item.activeIcon : item.icon, size: 22, color: color),
            const SizedBox(height: 3),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenterQR(BuildContext ctx) {
    return GestureDetector(
      onTap: () => ctx.push(AppConstants.checkinDashboardScreen),
      child: SizedBox(
        width: 72,
        child: Center(
          child: Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFF5252), Color(AppConstants.primaryRed)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(AppConstants.primaryRed).withOpacity(0.4),
                  blurRadius: 14,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white, size: 24),
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  const _NavItem(this.icon, this.activeIcon, this.label, this.index);
}
