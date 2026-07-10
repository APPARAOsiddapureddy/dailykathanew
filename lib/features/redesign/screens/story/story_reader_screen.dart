import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_service.dart';
import '../../data/mock_data.dart';
import 'day_complete_screen.dart';
import 'question_screen.dart';
import 'quiz_review_screen.dart';

class StoryReaderScreen extends StatefulWidget {
  final Journey journey;
  final Episode episode;
  final bool reviewAfterReading;
  const StoryReaderScreen({
    super.key,
    required this.journey,
    required this.episode,
    this.reviewAfterReading = false,
  });

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  bool _isLoading = true;
  bool _isFinishing = false;
  PageController? _pageController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _fetchDetails();
  }

  @override
  void dispose() {
    _persistProgress();
    WidgetsBinding.instance.removeObserver(this);
    _pageController?.dispose();
    super.dispose();
  }

  void _persistProgress() {
    if (widget.reviewAfterReading || !mounted || widget.episode.cards.isEmpty) {
      return;
    }
    context.read<AppState>().updateStoryDayProgress(
      widget.episode.id,
      _currentIndex,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _persistProgress();
    }
  }

  String? _proxiedImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (!rawUrl.startsWith('http')) return rawUrl;
    return '${ApiService.baseUrl}/app/image-proxy?url=${Uri.encodeComponent(rawUrl)}';
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await apiService.fetchStoryDay(
        widget.journey.id,
        widget.episode.dayNumber,
      );

      final photosData = (data['photos'] as List?) ?? [];
      final quizzesData = (data['questions'] as List?) ?? [];

      widget.episode.cards = photosData
          .map(
            (p) => StoryCard(
              id: p['id'],
              imageUrl: _proxiedImageUrl(p['imageUrl']),
              order: p['order'] ?? 0,
            ),
          )
          .toList();

      widget.episode.quizzes = quizzesData.map((q) {
        final optionsData = (q['options'] as List?) ?? [];
        return Quiz(
          id: q['id'],
          question: q['questionText'],
          options: optionsData
              .map((o) => QuizOption(id: o['id'], text: o['text']))
              .toList(),
        );
      }).toList();

      if (!widget.reviewAfterReading && mounted) {
        final savedIndex = context.read<AppState>().getLastPhotoIndexForDay(
          widget.episode.id,
        );
        if (savedIndex > 0 && savedIndex < widget.episode.cards.length) {
          _currentIndex = savedIndex;
        }
      }

      _pageController = PageController(initialPage: _currentIndex);
      if (mounted) unawaited(_precacheAround(_currentIndex));
    } catch (e) {
      debugPrint('Error fetching story day details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Pre-decodes the previous/current/next photo so swiping between them
  /// never shows a blank black frame while the network image loads.
  Future<void> _precacheAround(int index) async {
    for (final i in [index - 1, index, index + 1]) {
      if (i < 0 || i >= widget.episode.cards.length) continue;
      final url = widget.episode.cards[i].imageUrl;
      if (url == null) continue;
      if (!mounted) return;
      try {
        await precacheImage(NetworkImage(url), context);
      } catch (_) {}
    }
  }

  void _onPageChanged(int page) {
    setState(() => _currentIndex = page);
    context.read<AppState>().updateStoryDayProgress(widget.episode.id, page);
    _precacheAround(page);
  }

  void _handleEndOverscroll() {
    if (_isFinishing) return;
    _isFinishing = true;
    _finishStory();
  }

  void _handleTap(TapUpDetails details, int totalCards) {
    final screenWidth = MediaQuery.of(context).size.width;
    final tappedLeft = details.globalPosition.dx < screenWidth * 0.3;
    if (tappedLeft) {
      if (_currentIndex > 0) {
        _pageController?.previousPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    } else {
      if (_currentIndex < totalCards - 1) {
        _pageController?.nextPage(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      } else {
        _handleEndOverscroll();
      }
    }
  }

  void _finishStory() {
    _persistProgress();

    if (widget.reviewAfterReading ||
        context.read<AppState>().isDayCompleted(widget.episode.id)) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuizReviewScreen(episode: widget.episode),
        ),
      );
      return;
    }

    if (widget.episode.quizzes.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              QuestionScreen(journey: widget.journey, episode: widget.episode),
        ),
      );
    } else {
      // Days with no quiz skip QuestionScreen entirely, so this is the
      // only place that would ever mark them complete.
      context.read<AppState>().completeStoryDay(widget.episode.id);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DayCompleteScreen(
            journey: widget.journey,
            episode: widget.episode,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(
          child: CircularProgressIndicator(color: Color(0xFFF6C25A)),
        ),
      );
    }

    if (widget.episode.cards.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: Text(
            'Story not available',
            style: TextStyle(color: Colors.white70, fontSize: 18),
          ),
        ),
      );
    }

    final totalCards = widget.episode.cards.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // ── Swipeable + tappable full-screen photos ──
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapUp: (details) => _handleTap(details, totalCards),
            child: NotificationListener<OverscrollNotification>(
              onNotification: (notification) {
                if (notification.overscroll > 0 &&
                    _currentIndex == totalCards - 1) {
                  _handleEndOverscroll();
                }
                return false;
              },
              child: PageView.builder(
                controller: _pageController,
                itemCount: totalCards,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  final card = widget.episode.cards[index];
                  return card.imageUrl != null
                      ? Image.network(
                          card.imageUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/mahabharatam-cover.png',
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          ),
                        )
                      : Image.asset(
                          'assets/mahabharatam-cover.png',
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                        );
                },
              ),
            ),
          ),

          // ── Progress bars at the very top ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            left: 8,
            right: 8,
            child: Row(
              children: List.generate(totalCards, (i) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: EdgeInsets.only(right: i < totalCards - 1 ? 3 : 0),
                    decoration: BoxDecoration(
                      color: i <= _currentIndex
                          ? Colors.white
                          : Colors.white.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            ),
          ),

          // ── Close button (top-left) ──
          Positioned(
            top: MediaQuery.of(context).padding.top + 18,
            left: 12,
            child: GestureDetector(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.4),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, color: Colors.white, size: 18),
              ),
            ),
          ),

          // ── Bottom: photo counter ──
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 16,
            left: 16,
            right: 16,
            child: Text(
              '${_currentIndex + 1}/$totalCards',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
