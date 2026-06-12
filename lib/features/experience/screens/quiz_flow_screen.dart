import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../stories/models/story_models.dart';
import '../data/user_api_service.dart';
import 'completion_reward_screen.dart';
import 'quiz_review_screen.dart';

class QuizFlowScreen extends StatefulWidget {
  const QuizFlowScreen({
    super.key,
    required this.day,
    required this.detail,
    required this.userApi,
    required this.onFinished,
  });

  final StoryDaySummary day;
  final DayDetail detail;
  final UserApiService userApi;
  final VoidCallback onFinished;

  @override
  State<QuizFlowScreen> createState() => _QuizFlowScreenState();
}

class _QuizFlowScreenState extends State<QuizFlowScreen> {
  final Map<String, QuizOption> _selectedOptions = {};
  late final DateTime _startedAt = DateTime.now();
  int _index = 0;
  bool _submitting = false;
  String? _error;

  QuizQuestion get _question => widget.detail.questions[_index];
  bool get _allAnswered =>
      _selectedOptions.length == widget.detail.questions.length;

  Future<void> _submit() async {
    if (!_allAnswered || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final result = await widget.userApi.submitQuizAttempt(
        storyDayId: widget.detail.day.id,
        startedAt: _startedAt,
        timeSpentSeconds: DateTime.now().difference(_startedAt).inSeconds,
        selectedOptions: _selectedOptions,
        questions: widget.detail.questions,
      );
      await widget.userApi.completeDay(widget.detail.day.id);
      final review = await widget.userApi.fetchLatestQuizReview(
        widget.detail.day.id,
      );
      if (!mounted) return;
      widget.onFinished();

      if (review == null) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return;
      }

      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CompletionRewardScreen(
            day: widget.day,
            detail: widget.detail,
            result: result,
            userApi: widget.userApi,
            onReviewQuiz: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) =>
                      QuizReviewScreen(review: review, day: widget.day),
                ),
              );
            },
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedOptions[_question.id];

    return Scaffold(
      backgroundColor: AppColors.dusk,
      body: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.maroon, AppColors.dusk, AppColors.brown],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    IconButton.filledTonal(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Day ${widget.day.dayNumber} Quiz',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Text(
                  'Question ${_index + 1} of ${widget.detail.questions.length}',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: .72),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: (_index + 1) / widget.detail.questions.length,
                    minHeight: 8,
                    color: AppColors.gold,
                    backgroundColor: Colors.white.withValues(alpha: .18),
                  ),
                ),
                const SizedBox(height: 28),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  child: Container(
                    key: ValueKey(_question.id),
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: .94),
                      borderRadius: BorderRadius.circular(30),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: .38),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .24),
                          blurRadius: 30,
                          offset: const Offset(0, 16),
                        ),
                      ],
                    ),
                    child: Text(
                      _question.questionText,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Expanded(
                  child: ListView.separated(
                    itemCount: _question.options.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, optionIndex) {
                      final option = _question.options[optionIndex];
                      return _QuizOptionTile(
                        label: option.label.isEmpty
                            ? String.fromCharCode(65 + optionIndex)
                            : option.label,
                        text: option.text,
                        selected: selected?.id == option.id,
                        onTap: () => setState(
                          () => _selectedOptions[_question.id] = option,
                        ),
                      );
                    },
                  ),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFFFC2B8),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _index == 0
                            ? null
                            : () => setState(() => _index -= 1),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: BorderSide(
                            color: Colors.white.withValues(alpha: .34),
                          ),
                        ),
                        child: const Text('Previous'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: _submitting
                            ? null
                            : _index == widget.detail.questions.length - 1
                            ? (_allAnswered ? _submit : null)
                            : selected == null
                            ? null
                            : () => setState(() => _index += 1),
                        child: Text(
                          _submitting
                              ? 'Submitting...'
                              : _index == widget.detail.questions.length - 1
                              ? 'Submit'
                              : 'Next',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFF2DD) : Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: selected
                  ? AppColors.gold
                  : Colors.white.withValues(alpha: .34),
              width: selected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFE7B3),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.deepSaffron,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? AppColors.saffron : AppColors.mutedBrown,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
