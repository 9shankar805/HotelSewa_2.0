import 'package:flutter/material.dart';

class PriceAlertsScreen extends StatelessWidget {
  const PriceAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('PriceAlertsScreen')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
