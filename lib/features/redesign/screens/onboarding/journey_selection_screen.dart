import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import 'reminder_screen.dart';

class JourneySelectionScreen extends StatelessWidget {
  const JourneySelectionScreen({super.key});

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
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              Text(
                isTelugu ? 'మీ మొదటి ప్రయాణం' : 'Choose your first journey',
                style: const TextStyle(
                  fontSize: 32,
                  color: AppColors.sacredMaroon,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Serif Telugu',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              Expanded(
                child: ListView.separated(
                  itemCount: state.currentJourneys.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final journey = state.currentJourneys[index];
                    return _JourneyCard(
                      journey: journey,
                      onTap: () {
                        Navigator.of(context).pushReplacement(
                          MaterialPageRoute(builder: (_) => const ReminderScreen()),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _JourneyCard extends StatelessWidget {
  final Journey journey;
  final VoidCallback onTap;

  const _JourneyCard({required this.journey, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Stack(
            children: [
              Positioned.fill(
                child: journey.coverAsset.startsWith('http')
                    ? Image.network(
                        journey.coverAsset,
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.3),
                        colorBlendMode: BlendMode.darken,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/mahabharatam-cover.png',
                          fit: BoxFit.cover,
                          color: Colors.black.withValues(alpha: 0.3),
                          colorBlendMode: BlendMode.darken,
                        ),
                      )
                    : Image.asset(
                        journey.coverAsset,
                        fit: BoxFit.cover,
                        color: Colors.black.withValues(alpha: 0.3),
                        colorBlendMode: BlendMode.darken,
                      ),
              ),
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'ॐ',
                      style: TextStyle(
                        fontSize: 24,
                        color: AppColors.templeGold,
                        fontFamily: 'Noto Serif Telugu',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      journey.title,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppColors.white,
                        fontFamily: 'Noto Serif Telugu',
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${journey.totalDays} రోజులు · ${journey.partNamePlural}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.warmIvory,
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
