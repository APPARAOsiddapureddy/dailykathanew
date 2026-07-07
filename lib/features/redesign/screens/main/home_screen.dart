import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../story/universe_detail_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;
    final activeJourney = state.activeJourney;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.only(left: 20, right: 20, top: 8, bottom: 8),
        children: [
          // ── Top bar: OM logo + title + streak (NO search) ──
          Row(
            children: [
              // OM icon in gradient rounded square
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
              // Title
              Text(
                isTelugu ? 'డైలీ కథ' : 'Daily Katha',
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Noto Serif Telugu',
                  color: Color(0xFF6B1F22),
                ),
              ),
              const Spacer(),
              // Streak badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEAD2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: const Color(0xFFEAD3A8),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_fire_department,
                      size: 15,
                      color: Color(0xFFE0701C),
                    ),
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
            isTelugu ? 'ప్రియ గారు 🪔' : 'Priya Sharma 🪔',
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
                  builder: (_) =>
                      UniverseDetailScreen(journey: activeJourney),
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
                          // Tag pill
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
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

                          // Journey title
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

                          // Sub info
                          Text(
                            isTelugu
                                ? 'అయోధ్య కాండం · రోజు 12'
                                : 'Ayodhya Kanda · Day 12',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'Noto Sans Telugu',
                              color: Color(0xFFF6D8A6),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Progress bar row
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 7,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFFF0D6)
                                        .withValues(alpha: 0.28),
                                    borderRadius: BorderRadius.circular(99),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: FractionallySizedBox(
                                    widthFactor: 0.12,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFFFFE0A0),
                                            Color(0xFFFFF3DC),
                                          ],
                                        ),
                                        borderRadius:
                                            BorderRadius.circular(99),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                '12/100',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFFFFF0D2),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),

                          // Continue button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => UniverseDetailScreen(
                                        journey: activeJourney),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFFFF6E7),
                                foregroundColor: const Color(0xFFB4480F),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 13),
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
              Text(
                isTelugu ? 'అన్నీ' : 'All',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Noto Sans Telugu',
                  color: Color(0xFFB07A2A),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ── Two explore cards side by side ──
          Row(
            children: [
              // Mahabharatam card — blue gradient
              Expanded(
                child: _ExploreCard(
                  title: isTelugu ? 'మహాభారతం' : 'Mahabharatam',
                  subtitle: isTelugu ? '180 రోజులు' : '180 Days',
                  subtitleColor: const Color(0xFFCFE0F2),
                  gradientColors: const [
                    Color(0xFF7FA8C9),
                    Color(0xFF3C5E86),
                    Color(0xFF1E2E4A),
                  ],
                  overlayColor: const Color(0xFF0F1428),
                ),
              ),
              const SizedBox(width: 12),
              // Bhagavatam card — green gradient
              Expanded(
                child: _ExploreCard(
                  title: isTelugu ? 'భాగవతం' : 'Bhagavatam',
                  subtitle: isTelugu ? '120 రోజులు' : '120 Days',
                  subtitleColor: const Color(0xFFCDEBD8),
                  gradientColors: const [
                    Color(0xFF8FCFA8),
                    Color(0xFF3E8C63),
                    Color(0xFF1C4A34),
                  ],
                  overlayColor: const Color(0xFF0C241A),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExploreCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Color subtitleColor;
  final List<Color> gradientColors;
  final Color overlayColor;

  const _ExploreCard({
    required this.title,
    required this.subtitle,
    required this.subtitleColor,
    required this.gradientColors,
    required this.overlayColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 132,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Radial gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: const Alignment(0.0, -0.76),
                    radius: 1.2,
                    colors: gradientColors,
                    stops: const [0.0, 0.65, 1.0],
                  ),
                ),
              ),
            ),
            // Dark bottom overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      overlayColor.withValues(alpha: 0.9),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.6],
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
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Noto Sans Telugu',
                      color: subtitleColor,
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
