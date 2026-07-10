import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import '../main/main_shell.dart';
import 'question_screen.dart';
import 'story_reader_screen.dart';

class QuizResultsScreen extends StatelessWidget {
  final Journey journey;
  final Episode episode;
  final List<AnsweredQuestion> answeredQuestions;
  final int pointsEarned;

  const QuizResultsScreen({
    super.key,
    required this.journey,
    required this.episode,
    required this.answeredQuestions,
    required this.pointsEarned,
  });

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;
    final nextEpisode = state.getNextEpisode(journey, episode);

    final correctCount = answeredQuestions.where((a) => a.isCorrect).length;
    final wrongCount = answeredQuestions.length - correctCount;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),

              // Trophy icon
              const Icon(
                Icons.emoji_events,
                color: AppColors.templeGold,
                size: 64,
              ),
              const SizedBox(height: 16),

              // Title
              Text(
                isTelugu ? 'క్విజ్ ఫలితాలు' : 'Quiz Performance',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sacredMaroon,
                  fontFamily: 'Noto Serif Telugu',
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '${isTelugu ? "రోజు" : "Day"} ${episode.dayNumber} · ${episode.title}',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.softBrown,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              // ── Score cards ──
              Row(
                children: [
                  Expanded(
                    child: _ScoreCard(
                      icon: Icons.check_circle,
                      iconColor: Colors.green,
                      count: correctCount,
                      label: isTelugu ? 'సరైనవి' : 'Correct',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ScoreCard(
                      icon: Icons.cancel,
                      iconColor: Colors.red,
                      count: wrongCount,
                      label: isTelugu ? 'తప్పు' : 'Wrong',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Points earned
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: const Color(0xFFEADCC2)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.star,
                      color: AppColors.templeGold,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '+$pointsEarned',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.sacredMaroon,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isTelugu ? 'పాయింట్లు సంపాదించారు' : 'Points earned',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.softBrown,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Answer review header ──
              Text(
                isTelugu ? 'సమాధానాల సమీక్ష' : 'Answer review',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.sacredMaroon,
                ),
              ),
              const SizedBox(height: 16),

              // ── Each question review ──
              ...List.generate(answeredQuestions.length, (i) {
                final aq = answeredQuestions[i];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: aq.isCorrect
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question number + text + status icon
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 28,
                            height: 28,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: aq.isCorrect ? Colors.green : Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              aq.questionText,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.sacredMaroon,
                                fontWeight: FontWeight.w500,
                                height: 1.4,
                              ),
                            ),
                          ),
                          Icon(
                            aq.isCorrect ? Icons.check_circle : Icons.cancel,
                            color: aq.isCorrect ? Colors.green : Colors.red,
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),

                      // User's answer
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: aq.isCorrect
                              ? Colors.green.withValues(alpha: 0.08)
                              : Colors.red.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              isTelugu ? 'మీ సమాధానం' : 'Your answer',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: aq.isCorrect ? Colors.green : Colors.red,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              aq.userOptionText,
                              style: const TextStyle(
                                fontSize: 15,
                                color: AppColors.sacredMaroon,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Correct answer (only show if wrong)
                      if (!aq.isCorrect && aq.correctOptionText.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isTelugu ? 'సరైన సమాధానం' : 'Correct answer',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                aq.correctOptionText,
                                style: const TextStyle(
                                  fontSize: 15,
                                  color: AppColors.sacredMaroon,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }),

              const SizedBox(height: 24),

              if (nextEpisode != null) ...[
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => StoryReaderScreen(
                          journey: journey,
                          episode: nextEpisode,
                        ),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepSaffron,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isTelugu ? 'తదుపరి రోజుకు వెళ్ళండి →' : 'Go to Next Day →',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Return to Home
              OutlinedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const MainShell()),
                    (route) => false,
                  );
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  isTelugu ? 'హోమ్‌కి తిరిగి వెళ్ళు' : 'Return to Home',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScoreCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final int count;
  final String label;

  const _ScoreCard({
    required this.icon,
    required this.iconColor,
    required this.count,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEADCC2)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: iconColor, size: 28),
          const SizedBox(width: 10),
          Column(
            children: [
              Text(
                '$count',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: iconColor,
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.softBrown,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
