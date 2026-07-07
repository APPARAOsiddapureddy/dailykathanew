import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/mock_data.dart';
import '../../theme/redesign_theme.dart';
import 'day_complete_screen.dart';
import 'question_screen.dart';

class StoryReaderScreen extends StatefulWidget {
  final Episode episode;
  const StoryReaderScreen({super.key, required this.episode});

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late PageController _pageController;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
    if (widget.episode.quiz != null) {
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
              isTelugu ? 'అయోధ్య కాండం' : 'Ayodhya Kanda',
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
      body: PageView.builder(
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
                Text(
                  card.text,
                  style: const TextStyle(
                    fontSize: 20,
                    color: AppColors.ivoryLight,
                    height: 1.6,
                  ),
                  textAlign: TextAlign.center,
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
