import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import '../main/main_shell.dart';

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
                isTelugu
                    ? 'రోజు ${episode.dayNumber} పూర్తయింది!'
                    : 'Day ${episode.dayNumber} Complete!',
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
                    ? 'శభాష్! మీ ప్రయాణంలో మరో అడుగు ముందుకు వేశారు.'
                    : 'Well done! You took another step in your journey.',
                style: const TextStyle(
                  fontSize: 18,
                  color: AppColors.softBrown,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              // Dynamic stats
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.ivoryLight,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.templeGold.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Icon(
                          Icons.local_fire_department,
                          color: AppColors.deepSaffron,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${state.streak}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.sacredMaroon,
                          ),
                        ),
                        Text(
                          isTelugu ? 'రోజుల వరుస' : 'Day Streak',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.softBrown,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: 1,
                      height: 50,
                      color: AppColors.softBrown.withValues(alpha: 0.2),
                    ),
                    Column(
                      children: [
                        const Icon(
                          Icons.star,
                          color: AppColors.deepSaffron,
                          size: 32,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${state.points}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 20,
                            color: AppColors.sacredMaroon,
                          ),
                        ),
                        Text(
                          isTelugu ? 'పాయింట్లు' : 'Points',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.softBrown,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                child: Text(
                  isTelugu ? 'హోమ్‌కి తిరిగి వెళ్ళు' : 'Return to Home',
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
