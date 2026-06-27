import '../../../core/api/api_client.dart';

class V2UserApiService {
  V2UserApiService({ApiClient? client, String? authToken})
    : _client = client ?? ApiClient(authToken: authToken);

  final ApiClient _client;

  Future<PhoneCheckResult> checkPhone(String phoneNumber) async {
    final json = await _client.postJson('/api/users/check-phone', {
      'phoneNumber': phoneNumber,
    });
    return PhoneCheckResult.fromJson(json);
  }

  Future<AppUserSession> createSession({
    required String phoneNumber,
    String? name,
  }) async {
    final json = await _client.postJson('/api/users/session', {
      'phoneNumber': phoneNumber,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });
    return AppUserSession.fromJson(json);
  }

  Future<AppUserProfile> fetchMe() async {
    final json = await _client.getJson('/api/users/me');
    final user = json['user'];
    if (user is Map<String, dynamic>) return AppUserProfile.fromJson(user);
    throw const FormatException('Missing user profile');
  }

  Future<UserProgressSnapshot> fetchProgress() async {
    final json = await _client.getJson('/api/app/me/progress');
    return UserProgressSnapshot.fromJson(json);
  }

  Future<void> completeDay(String storyDayId) async {
    await _client.postJson(
      '/api/app/story-days/$storyDayId/complete',
      const <String, dynamic>{},
    );
  }

  Future<void> updateDayProgress({
    required String storyDayId,
    required int lastPhotoIndex,
  }) async {
    await _client.postJson('/api/app/story-days/$storyDayId/progress', {
      'status': 'IN_PROGRESS',
      'lastPhotoIndex': lastPhotoIndex,
    });
  }

  Future<void> deleteAccount() async {
    await _client.deleteJson('/api/users/me');
  }
}

class PhoneCheckResult {
  const PhoneCheckResult({required this.exists, required this.needsProfile});

  final bool exists;
  final bool needsProfile;

  factory PhoneCheckResult.fromJson(Map<String, dynamic> json) {
    return PhoneCheckResult(
      exists: json['exists'] == true,
      needsProfile: json['needsProfile'] == true,
    );
  }
}

class AppUserSession {
  const AppUserSession({required this.token, required this.user});

  final String token;
  final AppUserProfile user;

  factory AppUserSession.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    if (user is! Map<String, dynamic>) {
      throw const FormatException('Missing user profile');
    }
    return AppUserSession(
      token: (json['token'] ?? '').toString(),
      user: AppUserProfile.fromJson(user),
    );
  }
}

class AppUserProfile {
  const AppUserProfile({
    required this.id,
    required this.phoneNumber,
    required this.points,
    required this.currentStreak,
    required this.highestStreak,
  });

  final String id;
  final String phoneNumber;
  final int points;
  final int currentStreak;
  final int highestStreak;

  factory AppUserProfile.fromJson(Map<String, dynamic> json) {
    return AppUserProfile(
      id: (json['id'] ?? '').toString(),
      phoneNumber: (json['phoneNumber'] ?? '').toString(),
      points: _readInt(json['points']),
      currentStreak: _readInt(json['currentStreak']),
      highestStreak: _readInt(json['highestStreak']),
    );
  }
}

class UserProgressSnapshot {
  const UserProgressSnapshot({
    required this.completedStoryDayIds,
    required this.storyProgressByStoryId,
    required this.dayProgressByStoryDayId,
  });

  factory UserProgressSnapshot.empty() {
    return const UserProgressSnapshot(
      completedStoryDayIds: <String>{},
      storyProgressByStoryId: <String, StoryProgressSnapshot>{},
      dayProgressByStoryDayId: <String, StoryDayProgressSnapshot>{},
    );
  }

  final Set<String> completedStoryDayIds;
  final Map<String, StoryProgressSnapshot> storyProgressByStoryId;
  final Map<String, StoryDayProgressSnapshot> dayProgressByStoryDayId;

  factory UserProgressSnapshot.fromJson(Map<String, dynamic> json) {
    final storyProgress = json['storyProgress'];
    final storyProgressByStoryId = <String, StoryProgressSnapshot>{};
    if (storyProgress is List) {
      for (final item in storyProgress) {
        if (item is! Map<String, dynamic>) continue;
        final progress = StoryProgressSnapshot.fromJson(item);
        if (progress.storyId.isNotEmpty) {
          storyProgressByStoryId[progress.storyId] = progress;
        }
      }
    }

    final dayProgress = json['kathaProgress'];
    final completed = <String>{};
    final dayProgressByStoryDayId = <String, StoryDayProgressSnapshot>{};
    if (dayProgress is List) {
      for (final item in dayProgress) {
        if (item is! Map<String, dynamic>) continue;
        final progress = StoryDayProgressSnapshot.fromJson(item);
        if (progress.storyDayId.isEmpty) continue;
        dayProgressByStoryDayId[progress.storyDayId] = progress;
        if (progress.completed) completed.add(progress.storyDayId);
      }
    }

    return UserProgressSnapshot(
      completedStoryDayIds: completed,
      storyProgressByStoryId: storyProgressByStoryId,
      dayProgressByStoryDayId: dayProgressByStoryDayId,
    );
  }
}

class StoryProgressSnapshot {
  const StoryProgressSnapshot({
    required this.storyId,
    required this.completedDaysCount,
    this.lastOpenedDayNumber,
    this.startedAt,
    this.completedAt,
  });

  final String storyId;
  final int completedDaysCount;
  final int? lastOpenedDayNumber;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get started => startedAt != null || lastOpenedDayNumber != null;
  bool get completed => completedAt != null;

  factory StoryProgressSnapshot.fromJson(Map<String, dynamic> json) {
    return StoryProgressSnapshot(
      storyId: (json['storyId'] ?? '').toString(),
      completedDaysCount: _readInt(json['completedDaysCount']),
      lastOpenedDayNumber: _readNullableInt(json['lastOpenedDayNumber']),
      startedAt: _readDate(json['startedAt']),
      completedAt: _readDate(json['completedAt']),
    );
  }
}

class StoryDayProgressSnapshot {
  const StoryDayProgressSnapshot({
    required this.storyId,
    required this.storyDayId,
    required this.status,
    required this.lastPhotoIndex,
    this.startedAt,
    this.completedAt,
  });

  final String storyId;
  final String storyDayId;
  final String status;
  final int lastPhotoIndex;
  final DateTime? startedAt;
  final DateTime? completedAt;

  bool get started => startedAt != null || status == 'IN_PROGRESS' || completed;
  bool get inProgress => status == 'IN_PROGRESS';
  bool get completed => status == 'COMPLETED';

  factory StoryDayProgressSnapshot.fromJson(Map<String, dynamic> json) {
    return StoryDayProgressSnapshot(
      storyId: (json['storyId'] ?? '').toString(),
      storyDayId: (json['storyDayId'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      lastPhotoIndex: _readInt(json['lastPhotoIndex']),
      startedAt: _readDate(json['startedAt']),
      completedAt: _readDate(json['completedAt']),
    );
  }
}

int _readInt(Object? value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _readNullableInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _readDate(Object? value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  return DateTime.tryParse(value.toString());
}
