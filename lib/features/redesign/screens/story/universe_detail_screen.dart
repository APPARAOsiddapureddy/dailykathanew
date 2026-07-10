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

    // Flatten all episodes from all parts into a single list of days
    final allEpisodes = <Episode>[];
    for (final part in journey.parts) {
      allEpisodes.addAll(part.episodes);
    }
    allEpisodes.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: const Color(0xFF6B1F22),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  journey.coverAsset.startsWith('http')
                      ? Image.network(
                          journey.coverAsset,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.4),
                          colorBlendMode: BlendMode.darken,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/mahabharatam-cover.png',
                            fit: BoxFit.cover,
                            color: Colors.black.withValues(alpha: 0.4),
                            colorBlendMode: BlendMode.darken,
                          ),
                        )
                      : Image.asset(
                          journey.coverAsset,
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.4),
                          colorBlendMode: BlendMode.darken,
                        ),
                  // Bottom gradient for text readability
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 120,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            Colors.black.withValues(alpha: 0.6),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              title: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'ॐ',
                    style: TextStyle(color: AppColors.templeGold, fontSize: 16),
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
                    isTelugu
                        ? '${allEpisodes.length} రోజులు'
                        : '${allEpisodes.length} Days',
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

          // Section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Text(
                isTelugu ? 'అన్ని రోజులు' : 'All Days',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sacredMaroon,
                  fontFamily: 'Noto Serif Telugu',
                ),
              ),
            ),
          ),

          // Day-wise list
          allEpisodes.isEmpty
              ? SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(48),
                    child: Center(
                      child: Text(
                        isTelugu
                            ? 'ఈ కథకు ఇంకా రోజులు జోడించబడలేదు'
                            : 'No days available for this story yet',
                        style: const TextStyle(
                          color: AppColors.softBrown,
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final episode = allEpisodes[index];
                    final isCompleted = context.read<AppState>().isDayCompleted(
                      episode.id,
                    );
                    // Day 1 is always open; every later day requires the
                    // previous one to be completed first.
                    final isLocked =
                        index > 0 &&
                        !context.read<AppState>().isDayCompleted(
                          allEpisodes[index - 1].id,
                        );
                    return _DayTile(
                      episode: episode,
                      journey: journey,
                      isTelugu: isTelugu,
                      isCompleted: isCompleted,
                      isLocked: isLocked,
                    );
                  }, childCount: allEpisodes.length),
                ),
        ],
      ),
    );
  }
}

class _DayTile extends StatelessWidget {
  final Episode episode;
  final Journey journey;
  final bool isTelugu;
  final bool isCompleted;
  final bool isLocked;

  const _DayTile({
    required this.episode,
    required this.journey,
    required this.isTelugu,
    required this.isCompleted,
    required this.isLocked,
  });

  @override
  Widget build(BuildContext context) {
    final dayLabel = isTelugu
        ? 'రోజు ${episode.dayNumber}'
        : 'Day ${episode.dayNumber}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      child: Opacity(
        opacity: isLocked ? 0.55 : 1,
        child: Material(
          color: const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () {
              if (isLocked) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isTelugu
                          ? 'ముందు రోజులను పూర్తి చేయండి'
                          : 'Complete the previous day first',
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => StoryReaderScreen(
                    journey: journey,
                    episode: episode,
                    reviewAfterReading: isCompleted,
                  ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFEADCC2)),
              ),
              child: Row(
                children: [
                  // Day number badge
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: const Alignment(-0.4, -1.0),
                        end: const Alignment(0.4, 1.0),
                        colors: isLocked
                            ? [Colors.grey.shade400, Colors.grey.shade600]
                            : isCompleted
                            ? [Colors.green.shade400, Colors.green.shade700]
                            : [
                                const Color(0xFFF6C25A),
                                const Color(0xFFD0641C),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    alignment: Alignment.center,
                    child: isLocked
                        ? const Icon(Icons.lock, color: Colors.white, size: 18)
                        : isCompleted
                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                        : Text(
                            '${episode.dayNumber}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(width: 14),
                  // Day info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          dayLabel,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF6B1F22),
                            fontFamily: 'Noto Sans Telugu',
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          episode.title,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Color(0xFF8B7660),
                            fontFamily: 'Noto Sans Telugu',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Action buttons
                  if (isLocked)
                    const Icon(
                      Icons.lock_outline,
                      color: Color(0xFF9A876E),
                      size: 26,
                    )
                  else if (isCompleted)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // View Quiz Results label
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFBEAD2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isTelugu ? 'ఫలితాలు' : 'Results',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFFE0701C),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 28,
                        ),
                      ],
                    )
                  else
                    const Icon(
                      Icons.play_circle_fill,
                      color: Color(0xFFE0701C),
                      size: 28,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
