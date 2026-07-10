import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';

/// Full Terms & Conditions, shown natively in-app (no external link).
/// Kept in English only — legal text is authoritative in one language
/// to avoid translation-accuracy risk.
class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isTelugu = context.watch<AppState>().language == AppLanguage.telugu;

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
          isTelugu ? 'నిబంధనలు & షరతులు' : 'Terms & Conditions',
          style: const TextStyle(
            color: Color(0xFF6B1F22),
            fontSize: 22,
            fontFamily: 'Noto Serif Telugu',
            fontWeight: FontWeight.w400,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
          children: const [
            _Paragraph(
              'Last updated: 2026\n\n'
              'Please read these Terms & Conditions ("Terms") carefully before '
              'using Daily Katha (the "App"). By creating an account or using '
              'the App, you agree to be bound by these Terms.',
            ),
            _Section('1. About Daily Katha'),
            _Paragraph(
              'Daily Katha is a Telugu-first devotional storytelling app that '
              'delivers day-by-day stories from Indian epics and Puranas, '
              'along with quizzes, streaks, and points to encourage daily '
              'reading.',
            ),
            _Section('2. Your Account'),
            _Paragraph(
              'You create an account using your phone number and name. You are '
              'responsible for keeping your account accessible and for all '
              'activity under it. Please provide accurate information. You may '
              'delete your account at any time from Settings → Delete Account, '
              'which permanently removes your account and associated progress.',
            ),
            _Section('3. Acceptable Use'),
            _Paragraph(
              'You agree not to misuse the App — including attempting to '
              'reverse engineer it, scrape or bulk-extract its content, '
              'interfere with its normal operation, or use it for any unlawful '
              'purpose.',
            ),
            _Section('4. Subscriptions'),
            _Paragraph(
              'Premium features are currently free to all users while in '
              '"Coming Soon" status. If and when paid plans are introduced, '
              'pricing, billing, and cancellation terms will be clearly shown '
              'before purchase, and these Terms will be updated accordingly.',
            ),
            _Section('5. Content & Intellectual Property'),
            _Paragraph(
              'All stories, quiz content, illustrations, and app design are '
              'owned by Daily Katha or its licensors and are provided for your '
              'personal, non-commercial use. You may not redistribute or '
              'republish App content without permission.',
            ),
            _Section('6. Disclaimer'),
            _Paragraph(
              'Stories and content are presented for cultural, educational, '
              'and devotional enrichment. They do not constitute religious, '
              'legal, medical, or professional advice. The App is provided '
              '"as is" without warranties of any kind.',
            ),
            _Section('7. Limitation of Liability'),
            _Paragraph(
              'To the maximum extent permitted by law, Daily Katha shall not '
              'be liable for any indirect, incidental, or consequential '
              'damages arising from your use of the App.',
            ),
            _Section('8. Changes to These Terms'),
            _Paragraph(
              'We may update these Terms from time to time. Continued use of '
              'the App after changes take effect constitutes acceptance of the '
              'revised Terms.',
            ),
            _Section('9. Governing Law'),
            _Paragraph(
              'These Terms are governed by the laws of India, without regard '
              'to its conflict of law principles.',
            ),
            _Section('10. Contact'),
            _Paragraph(
              'If you have questions about these Terms, please reach out to '
              'us through the contact options available in the App.',
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  const _Section(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF6B1F22),
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  final String text;
  const _Paragraph(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Color(0xFF5A4A38),
      ),
    );
  }
}
