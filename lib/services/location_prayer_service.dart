import 'dart:async';
import 'package:adhan_dart/adhan_dart.dart';
import 'package:flutter/foundation.dart';
//import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:location/location.dart';
import '../core/constants/app_constants.dart';

class LocationPrayerService {
  static final LocationPrayerService _instance =
      LocationPrayerService._internal();
  factory LocationPrayerService() => _instance;
  LocationPrayerService._internal();

  final Location _location = Location();

  static bool _tzInitialized = false;
  static Future<void> initializeTimezones() async {
    if (_tzInitialized) return;
    tz.initializeTimeZones();
    _tzInitialized = true;
  }

  Future<bool> isAutoLocationEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(AppConstants.keyAutoLocationEnabled) ?? false;
  }

  Future<void> setAutoLocationEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.keyAutoLocationEnabled, enabled);
  }

  Future<bool> _checkAndRequestPermission() async {
    bool serviceEnabled = await _location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await _location.requestService();
      if (!serviceEnabled) {
        debugPrint("Location service disabled.");
        return false;
      }
    }

    PermissionStatus permission = await _location.hasPermission();
    if (permission == PermissionStatus.denied) {
      permission = await _location.requestPermission();
      if (permission != PermissionStatus.granted) {
        debugPrint("Permission denied.");
        return false;
      }
    }

    if (permission == PermissionStatus.deniedForever) {
      debugPrint("Permission denied forever.");
      return false;
    }

    return true;
  }

  // Future<Position?> getCurrentLocation() async {
  //   try {
  //     final hasPermission = await requestLocationPermission();
  //     if (!hasPermission) return null;
  //     debugPrint("📡 Getting device location...");
  //     // final LocationSettings locationSettings = LocationSettings(
  //     //   accuracy: LocationAccuracy.best,
  //     //   distanceFilter: 0,
  //     // );
  //     final position = await Geolocator.getCurrentPosition(
  //       desiredAccuracy: LocationAccuracy.best,
  //     );
  //     debugPrint(
  //       "✅ Location received: ${position.latitude}, ${position.longitude}",
  //     );
  //     return position;
  //   } catch (e) {
  //     debugPrint("Error getting location: $e");
  //     return null;
  //   }
  // }
  Future<LocationData?> getCurrentLocation() async {
    final allowed = await _checkAndRequestPermission();
    if (!allowed) {
      debugPrint("❌ Location permission denied");
      return null;
    }

    try {
      debugPrint("📡 Getting device location using LOCATION plugin...");
      await _location.changeSettings(
        accuracy: LocationAccuracy.balanced,
        interval: 5000,
        distanceFilter: 100,
      );
      final loc = await _location.getLocation().timeout(
        const Duration(seconds: 8),
        onTimeout: () async {
          debugPrint("⏰ Location request timed out, trying low accuracy...");
          await _location.changeSettings(accuracy: LocationAccuracy.low);
          return await _location.getLocation().timeout(const Duration(seconds: 5));
        },
      );
      debugPrint("✅ Location received: ${loc.latitude}, ${loc.longitude}");
      return loc;
    } catch (e) {
      debugPrint("❌ ERROR getting location: $e");
      try {
        debugPrint("🔄 Falling back to low accuracy location fetch...");
        await _location.changeSettings(accuracy: LocationAccuracy.low);
        final fallbackLoc = await _location.getLocation().timeout(const Duration(seconds: 5));
        debugPrint("✅ Fallback Location received: ${fallbackLoc.latitude}, ${fallbackLoc.longitude}");
        return fallbackLoc;
      } catch (ex) {
        debugPrint("❌ Fallback location also failed: $ex");
        return null;
      }
    }
  }

  /// ⭐ FIXED: Proper time formatting with correct AM/PM conversion
  Future<Map<String, String>?> calculatePrayerTimes({
    required double latitude,
    required double longitude,
  }) async {
    try {
      if (!_tzInitialized) {
        await initializeTimezones();
      }
      final location = tz.getLocation('Asia/Kolkata');
      final now = tz.TZDateTime.from(DateTime.now(), location);

      Coordinates coordinates = Coordinates(latitude, longitude);
      CalculationParameters params =
          CalculationMethodParameters.muslimWorldLeague();
      params.madhab = Madhab.hanafi;

      PrayerTimes prayerTimes = PrayerTimes(
        coordinates: coordinates,
        date: now,
        calculationParameters: params,
        precision: true,
      );
      debugPrint(
        "calculatePrayerTimes called with lat: $latitude, lng: $longitude",
      );
      debugPrint('=== RAW ADHAN TIMES (DateTime) ===');
      debugPrint('Fajr    : ${prayerTimes.fajr.toIso8601String()}');
      debugPrint('Sunrise : ${prayerTimes.sunrise.toIso8601String()}');
      debugPrint('Dhuhr   : ${prayerTimes.dhuhr.toIso8601String()}');
      debugPrint('Asr     : ${prayerTimes.asr.toIso8601String()}');
      debugPrint('Maghrib : ${prayerTimes.maghrib.toIso8601String()}');
      debugPrint('Isha    : ${prayerTimes.isha.toIso8601String()}');
      //debugPrint('Qiyam   : ${prayerTimes.qiyam?.toIso8601String()}');
      debugPrint('==================================');

      /// ✅ FIXED: Correct 12-hour format conversion
      String fmt(DateTime time) {
        final dt = tz.TZDateTime.from(time, location);
        final hour = dt.hour == 0
            ? 12
            : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
        final minute = dt.minute.toString().padLeft(2, '0');
        final period = dt.hour >= 12 ? 'PM' : 'AM';
        return "$hour:$minute $period";
      }

      return {
        "Fajr": fmt(prayerTimes.fajr),
        "sunrise": fmt(prayerTimes.sunrise),
        "Dhuhr": fmt(prayerTimes.dhuhr),
        "Asr": fmt(prayerTimes.asr),
        "Maghrib": fmt(prayerTimes.maghrib),
        "Isha": fmt(prayerTimes.isha),
      };
    } catch (e) {
      debugPrint("Error calculating prayer times: $e");
      return null;
    }
  }

  Future<PrayerTimes?> getRawPrayerTimesFromLocation() async {
    final loc = await getCurrentLocation();
    final prefs = await SharedPreferences.getInstance();
    
    double? latitude = loc?.latitude;
    double? longitude = loc?.longitude;

    if (latitude == null || longitude == null) {
      debugPrint("⚠️ Failed to get fresh location, trying fallback to last known coordinates...");
      latitude = prefs.getDouble(AppConstants.keyLastLatitude);
      longitude = prefs.getDouble(AppConstants.keyLastLongitude);
    } else {
      await prefs.setDouble(AppConstants.keyLastLatitude, latitude);
      await prefs.setDouble(AppConstants.keyLastLongitude, longitude);
    }

    if (latitude == null || longitude == null) {
      debugPrint("❌ Cannot get raw prayer times: location is null");
      return null;
    }

    if (!_tzInitialized) {
      await initializeTimezones();
    }
    
    final location = tz.getLocation('Asia/Kolkata');
    final now = tz.TZDateTime.from(DateTime.now(), location);

    final coordinates = Coordinates(latitude, longitude);
    final params = CalculationMethodParameters.muslimWorldLeague()
      ..madhab = Madhab.hanafi;

    try {
      return PrayerTimes(
        coordinates: coordinates,
        date: now,
        calculationParameters: params,
        precision: true,
      );
    } catch (e) {
      debugPrint("❌ Error creating PrayerTimes: $e");
      return null;
    }
  }

  /// ✅ Get prayer times from current location and save coordinates
  Future<Map<String, String>?> getPrayerTimesFromLocation() async {
    final loc = await getCurrentLocation();
    final prefs = await SharedPreferences.getInstance();
    
    double? latitude = loc?.latitude;
    double? longitude = loc?.longitude;

    if (latitude == null || longitude == null) {
      debugPrint("⚠️ Failed to get fresh location, trying fallback to last known coordinates...");
      latitude = prefs.getDouble(AppConstants.keyLastLatitude);
      longitude = prefs.getDouble(AppConstants.keyLastLongitude);
    } else {
      await prefs.setDouble(AppConstants.keyLastLatitude, latitude);
      await prefs.setDouble(AppConstants.keyLastLongitude, longitude);
    }

    if (latitude == null || longitude == null) {
      debugPrint("❌ Cannot get prayer times: location is null");
      return null;
    }

    return await calculatePrayerTimes(
      latitude: latitude,
      longitude: longitude,
    );
  }
  
  Future<Map<String, String>?> getLastKnownPrayerTimes() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble(AppConstants.keyLastLatitude);
    final lng = prefs.getDouble(AppConstants.keyLastLongitude);

    if (lat == null || lng == null) {
      debugPrint("⚠️ No last known location saved");
      return null;
    }

    return await calculatePrayerTimes(latitude: lat, longitude: lng);
  }

  Future<void> saveLastUpdatedNow() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      "last_prayer_update",
      DateTime.now().toIso8601String(),
    );
  }

  Future<String?> getLastUpdatedTime() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString("last_prayer_update");
    
    if (stored == null) {
      debugPrint("⚠️ No last update time found");
      return null;
    }

    try {
      final dt = DateTime.parse(stored);
      final hour = dt.hour == 0 ? 12 : (dt.hour > 12 ? dt.hour - 12 : dt.hour);
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';

      return "${dt.day}/${dt.month}/${dt.year} • $hour:$minute $period";
    } catch (e) {
      debugPrint("❌ Error parsing last update time: $e");
      return null;
    }
  }
}
