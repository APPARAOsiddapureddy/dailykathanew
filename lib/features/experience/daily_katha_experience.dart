import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/api/api_client.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/app_states.dart';
import '../stories/data/app_api_service.dart';
import '../stories/models/story_models.dart';
import 'data/user_api_service.dart';
import 'models/app_user_models.dart';
import 'screens/profile_settings_screen.dart';
import 'screens/completion_reward_screen.dart';
import 'screens/quiz_flow_screen.dart';
import 'screens/quiz_review_screen.dart';

class DailyKathaExperience extends StatefulWidget {
  const DailyKathaExperience({super.key});

  @override
  State<DailyKathaExperience> createState() => _DailyKathaExperienceState();
}

class _DailyKathaExperienceState extends State<DailyKathaExperience> {
  bool _showSplash = true;
  bool _loadingSession = true;
  bool _otpRequested = false;
  bool _profileRequested = false;
  bool _checkingPhone = false;
  bool _savingOnboarding = false;
  bool _loadingContent = false;
  int _tabIndex = 0;
  String _phoneNumber = '';
  String? _newUserName;
  String? _error;

  AppSession? _session;
  AppUser? _user;
  ProfileSummary _summary = const ProfileSummary(
    completedStories: 0,
    answeredQuestions: 0,
    correctAnswers: 0,
  );
  UserProgress _progress = UserProgress.empty;
  List<Story> _stories = const [];
  List<EarnedBadge> _badges = const [];

  AppApiService get _storyApi => AppApiService(authToken: _session?.token);
  UserApiService get _userApi =>
      UserApiService(client: ApiClient(authToken: _session?.token));

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  Future<void> _restoreSession() async {
    final session = await UserApiService.restoreSession();
    if (!mounted) return;
    setState(() {
      _session = session;
      _user = session?.user;
      _loadingSession = false;
    });
    if (session != null) await _refreshContent();
  }

  Future<void> _createSession() async {
    setState(() {
      _loadingSession = true;
      _error = null;
    });

    try {
      final session = await UserApiService().createSession(
        phoneNumber: '+91$_phoneNumber',
        name: _newUserName,
      );
      await UserApiService.saveSession(session);
      if (!mounted) return;
      setState(() {
        _session = session;
        _user = session.user;
        _otpRequested = false;
        _profileRequested = false;
        _newUserName = null;
      });
      await _refreshContent();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loadingSession = false);
    }
  }

  Future<void> _checkPhoneAndContinue(String phone) async {
    setState(() {
      _phoneNumber = phone;
      _checkingPhone = true;
      _error = null;
    });

    try {
      final phoneCheck = await UserApiService().checkPhone('+91$phone');
      if (!mounted) return;
      setState(() {
        _otpRequested = phoneCheck.exists && !phoneCheck.needsProfile;
        _profileRequested = phoneCheck.needsProfile;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _checkingPhone = false);
    }
  }

  Future<void> _refreshContent() async {
    if (_session == null) return;
    setState(() {
      _loadingContent = true;
      _error = null;
    });

    try {
      final results = await Future.wait<Object>([
        _storyApi.fetchStories(),
        _userApi.fetchMe(),
        _userApi.fetchProgress(),
        _userApi.fetchProfileSummary(),
        _userApi.fetchBadges(),
      ]);
      await _userApi.markActive();
      if (!mounted) return;
      setState(() {
        _stories = results[0] as List<Story>;
        _user = results[1] as AppUser;
        final session = _session;
        if (session != null) {
          UserApiService.saveSession(
            AppSession(token: session.token, user: _user!),
          );
        }
        _progress = results[2] as UserProgress;
        _summary = results[3] as ProfileSummary;
        _badges = results[4] as List<EarnedBadge>;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _loadingContent = false);
    }
  }

  Future<void> _openJourney(Story story) async {
    await _userApi.startStory(story.id);
    if (!mounted) return;
    await Navigator.of(context).push(
      _KathaRoute<void>(
        child: StoryJourneyScreen(
          story: story,
          progress: _progress,
          onStartDay: (day) => _openReader(story, day),
        ),
      ),
    );
    await _refreshContent();
  }

  Future<void> _openReader(Story story, StoryDaySummary day) async {
    await Navigator.of(context).push(
      _KathaRoute<void>(
        child: StoryReaderScreen(
          story: story,
          day: day,
          storyApi: _storyApi,
          userApi: _userApi,
          onFinished: _refreshContent,
        ),
      ),
    );
  }

  Future<void> _openSettings() async {
    final user = _user;
    if (user == null) return;

    await Navigator.of(context).push(
      _KathaRoute<void>(
        child: ProfileSettingsScreen(
          user: user,
          userApi: _userApi,
          onUserUpdated: (updatedUser) {
            setState(() => _user = updatedUser);
            final session = _session;
            if (session != null) {
              UserApiService.saveSession(
                AppSession(token: session.token, user: updatedUser),
              );
            }
          },
          onLogout: _logout,
        ),
      ),
    );
    await _refreshContent();
  }

  Future<void> _logout() async {
    await UserApiService.clearSession();
    if (!mounted) return;
    Navigator.of(context).popUntil((route) => route.isFirst);
    setState(() {
      _session = null;
      _user = null;
      _stories = const [];
      _badges = const [];
      _progress = UserProgress.empty;
      _summary = const ProfileSummary(
        completedStories: 0,
        answeredQuestions: 0,
        correctAnswers: 0,
      );
      _tabIndex = 0;
      _otpRequested = false;
      _profileRequested = false;
      _savingOnboarding = false;
      _newUserName = null;
    });
  }

  bool get _needsOnboarding {
    final user = _user;
    if (user == null) return false;
    return user.selectedLanguage == null || user.interests.isEmpty;
  }

  Future<void> _completeOnboarding({
    required String selectedLanguage,
    required List<String> interests,
  }) async {
    setState(() {
      _savingOnboarding = true;
      _error = null;
    });

    try {
      final updatedUser = await _userApi.updateMe(
        selectedLanguage: selectedLanguage,
        interests: interests,
      );
      final session = _session;
      if (session != null) {
        await UserApiService.saveSession(
          AppSession(token: session.token, user: updatedUser),
        );
      }
      if (!mounted) return;
      setState(() => _user = updatedUser);
      await _refreshContent();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _savingOnboarding = false);
    }
  }

  StoryDaySummary? _nextReadableDay(Story story) {
    if (story.days.isEmpty) return null;
    final completedIds = _progress.kathaProgress
        .where((item) => item.storyId == story.id && item.completed)
        .map((item) => item.storyDayId)
        .toSet();
    for (final day in story.days) {
      if (!completedIds.contains(day.id)) return day;
    }
    return story.days.last;
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onContinue: () => setState(() => _showSplash = false),
      );
    }

    if (_loadingSession) {
      return const Scaffold(
        body: AppLoading(message: 'Opening Daily Katha...'),
      );
    }

    if (_session == null) {
      if (_profileRequested) {
        return NewUserProfileScreen(
          phoneNumber: '+91$_phoneNumber',
          error: _error,
          onBack: () {
            setState(() {
              _profileRequested = false;
              _newUserName = null;
              _error = null;
            });
          },
          onContinue: (name) {
            setState(() {
              _newUserName = name;
              _profileRequested = false;
              _otpRequested = true;
              _error = null;
            });
          },
        );
      }

      return _otpRequested
          ? OtpScreen(
              error: _error,
              onVerified: _createSession,
              onChangeNumber: () => setState(() {
                _otpRequested = false;
                _newUserName = null;
              }),
            )
          : LoginScreen(
              checking: _checkingPhone,
              error: _error,
              onOtpRequested: _checkPhoneAndContinue,
            );
    }

    if (_needsOnboarding) {
      return OnboardingScreen(
        busy: _savingOnboarding,
        error: _error,
        onContinue: _completeOnboarding,
      );
    }

    return MainShell(
      tabIndex: _tabIndex,
      onTabChanged: (index) => setState(() => _tabIndex = index),
      loading: _loadingContent,
      error: _error,
      user: _user,
      stories: _stories,
      progress: _progress,
      summary: _summary,
      badges: _badges,
      onRetry: _refreshContent,
      onOpenJourney: _openJourney,
      onOpenSettings: _openSettings,
      onOpenFirstStory: () {
        if (_stories.isEmpty) return;
        final story = _stories.first;
        final day = _nextReadableDay(story);
        if (day == null) {
          _openJourney(story);
        } else {
          _openReader(story, day);
        }
      },
    );
  }
}

class _KathaRoute<T> extends PageRouteBuilder<T> {
  _KathaRoute({required Widget child})
    : super(
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, __, ___) => child,
        transitionsBuilder: (_, animation, __, child) {
          final curved = CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutCubic,
            reverseCurve: Curves.easeInCubic,
          );
          return FadeTransition(
            opacity: curved,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, .035),
                end: Offset.zero,
              ).animate(curved),
              child: child,
            ),
          );
        },
      );
}

class _LogoGlass extends StatelessWidget {
  const _LogoGlass({required this.size, required this.logoSize});

  final double size;
  final double logoSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(size * .28),
        border: Border.all(
          color: AppColors.gold.withValues(alpha: .55),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.gold.withValues(alpha: .28),
            blurRadius: 38,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Center(child: AppLogo(size: logoSize)),
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: InkWell(
        onTap: onContinue,
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [AppColors.maroon, AppColors.dusk, AppColors.brown],
            ),
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(-.35, -.45),
                      radius: 1.1,
                      colors: [
                        AppColors.saffron.withValues(alpha: .34),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              const SafeArea(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _LogoGlass(size: 112, logoSize: 74),
                      SizedBox(height: 26),
                      Text(
                        'డైలీ కథ',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 42,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        'DAILY KATHA',
                        style: TextStyle(
                          color: AppColors.gold,
                          fontSize: 13,
                          letterSpacing: 3,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'ప్రతి రోజు ఒక కథ,\nఒక మంచి పాఠం.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xEEFFF7E6),
                          fontSize: 16,
                          height: 1.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Positioned(
                left: 0,
                right: 0,
                bottom: 34,
                child: Text(
                  'Tap to begin',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white70,
                    fontWeight: FontWeight.w800,
                    letterSpacing: .8,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.onOtpRequested,
    required this.checking,
    this.error,
  });

  final ValueChanged<String> onOtpRequested;
  final bool checking;
  final String? error;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _number = '';

  void _append(String value) {
    if (_number.length >= 10) return;
    setState(() => _number += value);
  }

  @override
  Widget build(BuildContext context) {
    final ready = _number.length == 10;
    final formatted = _number.isEmpty
        ? '00000 00000'
        : '${_number.substring(0, _number.length > 5 ? 5 : _number.length)}'
              '${_number.length > 5 ? ' ${_number.substring(5)}' : ''}';

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [AppColors.maroon, AppColors.deepSaffron, AppColors.ivory],
            stops: [0, .5, 1],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 18),
              const _LogoGlass(size: 76, logoSize: 50),
              const SizedBox(height: 12),
              const Text(
                'డైలీ కథ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'రోజూ ఒక కథ ద్వారా జీవిత పాఠాలు',
                style: TextStyle(
                  color: Color(0xEEFFF7E6),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 26, 24, 20),
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Login / Sign up',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'We will verify your mobile number with OTP.',
                      style: TextStyle(color: AppColors.mutedBrown),
                    ),
                    const SizedBox(height: 18),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: ready ? AppColors.saffron : AppColors.border,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          const Text(
                            '+91',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Container(
                            width: 1,
                            height: 28,
                            color: AppColors.border,
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              formatted,
                              style: TextStyle(
                                color: _number.isEmpty
                                    ? AppColors.border
                                    : AppColors.brown,
                                fontSize: 21,
                                letterSpacing: 2,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: ready && !widget.checking
                          ? () => widget.onOtpRequested(_number)
                          : null,
                      child: Text(widget.checking ? 'Checking...' : 'Send OTP'),
                    ),
                    if (widget.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        widget.error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    _Keypad(
                      onDigit: _append,
                      onBackspace: () {
                        if (_number.isNotEmpty) {
                          setState(
                            () => _number = _number.substring(
                              0,
                              _number.length - 1,
                            ),
                          );
                        }
                      },
                    ),
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

class NewUserProfileScreen extends StatefulWidget {
  const NewUserProfileScreen({
    super.key,
    required this.phoneNumber,
    required this.onContinue,
    required this.onBack,
    this.error,
  });

  final String phoneNumber;
  final ValueChanged<String> onContinue;
  final VoidCallback onBack;
  final String? error;

  @override
  State<NewUserProfileScreen> createState() => _NewUserProfileScreenState();
}

class _NewUserProfileScreenState extends State<NewUserProfileScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final name = _nameController.text.trim();

    return Scaffold(
      body: Stack(
        children: [
          const _AmbientBackdrop(),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton.filledTonal(
                    onPressed: widget.onBack,
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                ),
                const SizedBox(height: 18),
                const Center(child: _LogoGlass(size: 98, logoSize: 58)),
                const SizedBox(height: 28),
                Text(
                  'Create your profile',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                Text(
                  widget.phoneNumber,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.deepSaffron,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 30),
                _GlassPanel(
                  child: TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.done,
                    textCapitalization: TextCapitalization.words,
                    decoration: const InputDecoration(
                      labelText: 'Name',
                      hintText: 'Enter your name',
                      prefixIcon: Icon(Icons.person_rounded),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => setState(() {}),
                    onSubmitted: (_) {
                      if (name.isNotEmpty) widget.onContinue(name);
                    },
                  ),
                ),
                if (widget.error != null) ...[
                  const SizedBox(height: 14),
                  Text(
                    widget.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: name.isEmpty
                      ? null
                      : () => widget.onContinue(name),
                  icon: const Icon(Icons.arrow_forward_rounded),
                  label: const Text('Continue to OTP'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class OtpScreen extends StatefulWidget {
  const OtpScreen({
    super.key,
    required this.onVerified,
    required this.onChangeNumber,
    this.error,
  });

  final VoidCallback onVerified;
  final VoidCallback onChangeNumber;
  final String? error;

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  String _otp = '';
  bool _verifying = false;

  void _append(String value) {
    if (_otp.length >= 4 || _verifying) return;
    setState(() => _otp += value);
    if (_otp.length == 4) {
      setState(() => _verifying = true);
      widget.onVerified();
    }
  }

  @override
  void didUpdateWidget(covariant OtpScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.error != null && widget.error != oldWidget.error) {
      setState(() => _verifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const _AmbientBackdrop(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(22, 18, 22, 24),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton.filledTonal(
                      onPressed: widget.onChangeNumber,
                      icon: const Icon(Icons.arrow_back_rounded),
                    ),
                  ),
                  const Spacer(),
                  const _LogoGlass(size: 88, logoSize: 50),
                  const SizedBox(height: 24),
                  Text(
                    'Enter OTP',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Temporary development login. OTP service will be added later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.mutedBrown),
                  ),
                  const SizedBox(height: 30),
                  _GlassPanel(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 18,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(4, (index) {
                        final filled = index < _otp.length;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 58,
                          height: 66,
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          decoration: BoxDecoration(
                            color: filled
                                ? const Color(0xFFFFF2DD)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: filled
                                  ? AppColors.saffron
                                  : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              filled ? _otp[index] : '',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 18),
                  if (_verifying)
                    const CircularProgressIndicator()
                  else
                    TextButton(
                      onPressed: widget.onChangeNumber,
                      child: const Text('Change number'),
                    ),
                  if (widget.error != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      widget.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                  const Spacer(),
                  _Keypad(
                    onDigit: _append,
                    onBackspace: () {
                      if (_otp.isNotEmpty && !_verifying) {
                        setState(
                          () => _otp = _otp.substring(0, _otp.length - 1),
                        );
                      }
                    },
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

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.busy,
    required this.error,
    required this.onContinue,
  });

  final bool busy;
  final String? error;
  final Future<void> Function({
    required String selectedLanguage,
    required List<String> interests,
  })
  onContinue;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  String _selectedLanguage = 'TELUGU';
  final Set<String> _selectedInterests = {'Mahabharatam'};

  static const _languages = [
    _PreferenceOption(
      id: 'TELUGU',
      title: 'Telugu',
      subtitle: 'Simple Telugu kathalu',
    ),
    _PreferenceOption(
      id: 'TELUGU_ENGLISH',
      title: 'English + Telugu',
      subtitle: 'Mixed language for easier reading',
    ),
  ];

  static const _interests = [
    _PreferenceOption(id: 'Mahabharatam', title: 'Mahabharatam'),
    _PreferenceOption(id: 'Ramayanam', title: 'Ramayanam'),
    _PreferenceOption(id: 'Sri Krishna Kathalu', title: 'Sri Krishna Kathalu'),
    _PreferenceOption(id: 'Shiva Kathalu', title: 'Shiva Kathalu'),
    _PreferenceOption(id: 'Temple Stories', title: 'Temple Stories'),
    _PreferenceOption(id: 'Festival Kathalu', title: 'Festival Kathalu'),
    _PreferenceOption(id: 'Kids Kathalu', title: 'Kids Kathalu'),
  ];

  void _toggleInterest(String interest) {
    setState(() {
      if (_selectedInterests.contains(interest)) {
        if (_selectedInterests.length == 1) return;
        _selectedInterests.remove(interest);
      } else {
        _selectedInterests.add(interest);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            const _AmbientBackdrop(),
            ListView(
              padding: const EdgeInsets.fromLTRB(22, 24, 22, 34),
              children: [
                const Center(child: _LogoGlass(size: 92, logoSize: 54)),
                const SizedBox(height: 24),
                Text(
                  'Make Daily Katha yours',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall,
                ),
                const SizedBox(height: 10),
                const Text(
                  'Choose your language and the kathalu you want to see first.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.mutedBrown, fontSize: 16),
                ),
                const SizedBox(height: 28),
                _GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Language',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      ..._languages.map(
                        (language) => _PreferenceTile(
                          title: language.title,
                          subtitle: language.subtitle,
                          selected: _selectedLanguage == language.id,
                          onTap: () =>
                              setState(() => _selectedLanguage = language.id),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                _GlassPanel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interests',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: _interests
                            .map(
                              (interest) => _InterestChip(
                                label: interest.title,
                                selected: _selectedInterests.contains(
                                  interest.id,
                                ),
                                onTap: () => _toggleInterest(interest.id),
                              ),
                            )
                            .toList(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                if (widget.error != null) ...[
                  Text(
                    widget.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                FilledButton.icon(
                  onPressed: widget.busy
                      ? null
                      : () => widget.onContinue(
                          selectedLanguage: _selectedLanguage,
                          interests: _selectedInterests.toList(),
                        ),
                  icon: widget.busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.arrow_forward_rounded),
                  label: Text(widget.busy ? 'Saving...' : 'Start Daily Katha'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PreferenceOption {
  const _PreferenceOption({
    required this.id,
    required this.title,
    this.subtitle,
  });

  final String id;
  final String title;
  final String? subtitle;
}

class _PreferenceTile extends StatelessWidget {
  const _PreferenceTile({
    required this.title,
    required this.selected,
    required this.onTap,
    this.subtitle,
  });

  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: selected ? const Color(0xFFFFF1E6) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: selected
              ? AppColors.saffron.withValues(alpha: .55)
              : AppColors.border.withValues(alpha: .42),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_off,
          color: selected ? AppColors.deepSaffron : AppColors.mutedBrown,
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: subtitle == null ? null : Text(subtitle!),
      ),
    );
  }
}

class _InterestChip extends StatelessWidget {
  const _InterestChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      onPressed: onTap,
      avatar: selected
          ? const Icon(
              Icons.check_rounded,
              size: 18,
              color: AppColors.deepSaffron,
            )
          : null,
      label: Text(label),
      labelStyle: TextStyle(
        color: selected ? AppColors.deepSaffron : AppColors.brown,
        fontWeight: FontWeight.w800,
      ),
      backgroundColor: selected ? const Color(0xFFFFE7B3) : Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      side: BorderSide(color: selected ? AppColors.gold : AppColors.border),
    );
  }
}

class MainShell extends StatelessWidget {
  const MainShell({
    super.key,
    required this.tabIndex,
    required this.onTabChanged,
    required this.loading,
    required this.error,
    required this.user,
    required this.stories,
    required this.progress,
    required this.summary,
    required this.badges,
    required this.onRetry,
    required this.onOpenJourney,
    required this.onOpenSettings,
    required this.onOpenFirstStory,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final bool loading;
  final String? error;
  final AppUser? user;
  final List<Story> stories;
  final UserProgress progress;
  final ProfileSummary summary;
  final List<EarnedBadge> badges;
  final VoidCallback onRetry;
  final ValueChanged<Story> onOpenJourney;
  final VoidCallback onOpenSettings;
  final VoidCallback onOpenFirstStory;

  @override
  Widget build(BuildContext context) {
    if (loading && stories.isEmpty) {
      return const Scaffold(body: AppLoading(message: 'Loading app data...'));
    }

    if (error != null && stories.isEmpty) {
      return Scaffold(
        body: ErrorState(message: error!, onRetry: onRetry),
      );
    }

    final pages = [
      HomeScreen(
        user: user,
        stories: stories,
        progress: progress,
        onStartToday: onOpenFirstStory,
        onOpenJourney: onOpenJourney,
      ),
      LibraryScreen(stories: stories, onOpenJourney: onOpenJourney),
      const CardsScreen(),
      ProfileScreen(
        user: user,
        summary: summary,
        badges: badges,
        onOpenSettings: onOpenSettings,
      ),
    ];

    return Scaffold(
      extendBody: true,
      body: RefreshIndicator(
        onRefresh: () async => onRetry(),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 320),
          switchInCurve: Curves.easeOutCubic,
          switchOutCurve: Curves.easeInCubic,
          transitionBuilder: (child, animation) {
            final offset = Tween<Offset>(
              begin: const Offset(0, .025),
              end: Offset.zero,
            ).animate(animation);
            return FadeTransition(
              opacity: animation,
              child: SlideTransition(position: offset, child: child),
            );
          },
          child: KeyedSubtree(key: ValueKey(tabIndex), child: pages[tabIndex]),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(18, 0, 18, 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xF8FFFCF6),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border.withValues(alpha: .45)),
            boxShadow: [
              BoxShadow(
                color: AppColors.brown.withValues(alpha: .12),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: NavigationBar(
              selectedIndex: tabIndex,
              onDestinationSelected: onTabChanged,
              height: 68,
              backgroundColor: Colors.transparent,
              indicatorColor: const Color(0xFFFFE4A8),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.menu_book_rounded),
                  label: 'Kathalu',
                ),
                NavigationDestination(
                  icon: Icon(Icons.style_rounded),
                  label: 'Cards',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.stories,
    required this.progress,
    required this.onStartToday,
    required this.onOpenJourney,
  });

  final AppUser? user;
  final List<Story> stories;
  final UserProgress progress;
  final VoidCallback onStartToday;
  final ValueChanged<Story> onOpenJourney;

  @override
  Widget build(BuildContext context) {
    final firstStory = stories.isEmpty ? null : stories.first;
    final displayName = user?.name?.isNotEmpty == true
        ? user!.name!
        : 'Daily Katha';

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          const _AmbientBackdrop(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 118),
            children: [
              _HomeTopBar(user: user, displayName: displayName),
              const SizedBox(height: 22),
              Text(
                '5 minutes. One katha. One lesson.',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  fontSize: 31,
                  color: AppColors.brown,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Continue your devotional story journey for today.',
                style: TextStyle(color: AppColors.mutedBrown, fontSize: 16),
              ),
              const SizedBox(height: 22),
              if (firstStory == null)
                const EmptyState(
                  icon: Icons.auto_stories_rounded,
                  title: 'No stories published yet',
                  message: 'Stories added from the CMS will appear here.',
                )
              else
                _TodayHero(
                  story: firstStory,
                  progress: _storyProgressFraction(firstStory, progress),
                  onStart: onStartToday,
                ),
              const SizedBox(height: 28),
              _SectionTitle(title: 'Continue Journey', action: ''),
              const SizedBox(height: 12),
              if (stories.isEmpty)
                const Text(
                  'No journeys available yet.',
                  style: TextStyle(color: AppColors.mutedBrown),
                )
              else
                SizedBox(
                  height: 188,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemBuilder: (context, index) {
                      final story = stories[index];
                      return _JourneyMiniCard(
                        story: story,
                        progress: _storyProgressFraction(story, progress),
                        onTap: () => onOpenJourney(story),
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(width: 14),
                    itemCount: stories.length,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({
    super.key,
    required this.stories,
    required this.onOpenJourney,
  });

  final List<Story> stories;
  final ValueChanged<Story> onOpenJourney;

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<Story>>{};
    for (final story in stories) {
      grouped.putIfAbsent(story.categoryName, () => []).add(story);
    }

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          const _AmbientBackdrop(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 112),
            children: [
              Text('Kathalu', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text(
                'Explore story worlds published from your CMS.',
                style: TextStyle(color: AppColors.mutedBrown, fontSize: 16),
              ),
              const SizedBox(height: 24),
              if (stories.isEmpty)
                const EmptyState(
                  icon: Icons.auto_stories_rounded,
                  title: 'No published kathalu',
                  message:
                      'Publish stories and days in the CMS to show them here.',
                )
              else
                for (final entry in grouped.entries) ...[
                  _GlassPanel(
                    padding: const EdgeInsets.all(16),
                    child: _SectionTitle(title: entry.key, action: ''),
                  ),
                  const SizedBox(height: 12),
                  ...entry.value.map(
                    (story) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _LibraryRow(
                        story: story,
                        onTap: () => onOpenJourney(story),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
            ],
          ),
        ],
      ),
    );
  }
}

class StoryJourneyScreen extends StatelessWidget {
  const StoryJourneyScreen({
    super.key,
    required this.story,
    required this.progress,
    required this.onStartDay,
  });

  final Story story;
  final UserProgress progress;
  final ValueChanged<StoryDaySummary> onStartDay;

  @override
  Widget build(BuildContext context) {
    final completedIds = progress.kathaProgress
        .where((item) => item.storyId == story.id && item.completed)
        .map((item) => item.storyDayId)
        .toSet();
    final currentDay = _firstIncompleteDay(story, completedIds);
    final completedCount = story.days
        .where((day) => completedIds.contains(day.id))
        .length;
    final totalDays = story.days.length;
    final progressValue = totalDays == 0 ? 0.0 : completedCount / totalDays;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(story.title),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        top: false,
        child: Stack(
          children: [
            const _AmbientBackdrop(),
            ListView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 118),
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(34),
                  ),
                  child: AspectRatio(
                    aspectRatio: .78,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Hero(
                          tag: 'story-cover-${story.id}',
                          child: KathaNetworkImage(url: story.coverImageUrl),
                        ),
                        const DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0x44000000),
                                Colors.transparent,
                                Color(0xEE2B1A12),
                              ],
                              stops: [0, .38, 1],
                            ),
                          ),
                        ),
                        Positioned(
                          left: 18,
                          right: 18,
                          bottom: 18,
                          child: Text(
                            story.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -26),
                  child: _GlassPanel(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Overall Progress',
                              style: TextStyle(
                                color: AppColors.deepSaffron,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              '$completedCount of $totalDays',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(
                          value: progressValue,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(999),
                          color: AppColors.gold,
                          backgroundColor: const Color(0xFFFFE7C7),
                        ),
                      ],
                    ),
                  ),
                ),
                Text(
                  'Journey So Far',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 12),
                if (story.days.isEmpty)
                  const EmptyState(
                    icon: Icons.event_busy_rounded,
                    title: 'No published days',
                    message: 'Publish days in the CMS to unlock this journey.',
                  )
                else
                  ...story.days.map((day) {
                    final completed = completedIds.contains(day.id);
                    final current = currentDay?.id == day.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _DayTimelineTile(
                        day: day,
                        completed: completed,
                        current: current,
                        onTap: completed || current
                            ? () => onStartDay(day)
                            : null,
                      ),
                    );
                  }),
              ],
            ),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: FilledButton.icon(
          onPressed: currentDay == null ? null : () => onStartDay(currentDay),
          icon: const Icon(Icons.play_arrow_rounded),
          label: Text(
            currentDay == null
                ? 'No day available'
                : 'Continue Day ${currentDay.dayNumber}',
          ),
        ),
      ),
    );
  }
}

class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({
    super.key,
    required this.story,
    required this.day,
    required this.storyApi,
    required this.userApi,
    required this.onFinished,
  });

  final Story story;
  final StoryDaySummary day;
  final AppApiService storyApi;
  final UserApiService userApi;
  final VoidCallback onFinished;

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  late Future<DayDetail> _detailFuture;
  final PageController _controller = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _detailFuture = _loadDay();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<DayDetail> _loadDay() {
    return widget.storyApi.fetchDay(
      storyId: widget.story.id,
      dayNumber: widget.day.dayNumber,
    );
  }

  void _saveProgress(DayDetail detail, int index) {
    widget.userApi.saveDayProgress(
      storyDayId: detail.day.id,
      lastPhotoIndex: index,
    );
  }

  Future<void> _finishDayWithoutQuiz(DayDetail detail) async {
    await widget.userApi.completeDay(detail.day.id);
    widget.onFinished();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      _KathaRoute<void>(
        child: CompletionRewardScreen(
          day: widget.day,
          detail: detail,
          result: null,
          userApi: widget.userApi,
        ),
      ),
    );
  }

  Future<void> _openQuiz(DayDetail detail) async {
    final existingReview = await widget.userApi.fetchLatestQuizReview(
      detail.day.id,
    );
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      _KathaRoute<void>(
        child: existingReview == null
            ? QuizFlowScreen(
                day: widget.day,
                detail: detail,
                userApi: widget.userApi,
                onFinished: widget.onFinished,
              )
            : QuizReviewScreen(review: existingReview, day: widget.day),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.brown,
      body: FutureBuilder<DayDetail>(
        future: _detailFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoading(message: 'Opening story...');
          }
          if (snapshot.hasError) {
            return ErrorState(
              message: '${snapshot.error}',
              onRetry: () => setState(() => _detailFuture = _loadDay()),
            );
          }

          final detail = snapshot.data!;
          if (detail.photos.isEmpty) {
            return SafeArea(
              child: EmptyState(
                icon: Icons.image_not_supported_rounded,
                title: 'No photos for this day',
                message: 'Photos uploaded in CMS will appear here.',
                action: FilledButton(
                  onPressed: detail.questions.isEmpty
                      ? () => _finishDayWithoutQuiz(detail)
                      : () => _openQuiz(detail),
                  child: Text(
                    detail.questions.isEmpty ? 'Complete Day' : 'Start Quiz',
                  ),
                ),
              ),
            );
          }

          final isFinalPhoto = _index == detail.photos.length - 1;
          return Center(
            child: AspectRatio(
              aspectRatio: 9 / 16,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: Stack(
                  children: [
                    PageView.builder(
                      controller: _controller,
                      itemCount: detail.photos.length,
                      onPageChanged: (index) {
                        setState(() => _index = index);
                        _saveProgress(detail, index);
                      },
                      itemBuilder: (_, index) => KathaNetworkImage(
                        url: detail.photos[index].imageUrl,
                        fit: BoxFit.cover,
                      ),
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xAA000000),
                            Colors.transparent,
                            Color(0xCC000000),
                          ],
                          stops: [0, .42, 1],
                        ),
                      ),
                      child: SizedBox.expand(),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _PhotoProgress(
                              count: detail.photos.length,
                              activeIndex: _index,
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                _RoundIconButton(
                                  icon: Icons.close_rounded,
                                  onTap: () => Navigator.of(context).pop(),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Day ${detail.day.dayNumber}: ${detail.day.title}',
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: .42),
                                borderRadius: BorderRadius.circular(26),
                                border: Border.all(color: Colors.white24),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.story.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Day ${detail.day.dayNumber}: ${detail.day.title}',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 22,
                                      height: 1.15,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    '${_index + 1} of ${detail.photos.length}',
                                    style: TextStyle(
                                      color: Colors.white.withValues(
                                        alpha: .78,
                                      ),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Align(
                              alignment: Alignment.bottomRight,
                              child: _SmallNextButton(
                                label: isFinalPhoto
                                    ? detail.questions.isEmpty
                                          ? 'Done'
                                          : 'Quiz'
                                    : 'Next',
                                icon: isFinalPhoto
                                    ? detail.questions.isEmpty
                                          ? Icons.check_rounded
                                          : Icons.quiz_rounded
                                    : Icons.arrow_forward_rounded,
                                onTap: () {
                                  if (isFinalPhoto) {
                                    detail.questions.isEmpty
                                        ? _finishDayWithoutQuiz(detail)
                                        : _openQuiz(detail);
                                  } else {
                                    _controller.nextPage(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cards = [
      ('Wisdom Cards', AppColors.maroon, Icons.auto_awesome_rounded),
      ('Festival Blessings', AppColors.saffron, Icons.temple_hindu_rounded),
      ('Story Moments', AppColors.peacock, Icons.image_rounded),
      ('Daily Morals', AppColors.lotus, Icons.lightbulb_rounded),
    ];

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          const _AmbientBackdrop(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 118),
            children: [
              Text('Cards', style: Theme.of(context).textTheme.displaySmall),
              const SizedBox(height: 8),
              const Text(
                'Collectable devotional cards will live here soon.',
                style: TextStyle(color: AppColors.mutedBrown, fontSize: 16),
              ),
              const SizedBox(height: 24),
              _GlassPanel(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.gold, AppColors.saffron],
                            ),
                          ),
                          child: const Icon(
                            Icons.lock_open_rounded,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Coming after share cards',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'The backend is unchanged; this is only a styled holding screen.',
                                style: TextStyle(color: AppColors.mutedBrown),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GridView.builder(
                itemCount: cards.length,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: .78,
                ),
                itemBuilder: (context, index) {
                  final item = cards[index];
                  return _CardPreview(
                    title: item.$1,
                    color: item.$2,
                    icon: item.$3,
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.user,
    required this.summary,
    required this.badges,
    required this.onOpenSettings,
  });

  final AppUser? user;
  final ProfileSummary summary;
  final List<EarnedBadge> badges;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    final displayName = user?.name?.isNotEmpty == true
        ? user!.name!
        : (user?.phoneNumber.isNotEmpty == true
              ? user!.phoneNumber
              : 'Daily Katha User');

    return SafeArea(
      bottom: false,
      child: Stack(
        children: [
          const _AmbientBackdrop(),
          ListView(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 118),
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Text(
                    'My Profile',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton.filledTonal(
                      onPressed: user == null ? null : onOpenSettings,
                      icon: const Icon(Icons.settings_rounded),
                      tooltip: 'Settings',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _GlassPanel(
                child: Column(
                  children: [
                    Container(
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [AppColors.gold, AppColors.saffron],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.saffron.withValues(alpha: .28),
                            blurRadius: 22,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.person_rounded,
                        color: Colors.white,
                        size: 58,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      displayName,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _MetricPill(
                          icon: Icons.star_rounded,
                          label: '${user?.points ?? 0} pts',
                          color: AppColors.deepSaffron,
                        ),
                        _MetricPill(
                          icon: Icons.local_fire_department_rounded,
                          label: '${user?.currentStreak ?? 0} day streak',
                          color: AppColors.maroon,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: .95,
                children: [
                  _ProfileStat(
                    icon: Icons.star_rounded,
                    value: '${user?.points ?? 0}',
                    label: 'Points',
                  ),
                  _ProfileStat(
                    icon: Icons.local_fire_department_rounded,
                    value: '${user?.currentStreak ?? 0} Days',
                    label: 'Streak',
                  ),
                  _ProfileStat(
                    icon: Icons.menu_book_rounded,
                    value: '${summary.completedStories}',
                    label: 'Completed Stories',
                  ),
                  _ProfileStat(
                    icon: Icons.emoji_events_rounded,
                    value: '${user?.highestStreak ?? 0} Days',
                    label: 'Highest Streak',
                  ),
                ],
              ),
              const SizedBox(height: 24),
              _GlassPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionTitle(title: 'Badges', action: ''),
                    const SizedBox(height: 14),
                    if (badges.isEmpty)
                      const Text(
                        'No badges earned yet.',
                        style: TextStyle(color: AppColors.mutedBrown),
                      )
                    else
                      Wrap(
                        spacing: 14,
                        runSpacing: 14,
                        children: badges
                            .map((badge) => _Badge(label: badge.name))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CardPreview extends StatelessWidget {
  const _CardPreview({
    required this.title,
    required this.color,
    required this.icon,
  });

  final String title;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, AppColors.brown],
        ),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: .22),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.centerRight,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: .2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white24),
              ),
              child: const Icon(
                Icons.lock_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const Spacer(),
          Icon(icon, color: AppColors.gold, size: 36),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              height: 1.12,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coming soon',
            style: TextStyle(
              color: Colors.white.withValues(alpha: .72),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Keypad extends StatelessWidget {
  const _Keypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  @override
  Widget build(BuildContext context) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '', '0', 'back'];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: keys.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: 12,
          crossAxisSpacing: 20,
          childAspectRatio: 1.45,
        ),
        itemBuilder: (context, index) {
          final key = keys[index];
          if (key.isEmpty) return const SizedBox.shrink();
          final isBackspace = key == 'back';
          return InkWell(
            onTap: isBackspace ? onBackspace : () => onDigit(key),
            borderRadius: BorderRadius.circular(20),
            child: Center(
              child: isBackspace
                  ? const Icon(Icons.backspace_outlined, color: AppColors.brown)
                  : Text(
                      key,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: AppColors.brown,
                      ),
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _AmbientBackdrop extends StatelessWidget {
  const _AmbientBackdrop();

  @override
  Widget build(BuildContext context) {
    return const Positioned.fill(
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7E6), Color(0xFFFFFBF2), Color(0xFFFFE7C7)],
          ),
        ),
      ),
    );
  }
}

class _HomeTopBar extends StatelessWidget {
  const _HomeTopBar({required this.user, required this.displayName});

  final AppUser? user;
  final String displayName;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: const LinearGradient(
              colors: [AppColors.saffron, AppColors.maroon],
            ),
            boxShadow: _softShadow,
          ),
          child: const Icon(
            Icons.local_fire_department_rounded,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Namaskaram',
                style: TextStyle(
                  color: AppColors.mutedBrown,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                displayName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
        ),
        _MetricPill(
          icon: Icons.stars_rounded,
          label: '${user?.points ?? 0}',
          color: AppColors.gold,
        ),
        const SizedBox(width: 8),
        _MetricPill(
          icon: Icons.local_fire_department_rounded,
          label: '${user?.currentStreak ?? 0}',
          color: AppColors.lotus,
        ),
      ],
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({
    required this.story,
    required this.progress,
    required this.onStart,
  });

  final Story story;
  final double progress;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: Hero(
        tag: 'story-cover-${story.id}',
        child: AspectRatio(
          aspectRatio: .78,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: Stack(
              fit: StackFit.expand,
              children: [
                KathaNetworkImage(url: story.coverImageUrl),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0xEE000000)],
                    ),
                  ),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: Alignment.topRight,
                      radius: 1.2,
                      colors: [Color(0x55F5C542), Colors.transparent],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(22),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          _DarkPill(label: story.categoryName),
                          const Spacer(),
                          _DarkPill(label: '${story.days.length} days'),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        story.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          height: 1.15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      if (story.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          story.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            height: 1.45,
                          ),
                        ),
                      ],
                      const SizedBox(height: 18),
                      LinearProgressIndicator(
                        value: progress,
                        minHeight: 5,
                        borderRadius: BorderRadius.circular(999),
                        color: AppColors.gold,
                        backgroundColor: Colors.white.withValues(alpha: .28),
                      ),
                      const SizedBox(height: 14),
                      FilledButton.icon(
                        onPressed: onStart,
                        icon: const Icon(Icons.play_circle_fill_rounded),
                        label: const Text('Start Today'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _JourneyMiniCard extends StatelessWidget {
  const _JourneyMiniCard({
    required this.story,
    required this.progress,
    required this.onTap,
  });

  final Story story;
  final double progress;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(26),
      child: Container(
        width: 260,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: AppColors.border.withValues(alpha: .5)),
          boxShadow: _softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned.fill(
                child: KathaNetworkImage(url: story.coverImageUrl),
              ),
              const Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x11000000), Color(0xDD2B1A12)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _DarkPill(label: story.categoryName),
                    const Spacer(),
                    Text(
                      story.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        height: 1.15,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 5,
                      color: AppColors.gold,
                      backgroundColor: Colors.white.withValues(alpha: .28),
                      borderRadius: BorderRadius.circular(99),
                    ),
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

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({required this.story, required this.onTap});

  final Story story;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(24),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border.withValues(alpha: .45)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                width: 78,
                height: 86,
                child: Hero(
                  tag: 'story-cover-${story.id}',
                  child: KathaNetworkImage(url: story.coverImageUrl),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    story.categoryName,
                    style: const TextStyle(
                      color: AppColors.peacock,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    story.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${story.days.length} published days',
                    style: const TextStyle(color: AppColors.mutedBrown),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 16),
          ],
        ),
      ),
    );
  }
}

class _GlassPanel extends StatelessWidget {
  const _GlassPanel({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .76),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppColors.border.withValues(alpha: .42)),
        boxShadow: _softShadow,
      ),
      child: child,
    );
  }
}

class _DayTimelineTile extends StatelessWidget {
  const _DayTimelineTile({
    required this.day,
    required this.completed,
    required this.current,
    this.onTap,
  });

  final StoryDaySummary day;
  final bool completed;
  final bool current;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = completed
        ? AppColors.success
        : current
        ? AppColors.saffron
        : AppColors.mutedBrown;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: current
            ? const Color(0xFFFFF2DD)
            : Colors.white.withValues(alpha: .9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: current
              ? AppColors.saffron.withValues(alpha: .42)
              : AppColors.border.withValues(alpha: .38),
        ),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 10,
        ),
        leading: Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: .14),
          ),
          child: Icon(
            completed
                ? Icons.check_circle_rounded
                : current
                ? Icons.play_arrow_rounded
                : Icons.lock_rounded,
            color: accent,
          ),
        ),
        title: Text(
          'Day ${day.dayNumber}',
          style: TextStyle(color: accent, fontWeight: FontWeight.w900),
        ),
        subtitle: Text(day.title.isEmpty ? 'Daily Katha' : day.title),
        trailing: current
            ? const Chip(label: Text('Current'))
            : completed
            ? const Icon(Icons.done_all_rounded, color: AppColors.success)
            : null,
      ),
    );
  }
}

class _PhotoProgress extends StatelessWidget {
  const _PhotoProgress({required this.count, required this.activeIndex});

  final int count;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(count, (index) {
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 4,
            margin: EdgeInsets.only(right: index == count - 1 ? 0 : 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: index <= activeIndex
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.34),
            ),
          ),
        );
      }),
    );
  }
}

class _SmallNextButton extends StatelessWidget {
  const _SmallNextButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.saffron.withValues(alpha: .94),
      borderRadius: BorderRadius.circular(999),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: .26),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({
    required this.icon,
    required this.value,
    required this.label,
  });

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.saffron, size: 32),
            const SizedBox(height: 12),
            Text(
              value,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.mutedBrown,
              ),
            ),
            const SizedBox(height: 4),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.mutedBrown,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const CircleAvatar(
          radius: 28,
          backgroundColor: Color(0xFFFFE7B3),
          child: Icon(
            Icons.workspace_premium_rounded,
            color: AppColors.deepSaffron,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: 82,
          child: Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({
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
        color: color.withValues(alpha: .16),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
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

class _RoundIconButton extends StatelessWidget {
  const _RoundIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .38),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, required this.action});

  final String title;
  final String action;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(title, style: Theme.of(context).textTheme.titleLarge),
        ),
        if (action.isNotEmpty)
          Text(
            action,
            style: const TextStyle(
              color: AppColors.deepSaffron,
              fontWeight: FontWeight.w900,
            ),
          ),
      ],
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .38),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w900,
          fontSize: 12,
        ),
      ),
    );
  }
}

StoryDaySummary? _firstIncompleteDay(Story story, Set<String> completedIds) {
  for (final day in story.days) {
    if (!completedIds.contains(day.id)) return day;
  }
  return story.days.isEmpty ? null : story.days.last;
}

double _storyProgressFraction(Story story, UserProgress progress) {
  if (story.days.isEmpty) return 0;
  final completedCount = progress.kathaProgress
      .where((item) => item.storyId == story.id && item.completed)
      .length;
  return (completedCount / story.days.length).clamp(0, 1);
}

final _softShadow = [
  BoxShadow(
    color: AppColors.saffron.withValues(alpha: .12),
    blurRadius: 28,
    offset: const Offset(0, 12),
  ),
];
