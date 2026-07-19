import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

class StorageService {
  static const String _notificationsKey = 'notifications';
  static List<NotificationModel> allNotifications = [];

  static Future<void> loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_notificationsKey);

    if (jsonString != null) {
      final List<dynamic> jsonList = jsonDecode(jsonString);
      final rawList = jsonList
          .map((e) => NotificationModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();

      // Deduplicate by ID
      final Map<int, NotificationModel> uniqueMap = {};
      for (var n in rawList) {
        uniqueMap[n.id] = n;
      }
      allNotifications = uniqueMap.values.toList();
    } else {
      allNotifications = [];
    }
  }

  static Future<void> saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    // Deduplicate before saving
    final Map<int, NotificationModel> uniqueMap = {};
    for (var n in allNotifications) {
      uniqueMap[n.id] = n;
    }
    allNotifications = uniqueMap.values.toList();
    final jsonList = allNotifications.map((e) => e.toMap()).toList();
    await prefs.setString(_notificationsKey, jsonEncode(jsonList));
  }

  static List<NotificationModel> getNotificationsByCategory(String category) {
    return allNotifications.where((n) => n.category == category).toList();
  }

  static Future<void> updateNotificationsByCategory(
    String category,
    List<NotificationModel> notifications,
  ) async {
    await loadNotifications();

    final otherCategories = allNotifications.where((n) => n.category != category).toList();

    final Map<int, NotificationModel> uniqueCategoryMap = {};
    for (var n in notifications) {
      uniqueCategoryMap[n.id] = n;
    }

    allNotifications = [
      ...otherCategories,
      ...uniqueCategoryMap.values,
    ];
    await saveNotifications();
  }
}
