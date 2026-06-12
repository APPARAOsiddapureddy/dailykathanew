class AppUser {
  const AppUser({
    required this.id,
    required this.phoneNumber,
    required this.points,
    required this.currentStreak,
    required this.highestStreak,
    required this.notificationPreference,
    required this.interests,
    this.name,
    this.avatarUrl,
    this.selectedLanguage,
  });

  final String id;
  final String phoneNumber;
  final String? name;
  final String? avatarUrl;
  final String? selectedLanguage;
  final List<String> interests;
  final int points;
  final int currentStreak;
  final int highestStreak;
  final String notificationPreference;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _readString(json['id']),
      phoneNumber: _readString(json['phoneNumber']),
      name: _readNullableString(json['name']),
      avatarUrl: _readNullableString(json['avatarUrl']),
      selectedLanguage: _readNullableString(json['selectedLanguage']),
      interests: _readStringList(json['interests']),
      points: _readInt(json['points']),
      currentStreak: _readInt(json['currentStreak']),
      highestStreak: _readInt(json['highestStreak']),
      notificationPreference: _readString(
        json['notificationPreference'],
        fallback: 'ALL',
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'avatarUrl': avatarUrl,
      'selectedLanguage': selectedLanguage,
      'interests': interests,
      'points': points,
      'currentStreak': currentStreak,
      'highestStreak': highestStreak,
      'notificationPreference': notificationPreference,
    };
  }
}

List<String> _readStringList(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class AppSession {
  const AppSession({required this.token, required this.user});

  final String token;
  final AppUser user;

  factory AppSession.fromJson(Map<String, dynamic> json) {
    return AppSession(
      token: _readString(json['token']),
      user: AppUser.fromJson(_readMap(json['user'])),
    );
  }

  Map<String, dynamic> toJson() {
    return {'token': token, 'user': user.toJson()};
  }
}

class ProfileSummary {
  const ProfileSummary({
    required this.completedStories,
    required this.answeredQuestions,
    required this.correctAnswers,
    this.accuracy,
  });

  final int completedStories;
  final int answeredQuestions;
  final int correctAnswers;
  final int? accuracy;

  factory ProfileSummary.fromJson(Map<String, dynamic> json) {
    return ProfileSummary(
      completedStories: _readInt(json['completedStories']),
      answeredQuestions: _readInt(json['answeredQuestions']),
      correctAnswers: _readInt(json['correctAnswers']),
      accuracy: json['accuracy'] == null ? null : _readInt(json['accuracy']),
    );
  }
}

class UserProgress {
  const UserProgress({
    required this.storyProgress,
    required this.kathaProgress,
  });

  final List<StoryProgress> storyProgress;
  final List<KathaProgressItem> kathaProgress;

  factory UserProgress.fromJson(Map<String, dynamic> json) {
    final rawStoryProgress = json['storyProgress'];
    final rawKathaProgress = json['kathaProgress'];
    return UserProgress(
      storyProgress: rawStoryProgress is List
          ? rawStoryProgress
                .whereType<Map<String, dynamic>>()
                .map(StoryProgress.fromJson)
                .toList()
          : const [],
      kathaProgress: rawKathaProgress is List
          ? rawKathaProgress
                .whereType<Map<String, dynamic>>()
                .map(KathaProgressItem.fromJson)
                .toList()
          : const [],
    );
  }

  static const empty = UserProgress(storyProgress: [], kathaProgress: []);
}

class StoryProgress {
  const StoryProgress({
    required this.storyId,
    required this.completedDaysCount,
    this.lastOpenedDayNumber,
  });

  final String storyId;
  final int completedDaysCount;
  final int? lastOpenedDayNumber;

  factory StoryProgress.fromJson(Map<String, dynamic> json) {
    return StoryProgress(
      storyId: _readString(json['storyId']),
      completedDaysCount: _readInt(json['completedDaysCount']),
      lastOpenedDayNumber: json['lastOpenedDayNumber'] == null
          ? null
          : _readInt(json['lastOpenedDayNumber']),
    );
  }
}

class KathaProgressItem {
  const KathaProgressItem({
    required this.storyId,
    required this.storyDayId,
    required this.status,
    required this.lastPhotoIndex,
  });

  final String storyId;
  final String storyDayId;
  final String status;
  final int lastPhotoIndex;

  bool get completed => status == 'COMPLETED';

  factory KathaProgressItem.fromJson(Map<String, dynamic> json) {
    return KathaProgressItem(
      storyId: _readString(json['storyId']),
      storyDayId: _readString(json['storyDayId']),
      status: _readString(json['status']),
      lastPhotoIndex: _readInt(json['lastPhotoIndex']),
    );
  }
}

class EarnedBadge {
  const EarnedBadge({
    required this.id,
    required this.name,
    this.iconUrl,
    this.earnedAt,
  });

  final String id;
  final String name;
  final String? iconUrl;
  final String? earnedAt;

  factory EarnedBadge.fromJson(Map<String, dynamic> json) {
    final badge = _readMap(json['badge']);
    return EarnedBadge(
      id: _readString(badge['id'], fallback: _readString(json['id'])),
      name: _readString(badge['name'], fallback: 'Badge'),
      iconUrl: _readNullableString(badge['iconUrl']),
      earnedAt: _readNullableString(json['earnedAt']),
    );
  }
}

class QuizAttemptResult {
  const QuizAttemptResult({
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.pointsAdded,
  });

  final int score;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final int pointsAdded;

  factory QuizAttemptResult.fromJson(Map<String, dynamic> json) {
    final attempt = _readMap(json['attempt']);
    return QuizAttemptResult(
      score: _readInt(attempt['score']),
      totalQuestions: _readInt(attempt['totalQuestions']),
      correctCount: _readInt(attempt['correctCount']),
      wrongCount: _readInt(attempt['wrongCount']),
      pointsAdded: _readInt(json['pointsAdded']),
    );
  }
}

class QuizReviewResult {
  const QuizReviewResult({
    required this.attemptId,
    required this.score,
    required this.totalQuestions,
    required this.correctCount,
    required this.wrongCount,
    required this.questions,
  });

  final String attemptId;
  final int score;
  final int totalQuestions;
  final int correctCount;
  final int wrongCount;
  final List<QuizReviewQuestion> questions;

  int get unattemptedCount =>
      totalQuestions -
      questions.where((item) => item.selectedOptionId != null).length;

  factory QuizReviewResult.fromJson(Map<String, dynamic> json) {
    final attempt = _readMap(json['attempt']);
    final rawQuestions = json['questions'];
    return QuizReviewResult(
      attemptId: _readString(attempt['id']),
      score: _readInt(attempt['score']),
      totalQuestions: _readInt(attempt['totalQuestions']),
      correctCount: _readInt(attempt['correctCount']),
      wrongCount: _readInt(attempt['wrongCount']),
      questions: rawQuestions is List
          ? rawQuestions
                .whereType<Map<String, dynamic>>()
                .map(QuizReviewQuestion.fromJson)
                .toList()
          : const [],
    );
  }
}

class QuizReviewQuestion {
  const QuizReviewQuestion({
    required this.id,
    required this.questionText,
    required this.order,
    required this.options,
    this.selectedOptionId,
    this.isCorrect,
  });

  final String id;
  final String questionText;
  final int order;
  final String? selectedOptionId;
  final bool? isCorrect;
  final List<QuizReviewOption> options;

  factory QuizReviewQuestion.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return QuizReviewQuestion(
      id: _readString(json['id']),
      questionText: _readString(json['questionText']),
      order: _readInt(json['order']),
      selectedOptionId: _readNullableString(json['selectedOptionId']),
      isCorrect: json['isCorrect'] is bool ? json['isCorrect'] as bool : null,
      options: rawOptions is List
          ? rawOptions
                .whereType<Map<String, dynamic>>()
                .map(QuizReviewOption.fromJson)
                .toList()
          : const [],
    );
  }
}

class QuizReviewOption {
  const QuizReviewOption({
    required this.id,
    required this.label,
    required this.text,
    required this.isCorrect,
  });

  final String id;
  final String label;
  final String text;
  final bool isCorrect;

  factory QuizReviewOption.fromJson(Map<String, dynamic> json) {
    return QuizReviewOption(
      id: _readString(json['id']),
      label: _readString(json['label']),
      text: _readString(json['text']),
      isCorrect: json['isCorrect'] == true,
    );
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
