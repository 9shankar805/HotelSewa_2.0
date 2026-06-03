import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Controls whether the app is in customer or owner mode.
/// Persisted across restarts.
class AppModeProvider extends ChangeNotifier {
  bool _isOwnerMode = false;

  bool get isOwnerMode => _isOwnerMode;

  AppModeProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _isOwnerMode = prefs.getString('user_role') == 'hotel_owner';
    notifyListeners();
  }

  Future<void> setOwnerMode(bool value) async {
    _isOwnerMode = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_role', value ? 'hotel_owner' : 'customer');
    notifyListeners();
  }

  Future<void> toggle() => setOwnerMode(!_isOwnerMode);
}
