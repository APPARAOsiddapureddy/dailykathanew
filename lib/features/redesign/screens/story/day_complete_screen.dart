import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';

class DayCompleteScreen extends StatelessWidget {
  final Episode episode;
  const DayCompleteScreen({super.key, required this.episode});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),
              const Icon(
                Icons.emoji_events,
                color: AppColors.templeGold,
                size: 100,
              ),
              const SizedBox(height: 32),
              Text(
                isTelugu ? 'రోజు ${episode.dayNumber} పూర్తయింది!' : 'Day ${episode.dayNumber} Complete!',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sacredMaroon,
                  fontFamily: 'Noto Serif Telugu',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                isTelugu
                    ? 'మీరు అయోధ్య కాండంలో మరో అడుగు ముందుకు వేశారు. శభాష్!'
                    : 'You have taken another step in Ayodhya Kanda. Well done!',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.softBrown,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.ivoryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.templeGold.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(Icons.local_fire_department, color: AppColors.deepSaffron, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          isTelugu ? '12 రోజుల వరుస' : '12 Day Streak',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.sacredMaroon,
                          ),
                        ),
                      ],
                    ),
                    Container(width: 1, height: 50, color: AppColors.softBrown.withOpacity(0.2)),
                    Column(
                      children: [
                        const Icon(Icons.menu_book, color: AppColors.deepSaffron, size: 32),
                        const SizedBox(height: 8),
                        Text(
                          isTelugu ? '12/100 రామాయణం' : '12/100 Ramayanam',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: AppColors.sacredMaroon,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.white,
                  foregroundColor: AppColors.deepSaffron,
                  side: const BorderSide(color: AppColors.deepSaffron),
                ),
                child: Text(isTelugu ? 'రేపటి కోసం గుర్తు చేయి' : 'Remind for tomorrow'),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text(isTelugu ? 'హోమ్‌కి తిరిగి వెళ్ళు' : 'Return to Home'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
