import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

enum AppLanguage { telugu, english }

class QuizOption {
  final String id;
  final String text;
  QuizOption({required this.id, required this.text});
}

class Quiz {
  final String id;
  final String question;
  final List<QuizOption> options;
  Quiz({required this.id, required this.question, required this.options});
}

class StoryCard {
  final String id;
  final String? imageUrl;
  final int order;
  StoryCard({required this.id, this.imageUrl, required this.order});
}

class Episode {
  final String id;
  final int dayNumber;
  final String title;
  List<StoryCard> cards;
  List<Quiz> quizzes;
  bool isCompleted;

  Episode({
    required this.id,
    required this.dayNumber,
    required this.title,
    this.cards = const [],
    this.quizzes = const [],
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
  final String categoryName;

  Journey({
    required this.id,
    required this.title,
    required this.description,
    required this.totalDays,
    required this.partNamePlural,
    required this.parts,
    required this.coverAsset,
    this.categoryName = '',
  });
}

/// Per-story progress from backend
class StoryProgressInfo {
  final String storyId;
  final int completedDaysCount;
  final int? lastOpenedDayNumber;
  final bool isCompleted;

  StoryProgressInfo({
    required this.storyId,
    required this.completedDaysCount,
    this.lastOpenedDayNumber,
    this.isCompleted = false,
  });
}

class AppState extends ChangeNotifier {
  static const _secureStorage = FlutterSecureStorage();
  static const _authTokenKey = 'auth_token';

  AppLanguage _language = AppLanguage.telugu;
  AppLanguage get language => _language;

  String _userName = "";
  String get userName => _userName;

  int _streak = 0;
  int get streak => _streak;

  int _points = 0;
  int get points => _points;

  List<Journey> _journeys = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _authToken;
  String? get authToken => _authToken;
  bool get isLoggedIn => _authToken != null && _authToken!.isNotEmpty;

  // User-specific progress
  Map<String, StoryProgressInfo> _storyProgressMap = {};
  Set<String> _completedDayIds = {};
  Map<String, int> _lastPhotoIndexByDayId = {};

  /// Total completed days across all stories for this user
  int get completedDays {
    int total = 0;
    for (final sp in _storyProgressMap.values) {
      total += sp.completedDaysCount;
    }
    return total;
  }

  /// Number of stories the user has started
  int get storiesStarted => _storyProgressMap.length;

  /// Get progress for a specific story
  StoryProgressInfo? getStoryProgress(String storyId) =>
      _storyProgressMap[storyId];

  /// Check if a specific day is completed
  bool isDayCompleted(String storyDayId) =>
      _completedDayIds.contains(storyDayId);

  int getLastPhotoIndexForDay(String storyDayId) =>
      _lastPhotoIndexByDayId[storyDayId] ?? 0;

  /// Get completed days count for a specific story
  int getCompletedDaysForStory(String storyId) {
    return _storyProgressMap[storyId]?.completedDaysCount ?? 0;
  }

  AppState() {
    _initUser();
    fetchData();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? "Guest";
    _authToken = await _secureStorage.read(key: _authTokenKey);
    final legacyToken = prefs.getString(_authTokenKey);
    if ((_authToken == null || _authToken!.isEmpty) &&
        legacyToken != null &&
        legacyToken.isNotEmpty) {
      _authToken = legacyToken;
      await _secureStorage.write(key: _authTokenKey, value: legacyToken);
      await prefs.remove(_authTokenKey);
    }
    if (_authToken != null && _authToken!.isNotEmpty) {
      apiService.setAuthToken(_authToken!);
      await _fetchUserProfile();
    }
    notifyListeners();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final data = await apiService.getMe();
      final user = data['user'];
      if (user != null) {
        _userName = user['name'] ?? _userName;
        _streak = user['currentStreak'] ?? 0;
        final serverPoints = user['points'] ?? 0;
        if (serverPoints is int) {
          _points = math.max(_points, serverPoints);
        }
        notifyListeners();
      }
      await _fetchProgress();
    } catch (e) {
      debugPrint('Error fetching user profile: $e');
      // Token may be expired — clear it
      if (e.toString().contains('401') || e.toString().contains('Invalid')) {
        await _clearAuth();
      }
    }
  }

  Future<void> _fetchProgress() async {
    if (!isLoggedIn) return;
    try {
      final data = await apiService.getProgress();
      final storyProgress = (data['storyProgress'] as List?) ?? [];
      final kathaProgress = (data['kathaProgress'] as List?) ?? [];

      _storyProgressMap = {};
      for (final sp in storyProgress) {
        final storyId = sp['storyId'] as String;
        _storyProgressMap[storyId] = StoryProgressInfo(
          storyId: storyId,
          completedDaysCount: sp['completedDaysCount'] ?? 0,
          lastOpenedDayNumber: sp['lastOpenedDayNumber'],
          isCompleted: sp['completedAt'] != null,
        );
      }

      _completedDayIds = {};
      _lastPhotoIndexByDayId = {};
      for (final kp in kathaProgress) {
        final storyDayId = kp['storyDayId'] as String?;
        if (storyDayId == null) continue;
        final lastPhotoIndex = kp['lastPhotoIndex'];
        if (lastPhotoIndex is int) {
          _lastPhotoIndexByDayId[storyDayId] = lastPhotoIndex;
        }
        if (kp['status'] == 'COMPLETED') {
          _completedDayIds.add(storyDayId);
        }
      }

      // Mark episodes as completed based on progress
      for (final journey in _journeys) {
        for (final part in journey.parts) {
          for (final episode in part.episodes) {
            episode.isCompleted = _completedDayIds.contains(episode.id);
          }
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching progress: $e');
    }
  }

  /// Called after successful login/registration
  Future<void> loginWithSession(String phoneNumber, {String? name}) async {
    final data = await apiService.createSession(phoneNumber, name: name);
    _authToken = data['token'];
    final user = data['user'];
    if (user != null) {
      _userName = user['name'] ?? _userName;
      _streak = user['currentStreak'] ?? 0;
      final serverPoints = user['points'] ?? 0;
      if (serverPoints is int) {
        _points = math.max(_points, serverPoints);
      }
    }

    // Store token + name locally
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: _authTokenKey, value: _authToken!);
    await prefs.remove(_authTokenKey);
    await prefs.setString('user_phone', phoneNumber);
    if (user?['name'] != null) {
      await prefs.setString('user_name', user['name']);
    }

    notifyListeners();
    await _fetchProgress();
  }

  Future<void> _clearAuth() async {
    _authToken = null;
    _storyProgressMap = {};
    _completedDayIds = {};
    _lastPhotoIndexByDayId = {};
    apiService.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _authTokenKey);
    await prefs.remove(_authTokenKey);
    notifyListeners();
  }

  Future<void> logout() async {
    _userName = "Guest";
    _streak = 0;
    _points = 0;
    await _clearAuth();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_phone');
    await prefs.remove('user_name');
  }

  /// Mark a story day as completed
  Future<void> completeStoryDay(String storyDayId) async {
    if (!isLoggedIn) return;
    try {
      await apiService.completeStoryDay(storyDayId);
      await refreshUserData();
    } catch (e) {
      debugPrint('Error completing story day: $e');
    }
  }

  Future<void> updateStoryDayProgress(
    String storyDayId,
    int lastPhotoIndex,
  ) async {
    if (!isLoggedIn) return;
    _lastPhotoIndexByDayId[storyDayId] = lastPhotoIndex;
    try {
      await apiService.updateStoryDayProgress(storyDayId, lastPhotoIndex);
    } catch (e) {
      debugPrint('Error updating story day progress: $e');
    }
  }

  Future<Map<String, dynamic>?> submitQuizAttempt(
    String storyDayId,
    List<Map<String, dynamic>> answers,
    {int? pointsEarned,
    int? correctCount,
    }
  ) async {
    if (!isLoggedIn) return null;
    try {
      final response = await apiService.submitQuizAttempt(
        storyDayId,
        answers,
        pointsEarned: pointsEarned,
        correctCount: correctCount,
      );
      final serverPoints =
          response['points'] ?? response['totalPoints'] ?? response['currentPoints'];
      if (serverPoints is int) {
        _points = math.max(_points, serverPoints);
        notifyListeners();
      }
      return response;
    } catch (e) {
      debugPrint('Error submitting quiz attempt: $e');
      return null;
    }
  }

  Future<void> deleteAccount() async {
    if (!isLoggedIn) return;
    try {
      await apiService.deleteAccount();
    } finally {
      await logout();
    }
  }

  void setLanguage(AppLanguage lang) {
    _language = lang;
    notifyListeners();
  }

  void updatePoints(int newPoints) {
    _points += newPoints;
    notifyListeners();
  }

  Future<void> fetchData() async {
    _isLoading = true;
    notifyListeners();
    try {
      final storiesData = await apiService.fetchStories();
      _journeys = await Future.wait(
        storiesData.map((s) async {
          final days = (s['days'] as List?) ?? [];
          final episodes = days
              .map(
                (d) => Episode(
                  id: d['id'],
                  dayNumber: d['dayNumber'],
                  title: d['title'] ?? 'Day ${d['dayNumber']}',
                ),
              )
              .toList();

          // Prefer the CMS cover. Older stories without one use their first
          // published day's share image or first photo as the heading image.
          String coverAsset = 'assets/mahabharatam-cover.png';
          String? rawUrl = s['coverImageUrl']?.toString().trim();
          if ((rawUrl == null || !rawUrl.startsWith('http')) &&
              days.isNotEmpty) {
            final firstDayNumber = days.first['dayNumber'];
            if (firstDayNumber is int) {
              try {
                rawUrl = await apiService.fetchStoryHeadingImage(
                  s['id'].toString(),
                  firstDayNumber,
                );
              } catch (error) {
                debugPrint(
                  'Error loading heading image for ${s['title']}: $error',
                );
              }
            }
          }
          if (rawUrl != null && rawUrl.startsWith('http')) {
            coverAsset = ApiService.proxiedImageUrl(rawUrl);
          }

          return Journey(
            id: s['id'],
            title: s['title'] ?? '',
            description: s['description'] ?? '',
            totalDays: days.length,
            partNamePlural: 'Days',
            parts: [
              JourneyPart(
                title: 'All Chapters',
                totalDays: days.length,
                episodes: episodes,
              ),
            ],
            coverAsset: coverAsset,
            categoryName: s['category']?['name'] ?? '',
          );
        }),
      );

      // If logged in, mark episodes with completion status
      if (isLoggedIn && _completedDayIds.isNotEmpty) {
        for (final journey in _journeys) {
          for (final part in journey.parts) {
            for (final episode in part.episodes) {
              episode.isCompleted = _completedDayIds.contains(episode.id);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading journeys: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Refresh all user data (call after completing a day, etc.)
  Future<void> refreshUserData() async {
    await _fetchUserProfile();
    await _fetchProgress();
  }

  List<Journey> get currentJourneys =>
      _journeys.isNotEmpty ? _journeys : _mockFallback();

  Journey get activeJourney => currentJourneys.first;

  List<Journey> _mockFallback() {
    return [
      Journey(
        id: 'ramayanam',
        title: 'రామాయణం',
        description: 'శ్రీరాముని జీవితం నుంచి విలువలు, ధైర్యం, ధర్మం.',
        totalDays: 100,
        partNamePlural: '6 కాండలు',
        coverAsset: 'assets/mahabharatam-cover.png',
        parts: [],
      ),
    ];
  }
}
