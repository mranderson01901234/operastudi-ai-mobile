import 'package:flutter/material.dart';

class AppTheme {
  // Clean monochrome dark theme inspired by Lightroom
  static const Color primaryDark = Color(0xFF1A1A1A);      // Main background
  static const Color secondaryDark = Color(0xFF2A2A2A);     // Card/surface background
  static const Color accentDark = Color(0xFF3A3A3A);        // Elevated surfaces
  static const Color textPrimary = Color(0xFFFFFFFF);       // Primary text
  static const Color textSecondary = Color(0xFFB0B0B0);     // Secondary text
  static const Color textDisabled = Color(0xFF707070);      // Disabled text
  
  // Monochrome accent colors - all white/gray based
  static const Color iconPrimary = Color(0xFFFFFFFF);       // Primary icons
  static const Color iconSecondary = Color(0xFFB0B0B0);     // Secondary icons
  static const Color iconDisabled = Color(0xFF707070);      // Disabled icons
  static const Color enhanceButton = Color(0xFF4A4A4A);     // Subtle enhance button

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: primaryDark,
      
      colorScheme: const ColorScheme.dark(
        primary: iconPrimary,
        secondary: iconSecondary,
        surface: secondaryDark,
        onPrimary: primaryDark,
        onSecondary: primaryDark,
        onSurface: textPrimary,
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: primaryDark,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      cardTheme: CardTheme(
        color: secondaryDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: enhanceButton,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),
      ),
      
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: textPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
      
      iconTheme: const IconThemeData(
        color: iconPrimary,
        size: 22,
      ),
      
      sliderTheme: SliderThemeData(
        activeTrackColor: iconPrimary,
        inactiveTrackColor: accentDark,
        thumbColor: iconPrimary,
        overlayColor: iconPrimary.withOpacity(0.1),
        valueIndicatorColor: accentDark,
        valueIndicatorTextStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
      
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: secondaryDark,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
      ),
      
      dividerTheme: const DividerThemeData(
        color: accentDark,
        thickness: 1,
        space: 1,
      ),
    );
  }
}
