class Story {
  const Story({
    required this.id,
    required this.title,
    required this.description,
    required this.coverImageUrl,
    required this.categoryName,
    required this.days,
  });

  final String id;
  final String title;
  final String description;
  final String? coverImageUrl;
  final String categoryName;
  final List<StoryDaySummary> days;

  factory Story.fromJson(Map<String, dynamic> json) {
    final rawDays = json['days'];
    final days = rawDays is List
        ? rawDays
              .whereType<Map<String, dynamic>>()
              .map(StoryDaySummary.fromJson)
              .toList()
        : <StoryDaySummary>[];
    days.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));

    return Story(
      id: _readString(json['id']),
      title: _readString(json['title'], fallback: 'Untitled Story'),
      description: _readString(json['description']),
      coverImageUrl: _readNullableString(json['coverImageUrl']),
      categoryName: _readString(
        _readMap(json['category'])['name'],
        fallback: 'Stories',
      ),
      days: days,
    );
  }
}

class StoryDaySummary {
  const StoryDaySummary({
    required this.id,
    required this.dayNumber,
    required this.title,
  });

  final String id;
  final int dayNumber;
  final String title;

  factory StoryDaySummary.fromJson(Map<String, dynamic> json) {
    return StoryDaySummary(
      id: _readString(json['id']),
      dayNumber: _readInt(json['dayNumber']),
      title: _readString(json['title'], fallback: 'Daily Katha'),
    );
  }
}

class DayDetail {
  const DayDetail({
    required this.story,
    required this.day,
    required this.photos,
    required this.questions,
  });

  final StoryInfo story;
  final DayInfo day;
  final List<StoryPhoto> photos;
  final List<QuizQuestion> questions;

  factory DayDetail.fromJson(Map<String, dynamic> json) {
    final rawPhotos = json['photos'];
    final rawQuestions = json['questions'];
    final photos = rawPhotos is List
        ? rawPhotos
              .whereType<Map<String, dynamic>>()
              .map(StoryPhoto.fromJson)
              .toList()
        : <StoryPhoto>[];
    final questions = rawQuestions is List
        ? rawQuestions
              .whereType<Map<String, dynamic>>()
              .map(QuizQuestion.fromJson)
              .toList()
        : <QuizQuestion>[];
    photos.sort((a, b) => a.order.compareTo(b.order));
    questions.sort((a, b) => a.order.compareTo(b.order));

    return DayDetail(
      story: StoryInfo.fromJson(_readMap(json['story'])),
      day: DayInfo.fromJson(_readMap(json['day'])),
      photos: photos,
      questions: questions,
    );
  }
}

class StoryInfo {
  const StoryInfo({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  factory StoryInfo.fromJson(Map<String, dynamic> json) {
    return StoryInfo(
      id: _readString(json['id']),
      title: _readString(json['title'], fallback: 'Daily Katha'),
      description: _readString(json['description']),
    );
  }
}

class DayInfo {
  const DayInfo({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.moral,
    required this.tomorrowTeaser,
  });

  final String id;
  final int dayNumber;
  final String title;
  final String moral;
  final String tomorrowTeaser;

  factory DayInfo.fromJson(Map<String, dynamic> json) {
    return DayInfo(
      id: _readString(json['id']),
      dayNumber: _readInt(json['dayNumber']),
      title: _readString(json['title'], fallback: 'Daily Katha'),
      moral: _readString(json['moral']),
      tomorrowTeaser: _readString(json['tomorrowTeaser']),
    );
  }
}

class StoryPhoto {
  const StoryPhoto({
    required this.id,
    required this.imageUrl,
    required this.order,
  });

  final String id;
  final String imageUrl;
  final int order;

  factory StoryPhoto.fromJson(Map<String, dynamic> json) {
    return StoryPhoto(
      id: _readString(json['id']),
      imageUrl: _readString(json['imageUrl']),
      order: _readInt(json['order']),
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.questionText,
    required this.order,
    required this.options,
  });

  final String id;
  final String questionText;
  final int order;
  final List<QuizOption> options;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return QuizQuestion(
      id: _readString(json['id']),
      questionText: _readString(json['questionText']),
      order: _readInt(json['order']),
      options: rawOptions is List
          ? rawOptions
                .whereType<Map<String, dynamic>>()
                .map(QuizOption.fromJson)
                .toList()
          : const [],
    );
  }
}

class QuizOption {
  const QuizOption({required this.id, required this.label, required this.text});

  final String id;
  final String label;
  final String text;

  factory QuizOption.fromJson(Map<String, dynamic> json) {
    return QuizOption(
      id: _readString(json['id']),
      label: _readString(json['label']),
      text: _readString(json['text']),
    );
  }
}

class CheckAnswerResult {
  const CheckAnswerResult({required this.correct});

  final bool correct;

  factory CheckAnswerResult.fromJson(Map<String, dynamic> json) {
    return CheckAnswerResult(correct: json['correct'] == true);
  }
}

String _readString(Object? value, {String fallback = ''}) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return fallback;
}

String? _readNullableString(Object? value) {
  if (value is String && value.trim().isNotEmpty) return value.trim();
  return null;
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  return const {};
}
