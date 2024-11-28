import 'package:flutter/material.dart';
import '../services/shared_preferences.dart' as sharedprefs;
import '../services/notification_service.dart' as notifservice;
import '../widgets/notification_dialog.dart';
import 'package:all_reminder/models/notification_model.dart';

class SnacksScreen extends StatefulWidget {
  const SnacksScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _SnacksScreenState createState() => _SnacksScreenState();
}

class _SnacksScreenState extends State<SnacksScreen> {
  List<NotificationModel> snacksNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await sharedprefs.NotificationService.loadNotifications();
    setState(() {
      snacksNotifications = sharedprefs.NotificationService.allNotifications
          .where((notification) => notification.category == 'snacks')
          .toList();
    });
  }

  Future<void> _saveNotifications() async {
    await sharedprefs.NotificationService.loadNotifications();
    sharedprefs.NotificationService.allNotifications = [
      ...sharedprefs.NotificationService.allNotifications
          .where((n) => n.category != 'snacks'),
      ...snacksNotifications,
    ];
    await sharedprefs.NotificationService.saveNotifications();
  }

  void _toggleNotification(int index) async {
    setState(() {
      snacksNotifications[index] = snacksNotifications[index].copyWith(
        enabled: !snacksNotifications[index].enabled,
      );
    });
    await notifservice.NotificationService().toggleNotification(
      snacksNotifications[index],
      index,
    );
    _saveNotifications();
  }

  void _deleteNotification(int index) async {
    setState(() {
      snacksNotifications.removeAt(index);
    });
    await notifservice.NotificationService().cancelNotification(index);
    _saveNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Snacks Reminders'),
        backgroundColor: Colors.orangeAccent,
      ),
      body: snacksNotifications.isEmpty
          ? const Center(
              child: Text(
                'No Reminders Yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: snacksNotifications.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                final notification = snacksNotifications[index];
                return Dismissible(
                  key: Key(notification.name),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    _deleteNotification(index);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Reminder deleted')),
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
                        backgroundColor: notification.enabled
                            ? Colors.orangeAccent
                            : Colors.grey,
                        child: Icon(
                          notification.enabled
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
                      subtitle: Text(
                        'Time: ${notification.time}\n${notification.message ?? "No message"}',
                        style:
                            const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      trailing: Switch(
                        value: notification.enabled,
                        onChanged: (value) => _toggleNotification(index),
                        activeColor: Colors.orangeAccent,
                      ),
                      onTap: () {
                        NotificationDialog.show(
                          context: context,
                          notification: notification,
                          category: 'snacks',
                          onSave: (updatedNotification) {
                            setState(() {
                              snacksNotifications[index] = updatedNotification
                                  .copyWith(category: 'snacks');
                            });
                            _saveNotifications();
                            notifservice.NotificationService()
                                .toggleNotification(
                              snacksNotifications[index],
                              index,
                            );
                          },
                        );
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orangeAccent,
        onPressed: () {
          NotificationDialog.show(
            context: context,
            category: 'snacks',
            onSave: (newNotification) {
              setState(() {
                snacksNotifications
                    .add(newNotification.copyWith(category: 'snacks'));
              });
              _saveNotifications();
              notifservice.NotificationService().toggleNotification(
                newNotification.copyWith(category: 'snacks'),
                snacksNotifications.length - 1,
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
