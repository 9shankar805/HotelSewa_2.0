import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

/// Feature 11: Push notification preferences
class NotificationPreferencesService {
  // GET notification-preferences — fetch current preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await ApiService.get('/notification-preferences');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load preferences'};
    }
  }

  // PUT notification-preferences — update preferences
  Future<Map<String, dynamic>> updatePreferences({
    bool? bookingUpdates,
    bool? paymentAlerts,
    bool? priceDropAlerts,
    bool? promotionalOffers,
    bool? reviewReminders,
    bool? chatMessages,
    bool? systemAnnouncements,
    bool? emailNotifications,
    bool? smsNotifications,
    bool? pushNotifications,
  }) async {
    try {
      final data = <String, dynamic>{
        if (bookingUpdates != null) 'booking_updates': bookingUpdates,
        if (paymentAlerts != null) 'payment_alerts': paymentAlerts,
        if (priceDropAlerts != null) 'price_drop_alerts': priceDropAlerts,
        if (promotionalOffers != null) 'promotional_offers': promotionalOffers,
        if (reviewReminders != null) 'review_reminders': reviewReminders,
        if (chatMessages != null) 'chat_messages': chatMessages,
        if (systemAnnouncements != null) 'system_announcements': systemAnnouncements,
        if (emailNotifications != null) 'email_notifications': emailNotifications,
        if (smsNotifications != null) 'sms_notifications': smsNotifications,
        if (pushNotifications != null) 'push_notifications': pushNotifications,
      };
      final response = await ApiService.put('/notification-preferences', data: data);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update preferences'};
    }
  }

  // PUT notification-preferences/mute — mute all for a duration
  Future<Map<String, dynamic>> muteAll({required int hours}) async {
    try {
      final response = await ApiService.put('/notification-preferences/mute', data: {'hours': hours});
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to mute notifications'};
    }
  }
}





