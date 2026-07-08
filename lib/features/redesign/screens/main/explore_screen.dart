import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import '../story/universe_detail_screen.dart';

enum StoryFilter { all, started, completed, notStarted }

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  StoryFilter _activeFilter = StoryFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    // Filter journeys based on search and filter
    final allJourneys = state.currentJourneys;
    final filteredJourneys = allJourneys.where((journey) {
      // Search filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        if (!journey.title.toLowerCase().contains(query) &&
            !journey.description.toLowerCase().contains(query) &&
            !journey.categoryName.toLowerCase().contains(query)) {
          return false;
        }
      }
      // Status filter using real progress data
      final progress = state.getStoryProgress(journey.id);
      final hasStarted = progress != null;
      final isCompleted = progress?.isCompleted ?? false;

      switch (_activeFilter) {
        case StoryFilter.all:
          return true;
        case StoryFilter.started:
          return hasStarted && !isCompleted;
        case StoryFilter.completed:
          return isCompleted;
        case StoryFilter.notStarted:
          return !hasStarted;
      }
    }).toList();

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Text(
            isTelugu ? 'అన్వేషించండి' : 'Explore',
            style: const TextStyle(
              fontSize: 32,
              color: AppColors.sacredMaroon,
              fontWeight: FontWeight.bold,
              fontFamily: 'Noto Serif Telugu',
            ),
          ),
          const SizedBox(height: 24),

          // ── Search bar ──
          TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() => _searchQuery = value.trim());
            },
            decoration: InputDecoration(
              hintText: isTelugu ? 'కథలు, పాత్రలు వెతకండి' : 'Search stories, characters',
              prefixIcon: const Icon(Icons.search, color: AppColors.softBrown),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, color: AppColors.softBrown, size: 20),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),

          const SizedBox(height: 16),

          // ── Filter chips ──
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _FilterChip(
                  label: isTelugu ? 'అన్నీ' : 'All',
                  isActive: _activeFilter == StoryFilter.all,
                  onTap: () => setState(() => _activeFilter = StoryFilter.all),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: isTelugu ? 'ప్రారంభించినవి' : 'Started',
                  isActive: _activeFilter == StoryFilter.started,
                  onTap: () => setState(() => _activeFilter = StoryFilter.started),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: isTelugu ? 'పూర్తయినవి' : 'Completed',
                  isActive: _activeFilter == StoryFilter.completed,
                  onTap: () => setState(() => _activeFilter = StoryFilter.completed),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: isTelugu ? 'ప్రారంభించలేదు' : 'Not Started',
                  isActive: _activeFilter == StoryFilter.notStarted,
                  onTap: () => setState(() => _activeFilter = StoryFilter.notStarted),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Section header ──
          Text(
            isTelugu ? 'మీ ఇతిహాసాలు' : 'Your Epics',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.sacredMaroon,
            ),
          ),
          const SizedBox(height: 16),

          // ── Story list ──
          if (filteredJourneys.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(
                child: Column(
                  children: [
                    const Icon(Icons.search_off, size: 48, color: AppColors.softBrown),
                    const SizedBox(height: 12),
                    Text(
                      isTelugu ? 'ఫలితాలు కనుగొనబడలేదు' : 'No stories found',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.softBrown,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...filteredJourneys.map((journey) {
              final progress = state.getStoryProgress(journey.id);
              final hasStarted = progress != null;
              final isCompleted = progress?.isCompleted ?? false;
              final daysCompleted = progress?.completedDaysCount ?? 0;

              // Build status text
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
                      border: Border.all(color: AppColors.sacredMaroon.withValues(alpha: 0.1)),
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: journey.coverAsset.startsWith('http')
                              ? Image.network(
                                  journey.coverAsset,
                                  width: 80, height: 80, fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Image.asset(
                                    'assets/mahabharatam-cover.png',
                                    width: 80, height: 80, fit: BoxFit.cover,
                                  ),
                                )
                              : Image.asset(journey.coverAsset, width: 80, height: 80, fit: BoxFit.cover),
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
                                style: TextStyle(
                                  fontSize: 14,
                                  color: statusColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => UniverseDetailScreen(journey: journey),
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
            }),

          const SizedBox(height: 32),

          // ── Coming Soon ──
          Text(
            isTelugu ? 'త్వరలో' : 'Coming Soon',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.sacredMaroon,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _ComingSoonChip(isTelugu ? 'పురాణాలు' : 'Puranas'),
              _ComingSoonChip(isTelugu ? 'భక్తుల కథలు' : 'Devotee Stories'),
              _ComingSoonChip(isTelugu ? 'ఆలయ కథలు' : 'Temple Stories'),
              _ComingSoonChip(isTelugu ? 'నీతి కథలు' : 'Moral Stories'),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFE0701C) : const Color(0xFFFFFDF8),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
            color: isActive ? const Color(0xFFE0701C) : const Color(0xFFEADCC2),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            fontFamily: 'Noto Sans Telugu',
            color: isActive ? Colors.white : const Color(0xFF8B7660),
          ),
        ),
      ),
    );
  }
}

class _ComingSoonChip extends StatelessWidget {
  final String label;
  const _ComingSoonChip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ivoryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBrown.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.softBrown),
      ),
    );
  }
}
