import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/constants/app_constants.dart';
import '../providers/language_provider.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import 'package:provider/provider.dart';

class AlarmRescheduler {
  static Future<void> rescheduleAll(BuildContext context) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final prefs = await SharedPreferences.getInstance();
    final notificationService = NotificationService();
    final notificationsPlugin = notificationService.notificationsPlugin;

    // Load auto-open setting
    final autoOpen = prefs.getBool('auto_open_app_on_ring') ?? false;

    // 1. Reschedule default prayers
    final List<String> prayerNames = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final List<Map<String, dynamic>> defaultPrayerTimes = prayerNames.map((name) {
      final defaultPrayer = AppConstants.defaultPrayerTimes.firstWhere((p) => p['name'] == name);
      return {
        'name': name,
        'time': prefs.getString('${name}_time') ?? defaultPrayer['time'],
        'message': prefs.getString('${name}_message') ?? defaultPrayer['message'],
        'enabled': prefs.getBool('${name}_enabled') ?? defaultPrayer['enabled'],
        'sound': prefs.getString('${name}_sound') ?? defaultPrayer['sound'],
      };
    }).toList();

    for (int i = 0; i < defaultPrayerTimes.length; i++) {
      final prayer = defaultPrayerTimes[i];
      if (prayer['enabled'] == true) {
          final baseId = _getPrayerBaseId(prayer['name']);
          final time = notificationService.parseTimeString(prayer['time']);
          final soundFile = prayer['sound'] ?? AppConstants.defaultPrayerSound;
          final channelId = 'prayer_$soundFile';

          // Cancel existing alarms for this prayer
          await notificationService.cancelNotification(baseId);

          // Translate name
          final translatedName = langProvider.translate(prayer['name']);

          for (int weekday = 1; weekday <= 7; weekday++) {
            final uniqueId = baseId * 10 + weekday;
            final nextInstance = _nextInstanceOfWeekdayAndTime(weekday, time);
            final message = _getPrayerMessageForWeekday(
              langProvider,
              prayer['name'],
              weekday,
              prayer['message'],
            );

            await notificationsPlugin.zonedSchedule(
              uniqueId,
              translatedName,
              message,
              tz.TZDateTime.from(nextInstance, tz.local),
              NotificationDetails(
                android: AndroidNotificationDetails(
                  channelId,
                  'Prayer Reminders',
                  sound: RawResourceAndroidNotificationSound(soundFile),
                  playSound: true,
                  importance: Importance.max,
                  priority: Priority.max,
                  enableVibration: true,
                  enableLights: true,
                  audioAttributesUsage: AudioAttributesUsage.notification,
                  fullScreenIntent: autoOpen,
                  category: AndroidNotificationCategory.alarm,
                ),
              ),
              androidScheduleMode: AndroidScheduleMode.exact,
              matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
              payload: 'prayer_${prayer['name']}',
            );
          }
        }
      }

      // 2. Reschedule custom notifications
    await StorageService.loadNotifications();
    for (final notification in StorageService.allNotifications) {
      if (notification.enabled) {
        final timeParts = notification.time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final payload = notification.category == AppConstants.categoryPrayer
            ? 'prayer_${notification.name}'
            : null;

        await notificationService.scheduleNotification(
          title: notification.name,
          message: notification.message ?? '',
          time: TimeOfDay(hour: hour, minute: minute),
          id: notification.id,
          repeatDays: notification.repeatDays,
          payload: payload,
          sound: notification.sound,
        );
      }
    }
  }

  static int _getPrayerBaseId(String name) {
    switch (name) {
      case 'Fajr': return 1;
      case 'Dhuhr': return 2;
      case 'Asr': return 3;
      case 'Maghrib': return 4;
      case 'Isha': return 5;
      default: return (name.hashCode).abs() % 100000;
    }
  }

  static DateTime _nextInstanceOfWeekdayAndTime(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    var scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduledTime.weekday != weekday) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    }

    return scheduledTime;
  }

  static String _getPrayerMessageForWeekday(
    LanguageProvider langProvider,
    String prayerName,
    int weekday,
    String currentMessage,
  ) {
    final defaultTemplate = "Time to pray $prayerName!";
    if (currentMessage == defaultTemplate ||
        currentMessage.isEmpty ||
        currentMessage == 'auto') {
      final messages = langProvider.getWeeklyMessages(prayerName);
      if (messages.isNotEmpty) {
        final listIndex = weekday == 7 ? 0 : weekday;
        if (listIndex < messages.length) {
          return messages[listIndex];
        }
      }
    }
    return currentMessage;
  }
}
