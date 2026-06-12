import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../models/app_user_models.dart';

class ReviewStatTile extends StatelessWidget {
  const ReviewStatTile({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.background,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: .16)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class QuestionPaletteButton extends StatelessWidget {
  const QuestionPaletteButton({
    super.key,
    required this.number,
    required this.selected,
    required this.correct,
    required this.attempted,
    required this.onTap,
  });

  final int number;
  final bool selected;
  final bool correct;
  final bool attempted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = !attempted
        ? const Color(0xFFF1E7DA)
        : correct
        ? const Color(0xFFEAF7EF)
        : const Color(0xFFFFEEEE);
    final textColor = !attempted
        ? AppColors.mutedBrown
        : correct
        ? AppColors.success
        : AppColors.error;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.saffron : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          '$number',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w900),
        ),
      ),
    );
  }
}

class ReviewQuestionCard extends StatelessWidget {
  const ReviewQuestionCard({
    super.key,
    required this.index,
    required this.total,
    required this.question,
    required this.onPrevious,
    required this.onNext,
  });

  final int index;
  final int total;
  final QuizReviewQuestion question;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: .44)),
        boxShadow: [
          BoxShadow(
            color: AppColors.saffron.withValues(alpha: .1),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Question ${index + 1} of $total',
              style: const TextStyle(
                color: AppColors.deepSaffron,
                fontSize: 17,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              question.questionText,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 18),
            ...question.options.map((option) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ReviewOptionTile(
                  option: option,
                  selected: question.selectedOptionId == option.id,
                ),
              );
            }),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPrevious,
                    icon: const Icon(Icons.chevron_left_rounded),
                    label: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onNext,
                    icon: const Icon(Icons.chevron_right_rounded),
                    label: const Text('Next'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewOptionTile extends StatelessWidget {
  const ReviewOptionTile({
    super.key,
    required this.option,
    required this.selected,
  });

  final QuizReviewOption option;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final isWrongChoice = selected && !option.isCorrect;
    final background = option.isCorrect
        ? const Color(0xFFEAF7EF)
        : isWrongChoice
        ? const Color(0xFFFFEEEE)
        : Colors.white;
    final borderColor = option.isCorrect
        ? AppColors.success
        : isWrongChoice
        ? AppColors.error
        : AppColors.border;
    final icon = option.isCorrect
        ? Icons.check_circle_rounded
        : isWrongChoice
        ? Icons.cancel_rounded
        : Icons.radio_button_unchecked_rounded;
    final iconColor = option.isCorrect
        ? AppColors.success
        : isWrongChoice
        ? AppColors.error
        : AppColors.mutedBrown;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              option.text,
              style: TextStyle(
                color: option.isCorrect || isWrongChoice
                    ? iconColor
                    : AppColors.brown,
                fontSize: 16,
                height: 1.35,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (selected)
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text(
                'Your Choice',
                style: TextStyle(
                  color: AppColors.mutedBrown,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
