import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';

class CompareHotelsScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const CompareHotelsScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Compare Hotels'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.compare_arrows, size: 80, color: Colors.grey.withOpacity(0.5)),
            const SizedBox(height: 16),
            const Text(
              'Select hotels to compare',
              style: TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/main-navigation'),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text('Add Hotels', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
