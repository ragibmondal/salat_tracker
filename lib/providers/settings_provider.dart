import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  
  // Keys for SharedPreferences
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notificationSoundKey = 'notification_sound';
  static const String _reminderTimeKey = 'reminder_time';
  
  SettingsProvider(this._prefs) {
    _loadSettings();
  }
  
  // Notification Settings
  bool _notificationsEnabled = true;
  String _notificationSound = 'azan';
  int _reminderTime = 0; // minutes before prayer time
  
  bool get notificationsEnabled => _notificationsEnabled;
  String get notificationSound => _notificationSound;
  int get reminderTime => _reminderTime;
  
  void _loadSettings() {
    _notificationsEnabled = _prefs.getBool(_notificationsEnabledKey) ?? true;
    _notificationSound = _prefs.getString(_notificationSoundKey) ?? 'azan';
    _reminderTime = _prefs.getInt(_reminderTimeKey) ?? 0;
  }
  
  Future<void> toggleNotifications(bool value) async {
    _notificationsEnabled = value;
    await _prefs.setBool(_notificationsEnabledKey, value);
    notifyListeners();
  }
  
  Future<void> setNotificationSound(String sound) async {
    _notificationSound = sound;
    await _prefs.setString(_notificationSoundKey, sound);
    notifyListeners();
  }
  
  Future<void> setReminderTime(int minutes) async {
    _reminderTime = minutes;
    await _prefs.setInt(_reminderTimeKey, minutes);
    notifyListeners();
  }
} 