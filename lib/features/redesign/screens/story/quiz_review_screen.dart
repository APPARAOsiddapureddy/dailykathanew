import 'package:flutter/material.dart';

import '../../data/api_service.dart';
import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';

/// Shows the quiz questions and correct answers for a completed day.
/// Fetches data from API and finds correct options without modifying data.
class QuizReviewScreen extends StatefulWidget {
  final Episode episode;

  const QuizReviewScreen({super.key, required this.episode});

  @override
  State<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<QuizReviewScreen> {
  bool _isLoading = true;
  List<_ReviewQuestion> _questions = [];

  @override
  void initState() {
    super.initState();
    _fetchAndProcessQuiz();
  }

  // The `/story-days/:id/quiz-attempts/latest` endpoint already returns
  // everything needed for review: each question with its full option list
  // (each option carrying its own `isCorrect`) plus the user's
  // `selectedOptionId` — no need to separately fetch the story day or
  // probe every option through checkAnswer.
  Future<void> _fetchAndProcessQuiz() async {
    try {
      final latestAttempt = await apiService.fetchLatestQuizAttempt(
        widget.episode.id,
      );
      final fetchedQuestions =
          latestAttempt['questions'] as List<dynamic>? ?? [];

      final questions = fetchedQuestions.map((q) {
        final optionsData = q['options'] as List<dynamic>? ?? [];
        final options = optionsData
            .map(
              (o) => _ReviewOption(
                id: o['id'] as String,
                label: o['label'] as String,
                text: o['text'] as String,
                isCorrect: o['isCorrect'] == true,
              ),
            )
            .toList();

        return _ReviewQuestion(
          questionText: q['questionText'] as String,
          options: options,
          userOptionId: q['selectedOptionId'] as String?,
        );
      }).toList();

      if (mounted) {
        setState(() {
          _questions = questions;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching quiz for review: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text('Day ${widget.episode.dayNumber} - Quiz'),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.deepSaffron),
            )
          : _questions.isEmpty
          ? const Center(
              child: Text(
                'No quiz found for this day',
                style: TextStyle(color: AppColors.softBrown, fontSize: 16),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Center(
                    child: Column(
                      children: [
                        const Icon(
                          Icons.emoji_events,
                          color: AppColors.templeGold,
                          size: 48,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quiz Answers',
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: AppColors.sacredMaroon,
                          ),
                        ),
                        Text(
                          widget.episode.title,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.softBrown,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Questions list
                  ...List.generate(_questions.length, (i) {
                    final question = _questions[i];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFEADCC2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Question number + text
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 28,
                                height: 28,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: AppColors.deepSaffron,
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
                                  question.questionText,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    color: AppColors.sacredMaroon,
                                    fontWeight: FontWeight.w500,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),

                          // Option list — correct answer and the user's
                          // choice are highlighted inline.
                          ...List.generate(question.options.length, (optIndex) {
                            final option = question.options[optIndex];
                            final isCorrect = option.isCorrect;
                            final isUserChoice =
                                option.id == question.userOptionId;

                            Color bgColor = AppColors.white;
                            Color borderColor = const Color(0xFFEADCC2);
                            if (isCorrect) {
                              bgColor = Colors.green.shade50;
                              borderColor = Colors.green;
                            } else if (isUserChoice) {
                              bgColor = Colors.red.shade50;
                              borderColor = Colors.red;
                            }

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: bgColor,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: borderColor,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        option.text,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          color: AppColors.sacredMaroon,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    if (isCorrect)
                                      const Icon(
                                        Icons.check_circle,
                                        color: Colors.green,
                                        size: 20,
                                      )
                                    else if (isUserChoice)
                                      const Icon(
                                        Icons.cancel,
                                        color: Colors.red,
                                        size: 20,
                                      ),
                                  ],
                                ),
                              ),
                            );
                          }),

                          if (question.userOptionId == null)
                            const Padding(
                              padding: EdgeInsets.only(top: 4),
                              child: Text(
                                'You did not answer this question',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontStyle: FontStyle.italic,
                                  color: AppColors.softBrown,
                                ),
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
    );
  }
}

class _ReviewOption {
  final String id;
  final String label;
  final String text;
  final bool isCorrect;
  _ReviewOption({
    required this.id,
    required this.label,
    required this.text,
    required this.isCorrect,
  });
}

class _ReviewQuestion {
  final String questionText;
  final List<_ReviewOption> options;
  final String? userOptionId;
  _ReviewQuestion({
    required this.questionText,
    required this.options,
    this.userOptionId,
  });
}
