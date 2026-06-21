import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../data/app_api_service.dart';
import '../models/story_models.dart';
import 'completion_screen.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({
    super.key,
    required this.api,
    this.story,
    this.day,
    required this.questions,
    this.onComplete,
    this.onCompleteWithResult,
  });

  final AppApiService api;
  final Story? story;
  final StoryDaySummary? day;
  final List<QuizQuestion> questions;
  final VoidCallback? onComplete;
  final void Function(QuizResult result)? onCompleteWithResult;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _questionIndex = 0;
  int _score = 0;
  String? _selectedOptionId;
  bool? _lastCorrect;
  bool _checking = false;
  String? _error;
  final List<QuizAnswerResult> _answers = <QuizAnswerResult>[];

  QuizQuestion get _question => widget.questions[_questionIndex];

  Future<void> _selectOption(QuizOption option) async {
    if (_checking || _selectedOptionId != null) return;

    setState(() {
      _checking = true;
      _selectedOptionId = option.id;
      _error = null;
    });

    try {
      final result = await widget.api.checkAnswer(
        questionId: _question.id,
        optionId: option.id,
      );
      setState(() {
        _lastCorrect = result.correct;
        if (result.correct) _score += 1;
        _answers.add(
          QuizAnswerResult(
            question: _question,
            selectedOption: option,
            correctOption: result.correctOptionId == null
                ? null
                : QuizOption(
                    id: result.correctOptionId!,
                    label: result.correctOptionLabel ?? '',
                    text: result.correctOptionText ?? '',
                  ),
            correct: result.correct,
          ),
        );
      });
    } catch (error) {
      setState(() {
        _selectedOptionId = null;
        _error = '$error';
      });
    } finally {
      if (mounted) {
        setState(() => _checking = false);
      }
    }
  }

  void _continue() {
    if (_questionIndex == widget.questions.length - 1) {
      if (widget.onCompleteWithResult != null) {
        widget.onCompleteWithResult!(
          QuizResult(
            score: _score,
            total: widget.questions.length,
            answers: List<QuizAnswerResult>.unmodifiable(_answers),
          ),
        );
        return;
      }
      if (widget.onComplete != null) {
        widget.onComplete!();
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CompletionScreen(
            api: widget.api,
            story: widget.story!,
            day: widget.day!,
            score: _score,
            total: widget.questions.length,
          ),
        ),
      );
      return;
    }

    setState(() {
      _questionIndex += 1;
      _selectedOptionId = null;
      _lastCorrect = null;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_questionIndex + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Today’s Quiz'),
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            children: [
              Text(
                'Question ${_questionIndex + 1} of ${widget.questions.length}',
                style: const TextStyle(
                  color: AppColors.mutedBrown,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                color: AppColors.gold,
                backgroundColor: const Color(0xFFFFE7C7),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(22),
                  child: Text(
                    _question.questionText,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: ListView.separated(
                  itemBuilder: (context, index) {
                    final option = _question.options[index];
                    return _OptionButton(
                      option: option,
                      selected: _selectedOptionId == option.id,
                      checked: _selectedOptionId != null,
                      correct: _selectedOptionId == option.id
                          ? _lastCorrect
                          : null,
                      onTap: () => _selectOption(option),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemCount: _question.options.length,
                ),
              ),
              if (_checking)
                const Padding(
                  padding: EdgeInsets.only(bottom: 12),
                  child: LinearProgressIndicator(color: AppColors.saffron),
                ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              if (_lastCorrect != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    _lastCorrect! ? 'Correct answer' : 'Wrong answer',
                    style: TextStyle(
                      color: _lastCorrect!
                          ? AppColors.success
                          : AppColors.error,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: _lastCorrect == null ? null : _continue,
                child: Text(
                  _questionIndex == widget.questions.length - 1
                      ? 'Finish Quiz'
                      : 'Next Question',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class QuizResult {
  const QuizResult({
    required this.score,
    required this.total,
    required this.answers,
  });

  final int score;
  final int total;
  final List<QuizAnswerResult> answers;
}

class QuizAnswerResult {
  const QuizAnswerResult({
    required this.question,
    required this.selectedOption,
    this.correctOption,
    required this.correct,
  });

  final QuizQuestion question;
  final QuizOption selectedOption;
  final QuizOption? correctOption;
  final bool correct;
}

class _OptionButton extends StatelessWidget {
  const _OptionButton({
    required this.option,
    required this.selected,
    required this.checked,
    required this.correct,
    required this.onTap,
  });

  final QuizOption option;
  final bool selected;
  final bool checked;
  final bool? correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color borderColor;
    final Color backgroundColor;
    final Color textColor;
    final IconData trailingIcon;

    if (selected && correct == true) {
      borderColor = AppColors.success;
      backgroundColor = const Color(0xFFEAF7EF);
      textColor = AppColors.success;
      trailingIcon = Icons.check_circle_rounded;
    } else if (selected && correct == false) {
      borderColor = AppColors.error;
      backgroundColor = const Color(0xFFFFEEEE);
      textColor = AppColors.error;
      trailingIcon = Icons.cancel_rounded;
    } else {
      borderColor = checked ? AppColors.border : AppColors.border;
      backgroundColor = Colors.white;
      textColor = AppColors.brown;
      trailingIcon = Icons.radio_button_unchecked_rounded;
    }

    return Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: checked ? null : onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 64),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: borderColor),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7B3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    option.label,
                    style: const TextStyle(
                      color: AppColors.deepSaffron,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  option.text,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(trailingIcon, color: textColor),
            ],
          ),
        ),
      ),
    );
  }
}
