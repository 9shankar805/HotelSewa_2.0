import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/presentation/providers/auth_provider.dart';
import '../hotel/presentation/services/hotel_service.dart';
import '../../core/constants/app_colors.dart';

class HotelRegistrationDebugScreen extends StatefulWidget {
  const HotelRegistrationDebugScreen({super.key});

  @override
  State<HotelRegistrationDebugScreen> createState() => _HotelRegistrationDebugScreenState();
}

class _HotelRegistrationDebugScreenState extends State<HotelRegistrationDebugScreen> {
  bool _isLoading = false;
  String _result = '';

  Future<void> _testHotelRegistration() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing hotel registration...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null || token.isEmpty) {
        setState(() {
          _result = '❌ No authentication token found. Please login first.';
          _isLoading = false;
        });
        return;
      }

      // Set token in hotel service
      HotelService.setToken(token);

      // Test data
      final testData = {
        'name': 'Test Hotel ${DateTime.now().millisecondsSinceEpoch}',
        'address': 'Test Address, Kathmandu',
        'city': 'Kathmandu',
        'country': 'Nepal',
        'contact_number': '+977-9800000000',
        'description': 'Test hotel for debugging',
        'state': 'Bagmati',
        'latitude': '27.7172',
        'longitude': '85.3240',
        'currency': 'NPR',
      };

      debugPrint('🧪 Testing hotel registration with data: $testData');
      
      final response = await HotelService.registerHotel(testData);
      
      setState(() {
        _result = '✅ Hotel registration successful!\n\nResponse: ${response.toString()}';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _result = '❌ Hotel registration failed!\n\nError: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  Future<void> _testGetMyHotels() async {
    setState(() {
      _isLoading = true;
      _result = 'Testing get my hotels...';
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final token = authProvider.token;
      
      if (token == null || token.isEmpty) {
        setState(() {
          _result = '❌ No authentication token found. Please login first.';
          _isLoading = false;
        });
        return;
      }

      // Set token in hotel service
      HotelService.setToken(token);

      final hotels = await HotelService.getMyHotels();
      
      setState(() {
        _result = '✅ My hotels retrieved successfully!\n\nHotels: ${hotels.toString()}';
        _isLoading = false;
      });
      
    } catch (e) {
      setState(() {
        _result = '❌ Get my hotels failed!\n\nError: ${e.toString()}';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Registration Debug'),
        backgroundColor: AppColors.info,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Hotel Registration API Test',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            
            Consumer<AuthProvider>(
              builder: (context, auth, _) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Authentication Status:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        Text('Token exists: ${auth.token != null ? "✅ Yes" : "❌ No"}'),
                        if (auth.token != null) ...[
                          const SizedBox(height: 4),
                          Text('Token preview: ${auth.token!.substring(0, 20)}...'),
                        ],
                        const SizedBox(height: 8),
                        Text('User: ${auth.user?.name ?? "Not logged in"}'),
                        Text('Email: ${auth.user?.email ?? "N/A"}'),
                      ],
                    ),
                  ),
                );
              },
            ),
            
            const SizedBox(height: 20),
            
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testHotelRegistration,
                    child: const Text('Test Hotel Registration'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _testGetMyHotels,
                    child: const Text('Test Get My Hotels'),
                  ),
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