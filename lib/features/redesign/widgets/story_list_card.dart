import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/mock_data.dart';
import '../theme/redesign_theme.dart';
import '../screens/story/universe_detail_screen.dart';

class StoryListCard extends StatelessWidget {
  final Journey journey;

  const StoryListCard({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    final progress = state.getStoryProgress(journey.id);
    final hasStarted = progress != null;
    final isCompleted = progress?.isCompleted ?? false;
    final daysCompleted = progress?.completedDaysCount ?? 0;

    String statusText;
    Color statusColor;
    String actionText;

    if (isCompleted) {
      statusText = isTelugu
          ? '${journey.totalDays} రోజులు · పూర్తయింది ✓'
          : '${journey.totalDays} Days · Completed ✓';
      statusColor = Colors.green;
      actionText = isTelugu ? 'మళ్ళీ చదువు' : 'Read Again';
    } else if (hasStarted) {
      statusText = isTelugu
          ? '$daysCompleted/${journey.totalDays} రోజులు · కొనసాగుతోంది'
          : '$daysCompleted/${journey.totalDays} Days · In Progress';
      statusColor = AppColors.deepSaffron;
      actionText = isTelugu ? 'కొనసాగించు' : 'Continue';
    } else {
      statusText = isTelugu
          ? '${journey.totalDays} రోజులు · ఇంకా ప్రారంభించలేదు'
          : '${journey.totalDays} Days · Not Started';
      statusColor = AppColors.softBrown;
      actionText = isTelugu ? 'ప్రారంభించు' : 'Start';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: GestureDetector(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UniverseDetailScreen(journey: journey),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.sacredMaroon.withValues(alpha: 0.1),
            ),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: journey.coverAsset.startsWith('http')
                    ? Image.network(
                        journey.coverAsset,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/mahabharatam-cover.png',
                          width: 80,
                          height: 80,
                          fit: BoxFit.cover,
                        ),
                      )
                    : Image.asset(
                        journey.coverAsset,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      journey.title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sacredMaroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      statusText,
                      style: TextStyle(fontSize: 14, color: statusColor),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                UniverseDetailScreen(journey: journey),
                          ),
                        );
                      },
                      child: Text(
                        actionText,
                        style: const TextStyle(
                          color: AppColors.deepSaffron,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
