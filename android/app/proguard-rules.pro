# Flutter Local Notifications
-keep class com.dexterous.** { *; }
-keep class io.flutter.plugins.** { *; }

# Keep notification classes
-keep class * extends com.dexterous.flutterlocalnotifications.** { *; }

# Keep timezone data
-keep class net.danlew.android.joda.** { *; }

# Keep shared preferences
-keep class androidx.preference.** { *; }

# Keep location services
-keep class com.baseflow.geolocator.** { *; }
-keep class com.lyokone.location.** { *; }

# Adhan library
-keep class com.batoulapps.adhan2.** { *; }
-keepclassmembers class com.batoulapps.adhan2.** { *; }

# Keep all notification sounds
-keep class **.R$raw { *; }