import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/constants/app_colors.dart';
import 'onboarding_data.dart';
import '../../auth/presentation/login_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with TickerProviderStateMixin {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  late AnimationController _iconController;

  @override
  void initState() {
    super.initState();
    _iconController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _iconController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (_currentIndex < onboardingData.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleGetStarted();
    }
  }

  Future<void> _handleGetStarted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('hasOnboarded', true);
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const LoginScreen(),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final item = onboardingData[_currentIndex];
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              item.accentColor,
              item.accentColor.withOpacity(0.75),
              const Color(0xFF1A1A2E),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar ──────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Page counter
                    Text(
                      '${_currentIndex + 1} / ${onboardingData.length}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    // Skip button
                    TextButton(
                      onPressed: _handleGetStarted,
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.8),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Illustration area ─────────────────────────────────────────
              Expanded(
                flex: 5,
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() => _currentIndex = index);
                    _iconController.reset();
                    _iconController.forward();
                  },
                  itemCount: onboardingData.length,
                  itemBuilder: (context, index) {
                    final pageItem = onboardingData[index];
                    return _buildIllustration(pageItem, size);
                  },
                ),
              ),

              // ── Text + controls ───────────────────────────────────────────
              Expanded(
                flex: 4,
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
                  ),
                  padding: const EdgeInsets.fromLTRB(32, 40, 32, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        item.title,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1A1A2E),
                          height: 1.2,
                          letterSpacing: -0.5,
                        ),
                      ).animate(key: ValueKey('title_$_currentIndex'))
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),

                      const SizedBox(height: 14),

                      // Subtitle
                      Text(
                        item.subtitle,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF6B7280),
                          height: 1.6,
                        ),
                      ).animate(key: ValueKey('sub_$_currentIndex'))
                          .fadeIn(delay: 100.ms, duration: 300.ms)
                          .slideY(begin: 0.2, end: 0, duration: 300.ms),

                      const Spacer(),

                      // Dots + Next button row
                      Row(
                        children: [
                          // Page dots
                          Row(
                            children: List.generate(
                              onboardingData.length,
                              (i) => AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(right: 8),
                                width: i == _currentIndex ? 28 : 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: i == _currentIndex
                                      ? item.accentColor
                                      : const Color(0xFFE0E0E0),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ),

                          const Spacer(),

                          // Next / Get Started button
                          GestureDetector(
                            onTap: _handleNext,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              width: _currentIndex == onboardingData.length - 1 ? 160 : 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: item.accentColor,
                                borderRadius: BorderRadius.circular(30),
                                boxShadow: [
                                  BoxShadow(
                                    color: item.accentColor.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _currentIndex == onboardingData.length - 1
                                    ? const Text(
                                        'Get Started',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      )
                                    : const Icon(
                                        Icons.arrow_forward_rounded,
                                        color: Colors.white,
                                        size: 26,
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIllustration(OnboardingItem item, Size size) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Glowing icon container
          AnimatedBuilder(
            animation: _iconController,
            builder: (context, child) {
              return Transform.scale(
                scale: 0.85 + (_iconController.value * 0.15),
                child: Opacity(
                  opacity: _iconController.value,
                  child: child,
                ),
              );
            },
            child: Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.3),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 40,
                    spreadRadius: 10,
                  ),
                ],
              ),
              child: Icon(
                item.icon,
                size: 90,
                color: Colors.white,
              ),
            ),
          ),

          const SizedBox(height: 32),

          // Floating feature pills
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: _getFeaturePills(item.id),
          ),
        ],
      ),
    );
  }

  List<Widget> _getFeaturePills(String id) {
    final pillData = {
      '1': ['Verified Hotels', 'Real Reviews', 'Best Prices'],
      '2': ['Khalti & eSewa', 'Instant Confirm', 'Secure Payment'],
      '3': ['Loyalty Points', 'Referral Bonus', 'Exclusive Deals'],
    };
    final pills = pillData[id] ?? [];
    return pills.asMap().entries.map((e) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Text(
          e.value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ).animate(delay: (e.key * 100 + 200).ms).fadeIn().slideY(begin: 0.3, end: 0);
    }).toList();
  }
}
