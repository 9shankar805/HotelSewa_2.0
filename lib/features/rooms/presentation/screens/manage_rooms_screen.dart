import 'package:flutter/material.dart';

class ManageRoomsScreen extends StatelessWidget {
  const ManageRoomsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('ManageRoomsScreen')),
      body: const Center(child: CircularProgressIndicator()),
    );
  }
}
