import 'package:flutter/material.dart';

class RoomDetailsScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;

  const RoomDetailsScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    final room = arguments?['room'] as Map<String, dynamic>?;
    return Scaffold(
      appBar: AppBar(title: Text(room?['type'] ?? 'Room Details')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
