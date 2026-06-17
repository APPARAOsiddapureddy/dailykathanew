import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../data/app_api_service.dart';
import '../models/story_models.dart';
import 'day_reader_screen.dart';

class CompletionScreen extends StatelessWidget {
  const CompletionScreen({
    super.key,
    required this.api,
    required this.story,
    required this.day,
    required this.score,
    required this.total,
  });

  final AppApiService api;
  final Story story;
  final StoryDaySummary day;
  final int score;
  final int total;

  StoryDaySummary? get _nextDay {
    for (final candidate in story.days) {
      if (candidate.dayNumber > day.dayNumber) return candidate;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final nextDay = _nextDay;
    final scoreText = total == 0
        ? 'No quiz assigned'
        : '$score / $total correct';

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const Spacer(),
              const AppLogo(size: 96),
              const SizedBox(height: 26),
              Text(
                'Day ${day.dayNumber} Completed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              Text(
                'మీరు ఈరోజు కథను పూర్తి చేశారు.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      icon: Icons.quiz_rounded,
                      title: scoreText,
                      label: 'Quiz Result',
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: _StatTile(
                      icon: Icons.workspace_premium_rounded,
                      title: '+1',
                      label: 'Day Progress',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              if (nextDay != null)
                _TomorrowCard(day: nextDay)
              else
                const _SeriesDoneCard(),
              const Spacer(),
              if (nextDay != null)
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => DayReaderScreen(
                          api: api,
                          story: story,
                          day: nextDay,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: Text('Continue to Day ${nextDay.dayNumber}'),
                ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                icon: const Icon(Icons.auto_stories_rounded),
                label: const Text('Back to Stories'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.title,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 118),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.6)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.saffron, size: 30),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.brown,
              fontWeight: FontWeight.w900,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.mutedBrown,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _TomorrowCard extends StatelessWidget {
  const _TomorrowCard({required this.day});

  final StoryDaySummary day;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7B3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.7)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            color: AppColors.deepSaffron,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Next Available Day',
                  style: TextStyle(
                    color: AppColors.deepSaffron,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Day ${day.dayNumber}: ${day.title}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SeriesDoneCard extends StatelessWidget {
  const _SeriesDoneCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF7EF),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.35)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle_rounded, color: AppColors.success),
          SizedBox(width: 14),
          Expanded(
            child: Text(
              'You have completed all currently published days in this story.',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
