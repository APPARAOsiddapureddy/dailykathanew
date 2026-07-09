import 'package:flutter/material.dart';

import '../../data/api_service.dart';
import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';

/// Shows the quiz questions and correct answers for a completed day.
/// Fetches data from API and finds correct options without modifying data.
class QuizReviewScreen extends StatefulWidget {
  final Journey journey;
  final Episode episode;

  const QuizReviewScreen({
    super.key,
    required this.journey,
    required this.episode,
  });

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

  Future<void> _fetchAndProcessQuiz() async {
    try {
      final dayData = await apiService.fetchStoryDay(widget.journey.id, widget.episode.dayNumber);
      final fetchedQuestions = dayData['questions'] as List<dynamic>? ?? [];

      List<_ReviewQuestion> questions = [];

      for (final q in fetchedQuestions) {
        final optionsData = q['options'] as List<dynamic>? ?? [];
        List<_ReviewOption> options = optionsData.map((o) => _ReviewOption(
          id: o['id'] as String,
          label: o['label'] as String,
          text: o['text'] as String,
        )).toList();

        String? correctOptionId;
        String? correctOptionText;
        for (final opt in options) {
          try {
            final result = await apiService.checkAnswer(q['id'], opt.id);
            if (result['correct'] == true) {
              correctOptionId = opt.id;
              correctOptionText = opt.text;
              break;
            }
          } catch (_) {}
        }

        questions.add(_ReviewQuestion(
          questionText: q['questionText'] as String,
          options: options,
          correctOptionId: correctOptionId,
          correctOptionText: correctOptionText ?? '',
        ));
      }

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
          ? const Center(child: CircularProgressIndicator(color: AppColors.deepSaffron))
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
                            const Icon(Icons.emoji_events, color: AppColors.templeGold, size: 48),
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
                              style: const TextStyle(fontSize: 14, color: AppColors.softBrown),
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
                                    width: 28, height: 28,
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

                              // Correct answer
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.green.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.check_circle, color: Colors.green, size: 18),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        question.correctOptionText,
                                        style: TextStyle(
                                          fontSize: 15,
                                          color: Colors.green.shade800,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
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
  _ReviewOption({required this.id, required this.label, required this.text});
}

class _ReviewQuestion {
  final String questionText;
  final List<_ReviewOption> options;
  final String? correctOptionId;
  final String correctOptionText;
  _ReviewQuestion({
    required this.questionText,
    required this.options,
    this.correctOptionId,
    required this.correctOptionText,
  });
}
