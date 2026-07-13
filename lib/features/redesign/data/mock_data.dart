import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/services/notification_service.dart';
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

  int _highestStreak = 0;
  int get highestStreak => _highestStreak;

  DateTime? _joinedAt;
  DateTime? get joinedAt => _joinedAt;

  int _points = 0;
  int get points => _points;

  List<Journey> _journeys = [];
  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _selectedJourneyId;

  // The signed-in user's id — used to scope per-account local prefs
  // (like reminder time) so switching accounts on one device can't leak
  // one account's settings into another's.
  String? _userId;

  // Notifications / daily reminder
  bool _notificationsEnabled = true;
  bool get notificationsEnabled => _notificationsEnabled;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 7, minute: 0);
  TimeOfDay get reminderTime => _reminderTime;

  String _reminderHourKey() => 'reminder_hour_${_userId ?? 'guest'}';
  String _reminderMinuteKey() => 'reminder_minute_${_userId ?? 'guest'}';

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
    _bootstrap();
  }

  /// Sequenced startup: the saved (or account) language must be known
  /// before content is fetched, so stories arrive in the right language.
  Future<void> _bootstrap() async {
    await _initUser();
    await fetchData();
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    _userName = prefs.getString('user_name') ?? "Guest";
    _selectedJourneyId = prefs.getString('selected_journey_id');
    _language = prefs.getString('app_language') == 'english'
        ? AppLanguage.english
        : AppLanguage.telugu;
    ApiService.contentLang = _language == AppLanguage.english ? 'en' : 'te';
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
    } else {
      // No signed-in account on this device right now — make sure no
      // stray reminder from a previous session keeps firing.
      await NotificationService.instance.cancelDailyReminder();
    }
    notifyListeners();
  }

  /// Loads the signed-in account's own saved reminder time (falls back to
  /// 7:00 AM the first time this account is used on this device) and
  /// makes sure the OS-scheduled notification matches this account's
  /// actual settings — so logging into a different account never keeps
  /// firing the previous account's reminder.
  Future<void> _syncReminderForCurrentUser() async {
    final prefs = await SharedPreferences.getInstance();
    _reminderTime = TimeOfDay(
      hour: prefs.getInt(_reminderHourKey()) ?? 7,
      minute: prefs.getInt(_reminderMinuteKey()) ?? 0,
    );
    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
        isTelugu: _language == AppLanguage.telugu,
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  /// Adopts the account's language preference from the backend — the DB copy
  /// is authoritative on login/session restore (reinstall, second device).
  /// Does NOT write back to the server; only setLanguage does that.
  Future<void> _applyServerLanguage(dynamic selectedLanguage) async {
    if (selectedLanguage == null) return;
    final AppLanguage serverLang = selectedLanguage == 'ENGLISH'
        ? AppLanguage.english
        : AppLanguage.telugu;
    if (serverLang == _language) return;
    _language = serverLang;
    ApiService.contentLang = serverLang == AppLanguage.english ? 'en' : 'te';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'app_language',
      serverLang == AppLanguage.english ? 'english' : 'telugu',
    );
    notifyListeners();
    // Content already on screen was fetched in the old language.
    await fetchData();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final data = await apiService.getMe();
      final user = data['user'];
      if (user != null) {
        _userId = user['id']?.toString();
        _userName = user['name'] ?? _userName;
        _streak = user['currentStreak'] ?? 0;
        _highestStreak = user['highestStreak'] ?? 0;
        final serverPoints = user['points'] ?? 0;
        if (serverPoints is int) {
          _points = serverPoints;
        }
        _joinedAt = DateTime.tryParse(user['createdAt']?.toString() ?? '');
        _notificationsEnabled = user['notificationPreference'] != 'OFF';
        await _applyServerLanguage(user['selectedLanguage']);
        await _syncReminderForCurrentUser();
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

  /// Exchanges a Firebase phone-auth ID token (already verified on-device
  /// by Firebase) for our own app session, logging the user in.
  Future<void> loginWithFirebaseToken(
    String phoneNumber,
    String idToken, {
    String? name,
  }) async {
    final data = await apiService.firebaseLogin(idToken, name: name);
    _authToken = data['token'];
    final user = data['user'];
    if (user != null) {
      _userId = user['id']?.toString();
      _userName = user['name'] ?? _userName;
      _streak = user['currentStreak'] ?? 0;
      _highestStreak = user['highestStreak'] ?? 0;
      final serverPoints = user['points'] ?? 0;
      if (serverPoints is int) {
        _points = serverPoints;
      }
      _joinedAt = DateTime.tryParse(user['createdAt']?.toString() ?? '');
      _notificationsEnabled = user['notificationPreference'] != 'OFF';
      await _applyServerLanguage(user['selectedLanguage']);
    }

    // Store token + name locally
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.write(key: _authTokenKey, value: _authToken!);
    await prefs.remove(_authTokenKey);
    await prefs.setString('user_phone', phoneNumber);
    if (user?['name'] != null) {
      await prefs.setString('user_name', user['name']);
    }

    // This account may have its own reminder time saved from a previous
    // session on this device (or none yet) — never inherit whatever the
    // last signed-in account had scheduled.
    await _syncReminderForCurrentUser();

    notifyListeners();
    await _fetchProgress();
  }

  Future<void> _clearAuth() async {
    _authToken = null;
    _userId = null;
    _storyProgressMap = {};
    _completedDayIds = {};
    _lastPhotoIndexByDayId = {};
    // Reset in-memory only — each account's own saved reminder time stays
    // in prefs under its own key for next time they log in.
    _notificationsEnabled = true;
    _reminderTime = const TimeOfDay(hour: 7, minute: 0);
    await NotificationService.instance.cancelDailyReminder();
    apiService.clearAuthToken();
    final prefs = await SharedPreferences.getInstance();
    await _secureStorage.delete(key: _authTokenKey);
    await prefs.remove(_authTokenKey);
    notifyListeners();
  }

  Future<void> logout() async {
    _userName = "Guest";
    _streak = 0;
    _highestStreak = 0;
    _points = 0;
    _joinedAt = null;
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
    List<Map<String, dynamic>> answers, {
    int? pointsEarned,
    int? correctCount,
  }) async {
    if (!isLoggedIn) return null;
    try {
      final response = await apiService.submitQuizAttempt(
        storyDayId,
        answers,
        pointsEarned: pointsEarned,
        correctCount: correctCount,
      );
      final pointsAdded = response['pointsAdded'];
      if (pointsAdded is int) {
        _points += pointsAdded;
        notifyListeners();
      }
      return response;
    } catch (e) {
      debugPrint('Error submitting quiz attempt: $e');
      return null;
    }
  }

  /// Update the display name on the backend and reflect it locally.
  /// Returns true on success.
  Future<bool> updateProfileName(String name) async {
    if (!isLoggedIn) return false;
    try {
      final response = await apiService.updateProfile(name: name);
      final user = response['user'];
      _userName = (user != null ? user['name'] : null) ?? name;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', _userName);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error updating profile: $e');
      return false;
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

  Future<void> setLanguage(AppLanguage lang) async {
    final bool changed = lang != _language;
    _language = lang;
    ApiService.contentLang = lang == AppLanguage.english ? 'en' : 'te';
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'app_language',
      lang == AppLanguage.english ? 'english' : 'telugu',
    );

    if (isLoggedIn) {
      try {
        await apiService.updateProfile(
          selectedLanguage: lang == AppLanguage.english ? 'ENGLISH' : 'TELUGU',
        );
      } catch (e) {
        // The local preference already applied; don't block on a flaky
        // connection — the backend copy just stays stale until next change.
        debugPrint('Error updating language preference: $e');
      }
    }

    if (changed) {
      // Reload content so titles/questions arrive in the new language.
      await fetchData();
    }
  }

  /// Enables/disables notifications: syncs the backend preference and the
  /// local daily-reminder schedule together.
  Future<void> setNotificationsEnabled(bool enabled) async {
    _notificationsEnabled = enabled;
    notifyListeners();

    if (isLoggedIn) {
      try {
        await apiService.updateProfile(
          notificationPreference: enabled ? 'DAILY_REMINDER' : 'OFF',
        );
      } catch (e) {
        debugPrint('Error updating notification preference: $e');
      }
    }

    if (enabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: _reminderTime.hour,
        minute: _reminderTime.minute,
        isTelugu: _language == AppLanguage.telugu,
      );
    } else {
      await NotificationService.instance.cancelDailyReminder();
    }
  }

  /// Changes the daily reminder time and reschedules if enabled.
  Future<void> setReminderTime(TimeOfDay time) async {
    _reminderTime = time;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_reminderHourKey(), time.hour);
    await prefs.setInt(_reminderMinuteKey(), time.minute);

    if (_notificationsEnabled) {
      await NotificationService.instance.scheduleDailyReminder(
        hour: time.hour,
        minute: time.minute,
        isTelugu: _language == AppLanguage.telugu,
      );
    }
  }

  /// Remembers the epic the user picked during onboarding (or from the
  /// explore tab) so [activeJourney] reflects their choice instead of
  /// always defaulting to whichever story the API returns first.
  Future<void> selectJourney(String journeyId) async {
    _selectedJourneyId = journeyId;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_journey_id', journeyId);
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

          // Covers come only from the CMS cover upload now (one per story,
          // language-neutral) — no more borrowing day photos.
          String coverAsset = 'assets/mahabharatam-cover.png';
          final rawUrl = s['coverImageUrl']?.toString().trim();
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

  Journey get activeJourney {
    final journeys = currentJourneys;
    final selectedId = _selectedJourneyId;
    if (selectedId != null) {
      for (final journey in journeys) {
        if (journey.id == selectedId) return journey;
      }
    }
    return journeys.first;
  }

  /// The day right after [current] in [journey] (by day number), or null
  /// if [current] is the last day.
  Episode? getNextEpisode(Journey journey, Episode current) {
    final allEpisodes = <Episode>[];
    for (final part in journey.parts) {
      allEpisodes.addAll(part.episodes);
    }
    allEpisodes.sort((a, b) => a.dayNumber.compareTo(b.dayNumber));
    final index = allEpisodes.indexWhere((e) => e.id == current.id);
    if (index == -1 || index == allEpisodes.length - 1) return null;
    return allEpisodes[index + 1];
  }

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
