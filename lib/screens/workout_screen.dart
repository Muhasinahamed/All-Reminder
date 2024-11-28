import 'package:flutter/material.dart';
import '../services/shared_preferences.dart' as sharedprefs;
import '../services/notification_service.dart' as notifservice;
import '../widgets/notification_dialog.dart';
import 'package:all_reminder/models/notification_model.dart';

class WorkoutScreen extends StatefulWidget {
  const WorkoutScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WorkoutScreenState createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends State<WorkoutScreen> {
  List<NotificationModel> workoutNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await sharedprefs.NotificationService.loadNotifications();
    setState(() {
      workoutNotifications = sharedprefs.NotificationService.allNotifications
          .where((notification) => notification.category == 'workout')
          .toList();
    });
  }

  Future<void> _saveNotifications() async {
    await sharedprefs.NotificationService.saveNotifications();
    sharedprefs.NotificationService.allNotifications = [
      ...sharedprefs.NotificationService.allNotifications
          .where((n) => n.category != 'workout'),
      ...workoutNotifications,
    ];
    await sharedprefs.NotificationService.saveNotifications();
  }

  void _toggleNotification(int index) async {
    setState(() {
      workoutNotifications[index].enabled =
          !workoutNotifications[index].enabled;
    });
    await notifservice.NotificationService().toggleNotification(
      workoutNotifications[index],
      index,
    );
    _saveNotifications();
  }

  void _deleteNotification(int index) async {
    setState(() {
      workoutNotifications.removeAt(index);
    });
    await notifservice.NotificationService().cancelNotification(index);
    _saveNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Reminders'),
        backgroundColor: Colors.orange,
      ),
      body: workoutNotifications.isEmpty
          ? const Center(
              child: Text(
                'No Reminders Yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: workoutNotifications.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                final notification = workoutNotifications[index];
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
                        backgroundColor:
                            notification.enabled ? Colors.orange : Colors.grey,
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
                        value: notification.enabled,
                        onChanged: (value) => _toggleNotification(index),
                        activeColor: Colors.orange,
                      ),
                      onTap: () {
                        NotificationDialog.show(
                          context: context,
                          notification: notification,
                          category: 'workout',
                          onSave: (updatedNotification) {
                            setState(() {
                              workoutNotifications[index] = updatedNotification
                                  .copyWith(category: 'workout');
                            });
                            _saveNotifications();
                            notifservice.NotificationService()
                                .toggleNotification(
                              workoutNotifications[index],
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
        backgroundColor: Colors.orange,
        onPressed: () {
          NotificationDialog.show(
            context: context,
            category: 'workout',
            onSave: (newNotification) {
              setState(() {
                workoutNotifications
                    .add(newNotification.copyWith(category: 'workout'));
              });
              _saveNotifications();
              notifservice.NotificationService().toggleNotification(
                newNotification.copyWith(category: 'workout'),
                workoutNotifications.length - 1,
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
