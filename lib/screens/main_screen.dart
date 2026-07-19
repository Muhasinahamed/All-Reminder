import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/app_constants.dart';
import '../widgets/common/custom_button.dart';
import '../widgets/common/glass_background.dart';
import 'base_reminder_screen.dart';
import 'prayer_reminder_screen.dart';
import 'about_screen.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../providers/theme_provider.dart';
import '../services/alarm_rescheduler.dart';
import 'dart:io';
import 'dart:convert';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _checkBatteryOptimizations();
      if (!mounted) return;
      await _checkForUpdates();
    });
  }

  Future<void> _checkBatteryOptimizations() async {
    final isIgnored = await Permission.ignoreBatteryOptimizations.isGranted;
    if (!isIgnored) {
      if (!mounted) return;
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;
      final textColor = theme.colorScheme.onSurface;
      final accentColor = isDark ? const Color(0xFF00F0FF) : const Color(0xFF0094FF);

      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF12131F).withValues(alpha: 0.88)
                      : const Color(0xFFFFFFFF).withValues(alpha: 0.86),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: accentColor.withValues(alpha: isDark ? 0.4 : 0.5),
                    width: 1.4,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.battery_alert, color: Color(0xFFFFB800), size: 28),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Battery Settings Required',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'To ensure prayer and workout alerts sound on time, you must change the battery usage setting for this app to "No Restriction" or "Unrestricted".',
                      style: TextStyle(fontSize: 14, color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 15),
                    Text(
                      'Instructions:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: accentColor,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '1. Tap "Go to Settings" below.',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    Text(
                      '2. Select "No restrictions" (on MIUI/Xiaomi, under Battery saver) or "Unrestricted".',
                      style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text(
                            'Later',
                            style: TextStyle(color: isDark ? Colors.white54 : Colors.black45),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: accentColor,
                            foregroundColor: isDark ? Colors.black : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: () async {
                            Navigator.of(context).pop();
                            try {
                              const channel = MethodChannel('in.inhomex.all_reminder/settings');
                              await channel.invokeMethod('openBatteryOptimizationSettings');
                            } catch (e) {
                              await Permission.ignoreBatteryOptimizations.request();
                            }
                          },
                          child: const Text(
                            'Go to Settings',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> _checkForUpdates() async {
    try {
      final client = HttpClient();
      client.connectionTimeout = const Duration(seconds: 15);
      final cacheBustUrl =
          "${AppConstants.updateConfigUrl}?t=${DateTime.now().millisecondsSinceEpoch}";
      final request = await client.getUrl(Uri.parse(cacheBustUrl));
      final response = await request.close();

      if (response.statusCode == HttpStatus.ok) {
        final contents = await response.transform(utf8.decoder).join();
        final jsonMap = jsonDecode(contents) as Map<String, dynamic>;

        final latestVersion = jsonMap['latest_version'] as String?;
        final releaseNotes =
            jsonMap['release_notes'] as String? ??
            'Bug fixes and performance improvements.';
        final downloadUrl =
            jsonMap['download_url'] as String? ??
            'https://play.google.com/store/apps/details?id=in.inhomex.all_reminder';

        if (latestVersion != null) {
          final packageInfo = await PackageInfo.fromPlatform();
          final currentVersion = packageInfo.version;

          if (_isVersionLower(currentVersion, latestVersion)) {
            if (mounted) {
              _showUpdateDialog(latestVersion, releaseNotes, downloadUrl);
            }
          }
        }
      }
    } catch (e) {
      debugPrint("Update check error: $e");
    }
  }

  bool _isVersionLower(String current, String latest) {
    try {
      final cParts = current
          .split('.')
          .map((e) => int.parse(e.replaceAll(RegExp(r'[^0-9]'), '')))
          .toList();
      final lParts = latest
          .split('.')
          .map((e) => int.parse(e.replaceAll(RegExp(r'[^0-9]'), '')))
          .toList();

      for (int i = 0; i < lParts.length; i++) {
        final c = i < cParts.length ? cParts[i] : 0;
        final l = lParts[i];
        if (c < l) return true;
        if (c > l) return false;
      }
      return false;
    } catch (_) {
      return current.compareTo(latest) < 0;
    }
  }

  void _showUpdateDialog(String version, String notes, String downloadUrl) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF12131F).withValues(alpha: 0.9),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(28),
          side: BorderSide(
            color: const Color(0xFF00F0FF).withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        title: Row(
          children: [
            const Icon(Icons.system_update, color: Color(0xFF00F0FF), size: 28),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'New Update Available (v$version)',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "A new version of the app is available. Please update to get the latest features and fixes.",
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 12),
              const Text(
                "What's New:",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF00F0FF),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                notes,
                style: const TextStyle(color: Colors.white60, fontSize: 13),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Later', style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00F0FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: () async {
              final uri = Uri.parse(downloadUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              }
            },
            child: const Text(
              'Update Now',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _navigateToCategory(
    BuildContext context,
    String title,
    String category,
    Color color,
  ) {
    if (category == AppConstants.categoryPrayer) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const PrayerReminderScreen()),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BaseReminderScreen(
            title: title,
            category: category,
            themeColor: color,
          ),
        ),
      );
    }
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
            langProvider.translate('app_title'),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: theme.colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFFFFB800).withValues(alpha: 0.4)
                        : const Color(0xFF0094FF).withValues(alpha: 0.4),
                  ),
                ),
                child: Icon(
                  isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round,
                  color: isDark
                      ? const Color(0xFFFFB800)
                      : const Color(0xFF0094FF),
                  size: 20,
                ),
              ),
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              onPressed: () => Provider.of<ThemeProvider>(context, listen: false).toggleTheme(),
            ),
            PopupMenuButton<String>(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF00F0FF).withValues(alpha: 0.3)
                        : const Color(0xFF0094FF).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.language,
                  color: isDark
                      ? const Color(0xFF00F0FF)
                      : const Color(0xFF0094FF),
                  size: 20,
                ),
              ),
              tooltip: langProvider.translate('select_language'),
              color: isDark
                  ? const Color(0xFF12131F).withValues(alpha: 0.94)
                  : const Color(0xF7FFFFFF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isDark
                      ? const Color(0xFF00F0FF).withValues(alpha: 0.3)
                      : const Color(0xFF0094FF).withValues(alpha: 0.3),
                ),
              ),
              onSelected: (langCode) async {
                await langProvider.changeLanguage(langCode);
                if (context.mounted) {
                  await AlarmRescheduler.rescheduleAll(context);
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'en',
                  child: Text(
                    'English',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
                PopupMenuItem(
                  value: 'ta',
                  child: Text(
                    'தமிழ் (Tamil)',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
                PopupMenuItem(
                  value: 'ur',
                  child: Text(
                    'اردو (Urdu)',
                    style: TextStyle(color: theme.colorScheme.onSurface),
                  ),
                ),
              ],
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.05),
                  border: Border.all(
                    color: isDark ? Colors.white24 : Colors.black12,
                  ),
                ),
                child: Icon(
                  Icons.info_outline,
                  color: theme.colorScheme.onSurface,
                  size: 20,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AboutScreen(),
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 20.0,
              vertical: 12.0,
            ),
            child: ListView(
              physics: const BouncingScrollPhysics(),
              children: [
                const SizedBox(height: 8),
                CustomButton(
                  label: langProvider.translate('prayer_planner'),
                  subtitle: langProvider.translate('prayer_subtitle'),
                  icon: AppConstants
                      .categoryIcons[AppConstants.categoryPrayer]!,
                  color: AppConstants.getCategoryColor(AppConstants.categoryPrayer, isDark),
                  onPressed: () => _navigateToCategory(
                    context,
                    langProvider.translate('prayer_planner'),
                    AppConstants.categoryPrayer,
                    AppConstants.getCategoryColor(AppConstants.categoryPrayer, isDark),
                  ),
                ),
                CustomButton(
                  label: langProvider.translate('workout_planner'),
                  subtitle: langProvider.translate('workout_subtitle'),
                  icon: AppConstants
                      .categoryIcons[AppConstants.categoryWorkout]!,
                  color: AppConstants.getCategoryColor(AppConstants.categoryWorkout, isDark),
                  onPressed: () => _navigateToCategory(
                    context,
                    langProvider.translate('workout_planner'),
                    AppConstants.categoryWorkout,
                    AppConstants.getCategoryColor(AppConstants.categoryWorkout, isDark),
                  ),
                ),
                CustomButton(
                  label: langProvider.translate('meal_planner'),
                  subtitle: langProvider.translate('meal_subtitle'),
                  icon:
                      AppConstants.categoryIcons[AppConstants.categoryMeal]!,
                  color: AppConstants.getCategoryColor(AppConstants.categoryMeal, isDark),
                  onPressed: () => _navigateToCategory(
                    context,
                    langProvider.translate('meal_planner'),
                    AppConstants.categoryMeal,
                    AppConstants.getCategoryColor(AppConstants.categoryMeal, isDark),
                  ),
                ),
                CustomButton(
                  label: langProvider.translate('medicine_planner'),
                  subtitle: langProvider.translate('medicine_subtitle'),
                  icon: AppConstants
                      .categoryIcons[AppConstants.categoryMedicine]!,
                  color: AppConstants.getCategoryColor(AppConstants.categoryMedicine, isDark),
                  onPressed: () => _navigateToCategory(
                    context,
                    langProvider.translate('medicine_planner'),
                    AppConstants.categoryMedicine,
                    AppConstants.getCategoryColor(AppConstants.categoryMedicine, isDark),
                  ),
                ),
                CustomButton(
                  label: langProvider.translate('study_planner'),
                  subtitle: langProvider.translate('study_subtitle'),
                  icon: AppConstants
                      .categoryIcons[AppConstants.categoryStudy]!,
                  color: AppConstants.getCategoryColor(AppConstants.categoryStudy, isDark),
                  onPressed: () => _navigateToCategory(
                    context,
                    langProvider.translate('study_planner'),
                    AppConstants.categoryStudy,
                    AppConstants.getCategoryColor(AppConstants.categoryStudy, isDark),
                  ),
                ),
                CustomButton(
                  label: langProvider.translate('sleeping_planner'),
                  subtitle: langProvider.translate('sleep_subtitle'),
                  icon:
                      AppConstants.categoryIcons[AppConstants.categorySleep]!,
                  color: AppConstants.getCategoryColor(AppConstants.categorySleep, isDark),
                  onPressed: () => _navigateToCategory(
                    context,
                    langProvider.translate('sleeping_planner'),
                    AppConstants.categorySleep,
                    AppConstants.getCategoryColor(AppConstants.categorySleep, isDark),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
