import 'package:flutter/material.dart';
import '../../../../core/constants/app_constants.dart';

class AutomatedMessagingScreen extends StatefulWidget {
  const AutomatedMessagingScreen({super.key});
  @override
  State<AutomatedMessagingScreen> createState() => _AutomatedMessagingScreenState();
}

class _AutomatedMessagingScreenState extends State<AutomatedMessagingScreen> {
  final List<Map<String, dynamic>> _templates = [
    {
      'id': '1',
      'trigger': 'booking_confirmed',
      'triggerLabel': 'Booking Confirmed',
      'icon': Icons.check_circle_outline_rounded,
      'color': Color(AppConstants.successGreen),
      'enabled': true,
      'timing': 'Immediately',
      'message': 'Dear {guest_name}, your booking at {hotel_name} is confirmed! Check-in: {checkin_date}, Check-out: {checkout_date}. Room: {room_type}. We look forward to welcoming you!',
    },
    {
      'id': '2',
      'trigger': 'pre_arrival',
      'triggerLabel': 'Pre-Arrival',
      'icon': Icons.flight_land_rounded,
      'color': Color(0xFF1890FF),
      'enabled': true,
      'timing': '24 hours before check-in',
      'message': 'Hi {guest_name}! Your stay at {hotel_name} starts tomorrow. Check-in time: {checkin_time}. Address: {hotel_address}. Need help? Reply to this message.',
    },
    {
      'id': '3',
      'trigger': 'checkin_day',
      'triggerLabel': 'Check-in Day',
      'icon': Icons.login_rounded,
      'color': Color(AppConstants.warningOrange),
      'enabled': false,
      'timing': 'Day of check-in at 8 AM',
      'message': 'Good morning {guest_name}! Today is your check-in day. Your room {room_number} will be ready by {checkin_time}. Early check-in available for Rs. 500 extra.',
    },
    {
      'id': '4',
      'trigger': 'checkout_reminder',
      'triggerLabel': 'Checkout Reminder',
      'icon': Icons.logout_rounded,
      'color': Color(AppConstants.primaryRed),
      'enabled': true,
      'timing': 'Day of checkout at 8 AM',
      'message': 'Hi {guest_name}, checkout is today by {checkout_time}. Need a late checkout? Contact reception. We hope you enjoyed your stay!',
    },
    {
      'id': '5',
      'trigger': 'review_request',
      'triggerLabel': 'Review Request',
      'icon': Icons.star_outline_rounded,
      'color': Color(0xFFFFBF00),
      'enabled': true,
      'timing': '2 hours after checkout',
      'message': 'Thank you for staying at {hotel_name}, {guest_name}! We hope you had a wonderful experience. Please take a moment to share your feedback: {review_link}',
    },
    {
      'id': '6',
      'trigger': 'cancellation',
      'triggerLabel': 'Booking Cancelled',
      'icon': Icons.cancel_outlined,
      'color': Color(AppConstants.errorRed),
      'enabled': false,
      'timing': 'Immediately on cancellation',
      'message': 'Hi {guest_name}, your booking #{booking_id} at {hotel_name} has been cancelled. Refund of Rs. {refund_amount} will be processed in 3-5 business days.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final card = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFEEEEEE);
    final enabledCount = _templates.where((t) => t['enabled'] == true).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Automated Messages'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: const Color(AppConstants.successGreen).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: Text('$enabledCount active', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(AppConstants.successGreen))),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFF1890FF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF1890FF).withOpacity(0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, color: Color(0xFF1890FF), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Messages are sent automatically at the right time. Use {variables} to personalize.',
                    style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : const Color(AppConstants.darkGray)),
                  ),
                ),
              ],
            ),
          ),
          // Template list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: _templates.length,
              itemBuilder: (_, i) => _buildTemplateCard(_templates[i], isDark, card, border),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> t, bool isDark, Color card, Color border) {
    final color = t['color'] as Color;
    final enabled = t['enabled'] as bool;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: enabled ? color.withOpacity(0.3) : border),
      ),
      child: Column(
        children: [
          // Header row
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Icon(t['icon'] as IconData, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t['triggerLabel'] as String, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
                      Text(t['timing'] as String, style: const TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: enabled,
                  onChanged: (v) => setState(() => t['enabled'] = v),
                  activeColor: const Color(AppConstants.primaryRed),
                ),
              ],
            ),
          ),
          // Message preview
          if (enabled) ...[
            Container(
              margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF2C2C2C) : const Color(AppConstants.lightGray),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                t['message'] as String,
                style: const TextStyle(fontSize: 12, height: 1.5, color: Color(AppConstants.darkGray)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _editTemplate(t),
                      icon: const Icon(Icons.edit_outlined, size: 14),
                      label: const Text('Edit', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(AppConstants.primaryRed),
                        side: const BorderSide(color: Color(AppConstants.primaryRed)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _previewTemplate(t),
                      icon: const Icon(Icons.visibility_outlined, size: 14),
                      label: const Text('Preview', style: TextStyle(fontSize: 12)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(AppConstants.mediumGray),
                        side: const BorderSide(color: Color(AppConstants.mediumGray)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  void _editTemplate(Map<String, dynamic> t) {
    final ctrl = TextEditingController(text: t['message'] as String);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 24, left: 24, right: 24, top: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Edit: ${t['triggerLabel']}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Available variables: {guest_name} {hotel_name} {checkin_date} {checkout_date} {room_type} {booking_id}',
              style: TextStyle(fontSize: 11, color: Color(AppConstants.mediumGray))),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              maxLines: 5,
              decoration: InputDecoration(
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(AppConstants.primaryRed), width: 2)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  setState(() => t['message'] = ctrl.text);
                  Navigator.pop(context);
                  _snack('Template saved');
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(AppConstants.primaryRed), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: const Text('Save Template', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _previewTemplate(Map<String, dynamic> t) {
    final preview = (t['message'] as String)
        .replaceAll('{guest_name}', 'Rahul Sharma')
        .replaceAll('{hotel_name}', 'Hotel Himalaya')
        .replaceAll('{checkin_date}', 'Dec 25, 2025')
        .replaceAll('{checkout_date}', 'Dec 28, 2025')
        .replaceAll('{room_type}', 'Deluxe Room')
        .replaceAll('{checkin_time}', '2:00 PM')
        .replaceAll('{checkout_time}', '11:00 AM')
        .replaceAll('{room_number}', '201')
        .replaceAll('{hotel_address}', 'Thamel, Kathmandu')
        .replaceAll('{booking_id}', 'BK2025001')
        .replaceAll('{refund_amount}', '5,000')
        .replaceAll('{review_link}', 'hotelsewa.com/review/abc123');

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('Preview: ${t['triggerLabel']}'),
        content: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: const Color(AppConstants.lightGray), borderRadius: BorderRadius.circular(10)),
          child: Text(preview, style: const TextStyle(fontSize: 13, height: 1.6)),
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))],
      ),
    );
  }

  void _snack(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(
    content: Text(msg), backgroundColor: const Color(AppConstants.successGreen),
    behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
  ));
}
