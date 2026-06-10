import '../../../app/config.dart';
import '../../../core/api/api_client.dart';
import '../models/story_models.dart';

class AppApiService {
  AppApiService({ApiClient? client, String? authToken})
    : _client = client ?? ApiClient(authToken: authToken);

  final ApiClient _client;

  Future<List<Story>> fetchStories() async {
    if (AppConfig.useDemoData) return _DemoContent.stories;

    final json = await _client.getJson('/api/app/stories');
    final rawStories = json['stories'];
    if (rawStories is! List) return const [];
    return rawStories
        .whereType<Map<String, dynamic>>()
        .map(Story.fromJson)
        .toList();
  }

  Future<DayDetail> fetchDay({
    required String storyId,
    required int dayNumber,
  }) async {
    if (AppConfig.useDemoData) {
      return _DemoContent.dayDetail(storyId: storyId, dayNumber: dayNumber);
    }

    final json = await _client.getJson(
      '/api/app/stories/$storyId/days/$dayNumber',
    );
    return DayDetail.fromJson(json);
  }

  Future<CheckAnswerResult> checkAnswer({
    required String questionId,
    required String optionId,
  }) async {
    if (AppConfig.useDemoData) {
      return CheckAnswerResult(correct: optionId.endsWith('-correct'));
    }

    final json = await _client.postJson(
      '/api/app/questions/$questionId/check-answer',
      {'optionId': optionId},
    );
    return CheckAnswerResult.fromJson(json);
  }
}

class _DemoContent {
  static const stories = <Story>[
    Story(
      id: 'mahabharatam',
      title: 'మహాభారతం',
      description:
          'ధర్మం, నిర్ణయం, కుటుంబం, భక్తి గురించి రోజువారీ కథల ప్రయాణం.',
      coverImageUrl: null,
      categoryName: 'Itihasam',
      days: [
        StoryDaySummary(
          id: 'mahabharatam-day-1',
          dayNumber: 1,
          title: 'కురుక్షేత్రం ప్రారంభం',
        ),
        StoryDaySummary(
          id: 'mahabharatam-day-2',
          dayNumber: 2,
          title: 'భీష్ముని గొప్ప ప్రతిజ్ఞ',
        ),
      ],
    ),
    Story(
      id: 'ramayanam',
      title: 'రామాయణం',
      description: 'శ్రీరాముని జీవితం నుంచి విలువలు, ధైర్యం, ధర్మం.',
      coverImageUrl: null,
      categoryName: 'Itihasam',
      days: [
        StoryDaySummary(
          id: 'ramayanam-day-1',
          dayNumber: 1,
          title: 'అయోధ్యలో ఆనందం',
        ),
      ],
    ),
  ];

  static DayDetail dayDetail({
    required String storyId,
    required int dayNumber,
  }) {
    final story = stories.firstWhere(
      (item) => item.id == storyId,
      orElse: () => stories.first,
    );
    final day = story.days.firstWhere(
      (item) => item.dayNumber == dayNumber,
      orElse: () => story.days.first,
    );

    return DayDetail(
      story: StoryInfo(
        id: story.id,
        title: story.title,
        description: story.description,
      ),
      day: DayInfo(id: day.id, dayNumber: day.dayNumber, title: day.title),
      photos: const [
        StoryPhoto(id: 'photo-1', imageUrl: '', order: 1),
        StoryPhoto(id: 'photo-2', imageUrl: '', order: 2),
        StoryPhoto(id: 'photo-3', imageUrl: '', order: 3),
      ],
      questions: const [
        QuizQuestion(
          id: 'question-1',
          questionText: 'అర్జునుడి రథానికి సారథి ఎవరు?',
          order: 1,
          options: [
            QuizOption(id: 'q1-a', label: 'A', text: 'భీష్ముడు'),
            QuizOption(id: 'q1-b-correct', label: 'B', text: 'శ్రీకృష్ణుడు'),
            QuizOption(id: 'q1-c', label: 'C', text: 'ద్రోణుడు'),
            QuizOption(id: 'q1-d', label: 'D', text: 'కర్ణుడు'),
          ],
        ),
        QuizQuestion(
          id: 'question-2',
          questionText: 'ఈ కథలో ప్రధానమైన పాఠం ఏమిటి?',
          order: 2,
          options: [
            QuizOption(id: 'q2-a', label: 'A', text: 'కోపంతో గెలవాలి'),
            QuizOption(id: 'q2-b', label: 'B', text: 'మౌనంగా ఉండాలి'),
            QuizOption(
              id: 'q2-c-correct',
              label: 'C',
              text: 'ధర్మం వైపు నిలవాలి',
            ),
            QuizOption(id: 'q2-d', label: 'D', text: 'ప్రశ్నలు అడగకూడదు'),
          ],
        ),
      ],
    );
  }
}
