import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../stories/models/story_models.dart';
import '../models/app_user_models.dart';
import '../widgets/quiz_review_widgets.dart';

class QuizReviewScreen extends StatefulWidget {
  const QuizReviewScreen({super.key, required this.review, required this.day});

  final QuizReviewResult review;
  final StoryDaySummary day;

  @override
  State<QuizReviewScreen> createState() => _QuizReviewScreenState();
}

class _QuizReviewScreenState extends State<QuizReviewScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final question = widget.review.questions[_index];

    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.ivory, AppColors.surface, Color(0xFFFFE7C7)],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
            children: [
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Day ${widget.day.dayNumber} Quiz Result',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 22),
              Text(
                'Overview',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 16),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.35,
                children: [
                  ReviewStatTile(
                    icon: Icons.star_border_rounded,
                    label: 'Total Score',
                    value: '${widget.review.score}',
                    color: AppColors.deepSaffron,
                    background: const Color(0xFFFFE7B3),
                  ),
                  ReviewStatTile(
                    icon: Icons.check_circle_rounded,
                    label: 'Correct',
                    value: '${widget.review.correctCount}',
                    color: AppColors.success,
                    background: const Color(0xFFEAF7EF),
                  ),
                  ReviewStatTile(
                    icon: Icons.cancel_rounded,
                    label: 'Incorrect',
                    value: '${widget.review.wrongCount}',
                    color: AppColors.error,
                    background: const Color(0xFFFFEEEE),
                  ),
                  ReviewStatTile(
                    icon: Icons.radio_button_unchecked_rounded,
                    label: 'Unattempted',
                    value: '${widget.review.unattemptedCount}',
                    color: AppColors.mutedBrown,
                    background: const Color(0xFFF1E7DA),
                  ),
                ],
              ),
              const SizedBox(height: 28),
              Text(
                'Summary',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(widget.review.questions.length, (
                  index,
                ) {
                  final item = widget.review.questions[index];
                  return QuestionPaletteButton(
                    number: index + 1,
                    selected: index == _index,
                    correct: item.isCorrect == true,
                    attempted: item.selectedOptionId != null,
                    onTap: () => setState(() => _index = index),
                  );
                }),
              ),
              const SizedBox(height: 18),
              ReviewQuestionCard(
                index: _index,
                total: widget.review.questions.length,
                question: question,
                onPrevious: _index == 0
                    ? null
                    : () => setState(() => _index -= 1),
                onNext: _index == widget.review.questions.length - 1
                    ? null
                    : () => setState(() => _index += 1),
              ),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
