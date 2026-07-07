import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import '../onboarding/language_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(isTelugu ? 'సెట్టింగ్‌లు' : 'Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          _SectionHeader(title: isTelugu ? 'ప్రాధాన్యతలు' : 'Preferences'),
          ListTile(
            title: Text(isTelugu ? 'భాష' : 'Language'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  isTelugu ? 'తెలుగు' : 'English',
                  style: const TextStyle(color: AppColors.softBrown),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios, size: 16),
              ],
            ),
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LanguageScreen()));
            },
          ),
          const Divider(),
          _SectionHeader(title: isTelugu ? 'నోటిఫికేషన్‌లు' : 'Notifications'),
          ListTile(
            title: Text(isTelugu ? 'గుర్తు సమయం' : 'Reminder Time'),
            trailing: Text(
              isTelugu ? 'ఉదయం 7:00' : '7:00 AM',
              style: const TextStyle(color: AppColors.softBrown),
            ),
            onTap: () {},
          ),
          const Divider(),
          _SectionHeader(title: isTelugu ? 'ఖాతా' : 'Account'),
          ListTile(
            title: Text(isTelugu ? 'సబ్‌స్క్రిప్షన్' : 'Subscription'),
            trailing: Text(
              isTelugu ? 'ఉచితం' : 'Free',
              style: const TextStyle(color: AppColors.softBrown),
            ),
            onTap: () {},
          ),
          ListTile(
            title: Text(isTelugu ? 'ప్రొఫైల్ సవరించు' : 'Edit Profile'),
            onTap: () {},
          ),
          ListTile(
            title: Text(isTelugu ? 'డౌన్‌లోడ్‌లు' : 'Downloads'),
            onTap: () {},
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: () {},
            child: Text(
              isTelugu ? 'లాగ్ అవుట్' : 'Log Out',
              style: const TextStyle(
                color: Colors.red,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: AppColors.deepSaffron,
        ),
      ),
    );
  }
}
