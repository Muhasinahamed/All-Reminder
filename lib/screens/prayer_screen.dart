import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;

import '../services/shared_preferences.dart' as sharedprefs;
import '../services/notification_service.dart' as notifservice;
import '../widgets/notification_dialog.dart';
import 'package:all_reminder/models/notification_model.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _PrayerScreenState createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  SharedPreferences? prefs;

  List<Map<String, dynamic>> prayerTimes = [
    {
      "name": "Fajr",
      "time": "05:00 AM",
      "enabled": false,
      "message": "Time to pray Fajr!"
    },
    {
      "name": "Dhuhr",
      "time": "12:30 PM",
      "enabled": false,
      "message": "Time to pray Dhuhr!"
    },
    {
      "name": "Asr",
      "time": "03:45 PM",
      "enabled": false,
      "message": "Time to pray Asr!"
    },
    {
      "name": "Maghrib",
      "time": "06:15 PM",
      "enabled": false,
      "message": "Time to pray Maghrib!"
    },
    {
      "name": "Isha",
      "time": "08:00 PM",
      "enabled": false,
      "message": "Time to pray Isha!"
    },
  ];

  List<NotificationModel> prayerNotifications = [];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();
    _initializeNotifications();
    _loadPrayerData();
    _loadNotifications();
    _requestPermissions();
    _monitorSystemTime();
  }

  Future<void> _requestPermissions() async {
    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  }

  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await notificationsPlugin.initialize(initializationSettings);

    const AndroidNotificationChannel cschannel = AndroidNotificationChannel(
        'allahuakbar', 'Prayer Reminders',
        description: 'Channel for prayer reminders',
        importance: Importance.high,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('allahu_akbar'));

    await notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(cschannel);
  }

  Future<void> _loadPrayerData() async {
    prefs = await SharedPreferences.getInstance();
    final now = DateTime.now();

    setState(() {
      for (int i = 0; i < prayerTimes.length; i++) {
        prayerTimes[i]['time'] =
            prefs?.getString('${prayerTimes[i]['name']}_time') ??
                prayerTimes[i]['time'];
        prayerTimes[i]['message'] =
            prefs?.getString('${prayerTimes[i]['name']}_message') ??
                prayerTimes[i]['message'];
        prayerTimes[i]['enabled'] =
            prefs?.getBool('${prayerTimes[i]['name']}_enabled') ?? false;

        // Reschedule any enabled prayer notifications
        if (prayerTimes[i]['enabled']) {
          final time = _parseTime(prayerTimes[i]['time']);
          final scheduledTime = tz.TZDateTime(
            tz.local,
            now.year,
            now.month,
            now.day,
            time.hour,
            time.minute,
          );

          // Adjust for past times
          final validScheduledTime = scheduledTime.isBefore(now)
              ? scheduledTime.add(const Duration(days: 1))
              : scheduledTime;

          _scheduleNotification(
            prayerTimes[i]['name'],
            prayerTimes[i]['message'],
            TimeOfDay(
                hour: validScheduledTime.hour,
                minute: validScheduledTime.minute),
          );
        }
      }
    });
  }

  Future<void> _loadNotifications() async {
    await sharedprefs.NotificationService.loadNotifications();
    setState(() {
      prayerNotifications = sharedprefs.NotificationService.allNotifications
          .where((notification) => notification.category == 'prayer')
          .toList();
    });
  }

  Future<void> _saveNotifications() async {
    await sharedprefs.NotificationService.saveNotifications();
    sharedprefs.NotificationService.allNotifications = [
      ...sharedprefs.NotificationService.allNotifications
          .where((n) => n.category != 'prayer'),
      ...prayerNotifications,
    ];
    await sharedprefs.NotificationService.saveNotifications();
  }

  Future<void> _savePrayerData() async {
    for (var prayer in prayerTimes) {
      await prefs?.setString('${prayer['name']}_time', prayer['time']);
      await prefs?.setString('${prayer['name']}_message', prayer['message']);
      await prefs?.setBool('${prayer['name']}_enabled', prayer['enabled']);
    }
  }

  void _scheduleNotification(
      String title, String message, TimeOfDay time) async {
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
      title.hashCode,
      title,
      message,
      tz.TZDateTime.from(validScheduledTime, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'allahuakbar',
          'channel_name',
          sound: RawResourceAndroidNotificationSound('allahu_akbar'),
          playSound: true,
          importance: Importance.high,
          priority: Priority.high,
          audioAttributesUsage: AudioAttributesUsage.notification,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exact,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.wallClockTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  void _toggleUserNotification(int index) async {
    setState(() {
      prayerNotifications[index].enabled = !prayerNotifications[index].enabled;
    });
    await notifservice.NotificationService().toggleNotification(
      prayerNotifications[index],
      index,
    );
    _saveNotifications();
  }

  TimeOfDay _parseTime(String time) {
    final timeParts = time.split(' ');
    final hourMinute = timeParts[0].split(':');
    int hour = int.parse(hourMinute[0]);
    final minute = int.parse(hourMinute[1]);

    // Handle AM/PM
    if (timeParts[1] == 'PM' && hour != 12) {
      hour += 12; // Convert PM hours (except for 12 PM)
    } else if (timeParts[1] == 'AM' && hour == 12) {
      hour = 0; // Convert 12 AM to 0 hours
    }

    return TimeOfDay(hour: hour, minute: minute);
  }

  void _monitorSystemTime() {
    DateTime lastKnownTime = DateTime.now();

    Timer.periodic(const Duration(seconds: 10), (timer) {
      final now = DateTime.now();

      if (now.difference(lastKnownTime).inMinutes.abs() > 1) {
        // System time change detected
        _loadPrayerData(); // Reschedule all active notifications
      }

      lastKnownTime = now;
    });
  }

  void _deletePrayerNotification(int index) async {
    setState(() {
      prayerNotifications.removeAt(index);
    });
    await notifservice.NotificationService().cancelNotification(index);
    _saveNotifications();
  }

  void _toggleReminder(int index) async {
    setState(() {
      prayerTimes[index]['enabled'] = !prayerTimes[index]['enabled'];
    });
    await _savePrayerData();

    if (prayerTimes[index]['enabled']) {
      final time = _parseTime(prayerTimes[index]['time']);
      _scheduleNotification(
        prayerTimes[index]['name'],
        prayerTimes[index]['message'],
        time,
      );
    } else {
      notificationsPlugin.cancel(prayerTimes[index]['name'].hashCode);
    }
  }

  void _pickTime(int index) async {
    final currentTime = _parseTime(prayerTimes[index]['time']);
    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
    );

    if (pickedTime != null) {
      setState(() {
        final period = pickedTime.period == DayPeriod.am ? "AM" : "PM";
        prayerTimes[index]['time'] =
            "${pickedTime.hourOfPeriod}:${pickedTime.minute.toString().padLeft(2, '0')} $period";
      });
      await _savePrayerData();

      if (prayerTimes[index]['enabled']) {
        _scheduleNotification(
          prayerTimes[index]['name'],
          prayerTimes[index]['message'],
          pickedTime,
        );
      }
    }
  }

  void _editMessage(int index) async {
    final controller =
        TextEditingController(text: prayerTimes[index]['message']);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Edit Message"),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: "Reminder Message"),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                  prayerTimes[index]['message'] = controller.text;
                });
                _savePrayerData();
                Navigator.pop(context);
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    List<dynamic> combinedNotifications = [
      ...prayerTimes,
      ...prayerNotifications,
    ];
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prayer Reminders'),
        backgroundColor: Colors.green,
      ),
      body: combinedNotifications.isEmpty
          ? const Center(
              child: Text(
                'No Reminders Yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: combinedNotifications.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                var notification = combinedNotifications[index];
                bool isPrayerNotification = notification is NotificationModel;
                bool isEnabled = isPrayerNotification
                    ? notification.enabled
                    : notification['enabled'];

                return isPrayerNotification
                    ? Dismissible(
                        key: Key(notification.name),
                        direction: DismissDirection.endToStart,
                        onDismissed: (direction) {
                          _deletePrayerNotification(index - prayerTimes.length);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text('Prayer Reminder deleted')),
                          );
                        },
                        background: Container(
                          color: Colors.red,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          child: const Icon(Icons.delete, color: Colors.white),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 5,
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(
                                vertical: 10, horizontal: 16),
                            leading: CircleAvatar(
                              backgroundColor: isEnabled
                                  ? Colors.green
                                  : Colors.grey, // Theme-based colors
                              child: Icon(
                                isEnabled
                                    ? Icons.notifications_active
                                    : Icons.notifications_off,
                                color: Colors.white,
                              ),
                            ),
                            title: Text(
                              notification.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Time: ${notification.time}'),
                                Text(
                                  'Message: ${notification.message ?? "No message"}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                              ],
                            ),
                            trailing: Switch(
                              value: isEnabled,
                              onChanged: (value) => _toggleUserNotification(
                                  index - prayerTimes.length),
                              activeColor: Colors.green,
                            ),
                            onTap: () {
                              NotificationDialog.show(
                                context: context,
                                notification: notification,
                                category: 'prayer',
                                onSave: (updatedNotification) {
                                  setState(() {
                                    prayerNotifications[
                                            index - prayerTimes.length] =
                                        updatedNotification.copyWith(
                                            category: 'prayer');
                                  });
                                  _saveNotifications();
                                  notifservice.NotificationService()
                                      .toggleNotification(
                                    prayerNotifications[
                                        index - prayerTimes.length],
                                    index - prayerTimes.length,
                                  );
                                },
                              );
                            },
                          ),
                        ),
                      )
                    : Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 5,
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                              vertical: 10, horizontal: 16),
                          leading: CircleAvatar(
                            backgroundColor:
                                isEnabled ? Colors.green : Colors.grey,
                            child: Icon(
                              isEnabled
                                  ? Icons.notifications_active
                                  : Icons.notifications_off,
                              color: Colors.white,
                            ),
                          ),
                          title: Text(notification['name']),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Time: ${notification['time']}'),
                              Text(
                                'Message: ${notification['message']}',
                                style: const TextStyle(
                                    fontSize: 14, color: Colors.grey),
                              ),
                            ],
                          ),
                          trailing: Switch(
                            value: isEnabled,
                            onChanged: (value) => _toggleReminder(index),
                            activeColor: Colors.green,
                          ),
                          onTap: () => _pickTime(index),
                          onLongPress: () => _editMessage(index),
                        ),
                      );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () {
          NotificationDialog.show(
            context: context,
            category: 'prayer',
            onSave: (newNotification) {
              setState(() {
                prayerNotifications.add(newNotification);
              });
              _saveNotifications();
              notifservice.NotificationService().toggleNotification(
                newNotification.copyWith(category: 'prayer'),
                prayerNotifications.length - 1,
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
