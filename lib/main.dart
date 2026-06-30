import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import 'dart:ui';
import 'core/theme/app_theme.dart';
import 'core/navigation/go_router_config.dart';
import 'core/providers/app_mode_provider.dart';
import 'core/services/shared/api_service.dart';
import 'core/services/shared/cache_service.dart';
import 'core/services/active_stay_service.dart';
import 'features/in_stay_ordering/presentation/providers/cart_provider.dart';
import 'firebase_options.dart';
// Owner Providers
import 'features/auth/presentation/providers/auth_provider.dart' as owner_auth;
import 'features/auth/presentation/services/auth_service.dart'
    as owner_auth_service;
import 'features/bookings/presentation/providers/booking_provider.dart'
    as owner_booking;
import 'features/bookings/presentation/services/booking_service.dart'
    as owner_booking_service;
import 'features/rooms/presentation/providers/room_provider.dart';
import 'features/earnings/presentation/providers/earnings_provider.dart';
import 'features/earnings/presentation/services/earnings_service.dart';
import 'features/profile/presentation/providers/profile_provider.dart'
    as owner_profile;
import 'features/profile/presentation/services/profile_service.dart'
    as owner_profile_service;
import 'features/calendar/presentation/providers/calendar_provider.dart';
import 'features/offers/presentation/providers/offers_provider.dart';
import 'features/chat/presentation/providers/chat_provider.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/dashboard/presentation/services/dashboard_service.dart';

void main() async {
  // Preserve the native splash until we explicitly remove it
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  HttpOverrides.global = MyHttpOverrides();
  await dotenv.load(fileName: '.env');

  // Initialize Hive offline cache
  await CacheService.init();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
  } catch (e) {
    debugPrint('Firebase init error (non-fatal): $e');
  }

  // Keep native splash visible for at least 3 seconds
  await Future.delayed(const Duration(seconds: 3));

  // Remove the native splash — Flutter UI takes over
  FlutterNativeSplash.remove();

  // Global Flutter error handler — logs errors instead of crashing silently
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exceptionAsString()}');
    debugPrint('[FlutterError] ${details.stack}');
  };

  // Catch async errors outside Flutter's widget tree
  PlatformDispatcher.instance.onError = (error, stack) {
    debugPrint('[PlatformError] $error');
    debugPrint('[PlatformError] $stack');
    return true; // handled
  };

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Wire session-expiry handler: clears token and redirects to login
    // Guard: don't redirect if already on /login, /splash, or /onboarding
    ApiService.onSessionExpired = () {
      final location = appRouter.routerDelegate.currentConfiguration.uri.path;
      if (location == '/login' || location == '/splash' || location == '/onboarding') {
        debugPrint('[SessionExpiry] Already on $location — skipping redirect');
        return;
      }
      debugPrint('[SessionExpiry] Redirecting to /login from $location');
      ApiService.clearToken();
      try {
        appRouter.go('/login');
      } catch (e) {
        debugPrint('Session expiry navigation error: $e');
      }
    };

    // Load any persisted active stay immediately (before first API call)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stayService = context.read<ActiveStayService>();
      stayService.loadPersistedStay();
      stayService.init(); // starts polling
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppModeProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => ActiveStayService()),
        ChangeNotifierProvider(
          create: (_) =>
              owner_auth.AuthProvider(owner_auth_service.AuthService()),
        ),
        ChangeNotifierProvider(
          create: (_) => owner_booking.BookingProvider(
            owner_booking_service.BookingService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => RoomProvider()),
        ChangeNotifierProvider(
          create: (_) => EarningsProvider(EarningsService()),
        ),
        ChangeNotifierProvider(
          create: (_) => owner_profile.ProfileProvider(
            owner_profile_service.ProfileService(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => CalendarProvider()),
        ChangeNotifierProvider(create: (_) => OffersProvider()),
        ChangeNotifierProvider(create: (_) => ChatProvider()),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(DashboardService()),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: appRouter,
        title: 'HotelSewa',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system, // Respects device dark/light setting
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: TextScaler.noScaling),
          child: child!,
        ),
      ),
    );
  }
}

// Extension for null-safe context usage
extension _ContextLet<T> on T {
  R let<R>(R Function(T) block) => block(this);
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (cert, host, port) => true;
  }
}
