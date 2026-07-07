import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import 'day_complete_screen.dart';

class QuestionScreen extends StatefulWidget {
  final Episode episode;
  const QuestionScreen({super.key, required this.episode});

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int? _selectedIndex;
  bool _isAnswered = false;

  void _onOptionSelected(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedIndex = index;
      _isAnswered = true;
    });

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => DayCompleteScreen(episode: widget.episode)),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;
    final quiz = widget.episode.quiz!;

    return Scaffold(
      backgroundColor: AppColors.warmIvory,
      appBar: AppBar(
        title: Text(isTelugu ? 'ప్రశ్న' : 'Question'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              quiz.question,
              style: const TextStyle(
                fontSize: 24,
                color: AppColors.sacredMaroon,
                fontWeight: FontWeight.bold,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 48),
            ...List.generate(quiz.options.length, (index) {
              final option = quiz.options[index];
              final isSelected = _selectedIndex == index;

              Color bgColor = AppColors.white;
              Color borderColor = Colors.transparent;

              if (_isAnswered) {
                if (option.isCorrect) {
                  bgColor = Colors.green.shade50;
                  borderColor = Colors.green;
                } else if (isSelected && !option.isCorrect) {
                  bgColor = Colors.red.shade50;
                  borderColor = Colors.red;
                }
              } else if (isSelected) {
                bgColor = AppColors.ivoryLight;
                borderColor = AppColors.deepSaffron;
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 16.0),
                child: GestureDetector(
                  onTap: () => _onOptionSelected(index),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: borderColor == Colors.transparent
                            ? AppColors.softBrown.withOpacity(0.2)
                            : borderColor,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.ivoryLight,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.deepSaffron.withOpacity(0.3)),
                          ),
                          child: Text(
                            String.fromCharCode(65 + index), // A, B, C, D
                            style: const TextStyle(
                              color: AppColors.deepSaffron,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            option.text,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppColors.sacredMaroon,
                            ),
                          ),
                        ),
                        if (_isAnswered && option.isCorrect)
                          const Icon(Icons.check_circle, color: Colors.green),
                        if (_isAnswered && isSelected && !option.isCorrect)
                          const Icon(Icons.cancel, color: Colors.red),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const Spacer(),
            if (!_isAnswered)
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
