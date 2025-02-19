import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._();
  factory NotificationService() => _instance;

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  NotificationService._() {
    _init();
  }

  Future<void> _init() async {
    tz.initializeTimeZones();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _notifications.initialize(
      const InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      ),
    );
  }

  Future<bool> requestPermission() async {
    final platform = _notifications.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (platform != null) {
      return await platform.requestPermission() ?? false;
    }
    return true;
  }

  Future<void> schedulePrayerNotification({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
  }) async {
    final now = DateTime.now();
    if (scheduledTime.isBefore(now)) {
      return;
    }

    await _notifications.zonedSchedule(
      id,
      'Prayer Time',
      'It\'s time for $prayerName prayer',
      tz.TZDateTime.from(scheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_reminders',
          'Prayer Reminders',
          channelDescription: 'Notifications for prayer times',
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound('azan'),
          playSound: true,
        ),
        iOS: DarwinNotificationDetails(
          sound: 'azan.aiff',
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );
  }

  Future<void> cancelPrayerNotification(int id) async {
    await _notifications.cancel(id);
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> showInstantNotification({
    required String title,
    required String body,
  }) async {
    await _notifications.show(
      0,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'instant_notifications',
          'Instant Notifications',
          channelDescription: 'Instant notifications for important updates',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
    );
  }
} 