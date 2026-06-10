class AppUser {
  const AppUser({
    required this.id,
    required this.phoneNumber,
    required this.points,
    required this.currentStreak,
    required this.highestStreak,
    this.name,
    this.avatarUrl,
  });

  final String id;
  final String phoneNumber;
  final String? name;
  final String? avatarUrl;
  final int points;
  final int currentStreak;
  final int highestStreak;

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: _readString(json['id']),
      phoneNumber: _readString(json['phoneNumber']),
      name: _readNullableString(json['name']),
      avatarUrl: _readNullableString(json['avatarUrl']),
      points: _readInt(json['points']),
      currentStreak: _readInt(json['currentStreak']),
      highestStreak: _readInt(json['highestStreak']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'phoneNumber': phoneNumber,
      'name': name,
      'avatarUrl': avatarUrl,
      'points': points,
      'currentStreak': currentStreak,
      'highestStreak': highestStreak,
    };
  }
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
