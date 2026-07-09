import 'package:flutter/material.dart';

import '../../data/api_service.dart';
import '../../data/mock_data.dart';
import 'day_complete_screen.dart';
import 'question_screen.dart';

class StoryReaderScreen extends StatefulWidget {
  final Journey journey;
  final Episode episode;
  const StoryReaderScreen({super.key, required this.journey, required this.episode});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  String? _proxiedImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (!rawUrl.startsWith('http')) return rawUrl;
    return '${ApiService.baseUrl}/app/image-proxy?url=${Uri.encodeComponent(rawUrl)}';
  }

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    try {
      final data = await apiService.fetchStoryDay(widget.journey.id, widget.episode.dayNumber);

      final photosData = (data['photos'] as List?) ?? [];
      final quizzesData = (data['questions'] as List?) ?? [];

      widget.episode.cards = photosData.map((p) => StoryCard(
        id: p['id'],
        imageUrl: _proxiedImageUrl(p['imageUrl']),
        order: p['order'] ?? 0,
      )).toList();

      widget.episode.quizzes = quizzesData.map((q) {
        final optionsData = (q['options'] as List?) ?? [];
        return Quiz(
          id: q['id'],
          question: q['questionText'],
          options: optionsData.map((o) => QuizOption(id: o['id'], text: o['text'])).toList(),
        );
      }).toList();
    } catch (e) {
      debugPrint('Error fetching story day details: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _goNext() {
    if (_currentIndex < widget.episode.cards.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _finishStory();
    }
  }

  void _goPrev() {
    if (_currentIndex > 0) {
      setState(() => _currentIndex--);
    }
  }

  void _finishStory() {
    if (widget.episode.quizzes.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => QuestionScreen(episode: widget.episode)),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => DayCompleteScreen(episode: widget.episode)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator(color: Color(0xFFF6C25A))),
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
          child: Text('Story not available', style: TextStyle(color: Colors.white70, fontSize: 18)),
        ),
      );
    }

    final card = widget.episode.cards[_currentIndex];
    final totalCards = widget.episode.cards.length;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTapUp: (details) {
          final screenWidth = MediaQuery.of(context).size.width;
          if (details.globalPosition.dx < screenWidth * 0.3) {
            _goPrev();
          } else {
            _goNext();
          }
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            // ── Full-screen image ──
            if (card.imageUrl != null)
              Image.network(
                card.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                errorBuilder: (_, __, ___) => Image.asset(
                  'assets/mahabharatam-cover.png',
                  fit: BoxFit.cover, width: double.infinity, height: double.infinity,
                ),
              )
            else
              Image.asset(
                'assets/mahabharatam-cover.png',
                fit: BoxFit.cover, width: double.infinity, height: double.infinity,
              ),

            // ── Progress bars at the very top ──
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              left: 8, right: 8,
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
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.4),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 18),
                ),
              ),
            ),

            // ── Bottom: counter + Next button ──
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 16,
              left: 16, right: 16,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_currentIndex + 1}/$totalCards',
                    style: const TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  GestureDetector(
                    onTap: _goNext,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0701C),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.arrow_forward, color: Colors.white, size: 18),
                          const SizedBox(width: 6),
                          Text(
                            _currentIndex < totalCards - 1 ? 'Next' : 'Finish',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
