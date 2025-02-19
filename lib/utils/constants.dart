import 'package:flutter/material.dart';

class AppConstants {
  static const String prayerBox = 'prayer_box';
  static const String trophyBox = 'trophy_box';
  static const String notificationChannelId = 'prayer_notifications';
  static const String notificationChannelName = 'Prayer Notifications';
  static const String notificationChannelDescription = 'Notifications for prayer times';

  static const List<String> prayerNames = [
    'Fajr',
    'Dhuhr',
    'Asr',
    'Maghrib',
    'Isha',
  ];

  static final Map<String, DateTime> defaultPrayerTimes = {
    'Fajr': DateTime(2024, 1, 1, 5, 0),
    'Dhuhr': DateTime(2024, 1, 1, 12, 30),
    'Asr': DateTime(2024, 1, 1, 15, 30),
    'Maghrib': DateTime(2024, 1, 1, 18, 0),
    'Isha': DateTime(2024, 1, 1, 19, 30),
  };

  static const Map<String, String> trophyDescriptions = {
    'beginner': 'Complete prayers for 3 days in a row',
    'consistent': 'Complete prayers for 7 days in a row',
    'dedicated': 'Complete prayers for 10 days in a row',
    'master': 'Complete prayers for 30 days in a row',
    'legend': 'Complete prayers for 100 days in a row',
  };

  static const Map<String, String> trophyIcons = {
    'beginner': '🌟',
    'consistent': '🏆',
    'dedicated': '👑',
    'master': '🎯',
    'legend': '⭐',
  };
} 