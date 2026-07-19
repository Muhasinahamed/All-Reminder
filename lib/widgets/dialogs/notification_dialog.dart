import 'package:all_reminder/services/notification_service.dart';
import 'package:flutter/material.dart';
import '../../models/notification_model.dart';
import '../common/glassy_snack_bar.dart';
import '../../core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class NotificationDialog {
  static void show({
    required BuildContext context,
    NotificationModel? notification,
    required Function(NotificationModel) onSave,
    required String category,
  }) {
    showDialog(
      context: context,
      builder: (context) => _NotificationDialogContent(
        notification: notification,
        category: category,
        onSave: onSave,
      ),
    );
  }
}

class _NotificationDialogContent extends StatefulWidget {
  final NotificationModel? notification;
  final String category;
  final Function(NotificationModel) onSave;

  const _NotificationDialogContent({
    this.notification,
    required this.category,
    required this.onSave,
  });

  @override
  State<_NotificationDialogContent> createState() =>
      _NotificationDialogContentState();
}

class _NotificationDialogContentState
    extends State<_NotificationDialogContent> {
  late TextEditingController nameController;
  late TextEditingController messageController;
  TimeOfDay? selectedTime;
  late List<int> selectedRepeatDays;
  late String repeatMode;
  String? selectedSound;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(
      text: widget.notification?.name ?? '',
    );
    messageController = TextEditingController(
      text: widget.notification?.message ?? '',
    );
    selectedSound = widget.notification?.sound ?? AppConstants.defaultPrayerSound;

    if (widget.notification != null) {
      selectedTime = NotificationService().parseTimeString(widget.notification!.time);
      selectedRepeatDays = List<int>.from(widget.notification!.repeatDays);
      
      if (selectedRepeatDays.length == 7) {
        repeatMode = 'Daily';
      } else if (selectedRepeatDays.length == 5 &&
          selectedRepeatDays.contains(1) &&
          selectedRepeatDays.contains(2) &&
          selectedRepeatDays.contains(3) &&
          selectedRepeatDays.contains(4) &&
          selectedRepeatDays.contains(5)) {
        repeatMode = 'Weekdays';
      } else if (selectedRepeatDays.length == 2 &&
          selectedRepeatDays.contains(6) &&
          selectedRepeatDays.contains(7)) {
        repeatMode = 'Weekends';
      } else {
        repeatMode = 'Custom';
      }
    } else {
      selectedTime = null;
      selectedRepeatDays = [1, 2, 3, 4, 5, 6, 7];
      repeatMode = 'Daily';
    }
  }

  @override
  void dispose() {
    nameController.dispose();
    messageController.dispose();
    super.dispose();
  }

  Future<void> _selectTime() async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00F0FF) : const Color(0xFF0070F3);

    final time = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: theme.copyWith(
            dialogTheme: DialogThemeData(
              backgroundColor: isDark ? const Color(0xFF12131F) : Colors.white,
            ),
            colorScheme: isDark
                ? ColorScheme.dark(
                    primary: primaryColor,
                    onPrimary: Colors.black,
                    surface: const Color(0xFF1A1C2E),
                    onSurface: Colors.white,
                  )
                : ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: Colors.white,
                    onSurface: Colors.black87,
                  ),
            timePickerTheme: TimePickerThemeData(
              backgroundColor: isDark ? const Color(0xFF12131F) : Colors.white,
              hourMinuteColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor.withValues(alpha: isDark ? 0.30 : 0.18);
                }
                return isDark ? const Color(0xFF1F2238) : const Color(0xFFF1F5F9);
              }),
              hourMinuteTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return isDark ? Colors.white : Colors.black87;
              }),
              dayPeriodColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return primaryColor;
                }
                return isDark ? const Color(0xFF1F2238) : const Color(0xFFE2E8F0);
              }),
              dayPeriodTextColor: WidgetStateColor.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return isDark ? Colors.black : Colors.white;
                }
                return isDark ? Colors.white70 : Colors.black87;
              }),
              dayPeriodBorderSide: BorderSide(
                color: primaryColor.withValues(alpha: 0.6),
                width: 1.2,
              ),
              dayPeriodShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              dialBackgroundColor: isDark
                  ? const Color(0xFF1A1C2E)
                  : const Color(0xFFF1F5F9),
              dialHandColor: primaryColor,
              dialTextColor: isDark ? Colors.white : Colors.black87,
              entryModeIconColor: primaryColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (time != null) {
      setState(() => selectedTime = time);
    }
  }

  void _save() {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (nameController.text.isEmpty || selectedTime == null) {
      GlassySnackBar.show(context, langProvider.translate('required_fields'));
      return;
    }

    final repeatDays = widget.category == AppConstants.categoryPrayer
        ? const [1, 2, 3, 4, 5, 6, 7]
        : selectedRepeatDays;

    final notification = NotificationModel(
      id: widget.notification?.id,
      name: nameController.text,
      time:
          '${selectedTime!.hour.toString().padLeft(2, '0')}:${selectedTime!.minute.toString().padLeft(2, '0')}',
      message: messageController.text.isEmpty ? null : messageController.text,
      enabled: widget.notification?.enabled ?? true,
      category: widget.category,
      repeatDays: repeatDays,
      sound: widget.category == AppConstants.categoryPrayer ? selectedSound : null,
    );

    widget.onSave(notification);
    Navigator.of(context).pop();
  }

  Widget _buildRepeatChip(String mode, String label, bool isDark) {
    final isSelected = repeatMode == mode;
    final activeColor = isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            repeatMode = mode;
            if (repeatMode == 'Daily') {
              selectedRepeatDays = [1, 2, 3, 4, 5, 6, 7];
            } else if (repeatMode == 'Weekdays') {
              selectedRepeatDays = [1, 2, 3, 4, 5];
            } else if (repeatMode == 'Weekends') {
              selectedRepeatDays = [6, 7];
            }
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: isSelected
                ? activeColor.withValues(alpha: isDark ? 0.22 : 0.16)
                : (isDark
                    ? Colors.white.withValues(alpha: 0.05)
                    : Colors.black.withValues(alpha: 0.04)),
            border: Border.all(
              color: isSelected
                  ? activeColor
                  : (isDark ? Colors.white24 : Colors.black12),
              width: isSelected ? 1.4 : 1.0,
            ),
          ),
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? activeColor : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;

    return AlertDialog(
      backgroundColor: isDark
          ? const Color(0xFF12131F).withValues(alpha: 0.94)
          : const Color(0xF7FFFFFF),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: BorderSide(
          color: isDark
              ? const Color(0xFF00F0FF).withValues(alpha: 0.4)
              : const Color(0xFF0094FF).withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      title: Text(
        langProvider.translate(widget.notification == null ? 'add_reminder' : 'edit_reminder'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 20,
          letterSpacing: 0.8,
        ),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: nameController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: langProvider.translate('reminder_name'),
                labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: messageController,
              style: TextStyle(color: textColor),
              decoration: InputDecoration(
                labelText: langProvider.translate('message_optional'),
                labelStyle: TextStyle(color: isDark ? Colors.white60 : Colors.black54),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF), width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 20),

            if (widget.category != AppConstants.categoryPrayer) ...[
              Text(
                langProvider.translate('repeat_pattern'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _buildRepeatChip('Daily', langProvider.translate('Daily'), isDark),
                  const SizedBox(width: 6),
                  _buildRepeatChip('Weekdays', langProvider.translate('Weekdays'), isDark),
                  const SizedBox(width: 6),
                  _buildRepeatChip('Weekends', langProvider.translate('Weekends'), isDark),
                  const SizedBox(width: 6),
                  _buildRepeatChip('Custom', langProvider.translate('Custom'), isDark),
                ],
              ),
              if (repeatMode == 'Custom') ...[
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(7, (index) {
                    final weekday = index + 1;
                    final dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                    final dayFullNames = [
                      'Monday',
                      'Tuesday',
                      'Wednesday',
                      'Thursday',
                      'Friday',
                      'Saturday',
                      'Sunday'
                    ];
                    final isSelected = selectedRepeatDays.contains(weekday);

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (isSelected) {
                            if (selectedRepeatDays.length > 1) {
                              selectedRepeatDays.remove(weekday);
                            }
                          } else {
                            selectedRepeatDays.add(weekday);
                            selectedRepeatDays.sort();
                          }
                        });
                      },
                      child: Tooltip(
                        message: dayFullNames[index],
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected
                                ? (isDark
                                    ? const Color(0xFF00F0FF)
                                    : const Color(0xFF0094FF))
                                : (isDark
                                    ? Colors.white.withValues(alpha: 0.08)
                                    : Colors.black.withValues(alpha: 0.06)),
                            border: Border.all(
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0xFF00F0FF)
                                      : const Color(0xFF0094FF))
                                  : (isDark ? Colors.white24 : Colors.black12),
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: (isDark
                                              ? const Color(0xFF00F0FF)
                                              : const Color(0xFF0094FF))
                                          .withValues(alpha: 0.35),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: Text(
                            dayLabels[index],
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isSelected
                                  ? (isDark ? Colors.black : Colors.white)
                                  : textColor,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
              const SizedBox(height: 20),
            ],

            if (widget.category == AppConstants.categoryPrayer) ...[
              Text(
                langProvider.translate('notification_sound'),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF),
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: selectedSound,
                dropdownColor: isDark ? const Color(0xFF12131F) : Colors.white,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? Colors.white24 : Colors.black12),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF), width: 1.5),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                ),
                items: AppConstants.prayerSounds.entries.map((entry) {
                  return DropdownMenuItem<String>(
                    value: entry.value,
                    child: Text(entry.key, style: TextStyle(color: textColor)),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    setState(() => selectedSound = val);
                  }
                },
              ),
              const SizedBox(height: 20),
            ],

            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFF00F0FF).withValues(alpha: 0.22)
                      : const Color(0xFF0070F3),
                  foregroundColor: isDark ? const Color(0xFF00F0FF) : Colors.white,
                  elevation: isDark ? 0 : 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(
                      color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0070F3),
                      width: 1.4,
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                ),
                onPressed: _selectTime,
                icon: const Icon(Icons.access_time_filled, size: 20),
                label: Text(
                  selectedTime == null
                      ? langProvider.translate('select_time')
                      : '${langProvider.translate('time')}: ${selectedTime!.format(context)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            langProvider.translate('cancel'),
            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF),
            foregroundColor: isDark ? Colors.black : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          ),
          onPressed: _save,
          child: Text(
            langProvider.translate(widget.notification == null ? 'add' : 'save'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}
