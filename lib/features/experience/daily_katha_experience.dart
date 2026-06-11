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
  bool _onboarded = true;
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
      MaterialPageRoute<void>(
        builder: (_) => StoryJourneyScreen(
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
      MaterialPageRoute<void>(
        builder: (_) => StoryReaderScreen(
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
      MaterialPageRoute<void>(
        builder: (_) => ProfileSettingsScreen(
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
      _newUserName = null;
    });
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

    if (!_onboarded) {
      return OnboardingScreen(
        onContinue: () => setState(() => _onboarded = true),
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
            gradient: RadialGradient(
              center: Alignment.topCenter,
              radius: 1.1,
              colors: [Color(0xFFFFE7B3), AppColors.ivory],
            ),
          ),
          child: const SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AppLogo(size: 168),
                  SizedBox(height: 28),
                  Text(
                    'Daily Katha',
                    style: TextStyle(
                      color: AppColors.deepSaffron,
                      fontSize: 38,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Tap to continue',
                    style: TextStyle(
                      color: AppColors.mutedBrown,
                      fontWeight: FontWeight.w800,
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
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 40),
            const AppLogo(size: 82),
            const SizedBox(height: 26),
            Text('Welcome', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 8),
            const Text(
              'Enter your mobile number to start your journey',
              style: TextStyle(color: AppColors.mutedBrown),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: _softShadow,
                ),
                child: Row(
                  children: [
                    const Text(
                      '+91',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(width: 1, height: 32, color: AppColors.border),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        formatted,
                        style: TextStyle(
                          color: _number.isEmpty
                              ? AppColors.border
                              : AppColors.brown,
                          fontSize: 22,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: FilledButton(
                onPressed: ready && !widget.checking
                    ? () => widget.onOtpRequested(_number)
                    : null,
                child: Text(widget.checking ? 'Checking...' : 'Get OTP'),
              ),
            ),
            if (widget.error != null) ...[
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Text(
                  widget.error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.error,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
            const SizedBox(height: 16),
            _Keypad(
              onDigit: _append,
              onBackspace: () {
                if (_number.isNotEmpty) {
                  setState(
                    () => _number = _number.substring(0, _number.length - 1),
                  );
                }
              },
            ),
            const SizedBox(height: 18),
          ],
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
      appBar: AppBar(
        leading: IconButton(
          onPressed: widget.onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 28),
            const AppLogo(size: 86),
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
            const SizedBox(height: 34),
            TextField(
              controller: _nameController,
              textInputAction: TextInputAction.done,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
                prefixIcon: Icon(Icons.person_rounded),
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) {
                if (name.isNotEmpty) widget.onContinue(name);
              },
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
              onPressed: name.isEmpty ? null : () => widget.onContinue(name),
              icon: const Icon(Icons.arrow_forward_rounded),
              label: const Text('Continue to OTP'),
            ),
          ],
        ),
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Spacer(),
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
              const SizedBox(height: 34),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final filled = index < _otp.length;
                  return Container(
                    width: 58,
                    height: 68,
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: filled ? AppColors.saffron : AppColors.border,
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
                    setState(() => _otp = _otp.substring(0, _otp.length - 1));
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key, required this.onContinue});

  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Spacer(),
              const AppLogo(size: 92),
              const SizedBox(height: 22),
              Text(
                'Daily Katha is ready',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your stories and progress will come from the backend.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedBrown),
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: onContinue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
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
      body: RefreshIndicator(
        onRefresh: () async => onRetry(),
        child: pages[tabIndex],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tabIndex,
        onDestinationSelected: onTabChanged,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFFFFE7B3),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_rounded), label: 'Home'),
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 110),
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: Color(0xFFFFE7B3),
                child: Icon(Icons.person_rounded, color: AppColors.deepSaffron),
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
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      displayName,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: AppColors.deepSaffron,
                      ),
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
                color: AppColors.saffron,
              ),
            ],
          ),
          const SizedBox(height: 26),
          Text(
            'Today Story',
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.deepSaffron),
          ),
          const SizedBox(height: 14),
          if (firstStory == null)
            const EmptyState(
              icon: Icons.auto_stories_rounded,
              title: 'No stories published yet',
              message: 'Stories added from the CMS will appear here.',
            )
          else
            _TodayHero(story: firstStory, onStart: onStartToday),
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
              height: 142,
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
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemCount: stories.length,
              ),
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text('Kathalu', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          const Text(
            'Story worlds from your CMS',
            style: TextStyle(color: AppColors.mutedBrown, fontSize: 16),
          ),
          const SizedBox(height: 24),
          if (stories.isEmpty)
            const EmptyState(
              icon: Icons.auto_stories_rounded,
              title: 'No published kathalu',
              message: 'Publish stories and days in the CMS to show them here.',
            )
          else
            for (final entry in grouped.entries) ...[
              _SectionTitle(title: entry.key, action: ''),
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
      appBar: AppBar(title: Text(story.title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 110),
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    KathaNetworkImage(url: story.coverImageUrl),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC2B1A12)],
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
                          fontSize: 24,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Transform.translate(
              offset: const Offset(0, -22),
              child: Card(
                child: Padding(
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
                    onTap: completed || current ? () => onStartDay(day) : null,
                  ),
                );
              }),
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
      MaterialPageRoute<void>(
        builder: (_) => CompletionRewardScreen(day: widget.day, result: null),
      ),
    );
  }

  Future<void> _openQuiz(DayDetail detail) async {
    final existingReview = await widget.userApi.fetchLatestQuizReview(
      detail.day.id,
    );
    if (!mounted) return;

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => existingReview == null
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

class CompletionRewardScreen extends StatelessWidget {
  const CompletionRewardScreen({
    super.key,
    required this.day,
    required this.result,
  });

  final StoryDaySummary day;
  final QuizAttemptResult? result;

  @override
  Widget build(BuildContext context) {
    final quizText = result == null
        ? 'No quiz'
        : '${result!.correctCount} / ${result!.totalQuestions}';
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            children: [
              const Spacer(),
              const Icon(
                Icons.workspace_premium_rounded,
                size: 92,
                color: AppColors.saffron,
              ),
              const SizedBox(height: 18),
              Text(
                'Day ${day.dayNumber} Completed',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 10),
              const Text(
                'Your progress is saved in the database.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.mutedBrown),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: _RewardTile(
                      icon: Icons.quiz_rounded,
                      title: quizText,
                      label: 'Quiz Score',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RewardTile(
                      icon: Icons.stars_rounded,
                      title: '+${result?.pointsAdded ?? 0}',
                      label: 'Quiz Points',
                    ),
                  ),
                ],
              ),
              const Spacer(),
              FilledButton.icon(
                onPressed: () =>
                    Navigator.of(context).popUntil((route) => route.isFirst),
                icon: const Icon(Icons.home_rounded),
                label: const Text('Back Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(
      bottom: false,
      child: EmptyState(
        icon: Icons.style_rounded,
        title: 'Cards coming later',
        message: 'This screen is not part of the current dynamic pass.',
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
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
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
          const CircleAvatar(
            radius: 54,
            backgroundColor: Color(0xFFFFE7B3),
            child: Icon(
              Icons.person_rounded,
              color: AppColors.deepSaffron,
              size: 60,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            displayName,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.headlineMedium?.copyWith(color: AppColors.deepSaffron),
          ),
          const SizedBox(height: 26),
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
          _SectionTitle(title: 'Badges', action: ''),
          const SizedBox(height: 12),
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
          mainAxisExtent: 58,
          crossAxisSpacing: 14,
          mainAxisSpacing: 6,
        ),
        itemBuilder: (context, index) {
          final key = keys[index];
          if (key.isEmpty) return const SizedBox.shrink();
          return TextButton(
            onPressed: key == 'back' ? onBackspace : () => onDigit(key),
            child: key == 'back'
                ? const Icon(
                    Icons.backspace_outlined,
                    color: AppColors.mutedBrown,
                  )
                : Text(
                    key,
                    style: const TextStyle(
                      fontSize: 28,
                      color: AppColors.brown,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
          );
        },
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.story, required this.onStart});

  final Story story;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: AspectRatio(
        aspectRatio: .82,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
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
              Padding(
                padding: const EdgeInsets.all(22),
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
                    FilledButton.icon(
                      onPressed: onStart,
                      icon: const Icon(Icons.play_circle_fill_rounded),
                      label: const Text('Start Story'),
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
      borderRadius: BorderRadius.circular(22),
      child: Container(
        width: 248,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border.withValues(alpha: .5)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              story.categoryName,
              style: const TextStyle(
                color: AppColors.deepSaffron,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              story.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const Spacer(),
            LinearProgressIndicator(
              value: progress,
              color: AppColors.deepSaffron,
              backgroundColor: const Color(0xFFFFE7C7),
              borderRadius: BorderRadius.circular(99),
            ),
          ],
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
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SizedBox(
            width: 58,
            height: 58,
            child: KathaNetworkImage(url: story.coverImageUrl),
          ),
        ),
        title: Text(
          story.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w900),
        ),
        subtitle: Text('${story.days.length} published days'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
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
    return Card(
      color: current ? const Color(0xFFFFF1E6) : Colors.white,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: current
              ? AppColors.saffron
              : const Color(0xFFFFE7B3),
          foregroundColor: current ? Colors.white : AppColors.deepSaffron,
          child: Icon(
            completed
                ? Icons.check_circle_rounded
                : current
                ? Icons.play_arrow_rounded
                : Icons.lock_rounded,
          ),
        ),
        title: Text(
          'Day ${day.dayNumber}',
          style: const TextStyle(
            color: AppColors.deepSaffron,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(day.title.isEmpty ? 'Daily Katha' : day.title),
        trailing: current ? const Chip(label: Text('Current')) : null,
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

class _RewardTile extends StatelessWidget {
  const _RewardTile({
    required this.icon,
    required this.title,
    required this.label,
  });

  final IconData icon;
  final String title;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Icon(icon, color: AppColors.saffron, size: 30),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedBrown,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
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
