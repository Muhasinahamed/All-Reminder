import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

class NotificationService {
  static List<NotificationModel> allNotifications = [];

  static Future<void> loadNotifications() async {
    // Your logic to load notifications from storage
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('notifications');
    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      allNotifications = jsonList.map((e) {
        return NotificationModel.fromMap(Map<String, dynamic>.from(e));
      }).toList();
    }
  }

  static Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonList = allNotifications.map((e) => e.toMap()).toList();
    await prefs.setString('notifications', jsonEncode(jsonList));
  }

  static List<NotificationModel> getNotificationsByCategory(String category) {
    return allNotifications.where((n) => n.category == category).toList();
  }
}
