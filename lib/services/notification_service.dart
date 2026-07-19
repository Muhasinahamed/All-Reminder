import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import '../models/notification_model.dart';
import '../core/constants/app_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  late FlutterLocalNotificationsPlugin notificationsPlugin;

  factory NotificationService() => _instance;

  NotificationService._internal() {
    notificationsPlugin = FlutterLocalNotificationsPlugin();
    _initialize();
  }

  Future<void> init() async {
    await _createNotificationChannel();
  }

  Future<void> _initialize() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const initSettings = InitializationSettings(android: androidSettings);

    await notificationsPlugin.initialize(initSettings);
    tz.initializeTimeZones();
    await _createNotificationChannel();
  }

  Future<void> _createNotificationChannel() async {
    final androidImplementation = notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();

    final channelDefs = [
      (AppConstants.channelPrayerId, AppConstants.channelPrayerName, AppConstants.channelPrayerDesc),
      (AppConstants.channelWorkoutId, AppConstants.channelWorkoutName, AppConstants.channelWorkoutDesc),
      (AppConstants.channelMealId, AppConstants.channelMealName, AppConstants.channelMealDesc),
      (AppConstants.channelMedicineId, AppConstants.channelMedicineName, AppConstants.channelMedicineDesc),
      (AppConstants.channelStudyId, AppConstants.channelStudyName, AppConstants.channelStudyDesc),
      (AppConstants.channelSleepId, AppConstants.channelSleepName, AppConstants.channelSleepDesc),
    ];

    for (final def in channelDefs) {
      final baseId = def.$1;
      final name = def.$2;
      final desc = def.$3;

      final activeChannelId = prefs.getString('sound_channel_id_$baseId') ?? baseId;
      final savedUri = prefs.getString('sound_uri_$baseId');
      final sound = (savedUri != null && savedUri.isNotEmpty)
          ? UriAndroidNotificationSound(savedUri)
          : null;

      final channel = AndroidNotificationChannel(
        activeChannelId,
        name,
        description: desc,
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        sound: sound,
      );

      await androidImplementation.createNotificationChannel(channel);
    }
  }

  DateTime _nextInstanceOfWeekdayAndTime(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
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

  String _getChannelIdForCategory(String? category, String? sound) {
    if (sound != null && sound.isNotEmpty) return 'prayer_$sound';
    switch (category) {
      case AppConstants.categoryPrayer:
        return AppConstants.channelPrayerId;
      case AppConstants.categoryWorkout:
        return AppConstants.channelWorkoutId;
      case AppConstants.categoryMeal:
        return AppConstants.channelMealId;
      case AppConstants.categoryMedicine:
        return AppConstants.channelMedicineId;
      case AppConstants.categoryStudy:
        return AppConstants.channelStudyId;
      case AppConstants.categorySleep:
        return AppConstants.channelSleepId;
      default:
        return AppConstants.channelPrayerId;
    }
  }

  String _getChannelNameForCategory(String? category, String? sound) {
    if (sound != null && sound.isNotEmpty) return 'Prayer Reminders';
    switch (category) {
      case AppConstants.categoryPrayer:
        return AppConstants.channelPrayerName;
      case AppConstants.categoryWorkout:
        return AppConstants.channelWorkoutName;
      case AppConstants.categoryMeal:
        return AppConstants.channelMealName;
      case AppConstants.categoryMedicine:
        return AppConstants.channelMedicineName;
      case AppConstants.categoryStudy:
        return AppConstants.channelStudyName;
      case AppConstants.categorySleep:
        return AppConstants.channelSleepName;
      default:
        return AppConstants.channelPrayerName;
    }
  }

  String _getChannelDescForCategory(String? category, String? sound) {
    if (sound != null && sound.isNotEmpty) return AppConstants.channelPrayerDesc;
    switch (category) {
      case AppConstants.categoryPrayer:
        return AppConstants.channelPrayerDesc;
      case AppConstants.categoryWorkout:
        return AppConstants.channelWorkoutDesc;
      case AppConstants.categoryMeal:
        return AppConstants.channelMealDesc;
      case AppConstants.categoryMedicine:
        return AppConstants.channelMedicineDesc;
      case AppConstants.categoryStudy:
        return AppConstants.channelStudyDesc;
      case AppConstants.categorySleep:
        return AppConstants.channelSleepDesc;
      default:
        return AppConstants.channelPrayerDesc;
    }
  }

  Future<void> scheduleNotification({
    required String title,
    required String message,
    required TimeOfDay time,
    required int id,
    List<int>? repeatDays,
    String? payload,
    String? sound,
    String? category,
  }) async {
    await cancelNotification(id);

    final days = repeatDays ?? const [1, 2, 3, 4, 5, 6, 7];

    final prefs = await SharedPreferences.getInstance();
    await prefs.reload();
    final baseChannelId = _getChannelIdForCategory(category, sound);
    final activeChannelId = prefs.getString('sound_channel_id_$baseChannelId') ?? baseChannelId;
    final channelName = _getChannelNameForCategory(category, sound);
    final channelDesc = _getChannelDescForCategory(category, sound);

    final AndroidNotificationSound? soundResource = (sound != null && sound.isNotEmpty)
        ? RawResourceAndroidNotificationSound(sound)
        : null;

    final autoOpen = prefs.getBool('auto_open_app_on_ring') ?? false;

    if (days.length == 7) {
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
        NotificationDetails(
          android: AndroidNotificationDetails(
            activeChannelId,
            channelName,
            channelDescription: channelDesc,
            importance: Importance.max,
            priority: Priority.max,
            sound: soundResource,
            playSound: true,
            enableVibration: true,
            enableLights: true,
            audioAttributesUsage: AudioAttributesUsage.notification,
            fullScreenIntent: autoOpen,
            category: AndroidNotificationCategory.reminder,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exact,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } else {
      for (final weekday in days) {
        final uniqueId = id * 10 + weekday;
        final nextInstance = _nextInstanceOfWeekdayAndTime(weekday, time);

        await notificationsPlugin.zonedSchedule(
          uniqueId,
          title,
          message,
          tz.TZDateTime.from(nextInstance, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              activeChannelId,
              channelName,
              channelDescription: channelDesc,
              importance: Importance.max,
              priority: Priority.max,
              sound: soundResource,
              playSound: true,
              enableVibration: true,
              enableLights: true,
              audioAttributesUsage: AudioAttributesUsage.notification,
              fullScreenIntent: autoOpen,
              category: AndroidNotificationCategory.reminder,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exact,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: payload,
        );
      }
    }
  }

  Future<void> cancelNotification(int id) async {
    await notificationsPlugin.cancel(id);
    for (int weekday = 1; weekday <= 7; weekday++) {
      await notificationsPlugin.cancel(id * 10 + weekday);
    }
  }

  Future<void> toggleNotification(
    NotificationModel notification,
    int id,
  ) async {
    if (notification.enabled) {
      final timeOfDay = parseTimeString(notification.time);

      final payload = '${notification.category}:${notification.name}';

      await scheduleNotification(
        title: notification.name,
        message: notification.message ?? '',
        time: timeOfDay,
        id: id,
        repeatDays: notification.repeatDays,
        payload: payload,
        sound: notification.sound,
        category: notification.category,
      );
    } else {
      await cancelNotification(id);
    }
  }

  TimeOfDay parseTimeString(String time) {
    try {
      final cleanTime = time.trim();
      final spaceParts = cleanTime.split(RegExp(r'\s+'));
      final hourMinute = spaceParts[0].split(':');
      int hour = int.parse(hourMinute[0]);
      final minute = int.parse(hourMinute[1]);

      if (spaceParts.length > 1) {
        final period = spaceParts[1].toUpperCase();
        if (period == 'PM' && hour != 12) {
          hour += 12;
        } else if (period == 'AM' && hour == 12) {
          hour = 0;
        }
      }

      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return const TimeOfDay(hour: 8, minute: 0);
    }
  }

  static Future<void> rescheduleCategoryNotifications(String category) async {
    final service = NotificationService();
    // First, ensure all channel registration definitions are updated with new sounds
    await service._createNotificationChannel();
    await StorageService.loadNotifications();
    final list = StorageService.getNotificationsByCategory(category);
    for (final n in list) {
      if (n.enabled) {
        await service.toggleNotification(n, n.id);
      }
    }
  }

  static const _channel = MethodChannel('in.inhomex.all_reminder/settings');

  static Future<void> openRingtonePicker([String? channelId]) async {
    try {
      await _channel.invokeMethod('openRingtonePicker', {
        if (channelId != null) 'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to open ringtone picker: '${e.message}'.");
      await openNotificationSettings(channelId);
    }
  }

  static Future<void> openNotificationSettings([String? channelId]) async {
    try {
      await NotificationService()._createNotificationChannel();
      await _channel.invokeMethod('openNotificationSettings', {
        if (channelId != null) 'channelId': channelId,
      });
    } on PlatformException catch (e) {
      debugPrint("Failed to open settings: '${e.message}'.");
      await openAppSettings();
    }
  }
}
