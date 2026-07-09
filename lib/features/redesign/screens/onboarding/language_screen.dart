import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import 'journey_selection_screen.dart';

class LanguageScreen extends StatefulWidget {
  /// True when reached from the first-run onboarding flow (should continue
  /// on to picking a journey). False when reopened later, e.g. from
  /// Settings, where changing the language should just go back.
  final bool isOnboarding;

  const LanguageScreen({super.key, this.isOnboarding = true});

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late AppLanguage? _selectedLanguage;

  @override
  void initState() {
    super.initState();
    _selectedLanguage = context.read<AppState>().language;
  }

  void _continue() {
    if (_selectedLanguage == null) return;

    context.read<AppState>().setLanguage(_selectedLanguage!);
    if (widget.isOnboarding) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const JourneySelectionScreen()),
      );
    } else {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 48),
              const Text(
                'మీ భాషను ఎంచుకోండి',
                style: TextStyle(
                  fontSize: 32,
                  color: AppColors.sacredMaroon,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Noto Serif Telugu',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Choose your language · మీరు దీన్ని తర్వాత మార్చవచ్చు',
                style: TextStyle(fontSize: 14, color: AppColors.softBrown),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 48),
              _LanguageCard(
                title: 'తెలుగు',
                subtitle: 'Telugu',
                isSelected: _selectedLanguage == AppLanguage.telugu,
                onTap: () =>
                    setState(() => _selectedLanguage = AppLanguage.telugu),
              ),
              const SizedBox(height: 16),
              _LanguageCard(
                title: 'English',
                subtitle: 'ఇంగ్లీష్',
                isSelected: _selectedLanguage == AppLanguage.english,
                onTap: () =>
                    setState(() => _selectedLanguage = AppLanguage.english),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: _selectedLanguage != null ? _continue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _selectedLanguage != null
                      ? AppColors.deepSaffron
                      : AppColors.greyText.withValues(alpha: 0.3),
                ),
                child: const Text('కొనసాగించండి'),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _LanguageCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _LanguageCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 24),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.ivoryLight : AppColors.white,
          border: Border.all(
            color: isSelected ? AppColors.deepSaffron : Colors.transparent,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? AppColors.deepSaffron
                        : AppColors.sacredMaroon,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 16,
                    color: AppColors.softBrown,
                  ),
                ),
              ],
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.deepSaffron,
                size: 32,
              ),
          ],
        ),
      ),
    );
  }
}
