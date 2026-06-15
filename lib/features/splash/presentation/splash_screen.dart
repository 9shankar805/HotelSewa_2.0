import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/app_mode_provider.dart';
import '../../auth/presentation/providers/auth_provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    // Set status bar color
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: AppColors.primary,
        statusBarIconBrightness: Brightness.light,
      ),
    );

    // Initialize animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.elasticOut,
      ),
    );

    // Start animations
    _animationController.forward();

    // Check authentication and navigate
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    try {
      final prefs = await SharedPreferences.getInstance().timeout(
        const Duration(seconds: 3),
        onTimeout: () => throw Exception('SharedPreferences timed out'),
      );
      final hasOnboarded = prefs.getBool('hasOnboarded') ?? false;
      final authToken = prefs.getString('authToken');
      final userRole = prefs.getString('user_role');

      await Future.delayed(const Duration(seconds: 2));

      if (!mounted) return;

      if (!hasOnboarded) {
        context.go('/onboarding');
      } else if (authToken != null && authToken.isNotEmpty) {
        // Get providers
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final appModeProvider = Provider.of<AppModeProvider>(context, listen: false);
        
        // Load user session first
        await authProvider.checkAuthStatus();
        
        if (userRole == 'hotel_owner') {
          // Set owner mode
          await appModeProvider.setOwnerMode(true);
          
          // Refresh all service tokens
          authProvider.refreshAllServiceTokens();
          
          // Check hotel status and navigate appropriately
          try {
            final route = await authProvider.checkHotelStatusAndNavigate();
            if (mounted) {
              switch (route) {
                case 'dashboard':
                  context.go('/owner/dashboard');
                  break;
                case 'pending':
                  context.go('/hotel-pending-approval');
                  break;
                default:
                  context.go('/hotel-registration');
              }
            }
          } catch (e) {
            debugPrint('Hotel status check failed: $e');
            if (mounted) context.go('/hotel-registration');
          }
        } else {
          // Customer mode
          await appModeProvider.setOwnerMode(false);
          context.go('/home');
        }
      } else {
        context.go('/login');
      }
    } catch (error) {
      debugPrint('Auth check error: $error');
      await Future.delayed(const Duration(seconds: 2));
      if (!mounted) return;
      context.go('/login');
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        child: Stack(
          children: [
            // Logo and tagline in center
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        'assets/logo.png',
                        width: 120,
                        height: 120,
                        errorBuilder: (context, error, stackTrace) {
                          return Text(
                            'HotelSewa',
                            style: TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                              letterSpacing: 8,
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      // Stylish tagline with accent line
                      Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 24, height: 1.5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'N E P A L',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white.withOpacity(0.7),
                                  letterSpacing: 5,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                width: 24, height: 1.5,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'No. 1 Hotel Booking Platform',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppColors.white.withOpacity(0.95),
                              letterSpacing: 0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Version at bottom
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: Text(
                  'Version 1.0.1',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.white.withOpacity(0.7),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
