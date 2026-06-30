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
  late AnimationController _ctrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

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

      // Wait at least 1.5 seconds on splash
      await Future.delayed(const Duration(milliseconds: 1500));

      if (!mounted) return;

      if (!hasOnboarded) {
        context.go('/onboarding');
      } else if (authToken != null && authToken.isNotEmpty) {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        final appModeProvider =
            Provider.of<AppModeProvider>(context, listen: false);

        await authProvider.checkAuthStatus();

        final freshRole = prefs.getString('user_role') ?? userRole ?? '';
        final isOwner = freshRole.toLowerCase().contains('owner');

        if (isOwner) {
          await appModeProvider.setOwnerMode(true);
          authProvider.refreshAllServiceTokens();
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
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      backgroundColor: Colors.white,
      body: FadeTransition(
        opacity: _fade,
        child: Stack(
          children: [
            // Full-screen splash image
            SizedBox.expand(
              child: Image.asset(
                'assets/splash.png',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.primary,
                  child: const Center(
                    child: Text(
                      'HotelSewa',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Animated dots overlay — covers the static dots baked into the image
            // Dots in splash.png are at ~89% from top of image
            Positioned.fill(
              child: Align(
                alignment: const Alignment(0, 0.78),
                child: _AnimatedDots(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Animated loading dots ────────────────────────────────────────────────────
class _AnimatedDots extends StatefulWidget {
  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        // Each dot is offset by 1/3 of the cycle
        final delay = i / 3;
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            // Shift animation value by delay, wrap around 0-1
            final t = (_ctrl.value - delay) % 1.0;
            // Pulse: scale 0.6 → 1.2 → 0.6 using a sine curve
            final scale = 0.6 + 0.6 * _pulse(t);
            // Active dot gets full white, inactive get semi-transparent white
            final isActive = ((_ctrl.value * 3).floor() % 3) == i;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 10 * scale,
              height: 10 * scale,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive
                    ? Colors.white
                    : Colors.white.withOpacity(0.4),
              ),
            );
          },
        );
      }),
    );
  }

  /// Returns 0→1→0 over the range t=0..1 (smooth pulse)
  double _pulse(double t) {
    // Use a simple triangle wave clamped to active window (first 50% of cycle)
    if (t < 0.25) return t / 0.25;
    if (t < 0.5) return 1.0 - (t - 0.25) / 0.25;
    return 0.0;
  }
}
