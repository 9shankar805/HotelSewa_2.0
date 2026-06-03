import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/api_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/shared/api_service.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _loading = true;
  bool _saving = false;

  // Master
  bool _allNotifications = true;

  // Booking
  bool _bookingConfirmation = true;
  bool _bookingReminder = true;
  bool _checkInReminder = true;
  bool _checkOutReminder = true;
  bool _bookingCancellation = true;

  // Payments
  bool _paymentSuccess = true;
  bool _refundUpdates = true;
  bool _paymentReminder = false;

  // Deals & Offers
  bool _flashSales = true;
  bool _personalizedDeals = true;
  bool _priceDropAlerts = false;
  bool _weekendDeals = true;

  // Account
  bool _securityAlerts = true;
  bool _loyaltyPoints = true;
  bool _reviewReminders = false;
  bool _appUpdates = false;

  // Channels
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _smsNotifications = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      final response = await ApiService.get(ApiConfig.notificationPreferencesEndpoint, token: token);
      if (response['success'] == true && response['data'] is Map) {
        final d = response['data'] as Map;
        setState(() {
          _allNotifications = d['all_notifications'] != false;
          _bookingConfirmation = d['booking_confirmation'] != false;
          _bookingReminder = d['booking_reminder'] != false;
          _checkInReminder = d['check_in_reminder'] != false;
          _checkOutReminder = d['check_out_reminder'] != false;
          _bookingCancellation = d['booking_cancellation'] != false;
          _paymentSuccess = d['payment_success'] != false;
          _refundUpdates = d['refund_updates'] != false;
          _paymentReminder = d['payment_reminder'] == true;
          _flashSales = d['flash_sales'] != false;
          _personalizedDeals = d['personalized_deals'] != false;
          _priceDropAlerts = d['price_drop_alerts'] == true;
          _weekendDeals = d['weekend_deals'] != false;
          _securityAlerts = d['security_alerts'] != false;
          _loyaltyPoints = d['loyalty_points'] != false;
          _reviewReminders = d['review_reminders'] == true;
          _appUpdates = d['app_updates'] == true;
          _pushNotifications = d['push_notifications'] != false;
          _emailNotifications = d['email_notifications'] != false;
          _smsNotifications = d['sms_notifications'] == true;
        });
      }
    } catch (_) {}
    setState(() => _loading = false);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('authToken');
      await ApiService.put(ApiConfig.notificationPreferencesEndpoint, token: token, data: {
        'all_notifications': _allNotifications,
        'booking_confirmation': _bookingConfirmation,
        'booking_reminder': _bookingReminder,
        'check_in_reminder': _checkInReminder,
        'check_out_reminder': _checkOutReminder,
        'booking_cancellation': _bookingCancellation,
        'payment_success': _paymentSuccess,
        'refund_updates': _refundUpdates,
        'payment_reminder': _paymentReminder,
        'flash_sales': _flashSales,
        'personalized_deals': _personalizedDeals,
        'price_drop_alerts': _priceDropAlerts,
        'weekend_deals': _weekendDeals,
        'security_alerts': _securityAlerts,
        'loyalty_points': _loyaltyPoints,
        'review_reminders': _reviewReminders,
        'app_updates': _appUpdates,
        'push_notifications': _pushNotifications,
        'email_notifications': _emailNotifications,
        'sms_notifications': _smsNotifications,
      });
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Notification preferences saved'), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating));
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Failed to save'), backgroundColor: AppColors.error, behavior: SnackBarBehavior.floating));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppColors.darkGray),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Notification Settings', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Master toggle
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      gradient: _allNotifications ? AppColors.primaryGradient : const LinearGradient(colors: [Color(0xFFE8ECF0), Color(0xFFE8ECF0)]),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('All Notifications', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                              Text('Enable or disable all notifications', style: TextStyle(fontSize: 12, color: Colors.white70)),
                            ],
                          ),
                        ),
                        Switch(
                          value: _allNotifications,
                          onChanged: (v) => setState(() => _allNotifications = v),
                          activeColor: Colors.white,
                          activeTrackColor: Colors.white.withOpacity(0.4),
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(),
                  const SizedBox(height: 20),

                  _buildSection('Booking Updates', Icons.hotel_rounded, AppColors.primary, [
                    _NotifItem('Booking Confirmation', 'When a booking is confirmed', _bookingConfirmation, (v) => setState(() => _bookingConfirmation = v)),
                    _NotifItem('Booking Reminder', '24 hours before check-in', _bookingReminder, (v) => setState(() => _bookingReminder = v)),
                    _NotifItem('Check-in Reminder', 'On the day of check-in', _checkInReminder, (v) => setState(() => _checkInReminder = v)),
                    _NotifItem('Check-out Reminder', 'Morning of check-out day', _checkOutReminder, (v) => setState(() => _checkOutReminder = v)),
                    _NotifItem('Cancellation Updates', 'When a booking is cancelled', _bookingCancellation, (v) => setState(() => _bookingCancellation = v)),
                  ]).animate().fadeIn(delay: 60.ms).slideY(begin: 0.05),
                  const SizedBox(height: 16),

                  _buildSection('Payments & Refunds', Icons.payment_rounded, AppColors.success, [
                    _NotifItem('Payment Successful', 'When payment is processed', _paymentSuccess, (v) => setState(() => _paymentSuccess = v)),
                    _NotifItem('Refund Updates', 'Status of your refunds', _refundUpdates, (v) => setState(() => _refundUpdates = v)),
                    _NotifItem('Payment Due Reminder', 'For pending payments', _paymentReminder, (v) => setState(() => _paymentReminder = v)),
                  ]).animate().fadeIn(delay: 120.ms).slideY(begin: 0.05),
                  const SizedBox(height: 16),

                  _buildSection('Deals & Offers', Icons.local_offer_rounded, AppColors.warning, [
                    _NotifItem('Flash Sales', 'Limited-time deals', _flashSales, (v) => setState(() => _flashSales = v)),
                    _NotifItem('Personalized Deals', 'Based on your preferences', _personalizedDeals, (v) => setState(() => _personalizedDeals = v)),
                    _NotifItem('Price Drop Alerts', 'When saved hotel prices drop', _priceDropAlerts, (v) => setState(() => _priceDropAlerts = v)),
                    _NotifItem('Weekend Specials', 'Weekend deals every Friday', _weekendDeals, (v) => setState(() => _weekendDeals = v)),
                  ]).animate().fadeIn(delay: 180.ms).slideY(begin: 0.05),
                  const SizedBox(height: 16),

                  _buildSection('Account & Activity', Icons.person_rounded, AppColors.purple, [
                    _NotifItem('Security Alerts', 'New sign-ins and security events', _securityAlerts, (v) => setState(() => _securityAlerts = v)),
                    _NotifItem('Loyalty Points', 'When you earn or redeem points', _loyaltyPoints, (v) => setState(() => _loyaltyPoints = v)),
                    _NotifItem('Review Reminders', 'After your stay ends', _reviewReminders, (v) => setState(() => _reviewReminders = v)),
                    _NotifItem('App Updates', 'New features and improvements', _appUpdates, (v) => setState(() => _appUpdates = v)),
                  ]).animate().fadeIn(delay: 240.ms).slideY(begin: 0.05),
                  const SizedBox(height: 16),

                  _buildSection('Notification Channels', Icons.tune_rounded, AppColors.info, [
                    _NotifItem('Push Notifications', 'In-app and device notifications', _pushNotifications, (v) => setState(() => _pushNotifications = v)),
                    _NotifItem('Email Notifications', 'Sent to your registered email', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
                    _NotifItem('SMS Notifications', 'Sent to your phone number', _smsNotifications, (v) => setState(() => _smsNotifications = v)),
                  ]).animate().fadeIn(delay: 300.ms).slideY(begin: 0.05),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, -4))]),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, padding: const EdgeInsets.symmetric(vertical: 16), elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: _saving
                    ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                    : const Text('Save Preferences', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<_NotifItem> items) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppColors.cardShadow),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(width: 34, height: 34, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 17)),
                const SizedBox(width: 12),
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.darkGray)),
              ],
            ),
          ),
          const Divider(color: AppColors.lightGray, height: 1),
          ...items.asMap().entries.map((e) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Expanded(child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.value.title, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _allNotifications ? AppColors.darkGray : AppColors.gray)),
                        Text(e.value.subtitle, style: const TextStyle(fontSize: 11, color: AppColors.gray)),
                      ],
                    )),
                    Switch(
                      value: _allNotifications && e.value.value,
                      onChanged: _allNotifications ? e.value.onChanged : null,
                      activeColor: AppColors.primary,
                    ),
                  ],
                ),
              ),
              if (e.key < items.length - 1) const Divider(color: AppColors.lightGray, height: 1, indent: 16, endIndent: 16),
            ],
          )),
        ],
      ),
    );
  }
}

class _NotifItem {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _NotifItem(this.title, this.subtitle, this.value, this.onChanged);
}