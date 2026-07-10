import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import '../../data/api_service.dart';
import 'quiz_results_screen.dart';

/// Stores the result of a single answered question.
class AnsweredQuestion {
  final String questionId;
  final String questionText;
  final String userOptionId;
  final String userOptionText;
  final String correctOptionId;
  final String correctOptionText;
  final bool isCorrect;

  AnsweredQuestion({
    required this.questionId,
    required this.questionText,
    required this.userOptionId,
    required this.userOptionText,
    required this.correctOptionId,
    required this.correctOptionText,
    required this.isCorrect,
  });
}

class QuestionScreen extends StatefulWidget {
  final Journey journey;
  final Episode episode;
  const QuestionScreen({
    super.key,
    required this.journey,
    required this.episode,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int _currentQuestionIndex = 0;
  int? _selectedIndex;
  bool _isAnswered = false;
  int? _correctIndex;

  // Track all answered questions for the results screen
  final List<AnsweredQuestion> _answeredQuestions = [];

  Quiz get _currentQuiz => widget.episode.quizzes[_currentQuestionIndex];
  int get _totalQuestions => widget.episode.quizzes.length;

  void _onOptionSelected(int index, String questionId, String optionId) async {
    if (_isAnswered) return;
    setState(() => _selectedIndex = index);

    try {
      final result = await apiService.checkAnswer(questionId, optionId);
      final isCorrect = result['correct'] == true;
      final correctOption = result['correctOption'];
      final correctOptionId = correctOption?['id'] as String? ?? '';
      final correctOptionText = correctOption?['text'] as String? ?? '';

      int correctIdx = index;
      if (!isCorrect && correctOptionId.isNotEmpty) {
        correctIdx = _currentQuiz.options.indexWhere(
          (o) => o.id == correctOptionId,
        );
      }

      // Record this answer
      _answeredQuestions.add(
        AnsweredQuestion(
          questionId: _currentQuiz.id,
          questionText: _currentQuiz.question,
          userOptionId: optionId,
          userOptionText: _currentQuiz.options[index].text,
          correctOptionId: correctOptionId,
          correctOptionText: correctOptionText.isNotEmpty
              ? correctOptionText
              : (correctIdx >= 0 ? _currentQuiz.options[correctIdx].text : ''),
          isCorrect: isCorrect,
        ),
      );

      setState(() {
        _isAnswered = true;
        _correctIndex = correctIdx;
      });
    } catch (e) {
      // On error, still record and move on
      _answeredQuestions.add(
        AnsweredQuestion(
          questionId: _currentQuiz.id,
          questionText: _currentQuiz.question,
          userOptionId: optionId,
          userOptionText: _currentQuiz.options[index].text,
          correctOptionId: '',
          correctOptionText: '',
          isCorrect: false,
        ),
      );
      setState(() {
        _isAnswered = true;
        _correctIndex = null;
      });
    }
  }

  void _goToNextQuestion() async {
    if (_currentQuestionIndex < _totalQuestions - 1) {
      // Next question
      setState(() {
        _currentQuestionIndex++;
        _selectedIndex = null;
        _isAnswered = false;
        _correctIndex = null;
      });
    } else {
      // All questions done — mark day as complete and show results
      final correctCount = _answeredQuestions
          .where((answer) => answer.isCorrect)
          .length;
      final response = await context.read<AppState>().submitQuizAttempt(
        widget.episode.id,
        _answeredQuestions
            .map(
              (answer) => {
                'questionId': answer.questionId,
                'selectedOptionId': answer.userOptionId,
              },
            )
            .toList(),
        correctCount: correctCount,
      );
      await context.read<AppState>().completeStoryDay(widget.episode.id);

      // Show what the backend actually credited, not a client-side guess.
      final pointsEarned = response?['pointsAdded'] is int
          ? response!['pointsAdded'] as int
          : correctCount;

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => QuizResultsScreen(
              journey: widget.journey,
              episode: widget.episode,
              answeredQuestions: _answeredQuestions,
              pointsEarned: pointsEarned,
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;
    final quiz = _currentQuiz;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(
          '${isTelugu ? 'ప్రశ్న' : 'Question'} ${_currentQuestionIndex + 1}/$_totalQuestions',
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Question counter bar
            Row(
              children: List.generate(_totalQuestions, (i) {
                Color barColor;
                if (i < _answeredQuestions.length) {
                  barColor = _answeredQuestions[i].isCorrect
                      ? Colors.green
                      : Colors.red;
                } else if (i == _currentQuestionIndex) {
                  barColor = AppColors.deepSaffron;
                } else {
                  barColor = const Color(0xFFEADCC2);
                }
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(
                      right: i < _totalQuestions - 1 ? 4 : 0,
                    ),
                    decoration: BoxDecoration(
                      color: barColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 32),

            // Question text
            Text(
              quiz.question,
              style: const TextStyle(
                fontSize: 22,
                color: AppColors.sacredMaroon,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // Options
            ...List.generate(quiz.options.length, (index) {
              final option = quiz.options[index];
              final isSelected = _selectedIndex == index;

              Color bgColor = AppColors.white;
              Color borderColor = const Color(0xFFEADCC2);

              if (_isAnswered) {
                final isThisCorrect = _correctIndex == index;
                if (isThisCorrect) {
                  bgColor = Colors.green.shade50;
                  borderColor = Colors.green;
                } else if (isSelected) {
                  bgColor = Colors.red.shade50;
                  borderColor = Colors.red;
                }
              } else if (isSelected) {
                bgColor = AppColors.ivoryLight;
                borderColor = AppColors.deepSaffron;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: GestureDetector(
                  onTap: () => _onOptionSelected(index, quiz.id, option.id),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderColor, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 30,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.ivoryLight,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: AppColors.deepSaffron.withValues(
                                alpha: 0.3,
                              ),
                            ),
                          ),
                          child: Text(
                            String.fromCharCode(65 + index),
                            style: const TextStyle(
                              color: AppColors.deepSaffron,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            option.text,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.sacredMaroon,
                            ),
                          ),
                        ),
                        if (_isAnswered && _correctIndex == index)
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 22,
                          ),
                        if (_isAnswered && isSelected && _correctIndex != index)
                          const Icon(Icons.cancel, color: Colors.red, size: 22),
                      ],
                    ),
                  ),
                ),
              );
            }),

            const Spacer(),

            // Next / See Results button (only visible after answering)
            if (_isAnswered)
              ElevatedButton(
                onPressed: _goToNextQuestion,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepSaffron,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _currentQuestionIndex < _totalQuestions - 1
                      ? (isTelugu ? 'తదుపరి ప్రశ్న →' : 'Next Question →')
                      : (isTelugu ? 'ఫలితాలు చూడండి' : 'See Results'),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            else
              Text(
                isTelugu ? 'ఒక సమాధానాన్ని ఎంచుకోండి' : 'Select an answer',
                style: const TextStyle(
                  color: AppColors.softBrown,
                  fontStyle: FontStyle.italic,
                ),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }
}
