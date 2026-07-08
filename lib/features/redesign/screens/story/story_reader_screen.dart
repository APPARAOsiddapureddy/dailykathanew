import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/api_service.dart';
import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
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
  late PageController _pageController;
  int _currentIndex = 0;
  bool _isLoading = true;

  String? _proxiedImageUrl(String? rawUrl) {
    if (rawUrl == null || rawUrl.isEmpty) {
      return null;
    }
    if (!rawUrl.startsWith('http')) {
      return rawUrl;
    }
    return '${ApiService.baseUrl}/app/image-proxy?url=${Uri.encodeComponent(rawUrl)}';
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextCard() {
    if (_currentIndex < widget.episode.cards.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishStory();
    }
  }

  void _finishStory() {
    if (widget.episode.quizzes.isNotEmpty) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => QuestionScreen(episode: widget.episode),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => DayCompleteScreen(episode: widget.episode),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    final isTelugu = state.language == AppLanguage.telugu;

    return Scaffold(
      backgroundColor: AppColors.sacredMaroon,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: AppColors.white),
        title: Column(
          children: [
            Text(
              widget.journey.title,
              style: const TextStyle(color: AppColors.ivoryLight, fontSize: 14),
            ),
            Text(
              isTelugu ? 'రోజు ${widget.episode.dayNumber}' : 'Day ${widget.episode.dayNumber}',
              style: const TextStyle(color: AppColors.templeGold, fontSize: 16),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: AppColors.templeGold))
        : widget.episode.cards.isEmpty 
          ? const Center(
              child: Text(
                'కథ అందుబాటులో లేదు\n(Story not available)', 
                style: TextStyle(color: AppColors.ivoryLight, fontSize: 18),
                textAlign: TextAlign.center,
              )
            )
          : PageView.builder(
              controller: _pageController,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemCount: widget.episode.cards.length,
              itemBuilder: (context, index) {
                final card = widget.episode.cards[index];
                return Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'ॐ',
                        style: TextStyle(
                          fontSize: 48,
                          color: AppColors.templeGold,
                          fontFamily: 'Noto Serif Telugu',
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        isTelugu ? 'కార్డ్ ${index + 1} / ${widget.episode.cards.length}' : 'Card ${index + 1} / ${widget.episode.cards.length}',
                        style: const TextStyle(color: AppColors.softBrown),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        widget.episode.title,
                        style: const TextStyle(
                          fontSize: 28,
                          color: AppColors.templeGold,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Noto Serif Telugu',
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      if (card.imageUrl != null)
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.network(
                              card.imageUrl!,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text(
                                  'Image not available',
                                  style: TextStyle(color: AppColors.ivoryLight),
                                ),
                              ),
                            ),
                          ),
                        )
                      else
                        const Expanded(
                          child: Center(
                            child: Text(
                              'Image not available',
                              style: TextStyle(color: AppColors.ivoryLight),
                            ),
                          ),
                        ),
                      const Spacer(),
                      TextButton(
                        onPressed: _nextCard,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isTelugu ? 'తదుపరి కార్డ్ కోసం స్వైప్ చేయండి' : 'Swipe for next card',
                              style: const TextStyle(color: AppColors.softBrown),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, color: AppColors.softBrown, size: 16),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
