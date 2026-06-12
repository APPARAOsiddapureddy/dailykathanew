import 'package:flutter/material.dart';

class AppColors {
  static const ivory = Color(0xFFFFF7E6);
  static const surface = Color(0xFFFFFBF2);
  static const card = Color(0xFFFFFFFF);
  static const brown = Color(0xFF2B1A12);
  static const mutedBrown = Color(0xFF735F50);
  static const saffron = Color(0xFFD97706);
  static const deepSaffron = Color(0xFF8D4B00);
  static const gold = Color(0xFFF5C542);
  static const maroon = Color(0xFF7F1D1D);
  static const success = Color(0xFF166534);
  static const error = Color(0xFFB42318);
  static const border = Color(0xFFE3C8A2);
  static const peacock = Color(0xFF1455A0);
  static const lotus = Color(0xFFC2417B);
  static const templeMist = Color(0xFFEAF2EF);
  static const dusk = Color(0xFF3A1C2B);
}

class DailyKathaTheme {
  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.saffron,
      brightness: Brightness.light,
      primary: AppColors.saffron,
      surface: AppColors.surface,
      error: AppColors.error,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.ivory,
      fontFamily: 'Roboto',
      splashFactory: NoSplash.splashFactory,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      hoverColor: const Color(0x14D97706),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFFFFFCF6),
        indicatorColor: const Color(0xFFFFE4A8),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        overlayColor: WidgetStateProperty.all(const Color(0x1AD97706)),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.deepSaffron : AppColors.mutedBrown,
          );
        }),
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: false,
        backgroundColor: AppColors.ivory,
        foregroundColor: AppColors.brown,
        surfaceTintColor: Colors.transparent,
      ),
      textTheme: const TextTheme(
        displaySmall: TextStyle(
          fontSize: 34,
          height: 1.18,
          fontWeight: FontWeight.w800,
          color: AppColors.brown,
        ),
        headlineMedium: TextStyle(
          fontSize: 26,
          height: 1.24,
          fontWeight: FontWeight.w800,
          color: AppColors.brown,
        ),
        titleLarge: TextStyle(
          fontSize: 21,
          height: 1.25,
          fontWeight: FontWeight.w800,
          color: AppColors.brown,
        ),
        titleMedium: TextStyle(
          fontSize: 17,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: AppColors.brown,
        ),
        bodyLarge: TextStyle(
          fontSize: 17,
          height: 1.48,
          color: AppColors.brown,
        ),
        bodyMedium: TextStyle(
          fontSize: 15,
          height: 1.45,
          color: AppColors.mutedBrown,
        ),
        labelLarge: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: Colors.white,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(54),
          backgroundColor: AppColors.saffron,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          foregroundColor: AppColors.deepSaffron,
          side: const BorderSide(color: AppColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: const BorderSide(color: Color(0x44E3C8A2)),
        ),
      ),
    );
  }
}
