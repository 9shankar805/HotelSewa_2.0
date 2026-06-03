import 'package:flutter/material.dart';

class WithdrawalsScreen extends StatelessWidget {
  const WithdrawalsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('WithdrawalsScreen')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
