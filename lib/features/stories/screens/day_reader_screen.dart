import 'package:flutter/material.dart';

import '../../../app/theme.dart';
import '../../../core/widgets/app_states.dart';
import '../data/app_api_service.dart';
import '../models/story_models.dart';
import 'completion_screen.dart';
import 'quiz_screen.dart';

class DayReaderScreen extends StatefulWidget {
  const DayReaderScreen({
    super.key,
    required this.api,
    required this.story,
    required this.day,
  });

  final AppApiService api;
  final Story story;
  final StoryDaySummary day;

  @override
  State<DayReaderScreen> createState() => _DayReaderScreenState();
}

class _DayReaderScreenState extends State<DayReaderScreen> {
  late Future<DayDetail> _detailFuture;
  final PageController _pageController = PageController();
  int _photoIndex = 0;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDay();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<DayDetail> _loadDay() async {
    final detail = await widget.api.fetchDay(
      storyId: widget.story.id,
      dayNumber: widget.day.dayNumber,
    );
    if (mounted) {
      for (final photo in detail.photos.take(3)) {
        if (photo.imageUrl.isNotEmpty) {
          precacheImage(NetworkImage(photo.imageUrl), context);
        }
      }
    }
    return detail;
  }

  void _reload() {
    setState(() {
      _photoIndex = 0;
      _detailFuture = _loadDay();
    });
  }

  void _openQuiz(DayDetail detail) {
    if (detail.questions.isEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute<void>(
          builder: (_) => CompletionScreen(
            api: widget.api,
            story: widget.story,
            day: widget.day,
            score: 0,
            total: 0,
          ),
        ),
      );
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => QuizScreen(
          api: widget.api,
          story: widget.story,
          day: widget.day,
          questions: detail.questions,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brown,
      body: FutureBuilder<DayDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Opening today’s story...');
          }

          if (snapshot.hasError) {
            return ErrorState(message: '${snapshot.error}', onRetry: _reload);
          }

          final detail = snapshot.data!;
          if (detail.photos.isEmpty) {
            return SafeArea(
              child: EmptyState(
                icon: Icons.image_not_supported_rounded,
                title: 'No photos for this day',
                message: 'Photos uploaded from the CMS will appear here.',
                action: FilledButton(
                  onPressed: () => _openQuiz(detail),
                  child: Text(
                    detail.questions.isEmpty ? 'Complete Day' : 'Go to Quiz',
                  ),
                ),
              ),
            );
          }

          final isFinalPhoto = _photoIndex == detail.photos.length - 1;
          return Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    itemCount: detail.photos.length,
                    onPageChanged: (index) =>
                        setState(() => _photoIndex = index),
                    itemBuilder: (context, index) {
                      return KathaNetworkImage(
                        url: detail.photos[index].imageUrl,
                        fit: BoxFit.cover,
                      );
                    },
                  ),
                  const Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0x99000000),
                            Colors.transparent,
                            Color(0xD9000000),
                          ],
                          stops: [0, 0.38, 1],
                        ),
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              IconButton.filledTonal(
                                onPressed: () => Navigator.of(context).pop(),
                                icon: const Icon(Icons.close_rounded),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Day ${detail.day.dayNumber}',
                                      style: const TextStyle(
                                        color: AppColors.gold,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    Text(
                                      detail.day.title.isEmpty
                                          ? detail.story.title
                                          : detail.day.title,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 17,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _PhotoProgress(
                            count: detail.photos.length,
                            activeIndex: _photoIndex,
                          ),
                          const Spacer(),
                          Align(
                            alignment: Alignment.bottomRight,
                            child: _SmallNextButton(
                              label: isFinalPhoto
                                  ? detail.questions.isEmpty
                                        ? 'Done'
                                        : 'Quiz'
                                  : 'Next',
                              icon: isFinalPhoto
                                  ? detail.questions.isEmpty
                                        ? Icons.check_rounded
                                        : Icons.quiz_rounded
                                  : Icons.arrow_forward_rounded,
                              onTap: () {
                                if (isFinalPhoto) {
                                  _openQuiz(detail);
                                } else {
                                  _pageController.nextPage(
                                    duration: const Duration(milliseconds: 260),
                                    curve: Curves.easeOut,
                                  );
                                }
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PhotoProgress extends StatelessWidget {
  const _PhotoProgress({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 4,
            margin: EdgeInsets.only(right: index == count - 1 ? 0 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: index <= activeIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.34),
            ),
          ),
        );
      }),
    );
  }
}

class _SmallNextButton extends StatelessWidget {
  const _SmallNextButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.deepSaffron,
      borderRadius: BorderRadius.circular(999),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
