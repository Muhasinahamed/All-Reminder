import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin notificationsPlugin;

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal() {
    notificationsPlugin = FlutterLocalNotificationsPlugin();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    notificationsPlugin.initialize(initSettings);

    // Initialize timezone database
    tz.initializeTimeZones();
    _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    const androidChannel = AndroidNotificationChannel(
      'Reminder_notifications',
      'All_Reminder_Notifications',
      description: 'Channel for All reminder notifications',
      importance: Importance.high,
    );

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(androidChannel);
  }

  Future<void> scheduleNotification(
    String title,
    String message,
    TimeOfDay time, {
    required int id,
  }) async {
    final now = DateTime.now();

    final scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    final validScheduledTime = scheduledTime.isBefore(now)
        ? scheduledTime.add(const Duration(days: 1))
        : scheduledTime;

    await notificationsPlugin.zonedSchedule(
      id,
      title,
      message,
      tz.TZDateTime.from(validScheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'Reminder_notifications',
          'All_Reminder_Notifications',
          importance: Importance.high,
          priority: Priority.high,
          playSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
  }

  Future<void> toggleNotification(
    NotificationModel notification,
    int id,
  ) async {
    if (notification.enabled) {
      final timeParts = notification.time.split(':');
      final hour = int.parse(timeParts[0]);
      final minute = int.parse(timeParts[1]);
      await scheduleNotification(
        notification.name,
        notification.message ?? '',
        TimeOfDay(hour: hour, minute: minute),
        id: id,
      );
    } else {
      await cancelNotification(id);
    }
  }
}
