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
      appBar: AppBar(
        title: Text(isTelugu ? 'ప్రీమియం' : 'Premium'),
      ),
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
              isTelugu ? 'అన్ని ఇతిహాసాలు, ప్రకటనలు లేకుండా' : 'All Epics, Ad-Free',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.softBrown,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _FeatureRow(isTelugu ? 'అన్ని ఇతిహాసాలకు పూర్తి ప్రవేశం' : 'Full access to all epics'),
            _FeatureRow(isTelugu ? 'ప్రకటనలు లేని ప్రశాంత పఠనం' : 'Peaceful reading without ads'),
            _FeatureRow(isTelugu ? 'ఆఫ్‌లైన్ డౌన్‌లోడ్' : 'Offline downloads'),
            const SizedBox(height: 32),
            _PlanCard(
              title: isTelugu ? 'వార్షికం' : 'Yearly',
              subtitle: isTelugu ? 'నెలకు కేవలం ₹67' : 'Only ₹67/mo',
              price: '₹799',
              period: isTelugu ? '/సం' : '/yr',
              badge: isTelugu ? 'అత్యుత్తమ విలువ · 33% ఆదా' : 'Best Value · Save 33%',
              isSelected: true,
            ),
            const SizedBox(height: 16),
            _PlanCard(
              title: isTelugu ? 'నెలవారీ' : 'Monthly',
              subtitle: isTelugu ? 'ఎప్పుడైనా రద్దు చేయవచ్చు' : 'Cancel anytime',
              price: '₹99',
              period: isTelugu ? '/నెల' : '/mo',
            ),
            const SizedBox(height: 16),
            _PlanCard(
              title: isTelugu ? 'కుటుంబం' : 'Family',
              subtitle: isTelugu ? '4 ప్రొఫైల్‌లు · ఒకే ఖాతా' : '4 profiles · One account',
              price: '₹1299',
              period: isTelugu ? '/సం' : '/yr',
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.templeGold,
                foregroundColor: AppColors.sacredMaroon,
              ),
              child: Text(isTelugu ? 'వార్షికం ఎంచుకోండి' : 'Choose Yearly'),
            ),
            const SizedBox(height: 16),
            Text(
              isTelugu ? 'పండుగ పాస్\nత్వరలో · ఎప్పుడైనా రద్దు చేయవచ్చు' : 'Festival Pass\nComing Soon · Cancel anytime',
              style: const TextStyle(color: AppColors.softBrown),
              textAlign: TextAlign.center,
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
          const Icon(Icons.check_circle, color: AppColors.deepSaffron, size: 20),
          const SizedBox(width: 12),
          Text(
            text,
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.sacredMaroon,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String price;
  final String period;
  final String? badge;
  final bool isSelected;

  const _PlanCard({
    required this.title,
    required this.subtitle,
    required this.price,
    required this.period,
    this.badge,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isSelected ? AppColors.ivoryLight : AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? AppColors.deepSaffron : AppColors.softBrown.withOpacity(0.2),
          width: 2,
        ),
      ),
      child: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.deepSaffron : AppColors.sacredMaroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: AppColors.softBrown,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      price,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? AppColors.deepSaffron : AppColors.sacredMaroon,
                      ),
                    ),
                    Text(
                      period,
                      style: const TextStyle(
                        color: AppColors.softBrown,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (badge != null)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: const BoxDecoration(
                  color: AppColors.deepSaffron,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(16),
                    topRight: Radius.circular(14),
                  ),
                ),
                child: Text(
                  badge!,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
