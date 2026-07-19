import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'core/constants/app_constants.dart';
import 'screens/main_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/language_provider.dart';

import 'services/notification_service.dart';
import 'widgets/dialogs/prayer_performance_dialog.dart';

final FlutterLocalNotificationsPlugin notificationsPlugin =
    FlutterLocalNotificationsPlugin();

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
bool _hasProcessedLaunchNotification = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  tz.initializeTimeZones();
  await _initializeNotifications();
  await _requestPermissions();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => ThemeProvider()),
        ChangeNotifierProvider(create: (context) => LanguageProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

Future<void> _initializeNotifications() async {
  await NotificationService().init();

  const AndroidInitializationSettings androidInitialization =
      AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings settings = InitializationSettings(
    android: androidInitialization,
  );

  await notificationsPlugin.initialize(
    settings,
    onDidReceiveNotificationResponse: (NotificationResponse response) {
      final payload = response.payload;
      if (payload != null && payload.isNotEmpty) {
        _handleNotificationClick(payload);
      }
    },
  );

  if (!_hasProcessedLaunchNotification) {
    final details = await notificationsPlugin.getNotificationAppLaunchDetails();
    if (details != null && details.didNotificationLaunchApp) {
      _hasProcessedLaunchNotification = true;
      final payload = details.notificationResponse?.payload;
      if (payload != null && payload.isNotEmpty) {
        _handleNotificationClick(payload);
      }
    }
  }
}

void _handleNotificationClick(String payload) {
  if (PrayerPerformanceDialog.isDialogShowing) return;

  String category = AppConstants.categoryPrayer;
  String reminderName = payload;

  if (payload.contains(':')) {
    final parts = payload.split(':');
    category = parts[0];
    reminderName = parts.sublist(1).join(':');
  } else if (payload.startsWith('prayer_')) {
    category = AppConstants.categoryPrayer;
    reminderName = payload.substring('prayer_'.length);
  }

  void triggerDialog() {
    if (PrayerPerformanceDialog.isDialogShowing) return;
    final context = navigatorKey.currentContext;
    if (context != null) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PrayerPerformanceDialog(
          prayer: reminderName,
          category: category,
        ),
      );
    } else {
      Future.delayed(const Duration(milliseconds: 500), triggerDialog);
    }
  }

  triggerDialog();
}

Future<void> _requestPermissions() async {
  if (await Permission.notification.isDenied) {
    await Permission.notification.request();
  }

  final iosPlugin = notificationsPlugin
      .resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin
      >();

  if (iosPlugin != null) {
    await iosPlugin.requestPermissions(alert: true, badge: true, sound: true);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Reminder App',
      theme: themeProvider.lightTheme,
      darkTheme: themeProvider.darkTheme,
      themeMode: themeProvider.themeMode,
      home: const MainScreen(),
    );
  }
}
