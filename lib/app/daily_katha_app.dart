import 'package:flutter/material.dart';

import '../features/experience/daily_katha_experience.dart';
import 'theme.dart';

class DailyKathaApp extends StatelessWidget {
  const DailyKathaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Katha',
      theme: DailyKathaTheme.light,
      home: const DailyKathaExperience(),
    );
  }
}
