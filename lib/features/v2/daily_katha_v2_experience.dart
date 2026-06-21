import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/material.dart';

import '../../app/config.dart';
import '../../app/theme.dart';
import '../../core/widgets/app_logo.dart';
import '../stories/data/app_api_service.dart';
import '../stories/models/story_models.dart' as cms;
import '../stories/screens/quiz_screen.dart';
import 'data/v2_user_api_service.dart';

class DailyKathaV2Experience extends StatefulWidget {
  const DailyKathaV2Experience({super.key});

  @override
  State<DailyKathaV2Experience> createState() => _DailyKathaV2ExperienceState();
}

enum _LaunchStage { splash, phone, profile, otp, home }

enum _ShellTab { home, library, bookmarks, profile }

class _DailyKathaV2ExperienceState extends State<DailyKathaV2Experience> {
  final AppApiService _api = AppApiService();
  V2UserApiService? _userApi;
  _LaunchStage _stage = _LaunchStage.splash;
  _ShellTab _tab = _ShellTab.home;
  String _phoneNumber = '';
  String? _profileName;
  ReadingProgress? _progress;
  UserProgressSnapshot _userProgress = UserProgressSnapshot.empty();
  final Set<String> _completedEpisodeIds = <String>{};
  final Set<String> _quizCompletedEpisodeIds = <String>{};
  final Map<String, QuizPerformance> _quizPerformanceByEpisodeId =
      <String, QuizPerformance>{};
  int _points = 0;
  int _streakDays = 0;
  List<MythSeries> _series = const [];
  bool _loadingContent = true;
  String? _contentError;
  String? _openingEpisodeId;
  final Set<String> _bookmarkedEpisodes = <String>{};

  @override
  void initState() {
    super.initState();
    unawaited(_finishSplash());
    unawaited(_loadStories());
  }

  Future<void> _loadStories() async {
    setState(() {
      _loadingContent = true;
      _contentError = null;
    });
    try {
      final stories = await _api.fetchStories();
      final baseSeries = stories.map(MythSeries.fromCmsStory).where((series) {
        return series.episodes.isNotEmpty;
      }).toList();
      final hydratedSeries = await Future.wait(
        baseSeries.map(_hydrateSeriesCover),
      );
      if (!mounted) return;
      setState(() {
        _series = hydratedSeries;
        _loadingContent = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _contentError = error.toString();
        _loadingContent = false;
      });
    }
  }

  Future<void> _finishSplash() async {
    await Future<void>.delayed(MotionSpec.splashHold);
    if (!mounted || _stage != _LaunchStage.splash) return;
    setState(() => _stage = _LaunchStage.phone);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: MotionSpec.navigation,
      switchInCurve: MotionSpec.standard,
      switchOutCurve: MotionSpec.standard.flipped,
      transitionBuilder: (child, animation) {
        if (motionReduced(context)) {
          return FadeTransition(opacity: animation, child: child);
        }
        final offset = Tween<Offset>(
          begin: const Offset(0, 0.025),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: offset, child: child),
        );
      },
      child: switch (_stage) {
        _LaunchStage.splash => const V2SplashScreen(key: ValueKey('splash')),
        _LaunchStage.phone => PhoneNumberScreen(
          key: const ValueKey('phone'),
          initialPhone: _phoneNumber,
          onPhoneReady: (phone, needsProfile) {
            setState(() {
              _phoneNumber = phone;
              _profileName = null;
              _stage = needsProfile ? _LaunchStage.profile : _LaunchStage.otp;
            });
          },
        ),
        _LaunchStage.profile => ProfileNameScreen(
          key: const ValueKey('profile-name'),
          phone: _phoneNumber,
          initialName: _profileName ?? '',
          onBack: () => setState(() => _stage = _LaunchStage.phone),
          onContinue: (name) {
            setState(() {
              _profileName = name;
              _stage = _LaunchStage.otp;
            });
          },
        ),
        _LaunchStage.otp => OtpVerificationScreen(
          key: const ValueKey('otp'),
          phone: _phoneNumber,
          onChangePhone: () => setState(() {
            _profileName = null;
            _stage = _LaunchStage.phone;
          }),
          onVerified: _createBackendSession,
        ),
        _LaunchStage.home => V2MainShell(
          key: const ValueKey('home'),
          tab: _tab,
          series: _series,
          loadingContent: _loadingContent,
          contentError: _contentError,
          openingEpisodeId: _openingEpisodeId,
          progress: _progress,
          userProgress: _userProgress,
          completedEpisodeIds: _completedEpisodeIds,
          points: _points,
          streakDays: _streakDays,
          bookmarkedEpisodeIds: _bookmarkedEpisodes,
          onTabChanged: (tab) => setState(() => _tab = tab),
          onOpenEpisode: _openEpisode,
          onOpenSeries: _openSeries,
          onRetryContent: _loadStories,
          onToggleBookmark: _toggleBookmark,
          onLogout: _logout,
        ),
      },
    );
  }

  void _openSeries(MythSeries series) {
    Navigator.of(context).push(
      CinematicRoute<void>(
        builder: (_) => SeriesDetailScreen(
          series: series,
          progress: _progress,
          userProgress: _userProgress,
          completedEpisodeIds: _completedEpisodeIds,
          onOpenEpisode: _openEpisode,
        ),
      ),
    );
  }

  Future<void> _createBackendSession() async {
    final session = await V2UserApiService().createSession(
      phoneNumber: '+91$_phoneNumber',
      name: _profileName,
    );
    final userApi = V2UserApiService(authToken: session.token);
    final progress = await userApi.fetchProgress();
    if (!mounted) return;
    setState(() {
      _userApi = userApi;
      _points = session.user.points;
      _streakDays = session.user.currentStreak;
      _completedEpisodeIds
        ..clear()
        ..addAll(progress.completedStoryDayIds);
      _userProgress = progress;
      _stage = _LaunchStage.home;
    });
  }

  Future<void> _openEpisode(MythSeries series, MythEpisode episode) async {
    if (_openingEpisodeId != null) return;
    setState(() => _openingEpisodeId = episode.id);

    MythEpisode resolvedEpisode;
    try {
      resolvedEpisode = await _loadEpisodeDetail(series, episode);
    } catch (error) {
      if (!mounted) return;
      setState(() => _openingEpisodeId = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load episode: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() {
      _openingEpisodeId = null;
      _series = _series.map((item) {
        if (item.id != series.id) return item;
        return item.replaceEpisode(resolvedEpisode);
      }).toList();
    });

    final resolvedSeries = _series.firstWhere(
      (item) => item.id == series.id,
      orElse: () => series.replaceEpisode(resolvedEpisode),
    );
    final savedProgress = _progressForEpisode(resolvedSeries, resolvedEpisode);
    final initialSlide = savedProgress?.slideIndex ?? 0;
    if (!_completedEpisodeIds.contains(resolvedEpisode.id)) {
      setState(() {
        _progress = ReadingProgress(
          seriesId: resolvedSeries.id,
          episodeId: resolvedEpisode.id,
          slideIndex: initialSlide,
          completed: false,
        );
      });
      unawaited(
        _saveEpisodeProgressInBackend(resolvedEpisode.id, initialSlide),
      );
    }

    Navigator.of(context).push(
      CinematicRoute<void>(
        builder: (_) => ReaderScreen(
          series: resolvedSeries,
          episode: resolvedEpisode,
          initialSlide: initialSlide,
          isBookmarked: _bookmarkedEpisodes.contains(resolvedEpisode.id),
          onToggleBookmark: () => _toggleBookmark(resolvedEpisode.id),
          onProgress: (slideIndex) {
            setState(() {
              _progress = ReadingProgress(
                seriesId: resolvedSeries.id,
                episodeId: resolvedEpisode.id,
                slideIndex: slideIndex,
                completed: false,
              );
            });
            unawaited(
              _saveEpisodeProgressInBackend(resolvedEpisode.id, slideIndex),
            );
          },
          onCompleted: () {
            final firstCompletion = _completedEpisodeIds.add(
              resolvedEpisode.id,
            );
            setState(() {
              _progress = ReadingProgress(
                seriesId: resolvedSeries.id,
                episodeId: resolvedEpisode.id,
                slideIndex: resolvedEpisode.slides.length - 1,
                completed: true,
              );
            });
            if (firstCompletion) {
              unawaited(_completeEpisodeInBackend(resolvedEpisode.id));
            }

            void finishStory() {
              Navigator.of(context).pop();
            }

            if (resolvedEpisode.questions.isNotEmpty) {
              final existingPerformance =
                  _quizPerformanceByEpisodeId[resolvedEpisode.id];
              if (existingPerformance != null) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute<void>(
                    builder: (_) => QuizPerformanceScreen(
                      episode: resolvedEpisode,
                      performance: existingPerformance,
                    ),
                  ),
                );
                return;
              }
              Navigator.of(context).pushReplacement(
                MaterialPageRoute<void>(
                  builder: (_) => QuizScreen(
                    api: _api,
                    questions: resolvedEpisode.questions,
                    onCompleteWithResult: (result) {
                      final firstQuizCompletion = _quizCompletedEpisodeIds.add(
                        resolvedEpisode.id,
                      );
                      final performance = QuizPerformance(
                        score: result.score,
                        total: result.total,
                        pointsEarned: firstQuizCompletion
                            ? result.score * 5
                            : 0,
                        answers: result.answers,
                      );
                      setState(() {
                        _quizPerformanceByEpisodeId[resolvedEpisode.id] =
                            performance;
                      });
                      if (firstQuizCompletion) unawaited(_refreshUserStats());
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute<void>(
                          builder: (_) => QuizPerformanceScreen(
                            episode: resolvedEpisode,
                            performance: performance,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            } else {
              finishStory();
            }
          },
        ),
      ),
    );
  }

  Future<MythEpisode> _loadEpisodeDetail(
    MythSeries series,
    MythEpisode episode,
  ) async {
    if (episode.isHydrated) return episode;
    final detail = await _api.fetchDay(
      storyId: series.id,
      dayNumber: episode.dayNumber,
    );
    return episode.hydrateFromCms(detail, series: series);
  }

  Future<MythSeries> _hydrateSeriesCover(MythSeries series) async {
    if (series.coverImageUrl?.trim().isNotEmpty == true) return series;
    if (series.episodes.isEmpty) return series;

    try {
      final firstEpisode = series.episodes.first;
      final detail = await _api.fetchDay(
        storyId: series.id,
        dayNumber: firstEpisode.dayNumber,
      );
      final hydratedEpisode = firstEpisode.hydrateFromCms(
        detail,
        series: series,
      );
      final firstPhotoUrl = detail.photos.isEmpty
          ? null
          : detail.photos.first.imageUrl.trim();
      return series
          .replaceEpisode(hydratedEpisode)
          .withCoverImageUrl(
            firstPhotoUrl?.isEmpty == true ? null : firstPhotoUrl,
          );
    } catch (_) {
      return series;
    }
  }

  void _toggleBookmark(String episodeId) {
    setState(() {
      if (!_bookmarkedEpisodes.add(episodeId)) {
        _bookmarkedEpisodes.remove(episodeId);
      }
    });
  }

  void _logout() {
    setState(() {
      _userApi = null;
      _phoneNumber = '';
      _profileName = null;
      _tab = _ShellTab.home;
      _progress = null;
      _userProgress = UserProgressSnapshot.empty();
      _completedEpisodeIds.clear();
      _quizCompletedEpisodeIds.clear();
      _quizPerformanceByEpisodeId.clear();
      _points = 0;
      _streakDays = 0;
      _bookmarkedEpisodes.clear();
      _stage = _LaunchStage.phone;
    });
  }

  Future<void> _completeEpisodeInBackend(String storyDayId) async {
    final userApi = _userApi;
    if (userApi == null) return;
    try {
      await userApi.completeDay(storyDayId);
      await _refreshUserStats();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save streak: $error'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveEpisodeProgressInBackend(
    String storyDayId,
    int slideIndex,
  ) async {
    final userApi = _userApi;
    if (userApi == null || _completedEpisodeIds.contains(storyDayId)) return;
    try {
      await userApi.updateDayProgress(
        storyDayId: storyDayId,
        lastPhotoIndex: slideIndex,
      );
    } catch (_) {
      // Keep reading smooth even if a background progress save fails.
    }
  }

  Future<void> _refreshUserStats() async {
    final userApi = _userApi;
    if (userApi == null) return;
    final user = await userApi.fetchMe();
    final progress = await userApi.fetchProgress();
    if (!mounted) return;
    setState(() {
      _points = user.points;
      _streakDays = user.currentStreak;
      _completedEpisodeIds
        ..clear()
        ..addAll(progress.completedStoryDayIds);
      _userProgress = progress;
    });
  }

  ReadingProgress? _progressForEpisode(MythSeries series, MythEpisode episode) {
    return progressForEpisode(
      liveProgress: _progress,
      userProgress: _userProgress,
      completedEpisodeIds: _completedEpisodeIds,
      series: series,
      episode: episode,
    );
  }
}

class MotionSpec {
  static const splashHold = Duration(milliseconds: 1700);
  static const micro = Duration(milliseconds: 190);
  static const soft = Duration(milliseconds: 260);
  static const navigation = Duration(milliseconds: 390);
  static const hero = Duration(milliseconds: 620);
  static const homeEntrance = Duration(milliseconds: 680);

  static const standard = Curves.easeOutCubic;
  static const emphasized = Curves.easeInOutCubicEmphasized;
  static const page = Curves.easeInOutCubic;
}

bool motionReduced(BuildContext context) {
  final media = MediaQuery.maybeOf(context);
  return media?.disableAnimations == true ||
      media?.accessibleNavigation == true;
}

class CinematicRoute<T> extends PageRouteBuilder<T> {
  CinematicRoute({required WidgetBuilder builder})
    : super(
        transitionDuration: MotionSpec.navigation,
        reverseTransitionDuration: MotionSpec.soft,
        pageBuilder: (context, animation, secondaryAnimation) =>
            builder(context),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          if (motionReduced(context)) {
            return FadeTransition(opacity: animation, child: child);
          }
          final fade = CurvedAnimation(
            parent: animation,
            curve: const Interval(0, 0.82, curve: MotionSpec.standard),
          );
          final slide =
              Tween<Offset>(
                begin: const Offset(0, 0.035),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(
                  parent: animation,
                  curve: MotionSpec.emphasized,
                ),
              );
          return FadeTransition(
            opacity: fade,
            child: SlideTransition(position: slide, child: child),
          );
        },
      );
}

class V2SplashScreen extends StatefulWidget {
  const V2SplashScreen({super.key});

  @override
  State<V2SplashScreen> createState() => _V2SplashScreenState();
}

class _V2SplashScreenState extends State<V2SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = motionReduced(context);
    return Scaffold(
      body: Stack(
        children: [
          AnimatedBuilder(
            animation: _controller,
            builder: (context, _) {
              return ParchmentBackdrop(
                glow: reduceMotion ? 0.42 : 0.34 + (_controller.value * 0.14),
                bellOffset: reduceMotion
                    ? 0
                    : math.sin(_controller.value * math.pi * 2) * 0.75,
              );
            },
          ),
          Center(
            child: StaggeredReveal(
              delay: Duration.zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AnimatedBuilder(
                    animation: _controller,
                    builder: (context, child) {
                      final pulse = reduceMotion
                          ? 0.0
                          : math.sin(_controller.value * math.pi) * 0.018;
                      return Transform.scale(
                        scale: 1 + pulse,
                        child: AppLogo(
                          size: 128,
                          glow: reduceMotion
                              ? 0.18
                              : 0.18 + (_controller.value * 0.12),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Daily Katha',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: AppColors.deepSaffron,
                      letterSpacing: 0,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ప్రతి రోజు ఒక కథ, ఒక మంచి పాఠం',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedBrown,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ParchmentBackdrop extends StatelessWidget {
  const ParchmentBackdrop({
    super.key,
    required this.glow,
    required this.bellOffset,
  });

  final double glow;
  final double bellOffset;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(0, -0.55 + bellOffset * 0.01),
          radius: 0.95,
          colors: [
            Color.lerp(const Color(0xFFFFF6DB), AppColors.gold, glow * 0.18)!,
            AppColors.ivory,
            const Color(0xFFFFEFD1),
          ],
          stops: const [0, 0.56, 1],
        ),
      ),
      child: CustomPaint(
        painter: _ParchmentPainter(glow: glow, bellOffset: bellOffset),
        child: const SizedBox.expand(),
      ),
    );
  }
}

class _ParchmentPainter extends CustomPainter {
  const _ParchmentPainter({required this.glow, required this.bellOffset});

  final double glow;
  final double bellOffset;

  @override
  void paint(Canvas canvas, Size size) {
    final dust = Paint()
      ..color = AppColors.deepSaffron.withValues(alpha: 0.035 + glow * 0.02)
      ..strokeWidth = 1.2;
    for (var i = 0; i < 22; i++) {
      final x = (size.width * ((i * 37) % 100) / 100) + bellOffset;
      final y = size.height * (((i * 53) % 100) / 100);
      canvas.drawCircle(Offset(x, y), 0.8 + (i % 3) * 0.5, dust);
    }

    final bellPaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4;
    final center = Offset(size.width * 0.5 + bellOffset, size.height * 0.18);
    canvas.drawArc(
      Rect.fromCenter(center: center, width: 132, height: 44),
      math.pi * 0.08,
      math.pi * 0.84,
      false,
      bellPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _ParchmentPainter oldDelegate) {
    return oldDelegate.glow != glow || oldDelegate.bellOffset != bellOffset;
  }
}

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({
    super.key,
    required this.initialPhone,
    required this.onPhoneReady,
  });

  final String initialPhone;
  final void Function(String phone, bool needsProfile) onPhoneReady;

  @override
  State<PhoneNumberScreen> createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  late String _phone;
  Timer? _autoSubmitTimer;
  bool _checking = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _phone = widget.initialPhone;
  }

  @override
  void dispose() {
    _autoSubmitTimer?.cancel();
    super.dispose();
  }

  void _append(String digit) {
    if (_phone.length >= 10 || _checking) return;
    setState(() {
      _phone += digit;
      _error = null;
    });
    if (_phone.length == 10) {
      _autoSubmitTimer?.cancel();
      _autoSubmitTimer = Timer(const Duration(milliseconds: 360), _requestOtp);
    }
  }

  void _backspace() {
    _autoSubmitTimer?.cancel();
    if (_checking) return;
    if (_phone.isEmpty) return;
    setState(() {
      _phone = _phone.substring(0, _phone.length - 1);
      _error = null;
    });
  }

  Future<void> _requestOtp() async {
    if (_phone.length != 10 || _checking) return;
    setState(() {
      _checking = true;
      _error = null;
    });
    try {
      final result = await V2UserApiService().checkPhone('+91$_phone');
      if (!mounted) return;
      widget.onPhoneReady(_phone, !result.exists || result.needsProfile);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _checking = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _phone.length > 5
        ? '${_phone.substring(0, 5)} ${_phone.substring(5)}'
        : _phone;
    return AuthScaffold(
      title: 'Daily Katha లోకి స్వాగతం',
      subtitle: 'మొదటి కథకు చేరుకోవడానికి మీ మొబైల్ నంబర్ నమోదు చేయండి.',
      child: AnimatedContainer(
        duration: MotionSpec.soft,
        curve: MotionSpec.standard,
        padding: const EdgeInsets.all(18),
        decoration: authCardDecoration(active: _phone.isNotEmpty),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.ivory,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: const Text(
                    '+91',
                    style: TextStyle(
                      color: AppColors.brown,
                      fontWeight: FontWeight.w900,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: MotionSpec.micro,
                    style: TextStyle(
                      color: _phone.isEmpty
                          ? AppColors.mutedBrown.withValues(alpha: 0.5)
                          : AppColors.brown,
                      fontSize: 24,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                    ),
                    child: Text(formatted.isEmpty ? '00000 00000' : formatted),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            FilledButton(
              onPressed: _phone.length == 10 && !_checking ? _requestOtp : null,
              child: const Text('OTP పొందండి'),
            ),
            if (_checking) ...[
              const SizedBox(height: 12),
              const Text(
                'Checking...',
                style: TextStyle(
                  color: AppColors.deepSaffron,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ],
        ),
      ),
      keypad: NumberPad(onDigit: _append, onBackspace: _backspace),
    );
  }
}

class ProfileNameScreen extends StatefulWidget {
  const ProfileNameScreen({
    super.key,
    required this.phone,
    required this.initialName,
    required this.onBack,
    required this.onContinue,
  });

  final String phone;
  final String initialName;
  final VoidCallback onBack;
  final ValueChanged<String> onContinue;

  @override
  State<ProfileNameScreen> createState() => _ProfileNameScreenState();
}

class _ProfileNameScreenState extends State<ProfileNameScreen> {
  late final TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    widget.onContinue(name);
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'Tell us your name',
      subtitle:
          '+91 ${widget.phone} is new here. Add your name to create your Daily Katha profile.',
      child: AnimatedContainer(
        duration: MotionSpec.soft,
        curve: MotionSpec.standard,
        padding: const EdgeInsets.all(18),
        decoration: authCardDecoration(active: true),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              autofocus: true,
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _continue(),
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: _continue, child: const Text('Continue')),
            TextButton(
              onPressed: widget.onBack,
              child: const Text('Change number'),
            ),
          ],
        ),
      ),
    );
  }
}

class OtpVerificationScreen extends StatefulWidget {
  const OtpVerificationScreen({
    super.key,
    required this.phone,
    required this.onChangePhone,
    required this.onVerified,
  });

  final String phone;
  final VoidCallback onChangePhone;
  final Future<void> Function() onVerified;

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  String _otp = '';
  bool _verifying = false;
  String? _error;

  void _append(String digit) {
    if (_otp.length >= 4 || _verifying) return;
    setState(() => _otp += digit);
    if (_otp.length == 4) {
      Future<void>.delayed(const Duration(milliseconds: 180), _verify);
    }
  }

  void _backspace() {
    if (_otp.isEmpty || _verifying) return;
    setState(() => _otp = _otp.substring(0, _otp.length - 1));
  }

  Future<void> _verify() async {
    if (_otp.length != 4 || _verifying) return;
    setState(() {
      _verifying = true;
      _error = null;
    });
    try {
      await Future<void>.delayed(const Duration(milliseconds: 520));
      await widget.onVerified();
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = '$error';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthScaffold(
      title: 'OTP నమోదు చేయండి',
      subtitle: '+91 ${widget.phone} కు పంపిన 4 అంకెల కోడ్‌ను నమోదు చేయండి.',
      child: AnimatedContainer(
        duration: MotionSpec.soft,
        curve: MotionSpec.standard,
        padding: const EdgeInsets.all(18),
        decoration: authCardDecoration(active: _otp.isNotEmpty),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(4, (index) {
                final active = index == _otp.length && !_verifying;
                final filled = index < _otp.length;
                return AnimatedContainer(
                  duration: MotionSpec.micro,
                  curve: MotionSpec.standard,
                  width: 58,
                  height: 64,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: filled
                        ? const Color(0xFFFFF4DA)
                        : AppColors.ivory.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: active ? AppColors.saffron : AppColors.border,
                      width: active ? 1.8 : 1,
                    ),
                  ),
                  child: Text(
                    filled ? '•' : '',
                    style: const TextStyle(
                      color: AppColors.deepSaffron,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 18),
            if (_error != null) ...[
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
            ],
            AnimatedSwitcher(
              duration: MotionSpec.micro,
              child: _verifying
                  ? const Text(
                      'లోడ్ అవుతోంది...',
                      key: ValueKey('verifying'),
                      style: TextStyle(
                        color: AppColors.deepSaffron,
                        fontWeight: FontWeight.w800,
                      ),
                    )
                  : TextButton(
                      key: const ValueKey('change-phone'),
                      onPressed: widget.onChangePhone,
                      child: const Text('నంబర్ మార్చండి'),
                    ),
            ),
          ],
        ),
      ),
      keypad: NumberPad(onDigit: _append, onBackspace: _backspace),
    );
  }
}

BoxDecoration authCardDecoration({required bool active}) {
  return BoxDecoration(
    color: AppColors.card.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(active ? 28 : 24),
    border: Border.all(
      color: active
          ? AppColors.saffron.withValues(alpha: 0.38)
          : AppColors.border.withValues(alpha: 0.55),
    ),
    boxShadow: [
      BoxShadow(
        color: AppColors.deepSaffron.withValues(alpha: active ? 0.16 : 0.08),
        blurRadius: active ? 34 : 24,
        offset: const Offset(0, 18),
      ),
    ],
  );
}

class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
    this.keypad,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? keypad;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ParchmentBackdrop(glow: 0.38, bellOffset: 0),
          SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 14),
                  child: Column(
                    children: [
                      const Spacer(flex: 1),
                      StaggeredReveal(
                        child: Column(
                          children: [
                            const AppLogo(size: 76),
                            const SizedBox(height: 24),
                            Text(
                              title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.headlineMedium,
                            ),
                            const SizedBox(height: 10),
                            Text(
                              subtitle,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(color: AppColors.mutedBrown),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 34),
                      Hero(
                        tag: 'auth-card',
                        child: Material(
                          color: Colors.transparent,
                          child: child,
                        ),
                      ),
                      const Spacer(flex: 2),
                      if (keypad case final keypad?) keypad,
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NumberPad extends StatelessWidget {
  const NumberPad({
    super.key,
    required this.onDigit,
    required this.onBackspace,
  });

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final values = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', '⌫'];
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisExtent: 56,
        mainAxisSpacing: 8,
        crossAxisSpacing: 12,
      ),
      itemCount: values.length,
      itemBuilder: (context, index) {
        final value = values[index];
        if (value.isEmpty) return const SizedBox.shrink();
        final isBack = value == '⌫';
        return PressableScale(
          onTap: isBack ? onBackspace : () => onDigit(value),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: isBack
                  ? Colors.transparent
                  : Colors.white.withValues(alpha: 0.42),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: isBack
                  ? const Icon(Icons.backspace_outlined, color: AppColors.brown)
                  : Text(
                      value,
                      style: const TextStyle(
                        color: AppColors.brown,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}

class V2MainShell extends StatelessWidget {
  const V2MainShell({
    super.key,
    required this.tab,
    required this.series,
    required this.loadingContent,
    required this.contentError,
    required this.openingEpisodeId,
    required this.progress,
    required this.userProgress,
    required this.completedEpisodeIds,
    required this.points,
    required this.streakDays,
    required this.bookmarkedEpisodeIds,
    required this.onTabChanged,
    required this.onOpenEpisode,
    required this.onOpenSeries,
    required this.onRetryContent,
    required this.onToggleBookmark,
    required this.onLogout,
  });

  final _ShellTab tab;
  final List<MythSeries> series;
  final bool loadingContent;
  final String? contentError;
  final String? openingEpisodeId;
  final ReadingProgress? progress;
  final UserProgressSnapshot userProgress;
  final Set<String> completedEpisodeIds;
  final int points;
  final int streakDays;
  final Set<String> bookmarkedEpisodeIds;
  final ValueChanged<_ShellTab> onTabChanged;
  final Future<void> Function(MythSeries series, MythEpisode episode)
  onOpenEpisode;
  final ValueChanged<MythSeries> onOpenSeries;
  final Future<void> Function() onRetryContent;
  final ValueChanged<String> onToggleBookmark;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final pages = <_ShellTab, Widget>{
      _ShellTab.home: HomeScreenV2(
        catalog: ContentCatalog(series),
        loadingContent: loadingContent,
        contentError: contentError,
        progress: progress,
        userProgress: userProgress,
        completedEpisodeIds: completedEpisodeIds,
        points: points,
        streakDays: streakDays,
        onOpenEpisode: onOpenEpisode,
        onOpenSeries: onOpenSeries,
        onRetryContent: onRetryContent,
      ),
      _ShellTab.library: LibraryScreenV2(
        catalog: ContentCatalog(series),
        loadingContent: loadingContent,
        contentError: contentError,
        progress: progress,
        userProgress: userProgress,
        completedEpisodeIds: completedEpisodeIds,
        onOpenEpisode: onOpenEpisode,
        onOpenSeries: onOpenSeries,
        onRetryContent: onRetryContent,
      ),
      _ShellTab.bookmarks: BookmarksScreenV2(
        catalog: ContentCatalog(series),
        bookmarkedEpisodeIds: bookmarkedEpisodeIds,
        onOpenEpisode: onOpenEpisode,
      ),
      _ShellTab.profile: ProfileScreenV2(
        points: points,
        streakDays: streakDays,
        completedCount: completedEpisodeIds.length,
        onLogout: onLogout,
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          AnimatedSwitcher(
            duration: MotionSpec.soft,
            child: KeyedSubtree(key: ValueKey(tab), child: pages[tab]!),
          ),
          if (openingEpisodeId != null) const EpisodeOpeningOverlay(),
        ],
      ),
      bottomNavigationBar: DailyKathaBottomNav(
        selected: tab,
        onChanged: onTabChanged,
      ),
    );
  }
}

class DailyKathaBottomNav extends StatelessWidget {
  const DailyKathaBottomNav({
    super.key,
    required this.selected,
    required this.onChanged,
  });

  final _ShellTab selected;
  final ValueChanged<_ShellTab> onChanged;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: selected.index,
      height: 74,
      backgroundColor: AppColors.card,
      indicatorColor: const Color(0xFFFFE7B0),
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      onDestinationSelected: (index) => onChanged(_ShellTab.values[index]),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.home_outlined),
          selectedIcon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        NavigationDestination(
          icon: Icon(Icons.auto_stories_outlined),
          selectedIcon: Icon(Icons.auto_stories_rounded),
          label: 'Library',
        ),
        NavigationDestination(
          icon: Icon(Icons.bookmark_border_rounded),
          selectedIcon: Icon(Icons.bookmark_rounded),
          label: 'Bookmarks',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Profile',
        ),
      ],
    );
  }
}

class EpisodeOpeningOverlay extends StatelessWidget {
  const EpisodeOpeningOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ColoredBox(
        color: AppColors.brown.withValues(alpha: 0.22),
        child: Center(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
              child: Container(
                width: 220,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.ivory.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.62),
                  ),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CinematicSkeleton(width: 64, height: 64, radius: 22),
                    SizedBox(height: 16),
                    Text(
                      'కథ సిద్ధమవుతోంది...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.brown,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreenV2 extends StatelessWidget {
  const HomeScreenV2({
    super.key,
    required this.catalog,
    required this.loadingContent,
    required this.contentError,
    required this.progress,
    required this.userProgress,
    required this.completedEpisodeIds,
    required this.points,
    required this.streakDays,
    required this.onOpenEpisode,
    required this.onOpenSeries,
    required this.onRetryContent,
  });

  final ContentCatalog catalog;
  final bool loadingContent;
  final String? contentError;
  final ReadingProgress? progress;
  final UserProgressSnapshot userProgress;
  final Set<String> completedEpisodeIds;
  final int points;
  final int streakDays;
  final Future<void> Function(MythSeries series, MythEpisode episode)
  onOpenEpisode;
  final ValueChanged<MythSeries> onOpenSeries;
  final Future<void> Function() onRetryContent;

  @override
  Widget build(BuildContext context) {
    final continueTarget = catalog.nextUnreadAfter(
      progress?.episodeId,
      completedEpisodeIds,
    );
    return Scaffold(
      body: Stack(
        children: [
          const ParchmentBackdrop(glow: 0.24, bellOffset: 0),
          SafeArea(
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate.fixed([
                      StaggeredReveal(
                        delay: Duration.zero,
                        child: HomeTopBar(
                          points: points,
                          streakDays: streakDays,
                        ),
                      ),
                      if (loadingContent) ...[
                        const SizedBox(height: 22),
                        const HomeContentSkeleton(),
                      ] else if (contentError != null) ...[
                        const SizedBox(height: 34),
                        EducationalEmptyState(
                          icon: Icons.wifi_off_rounded,
                          title: 'కథలు లోడ్ కాలేదు',
                          message: contentError!,
                          action: FilledButton.icon(
                            onPressed: onRetryContent,
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('మళ్లీ ప్రయత్నించండి'),
                          ),
                        ),
                      ] else if (continueTarget == null) ...[
                        const SizedBox(height: 34),
                        const EducationalEmptyState(
                          icon: Icons.auto_stories_outlined,
                          title: 'ఇంకా కథలు లేవు',
                          message:
                              'CMS లో published story days జోడించిన తర్వాత అవి ఇక్కడ కనిపిస్తాయి.',
                        ),
                      ] else ...[
                        const SizedBox(height: 22),
                        StaggeredReveal(
                          delay: const Duration(milliseconds: 90),
                          child: ContinueReadingCard(
                            pair: continueTarget,
                            progress: progressForEpisode(
                              liveProgress: progress,
                              userProgress: userProgress,
                              completedEpisodeIds: completedEpisodeIds,
                              series: continueTarget.series,
                              episode: continueTarget.episode,
                            ),
                            onTap: () => onOpenEpisode(
                              continueTarget.series,
                              continueTarget.episode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 28),
                        StaggeredReveal(
                          delay: const Duration(milliseconds: 180),
                          child: SectionHeader(
                            title: 'ఈరోజు కథ',
                            subtitle: '5 నిమిషాల్లో ఒక గొప్ప పాఠం',
                          ),
                        ),
                        const SizedBox(height: 12),
                        StaggeredReveal(
                          delay: const Duration(milliseconds: 230),
                          child: TodayKathaCard(
                            pair: catalog.todayEpisode ?? continueTarget,
                            onTap: () => onOpenEpisode(
                              (catalog.todayEpisode ?? continueTarget).series,
                              (catalog.todayEpisode ?? continueTarget).episode,
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                        StaggeredReveal(
                          delay: const Duration(milliseconds: 300),
                          child: SectionHeader(
                            title: 'Popular Series',
                            subtitle: 'మహా ఇతిహాసాల నుంచి మొదలు పెట్టండి',
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 246,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            physics: const BouncingScrollPhysics(),
                            itemCount: catalog.popularSeries.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 14),
                            itemBuilder: (context, index) {
                              final series = catalog.popularSeries[index];
                              return StaggeredReveal(
                                delay: Duration(milliseconds: 350 + index * 70),
                                child: SeriesCard(
                                  series: series,
                                  progressValue: seriesProgressValue(
                                    series: series,
                                    liveProgress: progress,
                                    userProgress: userProgress,
                                    completedEpisodeIds: completedEpisodeIds,
                                  ),
                                  onTap: () => onOpenSeries(series),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 30),
                        StaggeredReveal(
                          delay: const Duration(milliseconds: 580),
                          child: ContinueLearningStrip(
                            catalog: catalog,
                            onOpenEpisode: onOpenEpisode,
                          ),
                        ),
                        const SizedBox(height: 18),
                        StaggeredReveal(
                          delay: const Duration(milliseconds: 640),
                          child: ExploreAllStoriesCard(
                            onTap: () => onOpenSeries(catalog.series.first),
                          ),
                        ),
                      ],
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class HomeTopBar extends StatelessWidget {
  const HomeTopBar({super.key, required this.points, required this.streakDays});

  final int points;
  final int streakDays;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const AppLogo(size: 48),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('నమస్కారం', style: Theme.of(context).textTheme.bodyMedium),
              Text(
                'Daily Katha',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: AppColors.deepSaffron),
              ),
            ],
          ),
        ),
        RewardPill(
          icon: Icons.stars_rounded,
          label: '$points',
          color: AppColors.deepSaffron,
        ),
        const SizedBox(width: 8),
        RewardPill(
          icon: Icons.local_fire_department_rounded,
          label: '$streakDays',
          color: AppColors.saffron,
        ),
      ],
    );
  }
}

class RewardPill extends StatelessWidget {
  const RewardPill({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 17),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class HomeContentSkeleton extends StatelessWidget {
  const HomeContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CinematicSkeleton(height: 292, radius: 26),
        const SizedBox(height: 28),
        const CinematicSkeleton(width: 160, height: 22),
        const SizedBox(height: 12),
        const CinematicSkeleton(height: 164, radius: 26),
        const SizedBox(height: 30),
        const CinematicSkeleton(width: 190, height: 22),
        const SizedBox(height: 12),
        Row(
          children: const [
            Expanded(child: CinematicSkeleton(height: 230, radius: 24)),
            SizedBox(width: 14),
            Expanded(child: CinematicSkeleton(height: 230, radius: 24)),
          ],
        ),
      ],
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}

class ContinueReadingCard extends StatelessWidget {
  const ContinueReadingCard({
    super.key,
    required this.pair,
    required this.progress,
    required this.onTap,
  });

  final EpisodePair pair;
  final ReadingProgress? progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = progress == null ? 0.0 : progress!.percentage(pair.episode);
    return PressableScale(
      onTap: onTap,
      child: Container(
        decoration: cinematicCardDecoration(),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Hero(
              tag: 'episode-art-${pair.episode.id}',
              child: ProgressiveArtwork(
                asset: pair.series.coverAsset,
                imageUrl: pair.series.coverImageUrl,
                height: 214,
                accent: pair.series.accent,
                alignment: Alignment.center,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    progress == null ? 'Start Reading' : 'Continue Reading',
                    style: const TextStyle(
                      color: AppColors.deepSaffron,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '${pair.series.title} · Day ${pair.episode.dayNumber}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    pair.episode.title,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedBrown,
                    ),
                  ),
                  const SizedBox(height: 16),
                  SmoothProgress(value: percent),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TodayKathaCard extends StatelessWidget {
  const TodayKathaCard({super.key, required this.pair, required this.onTap});

  final EpisodePair pair;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        height: 164,
        decoration: cinematicCardDecoration(radius: 26),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Hero(
                tag: 'today-art-${pair.episode.id}',
                child: ProgressiveArtwork(
                  asset: pair.series.coverAsset,
                  imageUrl: pair.series.coverImageUrl,
                  accent: pair.series.accent,
                  alignment: Alignment.centerRight,
                ),
              ),
            ),
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.74),
                      Colors.black.withValues(alpha: 0.18),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      EpisodePill(text: pair.series.category),
                      const SizedBox(width: 8),
                      EpisodePill(text: '${pair.episode.readingMinutes} min'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    pair.episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pair.episode.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFFFFE7C2),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SeriesCard extends StatelessWidget {
  const SeriesCard({
    super.key,
    required this.series,
    required this.progressValue,
    required this.onTap,
  });

  final MythSeries series;
  final double progressValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 178,
      child: PressableScale(
        onTap: onTap,
        child: Container(
          decoration: cinematicCardDecoration(radius: 24),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Hero(
                tag: 'series-art-${series.id}',
                child: ProgressiveArtwork(
                  asset: series.coverAsset,
                  imageUrl: series.coverImageUrl,
                  height: 128,
                  accent: series.accent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      series.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${series.episodes.length} episodes',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 12),
                    SmoothProgress(value: progressValue),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContinueLearningStrip extends StatelessWidget {
  const ContinueLearningStrip({
    super.key,
    required this.catalog,
    required this.onOpenEpisode,
  });

  final ContentCatalog catalog;
  final Future<void> Function(MythSeries series, MythEpisode episode)
  onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    final items = catalog.recentEpisodes;
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader(
          title: 'Continue Learning',
          subtitle: 'మీరు ఇటీవల చూసిన కథలు',
        ),
        const SizedBox(height: 12),
        ...items.map(
          (pair) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: LearningRow(
              pair: pair,
              onTap: () => onOpenEpisode(pair.series, pair.episode),
            ),
          ),
        ),
      ],
    );
  }
}

class LearningRow extends StatelessWidget {
  const LearningRow({super.key, required this.pair, required this.onTap});

  final EpisodePair pair;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: cinematicCardDecoration(radius: 22),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: ProgressiveArtwork(
                asset: pair.series.coverAsset,
                imageUrl: pair.series.coverImageUrl,
                height: 66,
                width: 66,
                accent: pair.series.accent,
              ),
            ),
            const SizedBox(width: 13),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pair.series.title,
                    style: const TextStyle(
                      color: AppColors.deepSaffron,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    pair.episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Day ${pair.episode.dayNumber} · ${pair.episode.readingMinutes} min',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.brown),
          ],
        ),
      ),
    );
  }
}

class ExploreAllStoriesCard extends StatelessWidget {
  const ExploreAllStoriesCard({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF2B1A12),
          borderRadius: BorderRadius.circular(26),
          boxShadow: [
            BoxShadow(
              color: AppColors.brown.withValues(alpha: 0.16),
              blurRadius: 26,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.auto_stories_rounded,
              color: AppColors.gold,
              size: 34,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Explore All Stories',
                    style: Theme.of(
                      context,
                    ).textTheme.titleMedium?.copyWith(color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Ramayanam, Mahabharatam, Bhagavatam and more',
                    style: TextStyle(color: Color(0xFFFFE8C7)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }
}

class SeriesDetailScreen extends StatelessWidget {
  const SeriesDetailScreen({
    super.key,
    required this.series,
    required this.progress,
    required this.userProgress,
    required this.completedEpisodeIds,
    required this.onOpenEpisode,
  });

  final MythSeries series;
  final ReadingProgress? progress;
  final UserProgressSnapshot userProgress;
  final Set<String> completedEpisodeIds;
  final void Function(MythSeries series, MythEpisode episode) onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.ivory,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 288,
            backgroundColor: AppColors.ivory,
            leading: IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Hero(
                    tag: 'series-art-${series.id}',
                    child: ProgressiveArtwork(
                      asset: series.coverAsset,
                      imageUrl: series.coverImageUrl,
                      accent: series.accent,
                    ),
                  ),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.72),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 22,
                    right: 22,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        EpisodePill(text: series.category),
                        const SizedBox(height: 12),
                        Text(
                          series.title,
                          style: Theme.of(context).textTheme.displaySmall
                              ?.copyWith(color: Colors.white),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          series.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFFFE9CA),
                            fontSize: 16,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
            sliver: SliverList.separated(
              itemCount: series.episodes.length,
              separatorBuilder: (_, _) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final episode = series.episodes[index];
                final episodeProgress = progressForEpisode(
                  liveProgress: progress,
                  userProgress: userProgress,
                  completedEpisodeIds: completedEpisodeIds,
                  series: series,
                  episode: episode,
                );
                final isCompleted = completedEpisodeIds.contains(episode.id);
                final nextEpisode = series.nextUnreadEpisode(
                  completedEpisodeIds,
                );
                final isNext = nextEpisode?.id == episode.id;
                return StaggeredReveal(
                  delay: Duration(milliseconds: index * 40),
                  child: EpisodeListTile(
                    series: series,
                    episode: episode,
                    currentProgress: episodeProgress,
                    completed: isCompleted,
                    next: isNext,
                    onTap: () => onOpenEpisode(series, episode),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class EpisodeListTile extends StatelessWidget {
  const EpisodeListTile({
    super.key,
    required this.series,
    required this.episode,
    required this.currentProgress,
    required this.completed,
    required this.next,
    required this.onTap,
  });

  final MythSeries series;
  final MythEpisode episode;
  final ReadingProgress? currentProgress;
  final bool completed;
  final bool next;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final percent = completed ? 1.0 : currentProgress?.percentage(episode) ?? 0;
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: next
            ? cinematicCardDecoration(radius: 22).copyWith(
                border: Border.all(color: AppColors.saffron, width: 1.6),
              )
            : cinematicCardDecoration(radius: 22),
        child: Row(
          children: [
            Hero(
              tag: 'episode-art-${episode.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ProgressiveArtwork(
                  asset: series.coverAsset,
                  imageUrl: series.coverImageUrl,
                  height: 82,
                  width: 82,
                  accent: episode.accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Day ${episode.dayNumber}',
                    style: const TextStyle(
                      color: AppColors.deepSaffron,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  if (completed || next) ...[
                    const SizedBox(height: 6),
                    EpisodeStatusPill(
                      label: completed ? 'Completed' : 'Read next',
                      color: completed ? AppColors.success : AppColors.saffron,
                      icon: completed
                          ? Icons.check_circle_rounded
                          : Icons.arrow_forward_rounded,
                    ),
                  ],
                  const SizedBox(height: 5),
                  Text(
                    episode.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    episode.subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (percent > 0) ...[
                    const SizedBox(height: 10),
                    SmoothProgress(value: percent),
                  ],
                ],
              ),
            ),
            Icon(
              completed
                  ? Icons.check_circle_rounded
                  : next
                  ? Icons.arrow_forward_rounded
                  : Icons.play_arrow_rounded,
              color: completed ? AppColors.success : AppColors.saffron,
            ),
          ],
        ),
      ),
    );
  }
}

class EpisodeStatusPill extends StatelessWidget {
  const EpisodeStatusPill({
    super.key,
    required this.label,
    required this.color,
    required this.icon,
  });

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class ReaderScreen extends StatefulWidget {
  const ReaderScreen({
    super.key,
    required this.series,
    required this.episode,
    required this.initialSlide,
    required this.isBookmarked,
    required this.onToggleBookmark,
    required this.onProgress,
    required this.onCompleted,
  });

  final MythSeries series;
  final MythEpisode episode;
  final int initialSlide;
  final bool isBookmarked;
  final VoidCallback onToggleBookmark;
  final ValueChanged<int> onProgress;
  final VoidCallback onCompleted;

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with TickerProviderStateMixin {
  late final PageController _pageController;
  late int _index;
  bool _paused = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialSlide.clamp(0, widget.episode.slides.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    for (final slide in widget.episode.slides.skip(_index).take(3)) {
      precacheImage(slide.imageProvider, context);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _go(int direction) {
    final next = (_index + direction).clamp(
      0,
      widget.episode.slides.length - 1,
    );
    if (next == _index) return;
    _pageController.animateToPage(
      next,
      duration: motionReduced(context)
          ? Duration.zero
          : const Duration(milliseconds: 420),
      curve: MotionSpec.page,
    );
  }

  void _completeOrNext() {
    if (_index == widget.episode.slides.length - 1) {
      widget.onCompleted();
    } else {
      _go(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF130B07),
      body: GestureDetector(
        onLongPressStart: (_) => setState(() => _paused = true),
        onLongPressEnd: (_) => setState(() => _paused = false),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: widget.episode.slides.length,
                    onPageChanged: (value) {
                      setState(() => _index = value);
                      widget.onProgress(value);
                      for (final upcoming
                          in widget.episode.slides.skip(value).take(3)) {
                        precacheImage(upcoming.imageProvider, context);
                      }
                    },
                    itemBuilder: (context, index) {
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, _) {
                          var delta = 0.0;
                          if (_pageController.hasClients &&
                              _pageController.position.haveDimensions) {
                            delta =
                                (_pageController.page ?? _index.toDouble()) -
                                index.toDouble();
                          }
                          return ReaderSlideView(
                            slide: widget.episode.slides[index],
                            delta: delta,
                            paused: _paused,
                            isHeroSlide: index == widget.initialSlide,
                            heroTag: 'episode-art-${widget.episode.id}',
                          );
                        },
                      );
                    },
                  ),
                  Positioned.fill(
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: () => _go(-1),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            behavior: HitTestBehavior.translucent,
                            onTap: _completeOrNext,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Column(
                        children: [
                          Row(
                            children: List.generate(
                              widget.episode.slides.length,
                              (i) {
                                return Expanded(
                                  child: AnimatedContainer(
                                    duration: MotionSpec.soft,
                                    curve: MotionSpec.standard,
                                    margin: EdgeInsets.only(
                                      right:
                                          i == widget.episode.slides.length - 1
                                          ? 0
                                          : 6,
                                    ),
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: i <= _index
                                          ? Colors.white
                                          : Colors.white.withValues(
                                              alpha: 0.28,
                                            ),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              FrostedIconButton(
                                icon: Icons.close_rounded,
                                onTap: () => Navigator.of(context).pop(),
                              ),
                              const Spacer(),
                              FrostedIconButton(
                                icon: widget.isBookmarked
                                    ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                                onTap: widget.onToggleBookmark,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_paused)
                    Positioned.fill(
                      child: ColoredBox(
                        color: Colors.black.withValues(alpha: 0.18),
                        child: const Center(
                          child: Icon(
                            Icons.pause_circle_filled_rounded,
                            color: Colors.white,
                            size: 64,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(18, 10, 18, 14),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${_index + 1}/${widget.episode.slides.length}',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.72),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    ReaderPrimaryButton(
                      isLast: _index == widget.episode.slides.length - 1,
                      onTap: _completeOrNext,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ReaderSlideView extends StatelessWidget {
  const ReaderSlideView({
    super.key,
    required this.slide,
    required this.delta,
    required this.paused,
    required this.isHeroSlide,
    required this.heroTag,
  });

  final MythSlide slide;
  final double delta;
  final bool paused;
  final bool isHeroSlide;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    final artwork = Transform.translate(
      offset: Offset(delta * -36, 0),
      child: Transform.scale(
        scale: paused ? 1.0 : 1.035,
        child: ProgressiveArtwork(
          asset: slide.imageAsset,
          imageUrl: slide.imageUrl,
          accent: slide.accent,
          fit: BoxFit.cover,
        ),
      ),
    );
    return Stack(
      fit: StackFit.expand,
      children: [
        isHeroSlide ? Hero(tag: heroTag, child: artwork) : artwork,
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.24),
                Colors.transparent,
                Colors.transparent,
              ],
              stops: const [0, 0.48, 1],
            ),
          ),
        ),
      ],
    );
  }
}

class ReaderPrimaryButton extends StatelessWidget {
  const ReaderPrimaryButton({
    super.key,
    required this.isLast,
    required this.onTap,
  });

  final bool isLast;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Material(
          color: AppColors.saffron.withValues(alpha: 0.92),
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLast ? Icons.check_rounded : Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isLast ? 'Complete' : 'Next',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ReaderTextPanel extends StatelessWidget {
  const ReaderTextPanel({
    super.key,
    required this.slide,
    required this.episode,
    required this.isLast,
    required this.onPrimary,
  });

  final MythSlide slide;
  final MythEpisode episode;
  final bool isLast;
  final VoidCallback onPrimary;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(26),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppColors.ivory.withValues(alpha: 0.93),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(slide.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(
                slide.body,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  height: 1.5,
                  color: AppColors.brown,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onPrimary,
                icon: Icon(
                  isLast ? Icons.school_rounded : Icons.arrow_forward_rounded,
                ),
                label: Text(isLast ? 'నేర్చుకున్నది చూడండి' : 'తర్వాత'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LearningSummaryScreen extends StatelessWidget {
  const LearningSummaryScreen({
    super.key,
    required this.series,
    required this.episode,
    required this.onContinue,
  });

  final MythSeries series;
  final MythEpisode episode;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ParchmentBackdrop(glow: 0.3, bellOffset: 0),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FrostedIconButton(
                    icon: Icons.close_rounded,
                    dark: false,
                    onTap: () => Navigator.of(
                      context,
                    ).popUntil((route) => route.isFirst),
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredReveal(
                  child: Text(
                    'మీరు ఈ కథను పూర్తి చేశారు',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
                const SizedBox(height: 8),
                StaggeredReveal(
                  delay: const Duration(milliseconds: 80),
                  child: Text(
                    '${series.title} · Day ${episode.dayNumber}',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppColors.mutedBrown,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                StaggeredReveal(
                  delay: const Duration(milliseconds: 140),
                  child: LearningCard(
                    icon: Icons.history_edu_rounded,
                    title: 'What Happened',
                    text: episode.whatHappened,
                  ),
                ),
                const SizedBox(height: 14),
                StaggeredReveal(
                  delay: const Duration(milliseconds: 220),
                  child: LearningCard(
                    icon: Icons.lightbulb_rounded,
                    title: 'What We Learned',
                    text: episode.lesson,
                  ),
                ),
                const SizedBox(height: 20),
                StaggeredReveal(
                  delay: const Duration(milliseconds: 300),
                  child: Text(
                    'Characters Introduced',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (var i = 0; i < episode.characters.length; i++)
                      StaggeredReveal(
                        delay: Duration(milliseconds: 340 + i * 60),
                        child: CharacterChip(character: episode.characters[i]),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
      bottomSheet: Container(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          18 + MediaQuery.paddingOf(context).bottom,
        ),
        decoration: BoxDecoration(
          color: AppColors.ivory.withValues(alpha: 0.96),
          boxShadow: [
            BoxShadow(
              color: AppColors.brown.withValues(alpha: 0.08),
              blurRadius: 26,
              offset: const Offset(0, -12),
            ),
          ],
        ),
        child: FilledButton.icon(
          onPressed: onContinue,
          icon: const Icon(Icons.arrow_forward_rounded),
          label: Text(
            series.nextEpisodeAfter(episode.id) == null
                ? 'Home కు వెళ్లండి'
                : 'Continue Story',
          ),
        ),
      ),
    );
  }
}

class LearningCard extends StatelessWidget {
  const LearningCard({
    super.key,
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: cinematicCardDecoration(radius: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE7B0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: AppColors.deepSaffron),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 7),
                Text(text, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CharacterChip extends StatelessWidget {
  const CharacterChip({super.key, required this.character});

  final MythCharacter character;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.82),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_rounded, color: AppColors.saffron, size: 18),
          const SizedBox(width: 8),
          Text(
            '${character.name} · ${character.role}',
            style: const TextStyle(
              color: AppColors.brown,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class LibraryScreenV2 extends StatefulWidget {
  const LibraryScreenV2({
    super.key,
    required this.catalog,
    required this.loadingContent,
    required this.contentError,
    required this.progress,
    required this.userProgress,
    required this.completedEpisodeIds,
    required this.onOpenEpisode,
    required this.onOpenSeries,
    required this.onRetryContent,
  });

  final ContentCatalog catalog;
  final bool loadingContent;
  final String? contentError;
  final ReadingProgress? progress;
  final UserProgressSnapshot userProgress;
  final Set<String> completedEpisodeIds;
  final Future<void> Function(MythSeries series, MythEpisode episode)
  onOpenEpisode;
  final ValueChanged<MythSeries> onOpenSeries;
  final Future<void> Function() onRetryContent;

  @override
  State<LibraryScreenV2> createState() => _LibraryScreenV2State();
}

class _LibraryScreenV2State extends State<LibraryScreenV2> {
  final TextEditingController _search = TextEditingController();
  String _filter = 'All';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final query = _search.text.trim().toLowerCase();
    final series = widget.catalog.series.where((item) {
      final inProgress = isSeriesInProgress(
        series: item,
        liveProgress: widget.progress,
        userProgress: widget.userProgress,
        completedEpisodeIds: widget.completedEpisodeIds,
      );
      final matchesFilter =
          _filter == 'All' ||
          item.category == _filter ||
          (_filter == 'In Progress' && inProgress);
      final matchesQuery =
          query.isEmpty ||
          item.title.toLowerCase().contains(query) ||
          item.description.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();

    return Scaffold(
      body: Stack(
        children: [
          const ParchmentBackdrop(glow: 0.23, bellOffset: 0),
          SafeArea(
            child: ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 105),
              children: [
                Text(
                  'Library',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Ramayanam, Mahabharatam, Bhagavatam and timeless stories.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 20),
                SearchField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 14),
                FilterRail(
                  selected: _filter,
                  onSelected: (value) => setState(() => _filter = value),
                ),
                const SizedBox(height: 22),
                if (widget.loadingContent)
                  const LibraryContentSkeleton()
                else if (widget.contentError != null)
                  EducationalEmptyState(
                    icon: Icons.wifi_off_rounded,
                    title: 'Library లోడ్ కాలేదు',
                    message: widget.contentError!,
                    action: FilledButton.icon(
                      onPressed: widget.onRetryContent,
                      icon: const Icon(Icons.refresh_rounded),
                      label: const Text('మళ్లీ ప్రయత్నించండి'),
                    ),
                  )
                else if (series.isEmpty)
                  const EducationalEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'కథ దొరకలేదు',
                    message: 'మరో పేరు లేదా వర్గంతో వెతకండి.',
                  )
                else
                  ...series.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: LibrarySeriesTile(
                        series: item,
                        progressValue: seriesProgressValue(
                          series: item,
                          liveProgress: widget.progress,
                          userProgress: widget.userProgress,
                          completedEpisodeIds: widget.completedEpisodeIds,
                        ),
                        onTap: () => widget.onOpenSeries(item),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SearchField extends StatelessWidget {
  const SearchField({
    super.key,
    required this.controller,
    required this.onChanged,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Search stories, characters, categories',
        prefixIcon: const Icon(Icons.search_rounded),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.78),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.55),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: BorderSide(
            color: AppColors.border.withValues(alpha: 0.55),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(22),
          borderSide: const BorderSide(color: AppColors.saffron, width: 1.5),
        ),
      ),
    );
  }
}

class FilterRail extends StatelessWidget {
  const FilterRail({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  final String selected;
  final ValueChanged<String> onSelected;

  static const filters = [
    'All',
    'In Progress',
    'Itihasam',
    'Puranam',
    'Temple',
    'Festival',
    'Kids',
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final active = filter == selected;
          return ChoiceChip(
            selected: active,
            label: Text(filter),
            selectedColor: const Color(0xFFFFE4A8),
            backgroundColor: Colors.white.withValues(alpha: 0.7),
            onSelected: (_) => onSelected(filter),
          );
        },
      ),
    );
  }
}

class LibrarySeriesTile extends StatelessWidget {
  const LibrarySeriesTile({
    super.key,
    required this.series,
    required this.progressValue,
    required this.onTap,
  });

  final MythSeries series;
  final double progressValue;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: cinematicCardDecoration(radius: 24),
        child: Row(
          children: [
            Hero(
              tag: 'series-art-${series.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: ProgressiveArtwork(
                  asset: series.coverAsset,
                  imageUrl: series.coverImageUrl,
                  width: 92,
                  height: 104,
                  accent: series.accent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  EpisodePill(text: series.category, dark: false),
                  const SizedBox(height: 9),
                  Text(
                    series.title,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    series.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 12),
                  SmoothProgress(value: progressValue),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BookmarksScreenV2 extends StatelessWidget {
  const BookmarksScreenV2({
    super.key,
    required this.catalog,
    required this.bookmarkedEpisodeIds,
    required this.onOpenEpisode,
  });

  final ContentCatalog catalog;
  final Set<String> bookmarkedEpisodeIds;
  final Future<void> Function(MythSeries series, MythEpisode episode)
  onOpenEpisode;

  @override
  Widget build(BuildContext context) {
    final bookmarks = bookmarkedEpisodeIds
        .map(catalog.byEpisodeId)
        .whereType<EpisodePair>()
        .toList();

    return Scaffold(
      body: Stack(
        children: [
          const ParchmentBackdrop(glow: 0.22, bellOffset: 0),
          SafeArea(
            child: bookmarks.isEmpty
                ? const EducationalEmptyState(
                    icon: Icons.bookmark_add_outlined,
                    title: 'ఇంకా bookmarks లేవు',
                    message:
                        'చదువుతున్నప్పుడు ముఖ్యమైన కథలను సేవ్ చేస్తే అవి ఇక్కడ కనిపిస్తాయి.',
                  )
                : ListView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 22, 20, 105),
                    children: [
                      Text(
                        'Bookmarks',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 18),
                      ...bookmarks.map(
                        (pair) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: LearningRow(
                            pair: pair,
                            onTap: () =>
                                onOpenEpisode(pair.series, pair.episode),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class ProfileScreenV2 extends StatelessWidget {
  const ProfileScreenV2({
    super.key,
    required this.points,
    required this.streakDays,
    required this.completedCount,
    required this.onLogout,
  });

  final int points;
  final int streakDays;
  final int completedCount;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ParchmentBackdrop(glow: 0.2, bellOffset: 0),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 110),
              children: [
                Text(
                  'Profile',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 10),
                Text(
                  'Reading settings and account details will stay minimal so the focus remains on stories.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: cinematicCardDecoration(radius: 24),
                  child: const Row(
                    children: [
                      AppLogo(size: 56),
                      SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Daily Katha Reader',
                          style: TextStyle(
                            color: AppColors.brown,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: RewardStatCard(
                        icon: Icons.stars_rounded,
                        value: '$points',
                        label: 'Points',
                        color: AppColors.deepSaffron,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: RewardStatCard(
                        icon: Icons.local_fire_department_rounded,
                        value: '$streakDays',
                        label: 'Day streak',
                        color: AppColors.saffron,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                RewardStatCard(
                  icon: Icons.check_circle_rounded,
                  value: '$completedCount',
                  label: 'Completed days',
                  color: AppColors.success,
                ),
                const SizedBox(height: 14),
                const MinimalSettingTile(
                  icon: Icons.translate_rounded,
                  title: 'Language',
                  subtitle: 'Telugu-first',
                ),
                const SizedBox(height: 10),
                const MinimalSettingTile(
                  icon: Icons.text_fields_rounded,
                  title: 'Reading size',
                  subtitle: 'Comfortable for elders',
                ),
                const SizedBox(height: 10),
                MinimalSettingTile(
                  icon: Icons.logout_rounded,
                  title: 'Logout',
                  subtitle: 'Sign out from this device',
                  onTap: onLogout,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuizPerformance {
  const QuizPerformance({
    required this.score,
    required this.total,
    required this.pointsEarned,
    required this.answers,
  });

  final int score;
  final int total;
  final int pointsEarned;
  final List<QuizAnswerResult> answers;

  int get wrong => (total - score).clamp(0, total);
}

class QuizPerformanceScreen extends StatelessWidget {
  const QuizPerformanceScreen({
    super.key,
    required this.episode,
    required this.performance,
  });

  final MythEpisode episode;
  final QuizPerformance performance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const ParchmentBackdrop(glow: 0.24, bellOffset: 0),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 28),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: FrostedIconButton(
                    icon: Icons.close_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(22),
                  decoration: cinematicCardDecoration(radius: 28),
                  child: Column(
                    children: [
                      Container(
                        width: 82,
                        height: 82,
                        decoration: BoxDecoration(
                          color: AppColors.gold.withValues(alpha: 0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.emoji_events_rounded,
                          color: AppColors.deepSaffron,
                          size: 44,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Quiz Performance',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        episode.title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                      const SizedBox(height: 22),
                      Row(
                        children: [
                          Expanded(
                            child: RewardStatCard(
                              icon: Icons.check_circle_rounded,
                              value: '${performance.score}',
                              label: 'Correct',
                              color: AppColors.success,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: RewardStatCard(
                              icon: Icons.cancel_rounded,
                              value: '${performance.wrong}',
                              label: 'Wrong',
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      RewardStatCard(
                        icon: Icons.stars_rounded,
                        value: '+${performance.pointsEarned}',
                        label: performance.pointsEarned == 0
                            ? 'Already claimed'
                            : 'Points earned',
                        color: AppColors.deepSaffron,
                      ),
                      if (performance.answers.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'Answer review',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...performance.answers.indexed.map((entry) {
                          final index = entry.$1;
                          final answer = entry.$2;
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: index == performance.answers.length - 1
                                  ? 0
                                  : 12,
                            ),
                            child: QuizAnswerReviewCard(
                              answerNumber: index + 1,
                              answer: answer,
                            ),
                          );
                        }),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: const Text('Back to story'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class QuizAnswerReviewCard extends StatelessWidget {
  const QuizAnswerReviewCard({
    super.key,
    required this.answerNumber,
    required this.answer,
  });

  final int answerNumber;
  final QuizAnswerResult answer;

  @override
  Widget build(BuildContext context) {
    final statusColor = answer.correct ? AppColors.success : AppColors.error;
    final correctOption = answer.correctOption;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    '$answerNumber',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  answer.question.questionText,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              Icon(
                answer.correct
                    ? Icons.check_circle_rounded
                    : Icons.cancel_rounded,
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 14),
          QuizOptionReviewLine(
            label: 'Your answer',
            option: answer.selectedOption,
            color: statusColor,
          ),
          if (!answer.correct && correctOption != null) ...[
            const SizedBox(height: 8),
            QuizOptionReviewLine(
              label: 'Correct answer',
              option: correctOption,
              color: AppColors.success,
            ),
          ] else if (!answer.correct) ...[
            const SizedBox(height: 8),
            const QuizCorrectAnswerPendingLine(),
          ],
        ],
      ),
    );
  }
}

class QuizCorrectAnswerPendingLine extends StatelessWidget {
  const QuizCorrectAnswerPendingLine({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'Correct answer will appear after the CMS update is deployed.',
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: AppColors.success,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class QuizOptionReviewLine extends StatelessWidget {
  const QuizOptionReviewLine({
    super.key,
    required this.label,
    required this.option,
    required this.color,
  });

  final String label;
  final cms.QuizOption option;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final optionLabel = option.label.trim();
    final optionText = option.text.trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            optionLabel.isEmpty ? optionText : '$optionLabel. $optionText',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppColors.brown,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class RewardStatCard extends StatelessWidget {
  const RewardStatCard({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: cinematicCardDecoration(radius: 22),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: color),
                ),
                const SizedBox(height: 2),
                Text(label, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class MinimalSettingTile extends StatelessWidget {
  const MinimalSettingTile({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      padding: const EdgeInsets.all(16),
      decoration: cinematicCardDecoration(radius: 22),
      child: Row(
        children: [
          Icon(icon, color: AppColors.saffron),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 3),
                Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.mutedBrown,
            ),
          ],
        ],
      ),
    );

    if (onTap == null) {
      return content;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: content,
      ),
    );
  }
}

class EducationalEmptyState extends StatelessWidget {
  const EducationalEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(34),
        child: StaggeredReveal(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFE7B0),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Icon(icon, color: AppColors.deepSaffron, size: 42),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              if (action != null) ...[const SizedBox(height: 22), action!],
            ],
          ),
        ),
      ),
    );
  }
}

class LibraryContentSkeleton extends StatelessWidget {
  const LibraryContentSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: const [
        CinematicSkeleton(height: 128, radius: 24),
        SizedBox(height: 14),
        CinematicSkeleton(height: 128, radius: 24),
        SizedBox(height: 14),
        CinematicSkeleton(height: 128, radius: 24),
      ],
    );
  }
}

class ProgressiveArtwork extends StatefulWidget {
  const ProgressiveArtwork({
    super.key,
    required this.asset,
    required this.accent,
    this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.alignment = Alignment.center,
  });

  final String asset;
  final Color accent;
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final Alignment alignment;

  @override
  State<ProgressiveArtwork> createState() => _ProgressiveArtworkState();
}

class _ProgressiveArtworkState extends State<ProgressiveArtwork> {
  bool _loaded = false;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.width,
      height: widget.height,
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  widget.accent.withValues(alpha: 0.34),
                  const Color(0xFFFFE9BE),
                  AppColors.ivory,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Image.asset(
              widget.asset,
              fit: BoxFit.cover,
              alignment: widget.alignment,
              color: widget.accent.withValues(alpha: 0.24),
              colorBlendMode: BlendMode.overlay,
            ),
          ),
          AnimatedOpacity(
            opacity: _loaded ? 1 : 0,
            duration: MotionSpec.soft,
            curve: MotionSpec.standard,
            child: _ProgressiveImage(
              asset: widget.asset,
              imageUrl: widget.imageUrl,
              fit: widget.fit,
              alignment: widget.alignment,
              onReady: () {
                if (mounted && !_loaded) setState(() => _loaded = true);
              },
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  widget.accent.withValues(alpha: 0.12),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressiveImage extends StatelessWidget {
  const _ProgressiveImage({
    required this.asset,
    required this.imageUrl,
    required this.fit,
    required this.alignment,
    required this.onReady,
  });

  final String asset;
  final String? imageUrl;
  final BoxFit fit;
  final Alignment alignment;
  final VoidCallback onReady;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) {
      return Image.asset(
        asset,
        fit: fit,
        alignment: alignment,
        frameBuilder: _frameBuilder,
      );
    }

    return Image.network(
      _proxiedImageUrl(url),
      fit: fit,
      alignment: alignment,
      frameBuilder: _frameBuilder,
      errorBuilder: (context, error, stackTrace) {
        return Image.asset(
          asset,
          fit: fit,
          alignment: alignment,
          frameBuilder: _frameBuilder,
        );
      },
    );
  }

  Widget _frameBuilder(
    BuildContext context,
    Widget child,
    int? frame,
    bool wasSynchronouslyLoaded,
  ) {
    if (wasSynchronouslyLoaded || frame != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => onReady());
    }
    return child;
  }
}

String _proxiedImageUrl(String url) {
  final trimmed = url.trim();
  if (trimmed.isEmpty) return trimmed;
  if (trimmed.startsWith('${AppConfig.apiBaseUrl}/api/app/image-proxy')) {
    return trimmed;
  }
  return '${AppConfig.apiBaseUrl}/api/app/image-proxy?url=${Uri.encodeComponent(trimmed)}';
}

class CinematicSkeleton extends StatefulWidget {
  const CinematicSkeleton({
    super.key,
    this.width,
    this.height = 18,
    this.radius = 14,
  });

  final double? width;
  final double height;
  final double radius;

  @override
  State<CinematicSkeleton> createState() => _CinematicSkeletonState();
}

class _CinematicSkeletonState extends State<CinematicSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionReduced(context)) {
      return _skeletonBox(const Color(0xFFFFEBC6));
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              stops: const [0.12, 0.5, 0.88],
              colors: const [
                Color(0xFFFFE6BA),
                Color(0xFFFFF8E7),
                Color(0xFFFFE6BA),
              ],
              transform: _SlidingGradientTransform(_controller.value),
            ).createShader(rect);
          },
          child: _skeletonBox(Colors.white),
        );
      },
    );
  }

  Widget _skeletonBox(Color color) {
    return Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(widget.radius),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform(this.value);

  final double value;

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * (value * 2 - 1), 0, 0);
  }
}

class SmoothProgress extends StatelessWidget {
  const SmoothProgress({super.key, required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Container(
        height: 7,
        color: const Color(0xFFFFE8C3),
        child: Align(
          alignment: Alignment.centerLeft,
          child: AnimatedFractionallySizedBox(
            duration: MotionSpec.soft,
            curve: MotionSpec.standard,
            widthFactor: value.clamp(0, 1),
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.saffron, AppColors.gold],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class EpisodePill extends StatelessWidget {
  const EpisodePill({super.key, required this.text, this.dark = true});

  final String text;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: dark
            ? Colors.black.withValues(alpha: 0.34)
            : const Color(0xFFFFE7B0),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(
          color: dark
              ? Colors.white.withValues(alpha: 0.24)
              : AppColors.gold.withValues(alpha: 0.4),
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: dark ? Colors.white : AppColors.deepSaffron,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class FrostedIconButton extends StatelessWidget {
  const FrostedIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.dark = true,
  });

  final IconData icon;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    return PressableScale(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dark
                  ? Colors.black.withValues(alpha: 0.22)
                  : Colors.white.withValues(alpha: 0.68),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: dark
                    ? Colors.white.withValues(alpha: 0.22)
                    : AppColors.border.withValues(alpha: 0.45),
              ),
            ),
            child: Icon(icon, color: dark ? Colors.white : AppColors.brown),
          ),
        ),
      ),
    );
  }
}

class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child, required this.onTap});

  final Widget child;
  final VoidCallback onTap;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final reduce = motionReduced(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapCancel: () => setState(() => _pressed = false),
      onTapUp: (_) => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: reduce || !_pressed ? 1 : 0.985,
        duration: MotionSpec.micro,
        curve: MotionSpec.standard,
        child: widget.child,
      ),
    );
  }
}

class StaggeredReveal extends StatefulWidget {
  const StaggeredReveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
  });

  final Widget child;
  final Duration delay;

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: MotionSpec.homeEntrance,
    );
    _timer = Timer(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (motionReduced(context)) {
      return FadeTransition(opacity: _controller, child: widget.child);
    }
    final curved = CurvedAnimation(
      parent: _controller,
      curve: MotionSpec.standard,
    );
    return FadeTransition(
      opacity: curved,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: widget.child,
      ),
    );
  }
}

BoxDecoration cinematicCardDecoration({double radius = 24}) {
  return BoxDecoration(
    color: AppColors.card.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: AppColors.border.withValues(alpha: 0.42)),
    boxShadow: [
      BoxShadow(
        color: AppColors.deepSaffron.withValues(alpha: 0.08),
        blurRadius: 22,
        offset: const Offset(0, 14),
      ),
    ],
  );
}

class V2Content {
  static const cover = 'assets/mahabharatam-cover.png';

  static final series = <MythSeries>[
    MythSeries(
      id: 'mahabharatam',
      title: 'మహాభారతం',
      category: 'Itihasam',
      description: 'ధర్మం, నిర్ణయం, కుటుంబం, భక్తి గురించి మహా ప్రయాణం.',
      coverAsset: cover,
      accent: AppColors.maroon,
      episodes: [
        MythEpisode(
          id: 'mb-day-1',
          dayNumber: 1,
          title: 'కురుక్షేత్రం ప్రారంభం',
          subtitle: 'అర్జునుడి సందేహం, కృష్ణుడి ధర్మబోధ మొదలు.',
          readingMinutes: 5,
          accent: AppColors.maroon,
          whatHappened:
              'యుద్ధభూమిలో తన కుటుంబాన్ని చూసి అర్జునుడు దిగులుపడ్డాడు. ఆ సమయంలో కృష్ణుడు అతనికి కర్తవ్యం, ధర్మం, ధైర్యం గురించి మార్గం చూపడం ప్రారంభించాడు.',
          lesson:
              'సందేహం వచ్చినప్పుడు ఆగిపోవడం కాదు; సత్యాన్ని అర్థం చేసుకుని ధర్మం వైపు నిలబడటం ముఖ్యం.',
          characters: const [
            MythCharacter(name: 'అర్జునుడు', role: 'ధనుర్ధారి'),
            MythCharacter(name: 'శ్రీకృష్ణుడు', role: 'సారథి'),
          ],
          slides: const [
            MythSlide(
              id: 'mb1-1',
              title: 'యుద్ధభూమి నిశ్శబ్దం',
              body:
                  'కురుక్షేత్రంలో రెండు సైన్యాలు ఎదురెదురుగా నిలిచాయి. ఆ క్షణం చరిత్రలో గొప్ప సంభాషణకు ఆరంభం అయింది.',
              imageAsset: cover,
              accent: AppColors.maroon,
            ),
            MythSlide(
              id: 'mb1-2',
              title: 'అర్జునుడి మనసు',
              body:
                  'తనవారిని ఎదురుగా చూసిన అర్జునుడి చేతులు వణికాయి. యుద్ధం కన్నా ధర్మం ఏమిటి అన్న ప్రశ్న అతనిలో మొదలైంది.',
              imageAsset: cover,
              accent: AppColors.saffron,
            ),
            MythSlide(
              id: 'mb1-3',
              title: 'కృష్ణుడి శాంతి',
              body:
                  'కృష్ణుడు తొందరపడలేదు. ప్రశ్నకు సమాధానం చెప్పే ముందు, అర్జునుడి హృదయాన్ని వినాడు.',
              imageAsset: cover,
              accent: AppColors.deepSaffron,
            ),
            MythSlide(
              id: 'mb1-4',
              title: 'ధర్మం వైపు మొదటి అడుగు',
              body:
                  'సరైన నిర్ణయం భయం లేకపోవడం వల్ల కాదు. భయం ఉన్నా సత్యం వైపు నిలబడటం వల్ల మొదలవుతుంది.',
              imageAsset: cover,
              accent: AppColors.gold,
            ),
          ],
        ),
        MythEpisode(
          id: 'mb-day-2',
          dayNumber: 2,
          title: 'భీష్ముని ప్రతిజ్ఞ',
          subtitle: 'ఒక వాగ్దానం ఒక జీవితాన్ని ఎలా మార్చింది.',
          readingMinutes: 6,
          accent: AppColors.deepSaffron,
          whatHappened:
              'భీష్ముడు తన తండ్రి సంతోషం కోసం గొప్ప ప్రతిజ్ఞ చేశాడు. ఆ నిర్ణయం అతని జీవితాన్ని, రాజ్య భవిష్యత్తును ప్రభావితం చేసింది.',
          lesson:
              'వాగ్దానం గొప్పది. కానీ ప్రతి నిర్ణయం వెనుక దాని ప్రభావాన్ని అర్థం చేసుకోవడం కూడా అవసరం.',
          characters: const [
            MythCharacter(name: 'భీష్ముడు', role: 'ప్రతిజ్ఞాశీలి'),
            MythCharacter(name: 'శంతను', role: 'రాజు'),
          ],
          slides: const [
            MythSlide(
              id: 'mb2-1',
              title: 'రాజ్యం ముందు కుమారుడు',
              body:
                  'శంతనుని మనసులోని కోరికను తెలుసుకున్న దేవవ్రతుడు, తన జీవితానికి కొత్త దిశను ఇచ్చే నిర్ణయానికి సిద్ధమయ్యాడు.',
              imageAsset: cover,
              accent: AppColors.deepSaffron,
            ),
            MythSlide(
              id: 'mb2-2',
              title: 'భీష్మ ప్రతిజ్ఞ',
              body:
                  'తన సుఖాన్ని పక్కన పెట్టి రాజ్య శాంతి కోసం దేవవ్రతుడు ఘోరమైన వాగ్దానం చేశాడు.',
              imageAsset: cover,
              accent: AppColors.maroon,
            ),
          ],
        ),
      ],
    ),
    MythSeries(
      id: 'ramayanam',
      title: 'రామాయణం',
      category: 'Itihasam',
      description: 'శ్రీరాముని జీవితం నుంచి ధర్మం, ప్రేమ, నిబద్ధత.',
      coverAsset: cover,
      accent: AppColors.success,
      episodes: [
        MythEpisode.sample(
          id: 'rm-day-1',
          dayNumber: 1,
          title: 'అయోధ్యలో ఆనందం',
          subtitle: 'ధర్మం పుట్టిన ఇంటి కథ.',
          accent: AppColors.success,
        ),
      ],
    ),
    MythSeries(
      id: 'bhagavatam',
      title: 'భాగవతం',
      category: 'Puranam',
      description: 'శ్రీకృష్ణ కథలు, భక్తి, ధైర్యం, ప్రేమ.',
      coverAsset: cover,
      accent: const Color(0xFF1D4ED8),
      episodes: [
        MythEpisode.sample(
          id: 'bg-day-1',
          dayNumber: 1,
          title: 'కృష్ణుడి బాల్యం',
          subtitle: 'లీలల్లో దాగిన ప్రేమ, జ్ఞానం.',
          accent: const Color(0xFF1D4ED8),
        ),
      ],
    ),
    MythSeries(
      id: 'temple-stories',
      title: 'ఆలయ కథలు',
      category: 'Temple',
      description: 'భారత ఆలయాల వెనుక ఉన్న చరిత్ర, భక్తి, విశ్వాసం.',
      coverAsset: cover,
      accent: AppColors.saffron,
      episodes: [
        MythEpisode.sample(
          id: 'tp-day-1',
          dayNumber: 1,
          title: 'తిరుమల కథ',
          subtitle: 'శ్రద్ధతో మొదలయ్యే ప్రయాణం.',
          accent: AppColors.saffron,
        ),
      ],
    ),
    MythSeries(
      id: 'festival-stories',
      title: 'పండుగ కథలు',
      category: 'Festival',
      description: 'పండుగల అర్థం, ఆచారం, కథ, పాఠం.',
      coverAsset: cover,
      accent: const Color(0xFFD9468A),
      episodes: [
        MythEpisode.sample(
          id: 'fs-day-1',
          dayNumber: 1,
          title: 'దీపావళి అర్థం',
          subtitle: 'చీకటిపై వెలుగు గెలిచిన కథ.',
          accent: const Color(0xFFD9468A),
        ),
      ],
    ),
    MythSeries(
      id: 'kids-stories',
      title: 'పిల్లల కథలు',
      category: 'Kids',
      description: 'సులభమైన నీతి కథలు, కుటుంబంతో చదవడానికి.',
      coverAsset: cover,
      accent: const Color(0xFF7C3AED),
      episodes: [
        MythEpisode.sample(
          id: 'kd-day-1',
          dayNumber: 1,
          title: 'నిజం చెప్పిన బాలుడు',
          subtitle: 'ధైర్యంగా నిలిచిన చిన్న కథ.',
          accent: const Color(0xFF7C3AED),
        ),
      ],
    ),
  ];

  static List<MythSeries> get popularSeries => series.take(3).toList();

  static EpisodePair get featuredEpisode =>
      EpisodePair(series.first, series.first.episodes.first);

  static EpisodePair get todayEpisode =>
      EpisodePair(series.first, series.first.episodes.first);

  static List<EpisodePair> get recentEpisodes => [
    EpisodePair(series[1], series[1].episodes.first),
    EpisodePair(series[2], series[2].episodes.first),
  ];

  static EpisodePair? byEpisodeId(String id) {
    for (final item in series) {
      for (final episode in item.episodes) {
        if (episode.id == id) return EpisodePair(item, episode);
      }
    }
    return null;
  }
}

class ContentCatalog {
  const ContentCatalog(this.series);

  final List<MythSeries> series;

  EpisodePair? get featuredEpisode {
    for (final item in series) {
      if (item.episodes.isNotEmpty)
        return EpisodePair(item, item.episodes.first);
    }
    return null;
  }

  EpisodePair? get todayEpisode => featuredEpisode;

  List<MythSeries> get popularSeries => series.take(3).toList();

  List<EpisodePair> get recentEpisodes {
    final pairs = <EpisodePair>[];
    for (final item in series.skip(1)) {
      if (item.episodes.isNotEmpty) {
        pairs.add(EpisodePair(item, item.episodes.first));
      }
      if (pairs.length == 2) break;
    }
    return pairs;
  }

  EpisodePair? byEpisodeId(String? id) {
    if (id == null) return null;
    for (final item in series) {
      for (final episode in item.episodes) {
        if (episode.id == id) return EpisodePair(item, episode);
      }
    }
    return null;
  }

  EpisodePair? nextUnreadAfter(
    String? currentEpisodeId,
    Set<String> completedEpisodeIds,
  ) {
    if (currentEpisodeId != null) {
      for (final item in series) {
        final currentIndex = item.episodes.indexWhere(
          (episode) => episode.id == currentEpisodeId,
        );
        if (currentIndex == -1) continue;
        for (final episode in item.episodes.skip(currentIndex + 1)) {
          if (!completedEpisodeIds.contains(episode.id)) {
            return EpisodePair(item, episode);
          }
        }
      }
    }

    for (final item in series) {
      final episode = item.nextUnreadEpisode(completedEpisodeIds);
      if (episode != null && !completedEpisodeIds.contains(episode.id)) {
        return EpisodePair(item, episode);
      }
    }

    return featuredEpisode;
  }
}

class EpisodePair {
  const EpisodePair(this.series, this.episode);

  final MythSeries series;
  final MythEpisode episode;
}

class MythSeries {
  const MythSeries({
    required this.id,
    required this.title,
    required this.category,
    required this.description,
    required this.coverAsset,
    this.coverImageUrl,
    required this.accent,
    required this.episodes,
  });

  factory MythSeries.fromCmsStory(cms.Story story) {
    final categoryName = story.category?.name ?? _inferCategory(story.title);
    final accent = _accentFor('${story.title} $categoryName');
    return MythSeries(
      id: story.id,
      title: story.title,
      category: categoryName,
      description: story.description.isEmpty
          ? 'రోజువారీ కథల ప్రయాణం.'
          : story.description,
      coverAsset: V2Content.cover,
      coverImageUrl: story.coverImageUrl,
      accent: accent,
      episodes: story.days
          .map(
            (day) => MythEpisode.fromCmsDay(
              day,
              storyTitle: story.title,
              storyDescription: story.description,
              accent: accent,
            ),
          )
          .toList(),
    );
  }

  final String id;
  final String title;
  final String category;
  final String description;
  final String coverAsset;
  final String? coverImageUrl;
  final Color accent;
  final List<MythEpisode> episodes;

  MythSeries replaceEpisode(MythEpisode episode) {
    return MythSeries(
      id: id,
      title: title,
      category: category,
      description: description,
      coverAsset: coverAsset,
      coverImageUrl: coverImageUrl,
      accent: accent,
      episodes: episodes
          .map((item) => item.id == episode.id ? episode : item)
          .toList(),
    );
  }

  MythSeries withCoverImageUrl(String? imageUrl) {
    return MythSeries(
      id: id,
      title: title,
      category: category,
      description: description,
      coverAsset: coverAsset,
      coverImageUrl: imageUrl?.trim().isNotEmpty == true
          ? imageUrl!.trim()
          : coverImageUrl,
      accent: accent,
      episodes: episodes,
    );
  }

  MythEpisode? nextEpisodeAfter(String episodeId) {
    final index = episodes.indexWhere((episode) => episode.id == episodeId);
    if (index == -1 || index == episodes.length - 1) return null;
    return episodes[index + 1];
  }

  MythEpisode? nextUnreadEpisode(Set<String> completedEpisodeIds) {
    for (final episode in episodes) {
      if (!completedEpisodeIds.contains(episode.id)) return episode;
    }
    return episodes.isEmpty ? null : episodes.last;
  }
}

class MythEpisode {
  const MythEpisode({
    required this.id,
    required this.dayNumber,
    required this.title,
    required this.subtitle,
    required this.readingMinutes,
    required this.accent,
    required this.whatHappened,
    required this.lesson,
    required this.characters,
    required this.slides,
    this.questions = const [],
    this.isHydrated = false,
  });

  factory MythEpisode.fromCmsDay(
    cms.StoryDaySummary day, {
    required String storyTitle,
    required String storyDescription,
    required Color accent,
  }) {
    final title = day.title.isEmpty
        ? '$storyTitle Day ${day.dayNumber}'
        : day.title;
    return MythEpisode(
      id: day.id,
      dayNumber: day.dayNumber,
      title: title,
      subtitle: storyDescription.isEmpty ? storyTitle : storyDescription,
      readingMinutes: 5,
      accent: accent,
      whatHappened:
          'ఈ ఎపిసోడ్‌లో జరిగిన ముఖ్యమైన విషయాలను చదివిన తర్వాత ఇక్కడ సులభంగా చూస్తారు.',
      lesson: 'ఈ కథలోని పాఠం ఎపిసోడ్ పూర్తయ్యాక స్పష్టంగా కనిపిస్తుంది.',
      characters: const [
        MythCharacter(name: 'Daily Katha', role: 'Story guide'),
      ],
      questions: const [],
      slides: [
        MythSlide(
          id: '${day.id}-preview',
          title: title,
          body: storyDescription.isEmpty
              ? 'ఈ కథను ప్రారంభించండి.'
              : storyDescription,
          imageAsset: V2Content.cover,
          accent: accent,
        ),
      ],
    );
  }

  factory MythEpisode.sample({
    required String id,
    required int dayNumber,
    required String title,
    required String subtitle,
    required Color accent,
  }) {
    return MythEpisode(
      id: id,
      dayNumber: dayNumber,
      title: title,
      subtitle: subtitle,
      readingMinutes: 5,
      accent: accent,
      whatHappened:
          'ఈ కథలో ఒక చిన్న నిర్ణయం ఎలా పెద్ద పాఠంగా మారిందో సులభంగా తెలుసుకుంటాం.',
      lesson: 'ధర్మం, సహనం, నిజాయితీ ప్రతి కథలోని అసలు బలం.',
      characters: const [
        MythCharacter(name: 'ప్రధాన పాత్ర', role: 'కథానాయకుడు'),
      ],
      questions: const [],
      slides: [
        MythSlide(
          id: '$id-slide-1',
          title: title,
          body: subtitle,
          imageAsset: V2Content.cover,
          accent: accent,
        ),
        MythSlide(
          id: '$id-slide-2',
          title: 'కథలోని మలుపు',
          body:
              'ఒక సంఘటన పాత్రల మనసును మార్చి, కథను కొత్త దిశలోకి తీసుకెళ్లింది.',
          imageAsset: V2Content.cover,
          accent: accent,
        ),
      ],
    );
  }

  final String id;
  final int dayNumber;
  final String title;
  final String subtitle;
  final int readingMinutes;
  final Color accent;
  final String whatHappened;
  final String lesson;
  final List<MythCharacter> characters;
  final List<MythSlide> slides;
  final List<cms.QuizQuestion> questions;
  final bool isHydrated;

  MythEpisode hydrateFromCms(
    cms.DayDetail detail, {
    required MythSeries series,
  }) {
    final dayTitle = detail.day.title.isEmpty ? title : detail.day.title;
    final lessonText = detail.day.moral ?? lesson;
    final bodyText = lessonText.isNotEmpty ? lessonText : subtitle;
    final cmsSlides = detail.photos.isEmpty
        ? slides
        : detail.photos.map((photo) {
            final sceneNumber = photo.order <= 0 ? 1 : photo.order;
            return MythSlide(
              id: photo.id,
              title: sceneNumber == 1 ? dayTitle : '$dayTitle · $sceneNumber',
              body: bodyText,
              imageAsset: series.coverAsset,
              imageUrl: photo.imageUrl,
              accent: accent,
            );
          }).toList();

    return MythEpisode(
      id: id,
      dayNumber: detail.day.dayNumber == 0 ? dayNumber : detail.day.dayNumber,
      title: dayTitle,
      subtitle: detail.story.description.isEmpty
          ? subtitle
          : detail.story.description,
      readingMinutes: math.max(4, cmsSlides.length * 2),
      accent: accent,
      whatHappened: detail.story.description.isEmpty
          ? whatHappened
          : detail.story.description,
      lesson: lessonText,
      characters: characters,
      slides: cmsSlides,
      questions: detail.questions,
      isHydrated: true,
    );
  }
}

class MythSlide {
  const MythSlide({
    required this.id,
    required this.title,
    required this.body,
    required this.imageAsset,
    this.imageUrl,
    required this.accent,
  });

  final String id;
  final String title;
  final String body;
  final String imageAsset;
  final String? imageUrl;
  final Color accent;

  ImageProvider get imageProvider {
    final url = imageUrl?.trim();
    if (url == null || url.isEmpty) return AssetImage(imageAsset);
    return NetworkImage(_proxiedImageUrl(url));
  }
}

String _inferCategory(String title) {
  final normalized = title.toLowerCase();
  if (normalized.contains('భాగవ') || normalized.contains('bhag'))
    return 'Puranam';
  if (normalized.contains('temple') || normalized.contains('ఆలయ'))
    return 'Temple';
  if (normalized.contains('festival') || normalized.contains('పండుగ')) {
    return 'Festival';
  }
  if (normalized.contains('kids') || normalized.contains('పిల్ల'))
    return 'Kids';
  return 'Itihasam';
}

Color _accentFor(String value) {
  final normalized = value.toLowerCase();
  if (normalized.contains('రామ') || normalized.contains('rama')) {
    return AppColors.success;
  }
  if (normalized.contains('కృష్ణ') ||
      normalized.contains('భాగవ') ||
      normalized.contains('krishna') ||
      normalized.contains('bhag')) {
    return const Color(0xFF1D4ED8);
  }
  if (normalized.contains('festival') || normalized.contains('పండుగ')) {
    return const Color(0xFFD9468A);
  }
  if (normalized.contains('kids') || normalized.contains('పిల్ల')) {
    return const Color(0xFF7C3AED);
  }
  if (normalized.contains('temple') || normalized.contains('ఆలయ')) {
    return AppColors.saffron;
  }
  return AppColors.maroon;
}

class MythCharacter {
  const MythCharacter({required this.name, required this.role});

  final String name;
  final String role;
}

class ReadingProgress {
  const ReadingProgress({
    required this.seriesId,
    required this.episodeId,
    required this.slideIndex,
    required this.completed,
  });

  final String seriesId;
  final String episodeId;
  final int slideIndex;
  final bool completed;

  double percentage(MythEpisode episode) {
    if (completed) return 1;
    if (episode.slides.isEmpty) return 0;
    return (slideIndex + 1) / episode.slides.length;
  }

  double seriesProgress(MythSeries series) {
    if (series.episodes.isEmpty) return 0;
    final index = series.episodes.indexWhere(
      (episode) => episode.id == episodeId,
    );
    if (index == -1) return 0;
    final episode = series.episodes[index];
    return ((index) + percentage(episode)) / series.episodes.length;
  }
}

ReadingProgress? progressForEpisode({
  required ReadingProgress? liveProgress,
  required UserProgressSnapshot userProgress,
  required Set<String> completedEpisodeIds,
  required MythSeries series,
  required MythEpisode episode,
}) {
  if (liveProgress?.episodeId == episode.id) return liveProgress;

  final lastIndex = math.max(0, episode.slides.length - 1);
  if (completedEpisodeIds.contains(episode.id)) {
    return ReadingProgress(
      seriesId: series.id,
      episodeId: episode.id,
      slideIndex: lastIndex,
      completed: true,
    );
  }

  final dayProgress = userProgress.dayProgressByStoryDayId[episode.id];
  if (dayProgress == null || !dayProgress.started) return null;

  return ReadingProgress(
    seriesId: series.id,
    episodeId: episode.id,
    slideIndex: dayProgress.lastPhotoIndex.clamp(0, lastIndex).toInt(),
    completed: dayProgress.completed,
  );
}

bool isSeriesInProgress({
  required MythSeries series,
  required ReadingProgress? liveProgress,
  required UserProgressSnapshot userProgress,
  required Set<String> completedEpisodeIds,
}) {
  if (_seriesCompleted(series, userProgress, completedEpisodeIds)) return false;
  if (liveProgress?.seriesId == series.id) return true;

  final storyProgress = userProgress.storyProgressByStoryId[series.id];
  if (storyProgress?.started == true) return true;

  return userProgress.dayProgressByStoryDayId.values.any(
    (progress) => progress.storyId == series.id && progress.started,
  );
}

double seriesProgressValue({
  required MythSeries series,
  required ReadingProgress? liveProgress,
  required UserProgressSnapshot userProgress,
  required Set<String> completedEpisodeIds,
}) {
  if (series.episodes.isEmpty) return 0;
  if (_seriesCompleted(series, userProgress, completedEpisodeIds)) return 1;

  var completedCount = 0.0;
  for (final episode in series.episodes) {
    if (completedEpisodeIds.contains(episode.id)) {
      completedCount += 1;
      continue;
    }

    if (liveProgress?.episodeId == episode.id) {
      completedCount += liveProgress!.percentage(episode).clamp(0.0, 1.0);
      continue;
    }

    final dayProgress = userProgress.dayProgressByStoryDayId[episode.id];
    if (dayProgress == null || !dayProgress.started) continue;
    if (dayProgress.completed) {
      completedCount += 1;
    } else if (episode.isHydrated && episode.slides.isNotEmpty) {
      completedCount +=
          ((dayProgress.lastPhotoIndex + 1) / episode.slides.length).clamp(
            0.0,
            0.98,
          );
    } else {
      completedCount += _startedDayPlaceholderProgress(dayProgress);
    }
  }

  return (completedCount / series.episodes.length).clamp(0.0, 1.0);
}

bool _seriesCompleted(
  MythSeries series,
  UserProgressSnapshot userProgress,
  Set<String> completedEpisodeIds,
) {
  if (series.episodes.isEmpty) return false;
  final storyProgress = userProgress.storyProgressByStoryId[series.id];
  if (storyProgress?.completed == true) return true;
  return series.episodes.every((episode) {
    return completedEpisodeIds.contains(episode.id);
  });
}

double _startedDayPlaceholderProgress(StoryDayProgressSnapshot progress) {
  final slideWeight = (progress.lastPhotoIndex + 1) * 0.12;
  return math.min(0.7, math.max(0.18, slideWeight));
}
