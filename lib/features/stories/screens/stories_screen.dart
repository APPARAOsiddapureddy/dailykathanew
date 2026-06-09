import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_logo.dart';
import '../../../core/widgets/app_states.dart';
import '../data/app_api_service.dart';
import '../models/story_models.dart';
import '../widgets/story_cards.dart';
import 'story_detail_screen.dart';

class StoriesScreen extends StatefulWidget {
  const StoriesScreen({super.key, required this.api});

  final AppApiService api;

  @override
  State<StoriesScreen> createState() => _StoriesScreenState();
}

class _StoriesScreenState extends State<StoriesScreen> {
  late Future<List<Story>> _storiesFuture;

  @override
  void initState() {
    super.initState();
    _storiesFuture = widget.api.fetchStories();
  }

  void _reload() {
    setState(() {
      _storiesFuture = widget.api.fetchStories();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: FutureBuilder<List<Story>>(
          future: _storiesFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AppLoading(message: 'Loading stories...');
            }

            if (snapshot.hasError) {
              return ErrorState(message: '${snapshot.error}', onRetry: _reload);
            }

            final stories = snapshot.data ?? const <Story>[];
            if (stories.isEmpty) {
              return EmptyState(
                icon: Icons.auto_stories_rounded,
                title: 'No stories published yet',
                message: 'Published stories from your CMS will appear here.',
                action: FilledButton.icon(
                  onPressed: _reload,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Refresh'),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.saffron,
              onRefresh: () async => _reload(),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: _Header(storiesCount: stories.length),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                    sliver: SliverList.separated(
                      itemBuilder: (context, index) {
                        final story = stories[index];
                        return StoryCard(
                          story: story,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => StoryDetailScreen(
                                  api: widget.api,
                                  story: story,
                                ),
                              ),
                            );
                          },
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemCount: stories.length,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.storiesCount});

  final int storiesCount;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const AppLogo(size: 58),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily Katha',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'ప్రతి రోజు ఒక కథ, ఒక మంచి పాఠం',
                      style: TextStyle(
                        color: AppColors.mutedBrown,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                colors: [Color(0xFFFFE9B8), Color(0xFFFFF9EE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              border: Border.all(color: Color(0x77F5C542)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Today’s Katha',
                  style: TextStyle(
                    color: AppColors.deepSaffron,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose a story journey and continue day by day.',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  '$storiesCount story ${storiesCount == 1 ? 'world' : 'worlds'} available',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
