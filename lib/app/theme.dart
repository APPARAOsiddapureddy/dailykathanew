import 'package:flutter/material.dart';

class AppColors {
  const AppColors._();

  static const ivory = Color(0xFFFFF3DC);
  static const card = Color(0xFFFFFCF6);
  static const border = Color(0xFFE8D6B5);
  static const brown = Color(0xFF5C2B2E);
  static const mutedBrown = Color(0xFF9A7A5E);
  static const deepSaffron = Color(0xFFB84E19);
  static const saffron = Color(0xFFE0701C);
  static const gold = Color(0xFFF5A623);
  static const maroon = Color(0xFF6B1F22);
  static const success = Color(0xFF3D8B5E);
  static const error = Color(0xFFB42318);
}

final ThemeData dailyKathaTheme = ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: AppColors.ivory,
  colorScheme: ColorScheme.fromSeed(
    seedColor: AppColors.deepSaffron,
    primary: AppColors.deepSaffron,
    secondary: AppColors.gold,
    surface: AppColors.ivory,
    error: AppColors.error,
  ),
  fontFamily: 'Noto Sans Telugu',
  textTheme: const TextTheme(
    displaySmall: TextStyle(
      color: AppColors.brown,
      fontSize: 34,
      fontWeight: FontWeight.w900,
      height: 1.08,
      fontFamily: 'Noto Serif Telugu',
    ),
    headlineMedium: TextStyle(
      color: AppColors.brown,
      fontSize: 28,
      fontWeight: FontWeight.w900,
      height: 1.15,
      fontFamily: 'Noto Serif Telugu',
    ),
    titleLarge: TextStyle(
      color: AppColors.brown,
      fontSize: 21,
      fontWeight: FontWeight.w900,
      height: 1.25,
      fontFamily: 'Noto Serif Telugu',
    ),
    titleMedium: TextStyle(
      color: AppColors.brown,
      fontSize: 17,
      fontWeight: FontWeight.w900,
      height: 1.25,
    ),
    titleSmall: TextStyle(
      color: AppColors.brown,
      fontSize: 15,
      fontWeight: FontWeight.w800,
      height: 1.3,
    ),
    bodyLarge: TextStyle(
      color: AppColors.mutedBrown,
      fontSize: 16,
      height: 1.45,
      fontWeight: FontWeight.w600,
    ),
    bodyMedium: TextStyle(
      color: AppColors.mutedBrown,
      fontSize: 14,
      height: 1.4,
      fontWeight: FontWeight.w600,
    ),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.deepSaffron,
      foregroundColor: Colors.white,
      minimumSize: const Size.fromHeight(52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: const TextStyle(fontWeight: FontWeight.w900),
    ),
  ),
);
