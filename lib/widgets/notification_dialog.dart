import 'package:flutter/material.dart';
import '../models/notification_model.dart';

class NotificationDialog {
  static void show({
    required BuildContext context,
    NotificationModel? notification,
    required Function(NotificationModel) onSave,
    required String category,
  }) {
    final nameController =
        TextEditingController(text: notification?.name ?? '');
    final messageController =
        TextEditingController(text: notification?.message ?? '');
    TimeOfDay? time = notification != null
        ? TimeOfDay(
            hour: int.parse(notification.time.split(':')[0]),
            minute: int.parse(notification.time.split(':')[1]),
          )
        : null;

    showDialog(
      context: context,
      builder: (context) {
        return _NotificationDialogContent(
          nameController: nameController,
          messageController: messageController,
          initialTime: time,
          category: category,
          notification: notification,
          onSave: onSave,
        );
      },
    );
  }
}

class _NotificationDialogContent extends StatefulWidget {
  final TextEditingController nameController;
  final TextEditingController messageController;
  final TimeOfDay? initialTime;
  final String category;
  final NotificationModel? notification;
  final Function(NotificationModel) onSave;

  const _NotificationDialogContent({
    required this.nameController,
    required this.messageController,
    this.initialTime,
    required this.category,
    this.notification,
    required this.onSave,
  });

  @override
  _NotificationDialogContentState createState() =>
      _NotificationDialogContentState();
}

class _NotificationDialogContentState
    extends State<_NotificationDialogContent> {
  TimeOfDay? time;

  @override
  void initState() {
    super.initState();
    time = widget.initialTime;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title:
          Text(widget.notification == null ? 'Add Reminder' : 'Edit Reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: widget.nameController,
            decoration: const InputDecoration(labelText: 'Reminder Name'),
          ),
          TextField(
            controller: widget.messageController,
            decoration: const InputDecoration(labelText: 'Message'),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(50),
              ),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              elevation: 3,
            ),
            onPressed: () async {
              final selectedTime = await showTimePicker(
                context: context,
                initialTime: time ?? TimeOfDay.now(),
              );
              if (selectedTime != null) {
                setState(() {
                  time = selectedTime;
                });
              }
            },
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.access_time,
                  color: Color.fromARGB(255, 103, 80, 164),
                ),
                const SizedBox(width: 5),
                Text(
                  time == null
                      ? 'Select Time'
                      : 'Time: ${time?.format(context)}',
                  style: const TextStyle(
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (widget.nameController.text.isEmpty || time == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name and Time are required')),
              );
              return;
            }

            final updatedNotification = NotificationModel(
              name: widget.nameController.text,
              time:
                  '${time!.hour.toString().padLeft(2, '0')}:${time!.minute.toString().padLeft(2, '0')}',
              message: widget.messageController.text,
              enabled: widget.notification?.enabled ?? true,
              category: widget.category,
            );

            widget.onSave(updatedNotification);
            Navigator.of(context).pop();
          },
          child: Text(widget.notification == null ? 'Add' : 'Save'),
        ),
      ],
    );
  }
}
