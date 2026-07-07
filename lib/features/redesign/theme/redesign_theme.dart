import 'package:flutter/material.dart';

class AppColors {
  static const Color warmIvory = Color(0xFFFFF3DC);
  static const Color ivoryLight = Color(0xFFFFF6E7);
  static const Color deepSaffron = Color(0xFFB84E19);
  static const Color templeGold = Color(0xFFF5A623);
  static const Color sacredMaroon = Color(0xFF5C2B2E);
  static const Color softBrown = Color(0xFF996B4D);
  static const Color white = Colors.white;
  static const Color greyText = Color(0xFF666666);
}

final ThemeData redesignTheme = ThemeData(
  scaffoldBackgroundColor: AppColors.warmIvory,
  primaryColor: AppColors.deepSaffron,
  colorScheme: const ColorScheme.light(
    primary: AppColors.deepSaffron,
    secondary: AppColors.templeGold,
    surface: AppColors.warmIvory,
    error: AppColors.sacredMaroon,
    onPrimary: AppColors.white,
    onSecondary: AppColors.sacredMaroon,
    onSurface: AppColors.sacredMaroon,
  ),
  fontFamily: 'Noto Sans Telugu',
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.warmIvory,
    elevation: 0,
    iconTheme: IconThemeData(color: AppColors.sacredMaroon),
    titleTextStyle: TextStyle(
      color: AppColors.sacredMaroon,
      fontSize: 20,
      fontWeight: FontWeight.bold,
      fontFamily: 'Noto Serif Telugu',
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.deepSaffron,
      foregroundColor: AppColors.white,
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Noto Sans Telugu',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.deepSaffron,
      side: const BorderSide(color: AppColors.deepSaffron, width: 2),
      textStyle: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        fontFamily: 'Noto Sans Telugu',
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
    ),
  ),
  textTheme: const TextTheme(
    displayLarge: TextStyle(
      color: AppColors.sacredMaroon,
      fontWeight: FontWeight.bold,
      fontFamily: 'Noto Serif Telugu',
    ),
    displayMedium: TextStyle(
      color: AppColors.sacredMaroon,
      fontWeight: FontWeight.bold,
      fontFamily: 'Noto Serif Telugu',
    ),
    bodyLarge: TextStyle(
      color: AppColors.sacredMaroon,
      fontSize: 18,
      fontFamily: 'Noto Sans Telugu',
    ),
    bodyMedium: TextStyle(
      color: AppColors.sacredMaroon,
      fontSize: 16,
      fontFamily: 'Noto Sans Telugu',
    ),
    bodySmall: TextStyle(
      color: AppColors.softBrown,
      fontSize: 14,
      fontFamily: 'Noto Sans Telugu',
    ),
  ),
);
