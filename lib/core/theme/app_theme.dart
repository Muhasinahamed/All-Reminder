import 'package:flutter/material.dart';

class AppTheme {
  static const Color backgroundDark = Color(0xFF09090B);
  static const Color backgroundLight = Color(0xFFF1F5F9);
  static const Color neonCyan = Color(0xFF00F0FF);
  static const Color neonBlue = Color(0xFF0094FF);
  static const Color neonPurple = Color(0xFF9D00FF);
  static const Color neonEmerald = Color(0xFF00FF87);
  static const Color surfaceGlassDark = Color(0x12FFFFFF);
  static const Color surfaceGlassLight = Color(0x99FFFFFF);

  static ThemeData get lightTheme => ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: backgroundLight,
        primaryColor: neonBlue,
        colorScheme: const ColorScheme.light(
          primary: neonBlue,
          secondary: Color(0xFF8B5CF6),
          surface: surfaceGlassLight,
          onSurface: Color(0xFF0F172A),
          onPrimary: Colors.white,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Color(0xFF0F172A),
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: surfaceGlassLight,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(
              color: Colors.white,
              width: 1.5,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xF2FFFFFF),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: neonBlue.withValues(alpha: 0.4),
              width: 1.5,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: neonBlue,
          foregroundColor: Colors.white,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );

  static ThemeData get darkTheme => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: backgroundDark,
        primaryColor: neonCyan,
        colorScheme: const ColorScheme.dark(
          primary: neonCyan,
          secondary: neonPurple,
          surface: Color(0xFF121217),
          onSurface: Colors.white,
          onPrimary: Colors.black,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
        cardTheme: CardThemeData(
          color: surfaceGlassDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1.2,
            ),
          ),
        ),
        dialogTheme: DialogThemeData(
          backgroundColor: const Color(0xFF12131A).withValues(alpha: 0.85),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(
              color: neonCyan.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: neonCyan,
          foregroundColor: Colors.black,
          elevation: 10,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      );
}
