import 'package:flutter/material.dart';

class MultiCurrencyScreen extends StatelessWidget {
  const MultiCurrencyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('MultiCurrencyScreen')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
