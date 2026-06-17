import 'package:flutter/material.dart';

import '../features/v2/daily_katha_v2_experience.dart';
import 'theme.dart';

class DailyKathaApp extends StatelessWidget {
  const DailyKathaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Daily Katha',
      theme: DailyKathaTheme.light,
      home: const DailyKathaV2Experience(),
    );
  }
}
