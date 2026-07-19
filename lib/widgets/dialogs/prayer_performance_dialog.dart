import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/app_constants.dart';
import '../../models/notification_model.dart';
import '../../services/storage_service.dart';
import '../../main.dart';
import 'package:provider/provider.dart';
import '../../providers/language_provider.dart';

class PrayerPerformanceDialog extends StatefulWidget {
  final String prayer;
  final String category;
  static bool isDialogShowing = false;

  const PrayerPerformanceDialog({
    super.key,
    required this.prayer,
    this.category = AppConstants.categoryPrayer,
  });

  @override
  State<PrayerPerformanceDialog> createState() => _PrayerPerformanceDialogState();
}

class _PrayerPerformanceDialogState extends State<PrayerPerformanceDialog>
    with SingleTickerProviderStateMixin {
  int _secondsRemaining = 5;
  Timer? _timer;
  late AnimationController _controller;
  String _reminderMessage = '';

  @override
  void initState() {
    super.initState();
    PrayerPerformanceDialog.isDialogShowing = true;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 5),
    );
    _controller.reverse(from: 1.0);
    _loadReminderMessage();
    _startTimer();
  }

  Future<void> _loadReminderMessage() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final name = widget.prayer;
    final category = widget.category;
    final prefs = await SharedPreferences.getInstance();

    final defaultPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    if (category == AppConstants.categoryPrayer && defaultPrayers.contains(name)) {
      final storedMsg = prefs.getString('${name}_message') ?? 'auto';
      if (storedMsg == 'auto' || storedMsg.isEmpty) {
        final weekday = DateTime.now().weekday;
        final defaultTemplate = "Time to pray $name!";
        final messages = langProvider.getWeeklyMessages(name);
        if (messages.isNotEmpty) {
          final listIndex = weekday == 7 ? 0 : weekday;
          if (listIndex < messages.length) {
            _reminderMessage = messages[listIndex];
          } else {
            _reminderMessage = defaultTemplate;
          }
        } else {
          _reminderMessage = defaultTemplate;
        }
      } else {
        _reminderMessage = storedMsg;
      }
    } else {
      // Load custom reminder from StorageService for any category
      await StorageService.loadNotifications();
      final customList = StorageService.getNotificationsByCategory(category);
      final match = customList.firstWhere(
        (n) => n.name.trim().toLowerCase() == name.trim().toLowerCase(),
        orElse: () => NotificationModel(name: name, time: '', category: category),
      );
      _reminderMessage = match.message ?? 'Time for $name!';
    }

    if (mounted) {
      setState(() {});
    }
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 1) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _timer?.cancel();
        navigatorKey.currentState?.pop();
      }
    });
  }

  @override
  void dispose() {
    PrayerPerformanceDialog.isDialogShowing = false;
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  String _getHeaderTitle(LanguageProvider langProvider) {
    switch (widget.category) {
      case AppConstants.categoryWorkout:
        return langProvider.translate('workout_planner');
      case AppConstants.categoryMeal:
        return langProvider.translate('meal_planner');
      case AppConstants.categoryMedicine:
        return langProvider.translate('medicine_planner');
      case AppConstants.categoryStudy:
        return langProvider.translate('study_planner');
      case AppConstants.categorySleep:
        return langProvider.translate('sleeping_planner');
      case AppConstants.categoryPrayer:
      default:
        return langProvider.translate('perform_prayer');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final primaryColor = AppConstants.getCategoryColor(widget.category, isDark);
    final langProvider = Provider.of<LanguageProvider>(context);

    final defaultPrayers = ['Fajr', 'Dhuhr', 'Asr', 'Maghrib', 'Isha'];
    final displayName = (widget.category == AppConstants.categoryPrayer && defaultPrayers.contains(widget.prayer))
        ? langProvider.translate(widget.prayer)
        : widget.prayer;

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF12131F).withValues(alpha: 0.88)
                  : const Color(0xFFFFFFFF).withValues(alpha: 0.82),
              borderRadius: BorderRadius.circular(32),
              border: Border.all(
                color: primaryColor.withValues(alpha: isDark ? 0.5 : 0.6),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.35 : 0.25),
                  blurRadius: 30,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: IgnorePointer(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(32),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: isDark ? 0.25 : 0.60),
                            Colors.white.withValues(alpha: 0.0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getHeaderTitle(langProvider),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                          fontSize: 16,
                          letterSpacing: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 26,
                          color: textColor,
                          letterSpacing: 0.8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 130,
                        width: 130,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(alpha: 0.15),
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryColor.withValues(alpha: 0.4),
                                    blurRadius: 25,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                            AnimatedBuilder(
                              animation: _controller,
                              builder: (context, child) {
                                return SizedBox(
                                  width: 120,
                                  height: 120,
                                  child: CircularProgressIndicator(
                                    value: _controller.value,
                                    strokeWidth: 7,
                                    backgroundColor: isDark ? Colors.white10 : Colors.black12,
                                    color: primaryColor,
                                  ),
                                );
                              },
                            ),
                            Text(
                              '$_secondsRemaining',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 36,
                                color: primaryColor,
                                fontFamily: 'monospace',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      if (_reminderMessage.isNotEmpty)
                        Text(
                          _reminderMessage,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: isDark ? Colors.white70 : Colors.black87,
                            fontSize: 15,
                            height: 1.5,
                          ),
                        )
                      else
                        SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
