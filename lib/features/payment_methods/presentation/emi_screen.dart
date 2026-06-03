import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_button.dart';

class EmiScreen extends StatelessWidget {
  final Map<String, dynamic>? arguments;
  const EmiScreen({super.key, this.arguments});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EMI Options'),
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
              'Select EMI Plan',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView(
                children: [
                  _buildEmiPlan('3 Months', 'Rs. 2,500 / month', '12% interest p.a.'),
                  _buildEmiPlan('6 Months', 'Rs. 1,300 / month', '13% interest p.a.'),
                  _buildEmiPlan('12 Months', 'Rs. 700 / month', '15% interest p.a.'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            AppButton(
              label: 'Proceed with EMI',
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('EMI selected successfully')),
                );
                context.pop();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmiPlan(String duration, String monthlyAmount, String interest) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(duration, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(monthlyAmount),
            Text(interest, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          ],
        ),
        trailing: const Radio(value: true, groupValue: false, onChanged: null),
      ),
    );
  }
}
