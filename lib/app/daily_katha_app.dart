import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/redesign/data/mock_data.dart';
import '../features/redesign/screens/onboarding/splash_screen.dart';
import '../features/redesign/theme/redesign_theme.dart';

class DailyKathaApp extends StatelessWidget {
  const DailyKathaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Daily Katha',
        theme: redesignTheme,
        home: const SplashScreen(),
      ),
    );
  }
}
