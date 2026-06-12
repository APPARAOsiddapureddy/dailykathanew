import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../stories/models/story_models.dart';
import '../data/user_api_service.dart';
import '../models/app_user_models.dart';

class CompletionRewardScreen extends StatefulWidget {
  const CompletionRewardScreen({
    super.key,
    required this.day,
    required this.detail,
    required this.result,
    required this.userApi,
    this.onReviewQuiz,
  });

  final StoryDaySummary day;
  final DayDetail detail;
  final QuizAttemptResult? result;
  final UserApiService userApi;
  final VoidCallback? onReviewQuiz;

  @override
  State<CompletionRewardScreen> createState() => _CompletionRewardScreenState();
}

class _CompletionRewardScreenState extends State<CompletionRewardScreen> {
  late final Future<AppUser?> _userFuture = _loadUser();

  Future<AppUser?> _loadUser() async {
    try {
      return widget.userApi.fetchMe();
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final moral = widget.detail.day.moral.trim();
    final teaser = widget.detail.day.tomorrowTeaser.trim();
    final hasQuiz = widget.result != null;
    final quizScore = hasQuiz
        ? '${widget.result!.correctCount}/${widget.result!.totalQuestions}'
        : 'No quiz';
    final quizPoints = widget.result?.pointsAdded ?? 0;
    final totalDisplayPoints = 5 + quizPoints;

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFFE7B3), AppColors.ivory, AppColors.surface],
            stops: [0, .42, 1],
          ),
        ),
        child: FutureBuilder<AppUser?>(
          future: _userFuture,
          builder: (context, snapshot) {
            final user = snapshot.data;
            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Container(
                        width: 116,
                        height: 116,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [AppColors.gold, AppColors.saffron],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.saffron.withValues(alpha: .34),
                              blurRadius: 34,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.workspace_premium_rounded,
                          size: 62,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Text(
                      'Day ${widget.day.dayNumber} Completed',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.detail.story.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.mutedBrown,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (widget.day.title.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.day.title,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.mutedBrown),
                      ),
                    ],
                    const SizedBox(height: 26),
                    Row(
                      children: [
                        Expanded(
                          child: _CompletionTile(
                            icon: Icons.quiz_rounded,
                            title: quizScore,
                            label: 'Quiz Score',
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CompletionTile(
                            icon: Icons.stars_rounded,
                            title: '+$totalDisplayPoints',
                            label: 'Points Earned',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _CompletionTile(
                      icon: Icons.local_fire_department_rounded,
                      title: user == null
                          ? 'Updated'
                          : '${user.currentStreak} day${user.currentStreak == 1 ? '' : 's'}',
                      label: 'Current Streak',
                    ),
                    if (moral.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      _InfoCard(
                        icon: Icons.lightbulb_rounded,
                        title: 'Today Lesson',
                        body: moral,
                      ),
                    ],
                    const SizedBox(height: 18),
                    _InfoCard(
                      icon: Icons.calendar_month_rounded,
                      title: 'Tomorrow',
                      body: teaser.isEmpty
                          ? 'Continue this story journey when the next day is available.'
                          : teaser,
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: () => Navigator.of(
                        context,
                      ).popUntil((route) => route.isFirst),
                      icon: const Icon(Icons.home_rounded),
                      label: const Text('Back Home'),
                    ),
                    if (widget.onReviewQuiz != null) ...[
                      const SizedBox(height: 10),
                      OutlinedButton.icon(
                        onPressed: widget.onReviewQuiz,
                        icon: const Icon(Icons.fact_check_rounded),
                        label: const Text('Review Quiz'),
                      ),
                    ],
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CompletionTile extends StatelessWidget {
  const _CompletionTile({
    required this.icon,
    required this.title,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .86),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border.withValues(alpha: .46)),
        boxShadow: [
          BoxShadow(
            color: AppColors.saffron.withValues(alpha: .12),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.saffron, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.mutedBrown),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .84),
        borderRadius: BorderRadius.circular(26),
        border: Border.all(color: AppColors.border.withValues(alpha: .44)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: AppColors.saffron),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: const TextStyle(
                      color: AppColors.mutedBrown,
                      height: 1.45,
                    ),
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
