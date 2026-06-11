import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../stories/models/story_models.dart';
import '../data/user_api_service.dart';
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
      await widget.userApi.submitQuizAttempt(
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
          builder: (_) => QuizReviewScreen(review: review, day: widget.day),
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
      appBar: AppBar(title: const Text('Today Quiz')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Question ${_index + 1} of ${widget.detail.questions.length}',
                style: const TextStyle(
                  color: AppColors.mutedBrown,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_index + 1) / widget.detail.questions.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                color: AppColors.gold,
                backgroundColor: const Color(0xFFFFE7C7),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
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
                      color: AppColors.error,
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
      color: selected ? const Color(0xFFFFF1E6) : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.saffron : AppColors.border,
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
