import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';

class BookingCancellationScreen extends StatefulWidget {
  final Map<String, dynamic>? arguments;
  const BookingCancellationScreen({super.key, this.arguments});

  @override
  State<BookingCancellationScreen> createState() => _BookingCancellationScreenState();
}

class _BookingCancellationScreenState extends State<BookingCancellationScreen> {
  String? _selectedReason;
  final List<String> _reasons = [
    'Change of plans',
    'Found a better deal',
    'Personal emergency',
    'Travel dates changed',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cancel Booking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Why do you want to cancel?',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _reasons.length,
                itemBuilder: (context, index) {
                  return RadioListTile<String>(
                    title: Text(_reasons[index]),
                    value: _reasons[index],
                    groupValue: _selectedReason,
                    onChanged: (value) {
                      setState(() {
                        _selectedReason = value;
                      });
                    },
                    activeColor: AppColors.primary,
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Note: Cancellation fees may apply based on the hotel\'s policy.',
              style: TextStyle(color: Colors.red, fontSize: 12),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Confirm Cancellation',
              onPressed: _selectedReason == null
                  ? null
                  : () {
                      // Mock cancellation logic
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Booking cancelled successfully')),
                      );
                      context.go('/main-navigation');
                    },
            ),
          ],
        ),
      ),
    );
  }
}
