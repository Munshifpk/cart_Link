import 'package:flutter/material.dart';

/// Centralized palette for the "Royal Blue + Coral + Emerald" shopping theme.
class ThemeColors {
  // Brand / action colors
  static const Color primary = Color(0xFF1F6FEB); // Royal Blue - main CTAs, app bar, icons
  static const Color primaryDark = Color(0xFF1557C7); // Deeper Blue for contrast
  static const Color accent = Color(0xFFFF6B5A); // Coral - highlights, badges, alert actions

  // Surfaces and backgrounds
  static const Color background = Color(0xFFFFFFFF); // White card base
  static const Color surface = Color(0xFFF5F7FB); // Soft Gray page backgrounds
  static const Color scaffoldBackground = surface; // Alias for scaffold usage

  // Text
  static const Color textPrimary = Color(0xFF1F2A3D); // Charcoal for primary text
  static const Color textSecondary = Color(0xFF5B6575); // Muted Slate for secondary text

  // States
  static const Color success = Color(0xFF23B26D); // Emerald - confirmations, "Following" button
  static const Color error = Color(0xFFE74C3C); // Error state
  static const Color warning = Color(0xFFFFA726); // Warning state
  static const Color info = accent; // Info / links
  static const Color greenButton = success; // Button alias for legacy uses (now uses success color)

  // Utility
  static const Color white = Colors.white;
  static const Color dimwhite = Colors.white70;
  static const Color textColorWhite = white; // Backward compatibility
  static const Color divider = Color(0xFFE4E8EF); // Light Gray borders/dividers

  // Elevation shadow for cards
  static BoxShadow cardShadow = BoxShadow(
    color: const Color(0x0C0C2340).withOpacity(0.08),
    blurRadius: 12,
    offset: const Offset(0, 4),
  );

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryDark, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient accentGradient = LinearGradient(
    colors: [accent, primary],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Shared theme configuration applied across the app.
class AppTheme {
  static ThemeData get light {
    final colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: ThemeColors.primary,
      onPrimary: ThemeColors.white,
      secondary: ThemeColors.accent,
      onSecondary: ThemeColors.white,
      error: ThemeColors.error,
      onError: ThemeColors.white,
      background: ThemeColors.background,
      onBackground: ThemeColors.textPrimary,
      surface: ThemeColors.surface,
      onSurface: ThemeColors.textPrimary,
    );

    return ThemeData(
      colorScheme: colorScheme,
      scaffoldBackgroundColor: ThemeColors.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: ThemeColors.primary,
        foregroundColor: ThemeColors.white,
        elevation: 0,
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: ThemeColors.primary,
        selectedItemColor: ThemeColors.white,
        unselectedItemColor: Colors.white70,
        type: BottomNavigationBarType.fixed,
      ),
      cardTheme: CardThemeData(
        color: ThemeColors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: ThemeColors.primary,
          foregroundColor: ThemeColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ThemeColors.primary,
          side: const BorderSide(color: ThemeColors.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: ThemeColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: ThemeColors.primary),
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: ThemeColors.divider,
        thickness: 1,
      ),
    );
  }
}
