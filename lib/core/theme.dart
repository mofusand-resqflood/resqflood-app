
import 'package:flutter/material.dart';

class AppTheme {
  static final light = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: const Color(0xFFF5FAF8),
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF147D70),
      brightness: Brightness.light,
      surface: const Color(0xFFFFFFFF),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF5FAF8),
      foregroundColor: Color(0xFF164E48),
      elevation: 0,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFE5F3EE),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
  );
}
