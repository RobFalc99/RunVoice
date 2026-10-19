import 'package:flutter/material.dart';

class AppColors {
  // Primary palette - Hyper Orange / Neon Coral
  static const Color primary = Color(0xFFFF6B35);
  static const Color primaryLight = Color(0xFFFF8F5E);
  static const Color primaryDark = Color(0xFFE54E1B);

  // Accent - Cyber Cyan
  static const Color accent = Color(0xFF00F0FF);
  static const Color accentLight = Color(0xFF70F8FF);
  static const Color accentDark = Color(0xFF00B4C4);

  // Dark Neumorphic Base Surfaces
  static const Color background = Color(0xFF0F1319);
  static const Color surface = Color(0xFF141922);
  static const Color surfaceLight = Color(0xFF1B222E);
  static const Color surfaceHighlight = Color(0xFF242C3B);

  // Neumorphic Shadow System
  static const Color neuDarkShadow = Color(0xFF090C10);
  static const Color neuLightShadow = Color(0xFF1F2634);
  static const Color neuBorder = Color(0xFF232B3A);

  // Text
  static const Color textPrimary = Color(0xFFF3F6FA);
  static const Color textSecondary = Color(0xFF94A1B2);
  static const Color textMuted = Color(0xFF677587);

  // Status
  static const Color success = Color(0xFF00E676);
  static const Color warning = Color(0xFFFFB300);
  static const Color error = Color(0xFFFF3D57);
  static const Color info = Color(0xFF00F0FF);

  // HR Zones
  static const Color zone0 = Color(0xFF677587); // Resting - Gray
  static const Color zone1 = Color(0xFF00F0FF); // Recovery - Cyan
  static const Color zone2 = Color(0xFF00E676); // Aerobic - Green
  static const Color zone3 = Color(0xFFFFB300); // Tempo - Yellow
  static const Color zone4 = Color(0xFFFF6B35); // Threshold - Orange
  static const Color zone5 = Color(0xFFFF3D57); // Maximum - Neon Red

  static Color getZoneColor(int zone) {
    switch (zone) {
      case 0:
        return zone0;
      case 1:
        return zone1;
      case 2:
        return zone2;
      case 3:
        return zone3;
      case 4:
        return zone4;
      case 5:
        return zone5;
      default:
        return textMuted;
    }
  }
}

class NeumorphicDecorations {
  static BoxDecoration extruded({
    double radius = 16,
    Color color = AppColors.surface,
    Color? borderColor,
    double depth = 4,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppColors.neuBorder.withValues(alpha: 0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.neuDarkShadow.withValues(alpha: 0.9),
          offset: Offset(depth, depth),
          blurRadius: depth * 2.5,
        ),
        BoxShadow(
          color: AppColors.neuLightShadow.withValues(alpha: 0.6),
          offset: Offset(-depth * 0.7, -depth * 0.7),
          blurRadius: depth * 2,
        ),
      ],
    );
  }

  static BoxDecoration inset({
    double radius = 16,
    Color color = AppColors.background,
    Color? borderColor,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(
        color: borderColor ?? AppColors.neuDarkShadow.withValues(alpha: 0.8),
        width: 1.2,
      ),
      boxShadow: [
        BoxShadow(
          color: AppColors.neuDarkShadow.withValues(alpha: 0.7),
          offset: const Offset(2, 2),
          blurRadius: 4,
          spreadRadius: -1,
        ),
      ],
    );
  }
}

class AppTheme {
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primary,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        error: AppColors.error,
        onPrimary: Colors.white,
        onSecondary: Colors.black,
        onSurface: AppColors.textPrimary,
        onError: Colors.white,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.neuBorder, width: 1),
        ),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.textPrimary,
          fontSize: 22,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.surface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          side: const BorderSide(color: AppColors.surfaceHighlight),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neuBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.neuBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.accent, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 16,
        ),
        labelStyle: const TextStyle(color: AppColors.textSecondary),
        hintStyle: const TextStyle(color: AppColors.textMuted),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary;
          }
          return AppColors.textMuted;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.primary.withValues(alpha: 0.3);
          }
          return AppColors.surfaceHighlight;
        }),
      ),
      sliderTheme: const SliderThemeData(
        activeTrackColor: AppColors.primary,
        inactiveTrackColor: AppColors.surfaceHighlight,
        thumbColor: AppColors.primary,
        overlayColor: Color(0x29FF6B35),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.surfaceHighlight,
        thickness: 1,
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 6,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        contentTextStyle: const TextStyle(color: AppColors.textPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class HRZoneDefaults {
  static const List<String> zoneNames = [
    'Zone 0 - Riposo',
    'Zone 1 - Riscaldamento',
    'Zone 2 - Aerobica',
    'Zone 3 - Ritmo',
    'Zone 4 - Soglia',
    'Zone 5 - Massima',
  ];

  static const List<List<double>> zonePercentages = [
    [0.0, 0.50], // Zone 0
    [0.50, 0.60], // Zone 1
    [0.60, 0.70], // Zone 2
    [0.70, 0.80], // Zone 3
    [0.80, 0.90], // Zone 4
    [0.90, 1.00], // Zone 5
  ];
}
