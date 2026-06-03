import 'package:flutter/material.dart';

class DynamicPricingScreen extends StatelessWidget {
  const DynamicPricingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('DynamicPricingScreen')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
