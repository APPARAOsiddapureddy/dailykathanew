import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import '../story/universe_detail_screen.dart';
import '../../widgets/story_list_card.dart';

class HomeScreen extends StatelessWidget {
  final VoidCallback? onNavigateToExplore;
  const HomeScreen({super.key, this.onNavigateToExplore});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;
    final activeJourney = state.activeJourney;
    final journeys = state.currentJourneys;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
        children: [
          // ── Top bar: OM logo + title + streak ──
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: const LinearGradient(
                    begin: Alignment(-0.4, -1.0),
                    end: Alignment(0.4, 1.0),
                    colors: [Color(0xFFE88A2A), Color(0xFFC0501B)],
                  ),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'ॐ',
                  style: TextStyle(
                    fontSize: 22,
                    fontFamily: 'Noto Serif Telugu',
                    fontWeight: FontWeight.w400,
                    color: Color(0xFFFFF3DC),
                    height: 1.0,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Daily Katha',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Noto Serif Telugu',
                  color: Color(0xFF6B1F22),
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEAD2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: const Color(0xFFEAD3A8), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.local_fire_department, size: 15, color: Color(0xFFE0701C)),
                    const SizedBox(width: 4),
                    Text(
                      '${state.streak}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFC05A12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ── Greeting ──
          Text(
            isTelugu ? 'నమస్కారం,' : 'Namaste,',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              fontFamily: 'Noto Sans Telugu',
              color: Color(0xFF8B7660),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${state.userName} 🪔',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              fontFamily: 'Noto Serif Telugu',
              color: Color(0xFF6B1F22),
            ),
          ),

          const SizedBox(height: 16),

          // ── Continue Journey Card ──
          GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => UniverseDetailScreen(journey: activeJourney),
                ),
              );
            },
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFA03C12).withValues(alpha: 0.18),
                    blurRadius: 26,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  children: [
                    // Gradient background
                    Positioned.fill(
                      child: Container(
                        decoration: const BoxDecoration(
                          gradient: RadialGradient(
                            center: Alignment(0.56, -0.76),
                            radius: 1.3,
                            colors: [
                              Color(0xFFF6C25A),
                              Color(0xFFD0641C),
                              Color(0xFF7A241A),
                            ],
                            stops: [0.0, 0.55, 1.0],
                          ),
                        ),
                      ),
                    ),

                    // Cover image overlay if available
                    if (activeJourney.coverAsset.startsWith('http'))
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.15,
                          child: Image.network(
                            activeJourney.coverAsset,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                      ),

                    // OM watermark
                    Positioned(
                      top: -6,
                      right: 14,
                      child: Text(
                        'ॐ',
                        style: TextStyle(
                          fontSize: 82,
                          fontFamily: 'Noto Serif Telugu',
                          fontWeight: FontWeight.w400,
                          color: const Color(0xFFFFF6E4).withValues(alpha: 0.28),
                          height: 1.0,
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: const Color(0xFF3C0F0C).withValues(alpha: 0.32),
                              borderRadius: BorderRadius.circular(99),
                            ),
                            child: Text(
                              isTelugu
                                  ? 'CONTINUE JOURNEY · మీ ప్రయాణం'
                                  : 'CONTINUE JOURNEY',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 2.0,
                                color: Color(0xFFFFE7BE),
                              ),
                            ),
                          ),

                          const SizedBox(height: 34),

                          Text(
                            activeJourney.title,
                            style: const TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'Noto Serif Telugu',
                              color: Color(0xFFFFF6E7),
                            ),
                          ),

                          const SizedBox(height: 2),

                          Text(
                            isTelugu
                                ? '${activeJourney.totalDays} రోజులు'
                                : '${activeJourney.totalDays} Days',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Noto Sans Telugu',
                              color: Color(0xFFF6D8A6),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Progress bar
                          Builder(
                            builder: (context) {
                              final daysCompleted = state.getCompletedDaysForStory(activeJourney.id);
                              return Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 7,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF0D6).withValues(alpha: 0.28),
                                        borderRadius: BorderRadius.circular(99),
                                      ),
                                      alignment: Alignment.centerLeft,
                                      child: FractionallySizedBox(
                                        widthFactor: activeJourney.totalDays > 0
                                            ? (daysCompleted / activeJourney.totalDays).clamp(0.0, 1.0)
                                            : 0.0,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            gradient: const LinearGradient(
                                              colors: [Color(0xFFFFE0A0), Color(0xFFFFF3DC)],
                                            ),
                                            borderRadius: BorderRadius.circular(99),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    '$daysCompleted/${activeJourney.totalDays}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Color(0xFFFFF0D2),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),

                          const SizedBox(height: 16),

                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UniverseDetailScreen(journey: activeJourney),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF6E7),
                                foregroundColor: const Color(0xFFB4480F),
                                padding: const EdgeInsets.symmetric(vertical: 13),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                elevation: 0,
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    isTelugu ? 'కొనసాగించండి' : 'Continue',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      fontFamily: 'Noto Sans Telugu',
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right, size: 17),
                                ],
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
          ),

          const SizedBox(height: 22),

          // ── Explore header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isTelugu ? 'అన్వేషించండి' : 'Explore',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Noto Serif Telugu',
                  color: Color(0xFF6B1F22),
                ),
              ),
              GestureDetector(
                onTap: onNavigateToExplore,
                child: Text(
                  isTelugu ? 'అన్నీ' : 'All',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Noto Sans Telugu',
                    color: Color(0xFFB07A2A),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Dynamic explore cards ──
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: journeys.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final journey = journeys[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => UniverseDetailScreen(journey: journey),
                      ),
                    );
                  },
                  child: _ExploreCard(
                    title: journey.title,
                    subtitle: isTelugu
                        ? '${journey.totalDays} రోజులు'
                        : '${journey.totalDays} Days',
                    coverImageUrl: journey.coverAsset.startsWith('http')
                        ? journey.coverAsset
                        : null,
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),

          // ── Vertical list section ──
          Text(
            isTelugu ? 'మీ ఇతిహాసాలు' : 'Your Epics',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.sacredMaroon,
              fontFamily: 'Noto Serif Telugu',
            ),
          ),
          const SizedBox(height: 16),
          ...journeys.map((journey) => StoryListCard(journey: journey)),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? coverImageUrl;

  const _ExploreCard({
    required this.title,
    required this.subtitle,
    this.coverImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Cover image
            Positioned.fill(
              child: coverImageUrl != null && coverImageUrl!.startsWith('http')
                  ? Image.network(
                      coverImageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/mahabharatam-cover.png',
                        fit: BoxFit.cover,
                      ),
                    )
                  : Image.asset(
                      coverImageUrl ?? 'assets/mahabharatam-cover.png',
                      fit: BoxFit.cover,
                    ),
            ),
            // Gradient Overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.black.withValues(alpha: 0.4),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.4, 0.8],
                  ),
                ),
              ),
            ),
            // Text
            Positioned(
              left: 12,
              bottom: 10,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Noto Serif Telugu',
                      color: Color(0xFFFFF6E7),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Noto Sans Telugu',
                      color: Color(0xFFCFE0F2),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
