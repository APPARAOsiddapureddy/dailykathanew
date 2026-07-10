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
                  _initials(state.userName),
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
                      _joinedLabel(state.joinedAt, isTelugu),
                      style: const TextStyle(color: AppColors.softBrown),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StatWidget(
                value: '${state.completedDays}',
                label: isTelugu ? 'రోజులు' : 'Days',
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.softBrown.withValues(alpha: 0.2),
              ),
              _StatWidget(
                value: '${state.streak}',
                label: isTelugu ? 'వరుస' : 'Streak',
                subtitle: isTelugu
                    ? 'అత్యుత్తమం: ${state.highestStreak}'
                    : 'Best: ${state.highestStreak}',
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.softBrown.withValues(alpha: 0.2),
              ),
              _StatWidget(
                value: '${state.storiesStarted}',
                label: isTelugu ? 'ఇతిహాసం' : 'Epic',
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.softBrown.withValues(alpha: 0.2),
              ),
              _StatWidget(
                value: '${state.points}',
                label: isTelugu ? 'పాయింట్లు' : 'Points',
              ),
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
              border: Border.all(
                color: AppColors.sacredMaroon.withValues(alpha: 0.1),
              ),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: state.activeJourney.coverAsset.startsWith('http')
                      ? Image.network(
                          state.activeJourney.coverAsset,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/mahabharatam-cover.png',
                            width: 60,
                            height: 60,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Image.asset(
                          state.activeJourney.coverAsset,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                        ),
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
                        '${state.getCompletedDaysForStory(state.activeJourney.id)}/${state.activeJourney.totalDays}',
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
            icon: Icons.workspace_premium,
            title: isTelugu ? 'సబ్‌స్క్రిప్షన్' : 'Subscription',
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
            ),
          ),
          _ProfileMenuTile(
            icon: Icons.settings_outlined,
            title: isTelugu ? 'సెట్టింగ్‌లు' : 'Settings',
            onTap: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
          ),
        ],
      ),
    );
  }
}

class _StatWidget extends StatelessWidget {
  final String value;
  final String label;
  final String? subtitle;

  const _StatWidget({required this.value, required this.label, this.subtitle});

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
        Text(label, style: const TextStyle(color: AppColors.softBrown)),
        if (subtitle != null)
          Text(
            subtitle!,
            style: const TextStyle(fontSize: 11, color: AppColors.softBrown),
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
        style: const TextStyle(fontSize: 18, color: AppColors.sacredMaroon),
      ),
      trailing: const Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AppColors.softBrown,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
    );
  }
}

String _initials(String name) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.length >= 2
      ? trimmed.substring(0, 2)
      : trimmed.substring(0, 1);
}

const _enMonths = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];
const _teMonths = [
  'జన',
  'ఫిబ్ర',
  'మార్చి',
  'ఏప్రి',
  'మే',
  'జూన్',
  'జూలై',
  'ఆగ',
  'సెప్టెం',
  'అక్టో',
  'నవం',
  'డిసెం',
];

String _joinedLabel(DateTime? joinedAt, bool isTelugu) {
  if (joinedAt == null) {
    return isTelugu ? 'తెలుగు' : 'English';
  }
  final month = joinedAt.month - 1;
  return isTelugu
      ? 'తెలుగు · ${_teMonths[month]} ${joinedAt.year} నుండి'
      : 'English · Since ${_enMonths[month]} ${joinedAt.year}';
}
