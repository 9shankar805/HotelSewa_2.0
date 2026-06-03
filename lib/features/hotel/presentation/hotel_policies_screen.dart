import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class HotelPoliciesScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const HotelPoliciesScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hotel Policies'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildPolicySection(
            'Check-in & Check-out',
            '• Check-in: 2:00 PM\n• Check-out: 12:00 PM\n• Early check-in is subject to availability.',
          ),
          _buildPolicySection(
            'Cancellation Policy',
            '• Free cancellation up to 24 hours before check-in.\n• Cancellations within 24 hours will incur a 1-night charge.',
          ),
          _buildPolicySection(
            'Child & Extra Bed Policy',
            '• Children up to 5 years stay free using existing bedding.\n• Extra beds are available for Rs. 1,000 per night.',
          ),
          _buildPolicySection(
            'General Policies',
            '• Pets are not allowed.\n• Smoking is only permitted in designated areas.\n• Valid ID proof is required at check-in.',
          ),
        ],
      ),
    );
  }

  Widget _buildPolicySection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 15, color: Colors.black87, height: 1.5),
          ),
        ],
      ),
    );
  }
}
