import 'package:flutter/material.dart';

enum AppLanguage { telugu, english }

class QuizOption {
  final String text;
  final bool isCorrect;
  QuizOption(this.text, this.isCorrect);
}

class Quiz {
  final String question;
  final List<QuizOption> options;
  Quiz({required this.question, required this.options});
}

class StoryCard {
  final String text;
  final String? imageUrl;
  StoryCard({required this.text, this.imageUrl});
}

class Episode {
  final String id;
  final int dayNumber;
  final String title;
  final List<StoryCard> cards;
  final Quiz? quiz;
  bool isCompleted;

  Episode({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.cards,
    this.quiz,
    this.isCompleted = false,
  });
}

class JourneyPart {
  final String title;
  final int totalDays;
  final List<Episode> episodes;
  final bool isCompleted;
  final bool isLocked;

  JourneyPart({
    required this.title,
    required this.totalDays,
    required this.episodes,
    this.isCompleted = false,
    this.isLocked = false,
  });
}

class Journey {
  final String id;
  final String title;
  final String description;
  final int totalDays;
  final String partNamePlural;
  final List<JourneyPart> parts;
  final String coverAsset;

  Journey({
    required this.id,
    required this.title,
    required this.description,
    required this.totalDays,
    required this.partNamePlural,
    required this.parts,
    required this.coverAsset,
  });
}

class AppState extends ChangeNotifier {
  AppLanguage _language = AppLanguage.telugu;
  AppLanguage get language => _language;

  String get userName => "Priya Sharma";
  int get streak => 12;

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  List<Journey> get currentJourneys => _language == AppLanguage.telugu ? _teluguJourneys : _englishJourneys;

  Journey get activeJourney => currentJourneys.first;

  // MARK: - MOCK DATA (Telugu)
  final List<Journey> _teluguJourneys = [
    Journey(
      id: 'ramayanam',
      title: 'రామాయణం',
      description: 'శ్రీరాముని జీవితం నుంచి విలువలు, ధైర్యం, ధర్మం.',
      totalDays: 100,
      partNamePlural: '6 కాండలు',
      coverAsset: 'assets/mahabharatam-cover.png', // Fallback for mock
      parts: [
        JourneyPart(
          title: 'బాల కాండం',
          totalDays: 20,
          isCompleted: true,
          episodes: [],
        ),
        JourneyPart(
          title: 'అయోధ్య కాండం',
          totalDays: 25,
          episodes: [
            Episode(
              id: 'ayodhya-day-12',
              dayNumber: 12,
              title: 'కైకేయి రెండు వరాలు',
              cards: [
                StoryCard(text: 'కైకేయి తన రెండు వరాలను కోరింది — భరతునికి పట్టాభిషేకం, రామునికి పద్నాలుగు సంవత్సరాల వనవాసం.'),
                StoryCard(text: 'మాట తప్పలేని దశరథుడు దుఃఖంతో మౌనమయ్యాడు.'),
              ],
              quiz: Quiz(
                question: 'ఈ రోజు కథ నుండి కైకేయికి రెండు వరాలను ఎవరు ఇచ్చారు?',
                options: [
                  QuizOption('దశరథుడు', true),
                  QuizOption('రావణుడు', false),
                  QuizOption('భరతుడు', false),
                  QuizOption('హనుమంతుడు', false),
                ],
              ),
            ),
          ],
        ),
        JourneyPart(
          title: 'అరణ్య కాండం',
          totalDays: 20,
          isLocked: true,
          episodes: [],
        ),
      ],
    ),
    Journey(
      id: 'mahabharatam',
      title: 'మహాభారతం',
      description: 'ధర్మం, నిర్ణయం, కుటుంబం, భక్తి గురించి రోజువారీ కథల ప్రయాణం.',
      totalDays: 180,
      partNamePlural: '18 పర్వాలు',
      coverAsset: 'assets/mahabharatam-cover.png',
      parts: [],
    ),
    Journey(
      id: 'bhagavatam',
      title: 'భాగవతం',
      description: 'కృష్ణుని లీలలు మరియు భక్తి కథలు.',
      totalDays: 120,
      partNamePlural: '12 స్కంధాలు',
      coverAsset: 'assets/mahabharatam-cover.png',
      parts: [],
    ),
  ];

  // MARK: - MOCK DATA (English)
  final List<Journey> _englishJourneys = [
    Journey(
      id: 'ramayanam',
      title: 'Ramayanam',
      description: 'Values, courage, and dharma from the life of Lord Rama.',
      totalDays: 100,
      partNamePlural: '6 Kandas',
      coverAsset: 'assets/mahabharatam-cover.png',
      parts: [
        JourneyPart(
          title: 'Bala Kanda',
          totalDays: 20,
          isCompleted: true,
          episodes: [],
        ),
        JourneyPart(
          title: 'Ayodhya Kanda',
          totalDays: 25,
          episodes: [
            Episode(
              id: 'ayodhya-day-12',
              dayNumber: 12,
              title: 'Kaikeyi\'s Two Boons',
              cards: [
                StoryCard(text: 'Kaikeyi demanded her two boons — coronation for Bharata, and fourteen years of exile for Rama.'),
                StoryCard(text: 'Bound by his word, Dasharatha fell silent in profound grief.'),
              ],
              quiz: Quiz(
                question: 'Who granted Kaikeyi the two boons in today\'s story?',
                options: [
                  QuizOption('Dasharatha', true),
                  QuizOption('Ravana', false),
                  QuizOption('Bharata', false),
                  QuizOption('Hanuman', false),
                ],
              ),
            ),
          ],
        ),
        JourneyPart(
          title: 'Aranya Kanda',
          totalDays: 20,
          isLocked: true,
          episodes: [],
        ),
      ],
    ),
    Journey(
      id: 'mahabharatam',
      title: 'Mahabharatam',
      description: 'An epic journey of dharma, choices, family, and devotion.',
      totalDays: 180,
      partNamePlural: '18 Parvas',
      coverAsset: 'assets/mahabharatam-cover.png',
      parts: [],
    ),
    Journey(
      id: 'bhagavatam',
      title: 'Bhagavatam',
      description: 'The divine play of Krishna and tales of devotion.',
      totalDays: 120,
      partNamePlural: '12 Skandhas',
      coverAsset: 'assets/mahabharatam-cover.png',
      parts: [],
    ),
  ];
}
