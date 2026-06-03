import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageCtrl = PageController();
  int _current = 0;

  static const _pages = [
    _OnboardingPage(
      icon: Icons.hotel_rounded,
      color: Color(0xFFE60023),
      bg: Color(0xFFFFF5F5),
      title: 'Manage Your Hotel',
      subtitle: 'Everything you need to run your property — bookings, rooms, guests — all in one place.',
    ),
    _OnboardingPage(
      icon: Icons.calendar_today_rounded,
      color: Color(0xFF1890FF),
      bg: Color(0xFFE6F4FF),
      title: 'Smart Booking Management',
      subtitle: 'Handle reservations, check-ins, and check-outs seamlessly from your phone.',
    ),
    _OnboardingPage(
      icon: Icons.trending_up_rounded,
      color: Color(0xFF52C41A),
      bg: Color(0xFFF6FFED),
      title: 'Track Your Earnings',
      subtitle: 'Monitor revenue, view detailed reports, and withdraw your earnings anytime.',
    ),
    _OnboardingPage(
      icon: Icons.chat_bubble_outline_rounded,
      color: Color(0xFFFA8C16),
      bg: Color(0xFFFFF7E6),
      title: 'Stay Connected',
      subtitle: 'Communicate with guests instantly and respond to reviews to build your reputation.',
    ),
  ];

  void _next() {
    if (_current < _pages.length - 1) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
    } else {
      context.go(AppConstants.dashboardScreen);
    }
  }

  @override
  void dispose() { _pageCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final page = _pages[_current];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Skip
            Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(0, 12, 16, 0),
                child: TextButton(
                  onPressed: () => context.go(AppConstants.dashboardScreen),
                  child: const Text('Skip', style: TextStyle(color: Color(AppConstants.mediumGray), fontWeight: FontWeight.w600)),
                ),
              ),
            ),

            // Page view
            Expanded(
              child: PageView.builder(
                controller: _pageCtrl,
                onPageChanged: (i) => setState(() => _current = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _buildPage(_pages[i]),
              ),
            ),

            // Dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_pages.length, (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: _current == i ? 24 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _current == i ? const Color(AppConstants.primaryRed) : const Color(AppConstants.mediumGray).withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),

            // Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
              child: Row(
                children: [
                  if (_current > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pageCtrl.previousPage(duration: const Duration(milliseconds: 350), curve: Curves.easeInOut),
                        style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                        child: const Text('Back', style: TextStyle(fontWeight: FontWeight.w600)),
                      ),
                    )
                  else
                    const Spacer(),
                  if (_current > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: page.color,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: Text(
                        _current == _pages.length - 1 ? 'Get Started' : 'Next',
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage(_OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 140, height: 140,
            decoration: BoxDecoration(color: page.bg, shape: BoxShape.circle),
            child: Icon(page.icon, size: 64, color: page.color),
          ),
          const SizedBox(height: 48),
          Text(page.title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5), textAlign: TextAlign.center),
          const SizedBox(height: 16),
          Text(page.subtitle, style: const TextStyle(fontSize: 16, color: Color(AppConstants.mediumGray), height: 1.6), textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _OnboardingPage {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String subtitle;
  const _OnboardingPage({required this.icon, required this.color, required this.bg, required this.title, required this.subtitle});
}
