# Preserve AndroidX classes and members
-keep class androidx.** { *; }

# Preserve Firebase classes and members
-keep class com.google.firebase.** { *; }

# Preserve Flutter classes and members
-keep class io.flutter.** { *; }

# Optional: Retain logging methods for debugging in release builds
-assumenosideeffects class android.util.Log {
    public static *** d(...);
    public static *** v(...);
    public static *** i(...);
    public static *** w(...);
    public static *** e(...);
}
