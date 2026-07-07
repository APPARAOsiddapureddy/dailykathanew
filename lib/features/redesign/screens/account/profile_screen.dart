import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import 'settings_screen.dart';
import 'subscription_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.ivoryLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  isTelugu ? 'ప్రి' : 'Pri',
                  style: const TextStyle(
                    fontSize: 32,
                    color: AppColors.deepSaffron,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sacredMaroon,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isTelugu ? 'తెలుగు · జనవరి 2025 నుండి' : 'English · Since Jan 2025',
                      style: const TextStyle(
                        color: AppColors.softBrown,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatWidget(value: '12', label: isTelugu ? 'రోజులు' : 'Days'),
              Container(width: 1, height: 40, color: AppColors.softBrown.withOpacity(0.2)),
              _StatWidget(value: '12', label: isTelugu ? 'వరుస' : 'Streak'),
              Container(width: 1, height: 40, color: AppColors.softBrown.withOpacity(0.2)),
              _StatWidget(value: '1', label: isTelugu ? 'ఇతిహాసం' : 'Epic'),
            ],
          ),
          const SizedBox(height: 48),
          Text(
            isTelugu ? 'కొనసాగుతున్న ప్రయాణం' : 'Ongoing Journey',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.sacredMaroon,
            ),
          ),
          const SizedBox(height: 16),
          Container(
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
                  child: Image.asset(state.activeJourney.coverAsset, width: 60, height: 60, fit: BoxFit.cover),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ॐ ${state.activeJourney.title}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.sacredMaroon,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isTelugu ? '12/100' : '12/100',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.softBrown,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          _ProfileMenuTile(
            icon: Icons.favorite_border,
            title: isTelugu ? 'ఇష్టమైనవి' : 'Favorites',
          ),
          _ProfileMenuTile(
            icon: Icons.history,
            title: isTelugu ? 'చరిత్ర' : 'History',
          ),
          _ProfileMenuTile(
            icon: Icons.workspace_premium,
            title: isTelugu ? 'సబ్‌స్క్రిప్షన్' : 'Subscription',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SubscriptionScreen())),
          ),
          _ProfileMenuTile(
            icon: Icons.settings_outlined,
            title: isTelugu ? 'సెట్టింగ్‌లు' : 'Settings',
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String value;
  final String label;

  const _StatWidget({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.sacredMaroon,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.softBrown,
          ),
        ),
      ],
    );
  }
}

class _ProfileMenuTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  const _ProfileMenuTile({required this.icon, required this.title, this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.deepSaffron),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          color: AppColors.sacredMaroon,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.softBrown),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }
}
