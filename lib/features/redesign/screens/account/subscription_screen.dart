import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';

class SubscriptionScreen extends StatelessWidget {
  const SubscriptionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(title: Text(isTelugu ? 'ప్రీమియం' : 'Premium')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isTelugu ? 'డైలీ కథ ప్రీమియం' : 'Daily Katha Premium',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: AppColors.sacredMaroon,
                fontFamily: 'Noto Serif Telugu',
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              isTelugu
                  ? 'అన్ని ఇతిహాసాలు, ప్రకటనలు లేకుండా'
                  : 'All Epics, Ad-Free',
              style: const TextStyle(fontSize: 16, color: AppColors.softBrown),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _FeatureRow(
              isTelugu
                  ? 'అన్ని ఇతిహాసాలకు పూర్తి ప్రవేశం'
                  : 'Full access to all epics',
            ),
            _FeatureRow(
              isTelugu
                  ? 'ప్రకటనలు లేని ప్రశాంత పఠనం'
                  : 'Peaceful reading without ads',
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
              decoration: BoxDecoration(
                color: AppColors.ivoryLight,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.templeGold, width: 1.5),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.hourglass_top,
                    color: AppColors.deepSaffron,
                    size: 40,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    isTelugu ? 'త్వరలో వస్తుంది' : 'Coming Soon',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.sacredMaroon,
                      fontFamily: 'Noto Serif Telugu',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isTelugu
                        ? 'ప్రస్తుతం అన్ని కథలు ఉచితం. ప్రీమియం ప్లాన్‌లు త్వరలో అందుబాటులోకి వస్తాయి.'
                        : 'All stories are free for now. Premium plans will be available soon.',
                    style: const TextStyle(
                      color: AppColors.softBrown,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
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

class _FeatureRow extends StatelessWidget {
  final String text;
  const _FeatureRow(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          const Icon(
            Icons.check_circle,
            color: AppColors.deepSaffron,
            size: 20,
          ),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(fontSize: 16, color: AppColors.sacredMaroon),
          ),
        ],
      ),
    );
  }
}
