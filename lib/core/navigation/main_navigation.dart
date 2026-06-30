import 'package:flutter/material.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/saved/presentation/saved_screen.dart';
import '../../features/trips/presentation/my_trips_screen.dart';
import '../../features/profile/presentation/profile_screen.dart';
import '../../features/invite/presentation/invite_earn_screen.dart';
import '../constants/app_colors.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const InviteEarnScreen(), // Can replace with ExploreScreen later
    const MyTripsScreen(),
    const SavedScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) {
              setState(() {
                _currentIndex = index;
              });
            },
            type: BottomNavigationBarType.fixed,
            selectedItemColor: AppColors.primary,
            unselectedItemColor: const Color(0xFF9CA3AF),
            backgroundColor: Colors.white,
            elevation: 0,
            selectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.5,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
            items: [
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.home_outlined, 0),
                activeIcon: _buildNavIcon(Icons.home, 0, isActive: true),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_add_alt_outlined, 1),
                activeIcon: _buildNavIcon(Icons.person_add_alt, 1, isActive: true),
                label: 'Invite & Earn',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.work_outline, 2),
                activeIcon: _buildNavIcon(Icons.work, 2, isActive: true),
                label: 'Bookings',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.favorite_border, 3),
                activeIcon: _buildNavIcon(Icons.favorite, 3, isActive: true),
                label: 'Saved',
              ),
              BottomNavigationBarItem(
                icon: _buildNavIcon(Icons.person_outline, 4),
                activeIcon: _buildNavIcon(Icons.person, 4, isActive: true),
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavIcon(IconData icon, int index, {bool isActive = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        size: 26,
        color: isActive ? AppColors.primary : const Color(0xFF9CA3AF),
      ),
    );
  }
}
