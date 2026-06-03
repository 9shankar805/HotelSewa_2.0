import 'package:flutter/material.dart';

class PricingBreakdownScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const PricingBreakdownScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pricing Breakdown')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
