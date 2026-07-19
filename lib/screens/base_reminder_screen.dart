import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import '../core/constants/app_constants.dart';
import '../models/notification_model.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/common/notification_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/dialogs/notification_dialog.dart';
import '../widgets/common/glassy_snack_bar.dart';
import '../widgets/common/glass_background.dart';
import '../widgets/common/glass_fab.dart';
import '../providers/language_provider.dart';

class BaseReminderScreen extends StatefulWidget {
  final String title;
  final String category;
  final Color themeColor;

  const BaseReminderScreen({
    super.key,
    required this.title,
    required this.category,
    required this.themeColor,
  });

  @override
  State<BaseReminderScreen> createState() => _BaseReminderScreenState();
}

class _BaseReminderScreenState extends State<BaseReminderScreen> {
  List<NotificationModel> notifications = [];
  final NotificationService _notificationService = NotificationService();

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    await StorageService.loadNotifications();
    setState(() {
      notifications = StorageService.getNotificationsByCategory(
        widget.category,
      );
    });
  }

  Future<void> _saveNotifications() async {
    await StorageService.updateNotificationsByCategory(
      widget.category,
      notifications,
    );
  }

  Future<void> _loadSampleReminders() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final langCode = langProvider.currentLanguage;
    final samples = AppConstants.getSampleReminders(widget.category, langCode);

    final existingNames = notifications.map((n) => n.name.trim().toLowerCase()).toSet();
    final newSamples = samples.where((s) => !existingNames.contains(s.name.trim().toLowerCase())).toList();

    if (newSamples.isEmpty) {
      if (mounted) {
        GlassySnackBar.show(
          context,
          langProvider.translate('samples_already_added'),
        );
      }
      return;
    }

    setState(() {
      notifications.addAll(newSamples);
    });

    await _saveNotifications();

    for (var n in newSamples) {
      if (n.enabled) {
        await _notificationService.toggleNotification(n, n.id);
      }
    }

    if (mounted) {
      GlassySnackBar.show(
        context,
        langProvider.translate('sample_planner_loaded'),
      );
    }
  }

  Future<void> _clearAllReminders() async {
    for (var n in notifications) {
      await _notificationService.cancelNotification(n.id);
    }

    setState(() {
      notifications.clear();
    });

    await _saveNotifications();
  }

  Future<void> _changeNotificationSound(String channelId) async {
    await NotificationService.openRingtonePicker(channelId);
    // When MethodChannel returns, the sound and channel ID have been updated in SharedPreferences.
    // Reschedule all active reminders for this category to point to the new sound-configured channel ID.
    await NotificationService.rescheduleCategoryNotifications(widget.category);
    // Reload state
    await _loadNotifications();
  }

  Future<bool> _ensureNotificationPermission() async {
    final status = await Permission.notification.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await Permission.notification.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              "Notification permission permanently denied. Enable it from Settings.",
            ),
            action: SnackBarAction(
              label: "SETTINGS",
              onPressed: () {
                openAppSettings();
              },
            ),
          ),
        );
      }
      return false;
    }

    return false;
  }

  void _toggleNotification(int index) async {
    final isEnabled = notifications[index].enabled;

    if (!isEnabled) {
      final allowed = await _ensureNotificationPermission();
      if (!allowed) return;
    }
    setState(() {
      notifications[index] = notifications[index].copyWith(
        enabled: !notifications[index].enabled,
      );
    });

    await _notificationService.toggleNotification(notifications[index], notifications[index].id);
    await _saveNotifications();
  }

  void _deleteNotification(int index) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final notificationToDelete = notifications[index];
    setState(() {
      notifications.removeAt(index);
    });

    await _notificationService.cancelNotification(notificationToDelete.id);
    await _saveNotifications();

    if (mounted) {
      GlassySnackBar.show(context, langProvider.translate('reminder_deleted'));
    }
  }

  void _addOrEditNotification({NotificationModel? notification, int? index}) {
    NotificationDialog.show(
      context: context,
      notification: notification,
      category: widget.category,
      onSave: (updatedNotification) async {
        setState(() {
          if (index != null) {
            notifications[index] = updatedNotification;
          } else {
            notifications.add(updatedNotification);
          }
        });

        await _saveNotifications();
        await _notificationService.toggleNotification(
          updatedNotification,
          updatedNotification.id,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GlassBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text(
            widget.title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              letterSpacing: 1.0,
              color: theme.colorScheme.onSurface,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
              ),
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: theme.colorScheme.onSurface),
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          actions: [
            PopupMenuButton<String>(
              constraints: const BoxConstraints(maxWidth: 240),
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                  border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                ),
                child: Icon(Icons.more_vert_rounded, size: 18, color: theme.colorScheme.onSurface),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              color: isDark ? const Color(0xFF1A1C2E) : Colors.white,
              onSelected: (value) {
                if (value == 'setup_sample') {
                  _loadSampleReminders();
                } else if (value == 'notification_sound') {
                  final channelId = AppConstants.getChannelIdForCategory(widget.category);
                  _changeNotificationSound(channelId);
                } else if (value == 'clear_all') {
                  _clearAllReminders();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'setup_sample',
                  child: Row(
                    children: [
                      Icon(Icons.auto_awesome_rounded, color: widget.themeColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          langProvider.translate('setup_sample_planner'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'notification_sound',
                  child: Row(
                    children: [
                      Icon(Icons.music_note_rounded, color: widget.themeColor, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          langProvider.translate('notification_sound'),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: theme.colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                if (notifications.isNotEmpty)
                  PopupMenuItem(
                    value: 'clear_all',
                    child: Row(
                      children: [
                        const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            langProvider.translate('clear_all'),
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.redAccent,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: notifications.isEmpty
            ? EmptyState(
                message: langProvider.translate('no_reminders_yet'),
                icon: Icons.notifications_none_rounded,
                themeColor: widget.themeColor,
                actionLabel: langProvider.translate('setup_sample_planner'),
                onActionPressed: _loadSampleReminders,
              )
            : ListView.builder(
                itemCount: notifications.length,
                padding: const EdgeInsets.only(
                  left: 16.0,
                  right: 16.0,
                  top: 12.0,
                  bottom: 90.0,
                ),
                physics: const BouncingScrollPhysics(),
                itemBuilder: (context, index) {
                  return NotificationCard(
                    notification: notifications[index],
                    themeColor: widget.themeColor,
                    enabled: notifications[index].enabled,
                    onToggle: () => _toggleNotification(index),
                    onTap: () => _addOrEditNotification(
                      notification: notifications[index],
                      index: index,
                    ),
                    onDelete: () => _deleteNotification(index),
                  );
                },
              ),
        floatingActionButton: GlassFab(
          onPressed: () => _addOrEditNotification(),
          color: widget.themeColor,
          icon: Icons.add_rounded,
          size: 60,
        ),
      ),
    );
  }
}
