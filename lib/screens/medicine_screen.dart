import 'package:flutter/material.dart';
import '../services/shared_preferences.dart' as sharedprefs;
import '../services/notification_service.dart' as notifservice;
import '../widgets/notification_dialog.dart';
import 'package:all_reminder/models/notification_model.dart';

class MedicineScreen extends StatefulWidget {
  const MedicineScreen({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MedicineScreenState createState() => _MedicineScreenState();
}

class _MedicineScreenState extends State<MedicineScreen> {
  List<NotificationModel> medicineNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await sharedprefs.NotificationService.loadNotifications();
    setState(() {
      medicineNotifications = sharedprefs.NotificationService.allNotifications
          .where((notification) => notification.category == 'medicine')
          .toList();
    });
  }

  Future<void> _saveNotifications() async {
    await sharedprefs.NotificationService.loadNotifications();
    sharedprefs.NotificationService.allNotifications = [
      ...sharedprefs.NotificationService.allNotifications
          .where((n) => n.category != 'medicine'),
      ...medicineNotifications,
    ];
    await sharedprefs.NotificationService.saveNotifications();
  }

  void _toggleNotification(int index) async {
    setState(() {
      medicineNotifications[index] = medicineNotifications[index].copyWith(
        enabled: !medicineNotifications[index].enabled,
      );
    });
    await notifservice.NotificationService().toggleNotification(
      medicineNotifications[index],
      index,
    );
    _saveNotifications();
  }

  void _deleteNotification(int index) async {
    setState(() {
      medicineNotifications.removeAt(index);
    });
    await notifservice.NotificationService().cancelNotification(index);
    _saveNotifications();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medicine Reminders'),
        backgroundColor: Colors.blueAccent,
      ),
      body: medicineNotifications.isEmpty
          ? const Center(
              child: Text(
                'No Reminders Yet!',
                style: TextStyle(fontSize: 18, color: Colors.grey),
              ),
            )
          : ListView.builder(
              itemCount: medicineNotifications.length,
              padding: const EdgeInsets.all(16.0),
              itemBuilder: (context, index) {
                final notification = medicineNotifications[index];
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
                            ? Colors.blueAccent
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
                        activeColor: Colors.blueAccent,
                      ),
                      onTap: () {
                        NotificationDialog.show(
                          context: context,
                          notification: notification,
                          category: 'medicine',
                          onSave: (updatedNotification) {
                            setState(() {
                              medicineNotifications[index] = updatedNotification
                                  .copyWith(category: 'medicine');
                            });
                            _saveNotifications();
                            notifservice.NotificationService()
                                .toggleNotification(
                              medicineNotifications[index],
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
        backgroundColor: Colors.blueAccent,
        onPressed: () {
          NotificationDialog.show(
            context: context,
            category: 'medicine',
            onSave: (newNotification) {
              setState(() {
                medicineNotifications
                    .add(newNotification.copyWith(category: 'medicine'));
              });
              _saveNotifications();
              notifservice.NotificationService().toggleNotification(
                newNotification.copyWith(category: 'medicine'),
                medicineNotifications.length - 1,
              );
            },
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
