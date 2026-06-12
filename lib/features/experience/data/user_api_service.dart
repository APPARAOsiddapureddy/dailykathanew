import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/api/api_client.dart';
import '../../stories/models/story_models.dart';
import '../models/app_user_models.dart';

class UserApiService {
  UserApiService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;

  Future<PhoneCheckResult> checkPhone(String phoneNumber) async {
    final json = await _client.postJson('/api/users/check-phone', {
      'phoneNumber': phoneNumber,
    });
    return PhoneCheckResult.fromJson(json);
  }

  Future<AppSession> createSession({
    required String phoneNumber,
    String? name,
  }) async {
    final json = await _client.postJson('/api/users/session', {
      'phoneNumber': phoneNumber,
      if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
    });
    return AppSession.fromJson(json);
  }

  Future<AppUser> fetchMe() async {
    final json = await _client.getJson('/api/users/me');
    return AppUser.fromJson(_readMap(json['user']));
  }

  Future<AppUser> updateMe({
    String? name,
    String? notificationPreference,
    String? selectedLanguage,
    List<String>? interests,
  }) async {
    final json = await _client.patchJson('/api/users/me', {
      if (name != null) 'name': name,
      if (notificationPreference != null)
        'notificationPreference': notificationPreference,
      if (selectedLanguage != null) 'selectedLanguage': selectedLanguage,
      if (interests != null) 'interests': interests,
    });
    return AppUser.fromJson(_readMap(json['user']));
  }

  Future<void> markActive() async {
    await _client.postJson('/api/users/active', const {});
  }

  Future<UserProgress> fetchProgress() async {
    final json = await _client.getJson('/api/app/me/progress');
    return UserProgress.fromJson(json);
  }

  Future<ProfileSummary> fetchProfileSummary() async {
    final json = await _client.getJson('/api/app/me/profile-summary');
    return ProfileSummary.fromJson(json);
  }

  Future<List<EarnedBadge>> fetchBadges() async {
    final json = await _client.getJson('/api/app/me/badges');
    final badges = json['badges'];
    if (badges is! List) return const [];
    return badges
        .whereType<Map<String, dynamic>>()
        .map(EarnedBadge.fromJson)
        .toList();
  }

  Future<void> startStory(String storyId) async {
    await _client.postJson('/api/app/stories/$storyId/start', const {});
  }

  Future<void> saveDayProgress({
    required String storyDayId,
    required int lastPhotoIndex,
  }) async {
    await _client.postJson('/api/app/story-days/$storyDayId/progress', {
      'status': 'IN_PROGRESS',
      'lastPhotoIndex': lastPhotoIndex,
    });
  }

  Future<void> completeDay(String storyDayId) async {
    await _client.postJson(
      '/api/app/story-days/$storyDayId/complete',
      const {},
    );
  }

  Future<QuizAttemptResult> submitQuizAttempt({
    required String storyDayId,
    required DateTime startedAt,
    required int timeSpentSeconds,
    required Map<String, QuizOption> selectedOptions,
    required List<QuizQuestion> questions,
  }) async {
    final json = await _client.postJson(
      '/api/app/story-days/$storyDayId/quiz-attempts',
      {
        'startedAt': startedAt.toUtc().toIso8601String(),
        'timeSpentSeconds': timeSpentSeconds,
        'answers': questions.map((question) {
          final option = selectedOptions[question.id]!;
          return {'questionId': question.id, 'selectedOptionId': option.id};
        }).toList(),
      },
    );
    return QuizAttemptResult.fromJson(json);
  }

  Future<QuizReviewResult?> fetchLatestQuizReview(String storyDayId) async {
    final json = await _client.getJson(
      '/api/app/story-days/$storyDayId/quiz-attempts/latest',
    );
    if (json['attempt'] == null) return null;
    return QuizReviewResult.fromJson(json);
  }

  static Future<void> saveSession(AppSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  static Future<AppSession?> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sessionKey);
    if (raw == null || raw.isEmpty) return null;
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) return null;
    return AppSession.fromJson(decoded);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }

  static const _sessionKey = 'daily_katha_app_session';
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

Map<String, dynamic> _readMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  return const {};
}
