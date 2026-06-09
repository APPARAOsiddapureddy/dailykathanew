import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_states.dart';
import '../data/app_api_service.dart';
import '../models/story_models.dart';
import '../widgets/story_cards.dart';
import 'day_reader_screen.dart';

class StoryDetailScreen extends StatelessWidget {
  const StoryDetailScreen({super.key, required this.api, required this.story});

  final AppApiService api;
  final Story story;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              expandedHeight: 260,
              title: Text(story.title),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    KathaNetworkImage(url: story.coverImageUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC2B1A12)],
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 22,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            story.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              height: 1.16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          if (story.description.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              story.description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFFFFF7E6),
                                fontSize: 15,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (story.days.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: EmptyState(
                  icon: Icons.event_busy_rounded,
                  title: 'No published days',
                  message:
                      'When days are published in the CMS, they will show here.',
                ),
              )
            else ...[
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Published Days',
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                      ),
                      _CountPill(count: story.days.length),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                sliver: SliverList.separated(
                  itemBuilder: (context, index) {
                    final day = story.days[index];
                    return DayCard(
                      day: day,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => DayReaderScreen(
                              api: api,
                              story: story,
                              day: day,
                            ),
                          ),
                        );
                      },
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: story.days.length,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7B3),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.6)),
      ),
      child: Text(
        '$count days',
        style: const TextStyle(
          color: AppColors.deepSaffron,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
