import 'dart:async';

import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:geocoding/geocoding.dart';
import 'package:location/location.dart' as loc;
import 'package:permission_handler/permission_handler.dart' as perm;
//import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import '../models/notification_model.dart';
import '../services/location_prayer_service.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../widgets/common/notification_card.dart';
import '../widgets/common/empty_state.dart';
import '../widgets/dialogs/notification_dialog.dart';
import '../widgets/common/glassy_snack_bar.dart';
import '../core/constants/app_constants.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../services/alarm_rescheduler.dart';
import '../widgets/common/glass_background.dart';
import '../widgets/common/glass_container.dart';
import '../widgets/common/glass_fab.dart';

class PrayerReminderScreen extends StatefulWidget {
  const PrayerReminderScreen({super.key});

  @override
  State<PrayerReminderScreen> createState() => _PrayerReminderScreenState();
}

class _PrayerReminderScreenState extends State<PrayerReminderScreen> {
  List<Map<String, dynamic>> defaultPrayerTimes = [];
  List<NotificationModel> customNotifications = [];
  final NotificationService _notificationService = NotificationService();
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  SharedPreferences? _prefs;
  bool _loading = false;
  //bool _refreshing = false;
  final LocationPrayerService _locService = LocationPrayerService();
  bool _autoLocationEnabled = false;
  bool _autoOpenAppOnRing = false;
  String? _lastUpdated;
  String? _cityName;
  String? _sunriseTime;
  Timer? _countdownTimer;
  Duration? _timeToNextPrayer;
  Prayer? _nextPrayer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _runInitialSetup();
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _runInitialSetup() async {
    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // 1. Load data (fast)
      await _initializePrayerTimes();

      // 2. Show UI immediately
      if (!mounted) return;
      setState(() => _loading = false);

      // 3. Do heavy operations in background (non-blocking)
      _performBackgroundSetup();
    } catch (e) {
      debugPrint('Setup error: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _performBackgroundSetup() async {
    // Create channels first (can be slow)
    await _createPrayerNotificationChannels();
    await Future.delayed(const Duration(milliseconds: 10));
    // Load auto location status
    await _loadAutoLocationStatus();
    await Future.delayed(const Duration(milliseconds: 10));
    // Schedule notifications in background

    if (_autoLocationEnabled) {
      await _loadExistingLocationData();
    }
    _scheduleAllEnabledPrayers();
  }

  Future<void> _loadExistingLocationData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lat = prefs.getDouble(AppConstants.keyLastLatitude);
      final lng = prefs.getDouble(AppConstants.keyLastLongitude);

      if (lat != null && lng != null) {
        // Load city name
        await _loadCityName(lat, lng);

        // Get raw prayer times for countdown
        final prayerTimes = await _locService.getRawPrayerTimesFromLocation();
        if (prayerTimes != null && mounted) {
          _startNextPrayerCountdown(prayerTimes);

          // Load sunrise time
          final formatted = await _locService.calculatePrayerTimes(
            latitude: lat,
            longitude: lng,
          );
          if (formatted != null && mounted) {
            setState(() {
              _sunriseTime = formatted['sunrise'];
            });
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading existing location data: $e');
    }
  }

  Future<void> _createPrayerNotificationChannels() async {
    // Create notification channels for each sound
    for (var soundEntry in AppConstants.prayerSounds.entries) {
      final channelId = 'prayer_${soundEntry.value}';
      final androidChannel = AndroidNotificationChannel(
        channelId,
        'Prayer Reminders - ${soundEntry.key}',
        description:
            'Channel for prayer reminders with ${soundEntry.key} sound',
        importance: Importance.max,
        playSound: true,
        enableVibration: true,
        enableLights: true,
        sound: RawResourceAndroidNotificationSound(soundEntry.value),
      );

      try {
        await _notificationsPlugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.createNotificationChannel(androidChannel);
        debugPrint('✅ Created channel: $channelId');
      } catch (e) {
        debugPrint('Channel creation error for $channelId: $e');
      }
    }
  }

  Future<void> _showPrayerDemoIfNeeded({bool forceShow = false}) async {
    final hasSeenDemo = _prefs?.getBool('has_seen_prayer_demo') ?? false;
    if (!hasSeenDemo || forceShow) {
      if (!mounted) return;
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.deepPurple, size: 28),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  langProvider.translate('guide_title'),
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDemoStep(
                    Icons.location_on,
                    langProvider.translate('guide_step1_title'),
                    langProvider.translate('guide_step1_desc'),
                  ),
                  const SizedBox(height: 12),
                  _buildDemoStep(
                    Icons.toggle_on,
                    langProvider.translate('guide_step2_title'),
                    langProvider.translate('guide_step2_desc'),
                  ),
                  const SizedBox(height: 12),
                  _buildDemoStep(
                    Icons.access_time,
                    langProvider.translate('guide_step3_title'),
                    langProvider.translate('guide_step3_desc'),
                  ),
                  const SizedBox(height: 12),
                  _buildDemoStep(
                    Icons.message,
                    langProvider.translate('guide_step4_title'),
                    langProvider.translate('guide_step4_desc'),
                  ),
                  const SizedBox(height: 12),
                  _buildDemoStepWithAction(
                    Icons.volume_up,
                    langProvider.translate('guide_step5_title'),
                    langProvider.translate('guide_step5_desc'),
                    langProvider.translate('open_settings'),
                    () => NotificationService.openNotificationSettings(),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              onPressed: () async {
                await _prefs?.setBool('has_seen_prayer_demo', true);
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              child: Text(langProvider.translate('got_it')),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildDemoStep(IconData icon, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDemoStepWithAction(
    IconData icon,
    String title,
    String desc,
    String actionLabel,
    VoidCallback onAction,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: Colors.deepPurpleAccent, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                desc,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 6),
              InkWell(
                onTap: onAction,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel,
                      style: const TextStyle(
                        color: Colors.deepPurpleAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.open_in_new,
                      size: 12,
                      color: Colors.deepPurpleAccent,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _initializePrayerTimes() async {
    _prefs = await SharedPreferences.getInstance();

    // Load default prayer times
    defaultPrayerTimes = AppConstants.defaultPrayerTimes.map((prayer) {
      return {
        'name': prayer['name'],
        'time': _prefs?.getString('${prayer['name']}_time') ?? prayer['time'],
        'message':
            _prefs?.getString('${prayer['name']}_message') ?? prayer['message'],
        'enabled':
            _prefs?.getBool('${prayer['name']}_enabled') ?? prayer['enabled'],
        'sound':
            _prefs?.getString('${prayer['name']}_sound') ?? prayer['sound'],
      };
    }).toList();

    _autoOpenAppOnRing = _prefs?.getBool('auto_open_app_on_ring') ?? false;

    // Load custom notifications safely (deduplicated)
    await StorageService.loadNotifications();
    final loadedCustom = StorageService.getNotificationsByCategory(
      AppConstants.categoryPrayer,
    );
    final Map<int, NotificationModel> uniqueMap = {};
    for (var n in loadedCustom) {
      uniqueMap[n.id] = n;
    }
    customNotifications = uniqueMap.values.toList();

    // Show onboarding tutorial if needed
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showPrayerDemoIfNeeded();
    });
  }

  Future<void> _scheduleAllEnabledPrayers() async {
    for (int i = 0; i < defaultPrayerTimes.length; i++) {
      if (defaultPrayerTimes[i]['enabled']) {
        await _scheduleDefaultPrayer(i);
      }
    }

    // schedule custom notifications too (if any)
    for (int j = 0; j < customNotifications.length; j++) {
      if (customNotifications[j].enabled) {
        await _notificationService.toggleNotification(
          customNotifications[j],
          customNotifications[j].id,
        );
      }
    }
  }

  Future<void> _saveDefaultPrayerData() async {
    for (var prayer in defaultPrayerTimes) {
      await _prefs?.setString('${prayer['name']}_time', prayer['time']);
      await _prefs?.setString('${prayer['name']}_message', prayer['message']);
      await _prefs?.setBool('${prayer['name']}_enabled', prayer['enabled']);
      await _prefs?.setString('${prayer['name']}_sound', prayer['sound']);
    }
  }

  Future<void> _saveCustomNotifications() async {
    await StorageService.updateNotificationsByCategory(
      AppConstants.categoryPrayer,
      customNotifications,
    );
  }

  Future<void> _loadAutoLocationStatus() async {
    _autoLocationEnabled = await _locService.isAutoLocationEnabled();
    _lastUpdated = await _locService.getLastUpdatedTime();
    if (mounted) setState(() {});
  }

  Future<void> _handleMenuAction(String action) async {
    if (action == 'enable') {
      await _enableAutoLocation();
    } else if (action == 'disable') {
      await _disableAutoLocation();
    } else if (action == 'toggle_location') {
      if (_autoLocationEnabled) {
        await _disableAutoLocation();
      } else {
        await _enableAutoLocation();
      }
    } else if (action == 'refresh') {
      await _refreshPrayerTimes();
    } else if (action == 'toggle_auto_open') {
      await _toggleAutoOpenAppOnRing();
    } else if (action == 'fix_sound') {
      await NotificationService.openNotificationSettings(AppConstants.channelPrayerId);
    }
  }

  Future<void> _toggleAutoOpenAppOnRing() async {
    _autoOpenAppOnRing = !_autoOpenAppOnRing;
    await _prefs?.setBool('auto_open_app_on_ring', _autoOpenAppOnRing);
    
    if (mounted) {
      setState(() {});
      GlassySnackBar.show(
        context,
        _autoOpenAppOnRing
            ? "Auto Open App on Ring enabled"
            : "Auto Open App on Ring disabled",
      );
    }
    
    // Reschedule default prayer reminders
    await _scheduleAllEnabledPrayers();
    
    // Reschedule all custom notifications
    await StorageService.loadNotifications();
    for (final notification in StorageService.allNotifications) {
      if (notification.enabled) {
        final timeParts = notification.time.split(':');
        final hour = int.parse(timeParts[0]);
        final minute = int.parse(timeParts[1]);
        
        final payload = notification.category == AppConstants.categoryPrayer
            ? 'prayer_${notification.name}'
            : null;

        await _notificationService.scheduleNotification(
          title: notification.name,
          message: notification.message ?? '',
          time: TimeOfDay(hour: hour, minute: minute),
          id: notification.id,
          repeatDays: notification.repeatDays,
          payload: payload,
          sound: notification.sound,
        );
      }
    }
  }

  void _showOpenSettingsSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    GlassySnackBar.show(
      context,
      message,
      actionLabel: "SETTINGS",
      onActionPressed: () {
        perm.openAppSettings();
      },
    );
  }

  Future<bool> _ensureNotificationPermission() async {
    final status = await perm.Permission.notification.status;

    if (status.isGranted) return true;

    if (status.isDenied) {
      final result = await perm.Permission.notification.request();
      return result.isGranted;
    }

    if (status.isPermanentlyDenied || status.isRestricted) {
      if (!mounted) return false;
      _showOpenSettingsSnackBar(
        context,
        "Notification permission permanently denied",
      );
      return false;
    }

    return false;
  }

  Future<void> _onLocationCardTapped() async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    if (!_autoLocationEnabled) {
      await _enableAutoLocation();
    } else {
      GlassySnackBar.show(
        context,
        langProvider.translate('refreshing_location_prayer_times'),
      );
      await _refreshPrayerTimes();
    }
  }

  Future<void> _enableAutoLocation() async {
    final loc.Location location = loc.Location();

    loc.PermissionStatus permission = await location.hasPermission();

    if (permission == loc.PermissionStatus.denied ||
        permission == loc.PermissionStatus.deniedForever) {
      final req = await location.requestPermission();

      if (req == loc.PermissionStatus.denied ||
          req == loc.PermissionStatus.deniedForever) {
        if (!mounted) return;
        _showOpenSettingsSnackBar(context, "Location permission required");
        return;
      }
    }

    // 2️⃣ PERMISSION GRANTED → ENABLE AUTO LOCATION
    await _locService.setAutoLocationEnabled(true);
    if (mounted) {
      setState(() {
        _autoLocationEnabled = true;
      });
    }

    // 3️⃣ FETCH PRAYER TIME FROM LOCATION
    await _refreshPrayerTimes();

    if (mounted) {
      GlassySnackBar.show(context, "Auto-location enabled");
    }
  }

  Future<void> _disableAutoLocation() async {
    await _locService.setAutoLocationEnabled(false);
    _autoLocationEnabled = false;
    _countdownTimer?.cancel();

    if (mounted) {
      setState(() {
        _cityName = null;
        _sunriseTime = null;
        _nextPrayer = null;
        _timeToNextPrayer = null;
      });
      GlassySnackBar.show(context, "Auto-location disabled");
    }
  }

  Future<void> _refreshPrayerTimes() async {
    try {
      if (!_autoLocationEnabled) {
        if (mounted) {
          GlassySnackBar.show(context, "Enable auto-location first.");
        }
        return;
      }

      final rawPrayerTimes = await _locService.getRawPrayerTimesFromLocation();

      if (rawPrayerTimes == null) {
        if (mounted) {
          GlassySnackBar.show(context, "Failed to get prayer times");
        }
        return;
      }

      // ✅ Start countdown with raw PrayerTimes object
      _startNextPrayerCountdown(rawPrayerTimes);

      // final prefs = await SharedPreferences.getInstance();
      // final latitude = prefs.getDouble(AppConstants.keyLastLatitude);
      //final longitude = prefs.getDouble(AppConstants.keyLastLongitude);
      final latitude = rawPrayerTimes.coordinates.latitude;
      final longitude = rawPrayerTimes.coordinates.longitude;

      final formatted = await _locService.calculatePrayerTimes(
        latitude: latitude,
        longitude: longitude,
      );

      if (formatted == null) return;

      if (mounted) {
        setState(() {
          for (final p in defaultPrayerTimes) {
            if (formatted.containsKey(p['name'])) {
              p['time'] = formatted[p['name']];
            }
          }
          _sunriseTime = formatted['sunrise'];
        });
      }

      await _saveDefaultPrayerData();
      await _locService.saveLastUpdatedNow();
      _lastUpdated = await _locService.getLastUpdatedTime();

      await _loadCityName(latitude, longitude);

      await _scheduleAllEnabledPrayers();

      if (mounted) {
        GlassySnackBar.show(context, "Prayer times updated automatically");
      }
    } catch (e) {
      debugPrint("❌ Refresh error: $e");
      if (mounted) {
        GlassySnackBar.show(context, "Something went wrong");
      }
    }
  }

  Future<void> _loadCityName(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        if (mounted) {
          setState(() {
            _cityName = "${place.locality}, ${place.administrativeArea}";
          });
        }
      }
    } catch (e) {
      debugPrint("City lookup failed: $e");
    }
  }

  void _startNextPrayerCountdown(PrayerTimes prayerTimes) {
    _countdownTimer?.cancel();

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        _countdownTimer?.cancel();
        return;
      }

      try {
        final nowUtc = DateTime.now().toUtc();
        var next = prayerTimes.nextPrayer();
        var nextTime = prayerTimes.timeForPrayer(next);

        if (next == Prayer.fajrAfter) {
          // If past Isha, next prayer is Fajr tomorrow
          final tomorrow = DateTime.now().add(const Duration(days: 1));
          final tomorrowPrayerTimes = PrayerTimes(
            coordinates: prayerTimes.coordinates,
            date: tomorrow,
            calculationParameters: prayerTimes.calculationParameters,
            precision: true,
          );
          nextTime = tomorrowPrayerTimes.fajr;
        }

        final nextTimeUtc = nextTime.toUtc();
        final difference = nextTimeUtc.difference(nowUtc);

        if (mounted) {
          setState(() {
            _nextPrayer = next;
            _timeToNextPrayer = difference;
          });
        }
      } catch (e) {
        debugPrint("Error in prayer countdown timer: $e");
      }
    });
  }

  String _prayerToString(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
      case Prayer.fajrAfter:
        return "Fajr";
      case Prayer.sunrise:
        return "Sunrise";
      case Prayer.dhuhr:
        return "Dhuhr";
      case Prayer.asr:
        return "Asr";
      case Prayer.maghrib:
        return "Maghrib";
      case Prayer.isha:
      case Prayer.ishaBefore:
        return "Isha";
    }
  }

  DateTime _nextInstanceOfWeekdayAndTime(int weekday, TimeOfDay time) {
    final now = DateTime.now();
    DateTime scheduledTime = DateTime(
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    while (scheduledTime.weekday != weekday) {
      scheduledTime = scheduledTime.add(const Duration(days: 1));
    }

    if (scheduledTime.isBefore(now)) {
      scheduledTime = scheduledTime.add(const Duration(days: 7));
    }

    return scheduledTime;
  }

  String _getPrayerMessageForWeekday(
    String prayerName,
    int weekday,
    String currentMessage,
  ) {
    final defaultTemplate = "Time to pray $prayerName!";
    if (currentMessage == defaultTemplate ||
        currentMessage.isEmpty ||
        currentMessage == 'auto') {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final messages = langProvider.getWeeklyMessages(prayerName);
      if (messages.isNotEmpty) {
        final listIndex = weekday == 7 ? 0 : weekday;
        if (listIndex < messages.length) {
          return messages[listIndex];
        }
      }
    }
    return currentMessage;
  }

  int _getPrayerBaseId(String name) {
    switch (name) {
      case 'Fajr':
        return 1;
      case 'Dhuhr':
        return 2;
      case 'Asr':
        return 3;
      case 'Maghrib':
        return 4;
      case 'Isha':
        return 5;
      default:
        return (name.hashCode).abs() % 100000;
    }
  }

  Future<void> _scheduleDefaultPrayer(int index) async {
    try {
      final langProvider = Provider.of<LanguageProvider>(context, listen: false);
      final prayer = defaultPrayerTimes[index];
      final baseId = _getPrayerBaseId(prayer['name']);
      final time = _notificationService.parseTimeString(prayer['time']);
      final soundFile = prayer['sound'] ?? AppConstants.defaultPrayerSound;
      final channelId = 'prayer_$soundFile';

      // Cancel any existing weekly/daily alarms for this prayer
      await _notificationService.cancelNotification(baseId);

      // Translate name
      final translatedName = langProvider.translate(prayer['name']);

      // Schedule weekly notifications for all 7 days of the week
      for (int weekday = 1; weekday <= 7; weekday++) {
        final uniqueId = baseId * 10 + weekday;
        final nextInstance = _nextInstanceOfWeekdayAndTime(weekday, time);
        final message = _getPrayerMessageForWeekday(
          prayer['name'],
          weekday,
          prayer['message'],
        );

        await _notificationsPlugin.zonedSchedule(
          uniqueId,
          translatedName,
          message,
          tz.TZDateTime.from(nextInstance, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              channelId,
              'Prayer Reminders',
              sound: RawResourceAndroidNotificationSound(soundFile),
              playSound: true,
              importance: Importance.max,
              priority: Priority.max,
              enableVibration: true,
              enableLights: true,
              audioAttributesUsage: AudioAttributesUsage.notification,
              fullScreenIntent: _autoOpenAppOnRing,
              category: AndroidNotificationCategory.alarm,
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exact,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
          payload: 'prayer_${prayer['name']}',
        );
      }
      debugPrint('✅ Weekly prayer alarms scheduled for ${prayer['name']}');
    } catch (e) {
      debugPrint('Error scheduling prayer $index: $e');
    }
  }

  void _toggleDefaultPrayer(int index) async {
    final currentlyEnabled = defaultPrayerTimes[index]['enabled'] as bool;

    // If user is turning ON → check permission
    if (!currentlyEnabled) {
      final allowed = await _ensureNotificationPermission();

      if (!allowed) {
        // ❌ Permission not granted → DO NOT TOGGLE
        return;
      }
    }
    setState(() {
      defaultPrayerTimes[index]['enabled'] =
          !defaultPrayerTimes[index]['enabled'];
    });

    await _saveDefaultPrayerData();
    if (!currentlyEnabled) {
      if (defaultPrayerTimes[index]['enabled']) {
        _scheduleDefaultPrayer(index);
      } else {
        await _notificationService.cancelNotification(
          _getPrayerBaseId(defaultPrayerTimes[index]['name']),
        );
      }
    } else {
      await _notificationService.cancelNotification(
        _getPrayerBaseId(defaultPrayerTimes[index]['name']),
      );
    }
  }

  void _editDefaultPrayerTime(int index) async {
    final currentTime = _notificationService.parseTimeString(
      defaultPrayerTimes[index]['time'],
    );

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xFF00FF87) : const Color(0xFF047857);

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: currentTime,
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

    if (pickedTime != null) {
      setState(() {
        final period = pickedTime.period == DayPeriod.am ? 'AM' : 'PM';
        defaultPrayerTimes[index]['time'] =
            '${pickedTime.hourOfPeriod}:${pickedTime.minute.toString().padLeft(2, '0')} $period';
      });

      await _saveDefaultPrayerData();

      if (defaultPrayerTimes[index]['enabled']) {
        _scheduleDefaultPrayer(index);
      }
      if (_autoLocationEnabled && mounted) {
        GlassySnackBar.show(
          context,
          "Manual time saved. Auto-location will override this on next refresh.",
        );
      }
    }
  }

  void _editDefaultPrayerMessage(int index) async {
    final langProvider = Provider.of<LanguageProvider>(context, listen: false);
    final currentMessage = defaultPrayerTimes[index]['message'];
    final prayerName = defaultPrayerTimes[index]['name'];
    bool isAuto =
        currentMessage == 'auto' ||
        currentMessage == 'Time to pray $prayerName!';

    final controller = TextEditingController(
      text: isAuto ? 'Time to pray $prayerName!' : currentMessage,
    );

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(langProvider.translate('edit_reminder')),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              RadioGroup<bool>(
                groupValue: isAuto,
                onChanged: (bool? value) {
                  if (value != null) {
                    setDialogState(() {
                      isAuto = value;
                    });
                  }
                },
                child: Column(
                  children: [
                    RadioListTile<bool>(
                      value: true,
                      title: Text(langProvider.translate('auto_message')),
                    ),
                    RadioListTile<bool>(
                      value: false,
                      title: Text(langProvider.translate('custom_message')),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: controller,
                enabled: !isAuto,
                decoration: InputDecoration(
                  labelText: langProvider.translate('custom_message'),
                  filled: isAuto,
                  fillColor: isAuto
                      ? Theme.of(context).disabledColor.withAlpha(30)
                      : null,
                  border: const OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(langProvider.translate('cancel')),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  defaultPrayerTimes[index]['message'] = isAuto
                      ? 'auto'
                      : controller.text;
                });
                _saveDefaultPrayerData();
                Navigator.pop(context);

                if (defaultPrayerTimes[index]['enabled']) {
                  _scheduleDefaultPrayer(index);
                }
              },
              child: Text(langProvider.translate('save')),
            ),
          ],
        ),
      ),
    );
  }

  void _selectPrayerSound(int index) async {
    final currentSound =
        defaultPrayerTimes[index]['sound'] ?? AppConstants.defaultPrayerSound;

    //String? selectedSound = currentSound;

    await showDialog(
      context: context,
      builder: (context) => _SoundSelectionDialog(
        currentSound: currentSound,
        onSoundSelected: (selectedSound) async {
          if (selectedSound != currentSound) {
            setState(() {
              defaultPrayerTimes[index]['sound'] = selectedSound;
            });
            await _saveDefaultPrayerData();

            if (defaultPrayerTimes[index]['enabled']) {
              await _notificationService.cancelNotification(
                _getPrayerBaseId(defaultPrayerTimes[index]['name']),
              );
              _scheduleDefaultPrayer(index);
            }

            if (context.mounted) {
              GlassySnackBar.show(
                context,
                'Sound changed to ${AppConstants.prayerSounds.entries.firstWhere((e) => e.value == selectedSound).key}',
              );
            }
          }
        },
      ),
    );
  }

  void _toggleCustomNotification(int index) async {
    setState(() {
      customNotifications[index] = customNotifications[index].copyWith(
        enabled: !customNotifications[index].enabled,
      );
    });

    await _notificationService.toggleNotification(
      customNotifications[index],
      customNotifications[index].id,
    );
    await _saveCustomNotifications();
  }

  void _deleteCustomNotification(int index) async {
    final notificationToDelete = customNotifications[index];
    setState(() {
      customNotifications.removeAt(index);
    });

    await _notificationService.cancelNotification(notificationToDelete.id);
    await _saveCustomNotifications();

    if (mounted) {
      GlassySnackBar.show(context, AppConstants.reminderDeleted);
    }
  }

  void _addOrEditCustomNotification({
    NotificationModel? notification,
    int? index,
  }) {
    NotificationDialog.show(
      context: context,
      notification: notification,
      category: AppConstants.categoryPrayer,
      onSave: (updatedNotification) async {
        setState(() {
          if (index != null) {
            customNotifications[index] = updatedNotification;
          } else {
            final existingIndex = customNotifications.indexWhere((n) => n.id == updatedNotification.id);
            if (existingIndex >= 0) {
              customNotifications[existingIndex] = updatedNotification;
            } else {
              customNotifications.add(updatedNotification);
            }
          }
        });

        await _saveCustomNotifications();
        await _notificationService.toggleNotification(
          updatedNotification,
          updatedNotification.id,
        );
      },
    );
  }

  String _getSoundDisplayName(String soundKey) {
    return AppConstants.prayerSounds.entries
        .firstWhere(
          (entry) => entry.value == soundKey,
          orElse: () => const MapEntry('Default', 'allahu_akbar'),
        )
        .key;
  }

  @override
  Widget build(BuildContext context) {
    final allReminders = [...defaultPrayerTimes, ...customNotifications];
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.colorScheme.onSurface;
    final langProvider = Provider.of<LanguageProvider>(context);

    final accentGreen = isDark ? const Color(0xFF00FF87) : const Color(0xFF047857);

    return GlassBackground(
      child: Stack(
        children: [
          Scaffold(
            backgroundColor: Colors.transparent,
            appBar: AppBar(
              title: Text(
                langProvider.translate('prayer_planner'),
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: textColor),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              actions: [
                PopupMenuButton<String>(
                  icon: Icon(Icons.language, color: textColor),
                  tooltip: langProvider.translate('select_language'),
                  color: isDark ? const Color(0xFF12131F).withValues(alpha: 0.94) : const Color(0xF7FFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: accentGreen.withValues(alpha: 0.3)),
                  ),
                  onSelected: (langCode) async {
                    await langProvider.changeLanguage(langCode);
                    if (context.mounted) {
                      await AlarmRescheduler.rescheduleAll(context);
                      await _showPrayerDemoIfNeeded(forceShow: true);
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(value: 'en', child: Text('English', style: TextStyle(color: textColor))),
                    PopupMenuItem(value: 'ta', child: Text('தமிழ் (Tamil)', style: TextStyle(color: textColor))),
                    PopupMenuItem(value: 'ur', child: Text('اردو (Urdu)', style: TextStyle(color: textColor))),
                  ],
                ),
                PopupMenuButton<String>(
                  color: isDark ? const Color(0xFF12131F).withValues(alpha: 0.94) : const Color(0xF7FFFFFF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: BorderSide(color: accentGreen.withValues(alpha: 0.3)),
                  ),
                  onSelected: _handleMenuAction,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'toggle_location',
                      child: Row(
                        children: [
                          Icon(
                            _autoLocationEnabled
                                ? Icons.location_on
                                : Icons.location_off,
                            color: _autoLocationEnabled
                                ? accentGreen
                                : textColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              langProvider.translate('enable_auto_location'),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            _autoLocationEnabled
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: accentGreen,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'refresh',
                      enabled: _autoLocationEnabled,
                      child: Row(
                        children: [
                          Icon(
                            Icons.refresh,
                            color: _autoLocationEnabled
                                ? accentGreen
                                : textColor.withValues(alpha: 0.3),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            langProvider.translate('refresh_prayer_times'),
                            style: TextStyle(
                              color: _autoLocationEnabled
                                  ? textColor
                                  : textColor.withValues(alpha: 0.3),
                            ),
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'toggle_auto_open',
                      child: Row(
                        children: [
                          Icon(
                            _autoOpenAppOnRing
                                ? Icons.alarm_on
                                : Icons.alarm_off,
                            color: _autoOpenAppOnRing
                                ? accentGreen
                                : textColor.withValues(alpha: 0.5),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              langProvider.translate('auto_open_on_ring'),
                              style: TextStyle(color: textColor),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Icon(
                            _autoOpenAppOnRing
                                ? Icons.check_box
                                : Icons.check_box_outline_blank,
                            color: accentGreen,
                          ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'fix_sound',
                      child: Row(
                        children: [
                          Icon(
                            Icons.volume_up,
                            color: accentGreen,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            langProvider.translate('fix_sound'),
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            body: allReminders.isEmpty
                ? EmptyState(
                    message: langProvider.translate('no_reminders_yet'),
                    icon: Icons.access_time_filled_rounded,
                    themeColor: accentGreen,
                  )
                : Column(
                    children: [
                      GlassContainer(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        borderRadius: BorderRadius.circular(32),
                        blur: 38,
                        opacity: isDark ? 0.08 : 0.65,
                        borderColor: accentGreen.withValues(alpha: isDark ? 0.45 : 0.60),
                        padding: const EdgeInsets.all(18),
                        onTap: _onLocationCardTapped,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: accentGreen.withValues(alpha: isDark ? 0.16 : 0.14),
                                border: Border.all(color: accentGreen, width: 1.4),
                                boxShadow: [
                                  BoxShadow(
                                    color: accentGreen.withValues(alpha: isDark ? 0.35 : 0.20),
                                    blurRadius: 15,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _autoLocationEnabled ? Icons.location_on_rounded : Icons.location_off_rounded,
                                color: accentGreen,
                                size: 26,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _cityName ?? langProvider.translate('prayer_location_heading'),
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: textColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    _cityName != null
                                        ? "${langProvider.translate('updated')}: ${_lastUpdated ?? langProvider.translate('not_updated_yet')}"
                                        : langProvider.translate('tap_to_enable_location'),
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: isDark ? Colors.white60 : Colors.black54,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (_sunriseTime != null) ...[
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(
                                          Icons.wb_sunny_rounded,
                                          size: 15,
                                          color: Color(0xFFFFB800),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "${langProvider.translate('sunrise')}: $_sunriseTime",
                                          style: const TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: Color(0xFFFFB800),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                  if (_nextPrayer != null && _timeToNextPrayer != null) ...[
                                    const SizedBox(height: 12),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(color: accentGreen.withValues(alpha: 0.35)),
                                      ),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "🕌 ${langProvider.translate('next_prayer')}",
                                                style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                langProvider.translate(_prayerToString(_nextPrayer!)),
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: accentGreen,
                                                ),
                                              ),
                                            ],
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                            decoration: BoxDecoration(
                                              color: accentGreen.withValues(alpha: isDark ? 0.16 : 0.14),
                                              borderRadius: BorderRadius.circular(14),
                                              border: Border.all(color: accentGreen, width: 1.2),
                                            ),
                                            child: Text(
                                              "${_timeToNextPrayer!.inHours.toString().padLeft(2, '0')}:"
                                              "${(_timeToNextPrayer!.inMinutes % 60).toString().padLeft(2, '0')}:"
                                              "${(_timeToNextPrayer!.inSeconds % 60).toString().padLeft(2, '0')}",
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.bold,
                                                color: accentGreen,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                            ],
                          ),
                        ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: allReminders.length,
                          padding: const EdgeInsets.only(
                            left: 16.0,
                            right: 16.0,
                            top: 8.0,
                            bottom: 90.0,
                          ),
                          physics: const BouncingScrollPhysics(),
                          itemBuilder: (context, index) {
                            final isDefaultPrayer = index < defaultPrayerTimes.length;

                            if (isDefaultPrayer) {
                              final prayer = defaultPrayerTimes[index];
                              final soundName = _getSoundDisplayName(
                                prayer['sound'] ?? AppConstants.defaultPrayerSound,
                              );
                              final bool isEnabled = prayer['enabled'] ?? false;
                              final bool isActiveNext = _nextPrayer != null && _prayerToString(_nextPrayer!) == prayer['name'];

                              return GestureDetector(
                                onLongPress: () => _editDefaultPrayerMessage(index),
                                child: GlassContainer(
                                  margin: const EdgeInsets.only(bottom: 14),
                                  borderRadius: BorderRadius.circular(32),
                                  blur: 38,
                                  opacity: isEnabled ? (isDark ? 0.08 : 0.68) : (isDark ? 0.04 : 0.40),
                                  borderColor: isActiveNext
                                      ? accentGreen
                                      : (isEnabled
                                          ? accentGreen.withValues(alpha: isDark ? 0.45 : 0.60)
                                          : (isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08))),
                                  enableGlow: isActiveNext,
                                  glowColor: accentGreen,
                                  onTap: () => _editDefaultPrayerTime(index),
                                  padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 44,
                                            height: 44,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isEnabled ? accentGreen.withValues(alpha: isDark ? 0.15 : 0.14) : (isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.03)),
                                              border: Border.all(
                                                color: isEnabled ? accentGreen.withValues(alpha: isDark ? 0.7 : 0.8) : (isDark ? Colors.white24 : Colors.black12),
                                                width: 1.2,
                                              ),
                                            ),
                                            child: Icon(
                                              isEnabled ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
                                              color: isEnabled ? accentGreen : (isDark ? Colors.white38 : Colors.black38),
                                              size: 20,
                                            ),
                                          ),
                                          const SizedBox(width: 14),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  langProvider.translate(prayer['name']),
                                                  style: TextStyle(
                                                    fontSize: 17,
                                                    fontWeight: FontWeight.bold,
                                                    color: isEnabled ? textColor : textColor.withValues(alpha: 0.5),
                                                  ),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  "Time: ${prayer['time']}",
                                                  style: TextStyle(
                                                    fontSize: 13,
                                                    fontWeight: FontWeight.w600,
                                                    color: accentGreen,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05),
                                                border: Border.all(color: isDark ? Colors.white24 : Colors.black12),
                                              ),
                                              child: Icon(Icons.music_note_rounded, size: 18, color: accentGreen),
                                            ),
                                            tooltip: 'Change sound',
                                            onPressed: () => _selectPrayerSound(index),
                                          ),
                                          Switch(
                                            value: isEnabled,
                                            onChanged: (_) => _toggleDefaultPrayer(index),
                                            activeThumbColor: accentGreen,
                                            activeTrackColor: accentGreen.withValues(alpha: isDark ? 0.3 : 0.25),
                                            inactiveThumbColor: isDark ? Colors.white38 : Colors.black26,
                                            inactiveTrackColor: isDark ? Colors.white10 : Colors.black12,
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          Icon(Icons.speaker_notes_outlined, size: 12, color: isDark ? Colors.white54 : Colors.black45),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              prayer['message'] == 'auto'
                                                  ? 'Auto Weekly Azan Reminder'
                                                  : prayer['message'],
                                              style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : Colors.black54),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            soundName,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF),
                                              fontStyle: FontStyle.italic,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            } else {
                              final customIndex = index - defaultPrayerTimes.length;
                              final notification = customNotifications[customIndex];

                              return NotificationCard(
                                notification: notification,
                                themeColor: accentGreen,
                                enabled: notification.enabled,
                                onToggle: () => _toggleCustomNotification(customIndex),
                                onTap: () => _addOrEditCustomNotification(
                                  notification: notification,
                                  index: customIndex,
                                ),
                                onDelete: () => _deleteCustomNotification(customIndex),
                              );
                            }
                          },
                      ),
                    ),
                  ],
                ),
          floatingActionButton: GlassFab(
            onPressed: () => _addOrEditCustomNotification(),
            color: accentGreen,
            icon: Icons.add_rounded,
            size: 60,
          ),
        ),
        if (_loading)
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(color: accentGreen),
              ),
            ),
          ),
      ],
    ),
  );
}
}

class _SoundSelectionDialog extends StatefulWidget {
  final String currentSound;
  final Function(String) onSoundSelected;

  const _SoundSelectionDialog({
    required this.currentSound,
    required this.onSoundSelected,
  });

  @override
  State<_SoundSelectionDialog> createState() => _SoundSelectionDialogState();
}

class _SoundSelectionDialogState extends State<_SoundSelectionDialog> {
  late String selectedSound;
  final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  String? currentlyPlaying;
  Timer? _previewTimer;
  // Simulated sound durations (in seconds) - replace with actual durations
  final Map<String, int> soundDurations = {
    'allahu_akbar': 9,
    'adhan': 172,
    'mansur_al_zahrane_adhan': 184,
    'mishary_rashid_alafasy_adhan': 187,
    'nasser_al_qatami_adhan': 132,
    'badee_jadu_adhan': 206,
  };

  @override
  void initState() {
    super.initState();
    selectedSound = widget.currentSound;
  }

  Future<void> _previewSound(String soundFile) async {
    await _stopPreview();
    setState(() {
      currentlyPlaying = soundFile;
    });

    // Show notification with sound for preview
    await _notificationsPlugin.show(
      99999, // Temporary ID for preview
      'Sound Preview',
      'Playing ${AppConstants.prayerSounds.entries.firstWhere((e) => e.value == soundFile).key}',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'prayer_$soundFile',
          'Prayer Sound Preview',
          sound: RawResourceAndroidNotificationSound(soundFile),
          playSound: true,
          importance: Importance.high,
          priority: Priority.high,
          autoCancel: true,
          //timeoutAfter: 10000, // Auto dismiss after 3 seconds
        ),
      ),
    );

    int durationSeconds = soundDurations[soundFile] ?? 5;
    // Simulate playing duration
    _previewTimer = Timer(Duration(seconds: durationSeconds), () async {
      await _stopPreview();
    });
  }

  Future<void> _stopPreview() async {
    // Cancel timer if active
    _previewTimer?.cancel();
    _previewTimer = null;

    // Remove notification sound
    await _notificationsPlugin.cancel(99999);

    if (mounted) {
      setState(() {
        currentlyPlaying = null;
      });
    }
  }

  String _formatDuration(int seconds) {
    if (seconds < 60) {
      return '${seconds}s';
    }
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return remainingSeconds > 0
        ? '${minutes}m ${remainingSeconds}s'
        : '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final langProvider = Provider.of<LanguageProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Theme-aware colors
    final dialogBg = isDark ? const Color(0xFF0D1117) : Colors.white;
    final cardSelectedBg = isDark
        ? const Color(0xFF1C2733)
        : Colors.green.shade50;
    final cardUnselectedBg = isDark
        ? const Color(0xFF151B22)
        : Colors.grey.shade100;
    final textColor = isDark ? Colors.white : Colors.black87;
    final radioInactiveColor = isDark
        ? Colors.grey.shade500
        : Colors.grey.shade600;
    final durationBadgeBg = isDark
        ? const Color(0xFF243447)
        : Colors.blue.shade50;
    final durationBadgeBorder = isDark
        ? Colors.blueAccent.shade700
        : Colors.blue.shade200;
    final durationTextColor = isDark ? Colors.blueAccent : Colors.blue.shade800;
    final cancelTextColor = isDark
        ? Colors.grey.shade400
        : Colors.grey.shade700;

    return AlertDialog(
      backgroundColor: dialogBg,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(
        langProvider.translate('select_sound'),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: textColor,
          fontSize: 20,
        ),
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ListView.builder(
          shrinkWrap: true,
          itemCount: AppConstants.prayerSounds.length,
          itemBuilder: (context, index) {
            final entry = AppConstants.prayerSounds.entries.elementAt(index);
            final soundName = entry.key;
            final soundFile = entry.value;
            final duration = soundDurations[soundFile] ?? 0;
            final isSelected = selectedSound == soundFile;
            final isPlaying = currentlyPlaying == soundFile;

            return InkWell(
              onTap: () {
                setState(() {
                  selectedSound = soundFile;
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                color: isSelected ? cardSelectedBg : cardUnselectedBg,
                elevation: isSelected ? 5 : 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 5,
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 2),
                      // Custom Radio Button
                      Container(
                        width: 26,
                        height: 26,
                        margin: const EdgeInsets.only(right: 14),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isSelected
                                ? Colors.green
                                : radioInactiveColor,
                            width: 2,
                          ),
                          color: isSelected ? Colors.green : Colors.transparent,
                        ),
                        child: isSelected
                            ? Icon(
                                Icons.check,
                                size: 16,
                                color: isDark ? Colors.black : Colors.white,
                              )
                            : null,
                      ),

                      // Sound Name
                      Expanded(
                        child: Text(
                          soundName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                      ),

                      // Duration badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: durationBadgeBg,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: durationBadgeBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          _formatDuration(duration),
                          style: TextStyle(
                            fontSize: 10,
                            color: durationTextColor,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),

                      // Play / Stop Button
                      IconButton(
                        icon: Icon(
                          isPlaying
                              ? Icons.stop_circle_rounded
                              : Icons.play_circle_fill_rounded,
                          color: isPlaying ? Colors.red : Colors.green,
                          size: 32,
                        ),
                        onPressed: isPlaying
                            ? _stopPreview
                            : () => _previewSound(soundFile),
                        tooltip: isPlaying ? 'Stop' : 'Preview',
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // ACTION BUTTONS
      actions: [
        TextButton(
          onPressed: () {
            _stopPreview();
            Navigator.pop(context);
          },
          style: TextButton.styleFrom(foregroundColor: cancelTextColor),
          child: Text(langProvider.translate('cancel')),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            _stopPreview();
            widget.onSoundSelected(selectedSound);
            Navigator.pop(context);
          },
          child: Text(
            langProvider.translate('save'),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    // Cancel any playing preview notification when dialog closes
    _previewTimer?.cancel();
    _notificationsPlugin.cancel(99999);
    super.dispose();
  }
}
