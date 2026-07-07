import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import 'story_reader_screen.dart';

class UniverseDetailScreen extends StatelessWidget {
  final Journey journey;
  const UniverseDetailScreen({super.key, required this.journey});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Image.asset(
                journey.coverAsset,
                fit: BoxFit.cover,
                color: Colors.black.withOpacity(0.4),
                colorBlendMode: BlendMode.darken,
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ॐ',
                    style: TextStyle(
                      color: AppColors.templeGold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    journey.title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontFamily: 'Noto Serif Telugu',
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    isTelugu ? '12/100 రోజులు' : '12/100 Days',
                    style: const TextStyle(
                      color: AppColors.ivoryLight,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              titlePadding: const EdgeInsets.only(left: 48, bottom: 16),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final part = journey.parts[index];
                return _JourneyPartTile(part: part, journey: journey);
              },
              childCount: journey.parts.length,
            ),
          ),
        ],
      ),
    );
  }
}

class _JourneyPartTile extends StatelessWidget {
  final JourneyPart part;
  final Journey journey;

  const _JourneyPartTile({required this.part, required this.journey});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    String subtitle = '';
    Color statusColor = AppColors.softBrown;
    IconData? icon;

    if (part.isCompleted) {
      subtitle = isTelugu ? '${part.totalDays} రోజులు · పూర్తయింది' : '${part.totalDays} Days · Completed';
      statusColor = Colors.green;
      icon = Icons.check_circle;
    } else if (part.isLocked) {
      subtitle = isTelugu ? '${part.totalDays} రోజులు · లాక్ చేయబడింది' : '${part.totalDays} Days · Locked';
      statusColor = AppColors.greyText;
      icon = Icons.lock;
    } else {
      subtitle = isTelugu ? '${part.totalDays} రోజులు · రోజు 12 కొనసాగుతోంది' : '${part.totalDays} Days · Day 12 In Progress';
      statusColor = AppColors.deepSaffron;
      icon = Icons.play_circle_fill;
    }

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      title: Text(
        part.title,
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: part.isLocked ? AppColors.greyText : AppColors.sacredMaroon,
        ),
      ),
      subtitle: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: statusColor),
            const SizedBox(width: 4),
          ],
          Text(
            subtitle,
            style: TextStyle(color: statusColor, fontSize: 14),
          ),
        ],
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.softBrown),
      onTap: part.isLocked
          ? null
          : () {
              if (part.episodes.isNotEmpty) {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => StoryReaderScreen(episode: part.episodes.first),
                  ),
                );
              }
            },
    );
  }
}
