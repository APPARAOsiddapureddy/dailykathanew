import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../app/config.dart';
import '../../data/mock_data.dart';
import '../onboarding/language_screen.dart';
import '../auth/auth_screens.dart';
import 'subscription_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  static final Uri _privacyPolicyUri = Uri.parse(
    '${AppConfig.apiBaseUrl}/privacy-policy',
  );

  Future<void> _logout(BuildContext context) async {
    await context.read<AppState>().logout();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
        (route) => false,
      );
    }
  }

  Future<void> _openPrivacyPolicy(BuildContext context) async {
    final opened = await launchUrl(
      _privacyPolicyUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to open privacy policy')),
      );
    }
  }

  Future<void> _deleteAccount(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete account?'),
        content: const Text(
          'This will permanently delete your account and sign you out.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await context.read<AppState>().deleteAccount();
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const PhoneLoginScreen()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    return Scaffold(
      backgroundColor: const Color(0xFFFAF4E8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: Color(0xFF6B1F22),
            size: 22,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          isTelugu ? 'సెట్టింగ్‌లు' : 'Settings',
          style: const TextStyle(
            color: Color(0xFF6B1F22),
            fontSize: 26,
            fontFamily: 'Noto Serif Telugu',
            fontWeight: FontWeight.w400,
          ),
        ),
        titleSpacing: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        children: [
          _SectionHeader(title: isTelugu ? 'ప్రాధాన్యతలు' : 'Preferences'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFEADCC2)),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.language,
                  title: isTelugu ? 'భాష' : 'Language',
                  trailingText: isTelugu ? 'తెలుగు' : 'English',
                  showBottomBorder: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LanguageScreen()),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.notifications_none,
                  title: isTelugu ? 'నోటిఫికేషన్‌లు' : 'Notifications',
                  trailingWidget: Container(
                    width: 44,
                    height: 26,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE0701C),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Stack(
                      children: [
                        Positioned(
                          right: 3,
                          top: 3,
                          child: Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFFFFF6E7),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  showBottomBorder: true,
                ),
                _SettingsTile(
                  icon: Icons.access_time,
                  title: isTelugu ? 'గుర్తు సమయం' : 'Reminder Time',
                  trailingText: isTelugu ? 'ఉదయం 7:00' : '7:00 AM',
                  showBottomBorder: false,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          _SectionHeader(title: isTelugu ? 'ఖాతా' : 'Account'),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF8),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: const Color(0xFFEADCC2)),
            ),
            child: Column(
              children: [
                _SettingsTile(
                  icon: Icons.workspace_premium_outlined,
                  title: isTelugu ? 'సబ్‌స్క్రిప్షన్' : 'Subscription',
                  trailingWidget: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBEAD2),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isTelugu ? 'ఉచితం' : 'Free',
                      style: const TextStyle(
                        color: Color(0xFF8A5A14),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Noto Sans Telugu',
                      ),
                    ),
                  ),
                  showBottomBorder: true,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const SubscriptionScreen(),
                      ),
                    );
                  },
                ),
                _SettingsTile(
                  icon: Icons.person_outline,
                  title: isTelugu ? 'ప్రొఫైల్ సవరించు' : 'Edit Profile',
                  showBottomBorder: true,
                ),
                _SettingsTile(
                  icon: Icons.download_outlined,
                  title: isTelugu ? 'డౌన్‌లోడ్‌లు' : 'Downloads',
                  showBottomBorder: false,
                ),
                _SettingsTile(
                  icon: Icons.privacy_tip_outlined,
                  title: isTelugu ? 'గోప్యతా విధానం' : 'Privacy Policy',
                  showBottomBorder: true,
                  onTap: () => _openPrivacyPolicy(context),
                ),
                _SettingsTile(
                  icon: Icons.delete_forever_outlined,
                  title: isTelugu ? 'ఖాతా తొలగించు' : 'Delete Account',
                  showBottomBorder: false,
                  iconColor: const Color(0xFFB3261E),
                  titleColor: const Color(0xFFB3261E),
                  onTap: () => _deleteAccount(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          TextButton(
            onPressed: () => _logout(context),
            style: TextButton.styleFrom(
              backgroundColor: const Color(0xFFFBEFEC),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: const BorderSide(color: Color(0xFFE7C9C0)),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: Text(
              isTelugu ? 'లాగ్ అవుట్' : 'Log Out',
              style: const TextStyle(
                color: Color(0xFF98332B),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                fontFamily: 'Noto Sans Telugu',
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
      padding: const EdgeInsets.only(top: 6, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Color(0xFFB07A2A),
          letterSpacing: 0.48, // 0.04em
          fontFamily: 'Noto Sans Telugu',
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailingText;
  final Widget? trailingWidget;
  final bool showBottomBorder;
  final VoidCallback? onTap;
  final Color? iconColor;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    this.trailingText,
    this.trailingWidget,
    this.showBottomBorder = true,
    this.onTap,
    this.iconColor,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          border: showBottomBorder
              ? const Border(bottom: BorderSide(color: Color(0xFFF0E7D5)))
              : null,
        ),
        child: Row(
          children: [
            Icon(icon, color: iconColor ?? const Color(0xFFC05A12), size: 19),
            const SizedBox(width: 13),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: titleColor ?? const Color(0xFF3F2E1E),
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Noto Sans Telugu',
                ),
              ),
            ),
            if (trailingText != null) ...[
              Text(
                trailingText!,
                style: const TextStyle(
                  color: Color(0xFF9A876E),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  fontFamily: 'Noto Sans Telugu',
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (trailingWidget != null) ...[
              trailingWidget!,
              const SizedBox(width: 8),
            ],
            if (trailingWidget == null)
              const Icon(
                Icons.arrow_forward_ios,
                color: Color(0xFFC7B394),
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}
