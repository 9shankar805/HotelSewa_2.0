import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../hotel/presentation/services/hotel_service.dart';
import '../../core/providers/app_mode_provider.dart';
import '../../core/services/shared/api_service.dart';
import '../../core/constants/api_config.dart';
import '../../core/constants/app_colors.dart';

class HotelAuthDebugScreen extends StatefulWidget {
  const HotelAuthDebugScreen({super.key});

  @override
  State<HotelAuthDebugScreen> createState() => _HotelAuthDebugScreenState();
}

class _HotelAuthDebugScreenState extends State<HotelAuthDebugScreen> {
  bool _isLoading = false;
  String _result = '';

  Future<void> _testHotelAuth() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing hotel authentication...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final appModeProvider = Provider.of<AppModeProvider>(context, listen: false);
      
      setState(() {
        _result += '\n\n🔍 Authentication Status:';
        _result += '\n• Token exists: ${authProvider.token != null ? "✅ Yes" : "❌ No"}';
        _result += '\n• Is authenticated: ${authProvider.isAuthenticated ? "✅ Yes" : "❌ No"}';
        _result += '\n• User exists: ${authProvider.user != null ? "✅ Yes" : "❌ No"}';
        _result += '\n• Is owner mode: ${appModeProvider.isOwnerMode ? "✅ Yes" : "❌ No"}';
      });

      if (authProvider.token == null || authProvider.token!.isEmpty) {
        setState(() {
          _result += '\n\n❌ No authentication token found. Please login first.';
          _isLoading = false;
        });
        return;
      }

      // Test hotel status check
      setState(() {
        _result += '\n\n🏨 Testing hotel status check...';
      });

      final route = await authProvider.checkHotelStatusAndNavigate();
      
      setState(() {
        _result += '\n✅ Hotel status check completed!';
        _result += '\n• Recommended route: $route';
        _result += '\n• Has hotel: ${authProvider.hasHotel ? "✅ Yes" : "❌ No"}';
        _result += '\n• Hotel approved: ${authProvider.isHotelApproved ? "✅ Yes" : "❌ No"}';
      });

      // Test direct API call
      setState(() {
        _result += '\n\n🔧 Testing direct API call...';
      });

      HotelService.setToken(authProvider.token!);
      final hotelService = HotelService();
      final response = await hotelService.getHotelStatus();
      
      setState(() {
        _result += '\n✅ Direct API call completed!';
        _result += '\n• Response: ${response.toString()}';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _result += '\n\n❌ Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _testMyHotels() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing /my-hotels endpoint...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.token == null || authProvider.token!.isEmpty) {
        setState(() {
          _result = '❌ No authentication token found. Please login first.';
          _isLoading = false;
        });
        return;
      }

      HotelService.setToken(authProvider.token!);
      final hotels = await HotelService.getMyHotels();
      
      setState(() {
        _result = '✅ My hotels retrieved successfully!';
        _result += '\n\n📊 Results:';
        _result += '\n• Number of hotels: ${hotels.length}';
        
        if (hotels.isEmpty) {
          _result += '\n• Status: No hotels found - user needs to register';
        } else {
          for (int i = 0; i < hotels.length; i++) {
            final hotel = hotels[i];
            _result += '\n\n🏨 Hotel ${i + 1}:';
            _result += '\n  • Name: ${hotel['name'] ?? 'N/A'}';
            _result += '\n  • Status: ${hotel['status'] ?? 'N/A'}';
            _result += '\n  • ID: ${hotel['id'] ?? 'N/A'}';
            _result += '\n  • City: ${hotel['city'] ?? 'N/A'}';
          }
        }
        
        _result += '\n\n📋 Raw Response: ${hotels.toString()}';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _result = '❌ My hotels API failed!\n\nError: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _testTokenRefresh() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing token refresh...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      
      if (authProvider.token == null || authProvider.token!.isEmpty) {
        setState(() {
          _result = '❌ No authentication token found. Please login first.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _result += '\n\n🔄 Refreshing all service tokens...';
      });

      // Refresh tokens for all services
      authProvider.refreshAllServiceTokens();
      
      setState(() {
        _result += '\n✅ Token refresh completed!';
        _result += '\n\n🧪 Testing earnings API after refresh...';
      });

      // Test earnings API after refresh
      final response = await ApiService.get(ApiConfig.ownerEarningsEndpoint, token: authProvider.token);
      
      setState(() {
        _result += '\n📥 Earnings API response: ${response.toString()}';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _result += '\n\n❌ Error: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Auth Debug'),
        backgroundColor: AppColors.warning,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hotel Mode Authentication Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            Consumer2<AuthProvider, AppModeProvider>(
              builder: (context, auth, appMode, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Current Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('🔐 Token: ${auth.token != null ? "✅ Present" : "❌ Missing"}'),
                        Text('👤 User: ${auth.user?.name ?? "Not logged in"}'),
                        Text('🏨 Has Hotel: ${auth.hasHotel ? "✅ Yes" : "❌ No"}'),
                        Text('✅ Hotel Approved: ${auth.isHotelApproved ? "✅ Yes" : "❌ No"}'),
                        Text('🏢 Owner Mode: ${appMode.isOwnerMode ? "✅ Active" : "❌ Inactive"}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                ElevatedButton(
                  onPressed: _isLoading ? null : _testHotelAuth,
                  child: const Text('Test Hotel Auth'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testMyHotels,
                  child: const Text('Test My Hotels API'),
                ),
                ElevatedButton(
                  onPressed: _isLoading ? null : _testTokenRefresh,
                  child: const Text('Test Token Refresh'),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'Result:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.gray),
                  borderRadius: BorderRadius.circular(8),
                  color: AppColors.gray.shade50,
                ),
                child: SingleChildScrollView(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Text(
                          _result.isEmpty ? 'No test run yet. Click a button above to test.' : _result,
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}