import 'package:shared_preferences/shared_preferences.dart';
import 'shared/api_service.dart';

/// Feature 5: Guest profile / structured preferences
class GuestPreferencesService {
  // GET user/preferences — fetch all guest preferences
  Future<Map<String, dynamic>> getPreferences() async {
    try {
      final response = await ApiService.get('/user/preferences');
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to load preferences'};
    }
  }

  // PUT user/preferences — update structured preferences
  // Covers: bed type, floor, smoking, dietary, accessibility, pillow type, etc.
  Future<Map<String, dynamic>> updatePreferences({
    String? bedType,           // 'king', 'queen', 'twin', 'double'
    String? floorPreference,   // 'low', 'high', 'any'
    bool? smokingRoom,
    List<String>? dietaryNeeds, // ['vegetarian', 'halal', 'vegan', ...]
    bool? accessibilityNeeds,
    String? pillowType,        // 'soft', 'firm', 'any'
    String? roomTemperature,   // 'cool', 'warm', 'any'
    Map<String, dynamic>? extra,
  }) async {
    try {
      final data = <String, dynamic>{
        if (bedType != null) 'bed_type': bedType,
        if (floorPreference != null) 'floor_preference': floorPreference,
        if (smokingRoom != null) 'smoking_room': smokingRoom,
        if (dietaryNeeds != null) 'dietary_needs': dietaryNeeds,
        if (accessibilityNeeds != null) 'accessibility_needs': accessibilityNeeds,
        if (pillowType != null) 'pillow_type': pillowType,
        if (roomTemperature != null) 'room_temperature': roomTemperature,
        ...?extra,
      };
      final response = await ApiService.put('/user/preferences', data: data);
      return {'success': true, 'data': response['data']};
    } catch (e) {
      return {'success': false, 'message': 'Failed to update preferences'};
    }
  }
}





