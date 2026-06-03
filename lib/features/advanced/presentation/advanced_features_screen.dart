import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class AdvancedFeaturesScreen extends StatefulWidget {
  const AdvancedFeaturesScreen({Key? key}) : super(key: key);

  @override
  State<AdvancedFeaturesScreen> createState() => _AdvancedFeaturesScreenState();
}

class _AdvancedFeaturesScreenState extends State<AdvancedFeaturesScreen> {
  final Map<String, bool> _preferences = {
    'notifications': true,
    'locationServices': true,
    'autoCheckIn': false,
    'smartRecommendations': true,
    'priceAlerts': true,
  };

  final _features = [
    {'id': 'smart-search', 'title': 'Smart Search', 'description': 'AI-powered search with personalized recommendations', 'icon': Icons.search, 'route': '/search'},
    {'id': 'price-tracker', 'title': 'Price Tracker', 'description': 'Track price changes for your favorite hotels', 'icon': Icons.trending_down, 'route': '/price-alerts'},
    {'id': 'loyalty-program', 'title': 'HotelSewa Rewards', 'description': 'Earn points and unlock exclusive benefits', 'icon': Icons.card_giftcard, 'route': '/loyalty-program'},
    {'id': 'group-booking', 'title': 'Group Booking', 'description': 'Book multiple rooms for events and groups', 'icon': Icons.group, 'route': '/hotel-list'},
    {'id': 'virtual-tour', 'title': 'Virtual Tours', 'description': '360° virtual tours of hotel rooms', 'icon': Icons.view_in_ar, 'route': '/gallery'},
    {'id': 'concierge', 'title': 'Digital Concierge', 'description': 'AI assistant for travel recommendations', 'icon': Icons.assistant, 'route': '/ai-chat'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Advanced Features', style: TextStyle(color: AppColors.darkGray, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.darkGray),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              margin: const EdgeInsets.only(bottom: 8),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enhance your booking experience with our pro tools and AI-powered services.', style: TextStyle(fontSize: 14, color: Color(0xFF666666), height: 1.4)),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Pro Services', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 16),
                  ..._features.map((feature) {
                    return InkWell(
                      onTap: () {
                        if (feature['route'] != null) {
                          context.push(feature['route'] as String);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(feature['icon'] as IconData, size: 24, color: AppColors.primary),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(feature['title'] as String, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Color(0xFF333333))),
                                  const SizedBox(height: 4),
                                  Text(feature['description'] as String, style: const TextStyle(fontSize: 13, color: Color(0xFF666666), height: 1.2)),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFCCCCCC)),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Preferences', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 16),
                  _buildPreference('notifications', 'Push Notifications', 'Get booking updates and offers'),
                  _buildPreference('locationServices', 'Location Services', 'Find nearby hotels automatically'),
                  _buildPreference('autoCheckIn', 'Auto Check-in', 'Automatic check-in when you arrive'),
                  _buildPreference('smartRecommendations', 'Smart Recommendations', 'Personalized hotel suggestions'),
                  _buildPreference('priceAlerts', 'Price Alerts', 'Notify when prices drop'),
                ],
              ),
            ),
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.only(bottom: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Quick Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF333333))),
                  const SizedBox(height: 16),
                  _buildActionButton(Icons.history, 'Recent Searches'),
                  _buildActionButton(Icons.favorite, 'Saved Hotels'),
                  _buildActionButton(Icons.share, 'Share App'),
                ],
              ),
            ),
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFFE6F7FF), borderRadius: BorderRadius.circular(8)),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.lightbulb_outline, size: 24, color: Color(0xFF1890FF)),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Pro Tip', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF1890FF))),
                        SizedBox(height: 4),
                        Text('Enable all smart features for the best personalized experience and exclusive deals!', style: TextStyle(fontSize: 14, color: Color(0xFF1890FF), height: 1.4)),
                      ],
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

  Widget _buildPreference(String key, String label, String description) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFFF0F0F0)))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                const SizedBox(height: 2),
                Text(description, style: const TextStyle(fontSize: 14, color: Color(0xFF666666))),
              ],
            ),
          ),
          Switch(
            value: _preferences[key]!,
            onChanged: (value) => setState(() => _preferences[key] = value),
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.5),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String text) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: ElevatedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 20, color: Colors.white),
        label: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          padding: const EdgeInsets.all(12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}
