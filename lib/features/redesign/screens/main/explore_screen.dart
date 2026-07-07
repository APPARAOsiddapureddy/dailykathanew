import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';

class ExploreScreen extends StatelessWidget {
  const ExploreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

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
          TextField(
            decoration: InputDecoration(
              hintText: isTelugu ? 'కథలు, పాత్రలు వెతకండి' : 'Search stories, characters',
              prefixIcon: const Icon(Icons.search, color: AppColors.softBrown),
              filled: true,
              fillColor: AppColors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
          const SizedBox(height: 32),
          Text(
            isTelugu ? 'మీ ఇతిహాసాలు' : 'Your Epics',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.sacredMaroon,
            ),
          ),
          const SizedBox(height: 16),
          ...state.currentJourneys.map((journey) {
            final isStarted = journey.id == 'ramayanam';
            return Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.sacredMaroon.withOpacity(0.1)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(journey.coverAsset, width: 80, height: 80, fit: BoxFit.cover),
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
                            isStarted
                                ? (isTelugu ? 'రోజు 12 / 100' : 'Day 12 / 100')
                                : (isTelugu
                                    ? '${journey.totalDays} రోజులు · ఇంకా ప్రారంభించలేదు'
                                    : '${journey.totalDays} Days · Not Started'),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.softBrown,
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (!isStarted)
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                isTelugu ? 'ప్రారంభించు' : 'Start',
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
            );
          }).toList(),
          const SizedBox(height: 32),
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
              _Chip(isTelugu ? 'పురాణాలు' : 'Puranas'),
              _Chip(isTelugu ? 'భక్తుల కథలు' : 'Devotee Stories'),
              _Chip(isTelugu ? 'ఆలయ కథలు' : 'Temple Stories'),
              _Chip(isTelugu ? 'నీతి కథలు' : 'Moral Stories'),
            ],
          ),
        ],
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  const _Chip(this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.ivoryLight,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.softBrown.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: const TextStyle(color: AppColors.softBrown),
      ),
    );
  }
}
