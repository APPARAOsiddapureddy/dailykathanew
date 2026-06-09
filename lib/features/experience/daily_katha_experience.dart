import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/widgets/app_logo.dart';

class DailyKathaExperience extends StatefulWidget {
  const DailyKathaExperience({super.key});

  @override
  State<DailyKathaExperience> createState() => _DailyKathaExperienceState();
}

class _DailyKathaExperienceState extends State<DailyKathaExperience> {
  bool _showSplash = true;
  bool _isLoggedIn = false;
  bool _otpRequested = false;
  bool _onboarded = false;
  int _tabIndex = 0;
  int _points = 50;
  int _streak = 5;
  final Set<String> _interests = {'మహాభారతం', 'శ్రీకృష్ణ కథలు'};
  final Set<int> _completedDays = {1, 2, 3, 4};
  bool _cardUnlocked = true;

  void _finishAuth() {
    setState(() {
      _isLoggedIn = true;
      _otpRequested = false;
    });
  }

  void _finishOnboarding() {
    setState(() => _onboarded = true);
  }

  void _completeDay(int score, int total) {
    setState(() {
      _completedDays.add(5);
      _points += 10 + (score == total ? 5 : 0);
      _streak = 6;
      _cardUnlocked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_showSplash) {
      return SplashScreen(
        onContinue: () => setState(() => _showSplash = false),
      );
    }
    if (!_isLoggedIn) {
      return _otpRequested
          ? OtpScreen(
              onVerified: _finishAuth,
              onChangeNumber: () => setState(() => _otpRequested = false),
            )
          : LoginScreen(
              onOtpRequested: () => setState(() => _otpRequested = true),
            );
    }
    if (!_onboarded) {
      return OnboardingScreen(
        selected: _interests,
        onToggle: (interest) {
          setState(() {
            if (_interests.contains(interest)) {
              _interests.remove(interest);
            } else {
              _interests.add(interest);
            }
          });
        },
        onContinue: _finishOnboarding,
      );
    }

    return MainShell(
      tabIndex: _tabIndex,
      onTabChanged: (index) => setState(() => _tabIndex = index),
      points: _points,
      streak: _streak,
      completedDays: _completedDays,
      cardUnlocked: _cardUnlocked,
      onStartToday: () => _openStoryDetail(context),
      onOpenReader: () => _openReader(context),
    );
  }

  void _openStoryDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryJourneyScreen(
          completedDays: _completedDays,
          onStart: () {
            Navigator.of(context).pop();
            _openReader(context);
          },
        ),
      ),
    );
  }

  void _openReader(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StoryReaderScreen(
          onComplete: () {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute<void>(
                builder: (_) => QuizFlowScreen(
                  onComplete: (score, total) {
                    _completeDay(score, total);
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute<void>(
                        builder: (_) => CompletionRewardScreen(
                          score: score,
                          total: total,
                          points: _points + 10 + (score == total ? 5 : 0),
                          streak: 6,
                          onUnlockCard: () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute<void>(
                                builder: (_) => const ShareCardScreen(),
                              ),
                            );
                          },
                          onHome: () => Navigator.of(
                            context,
                          ).popUntil((route) => route.isFirst),
                        ),
                      ),
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
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
          child: SafeArea(
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const AppLogo(size: 184),
                    const SizedBox(height: 34),
                    Text(
                      'Daily Katha',
                      style: Theme.of(context).textTheme.displaySmall?.copyWith(
                        color: AppColors.deepSaffron,
                        fontSize: 38,
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'ప్రతి రోజు ఒక కథ, ఒక మంచి పాఠం',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.mutedBrown,
                        fontSize: 19,
                        height: 1.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 54),
                    const _ProgressLine(),
                    const SizedBox(height: 16),
                    const Text(
                      'Tap to continue',
                      style: TextStyle(
                        color: AppColors.deepSaffron,
                        fontWeight: FontWeight.w800,
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

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.onOtpRequested});

  final VoidCallback onOtpRequested;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  String _number = '';

  void _append(String value) {
    if (_number.length >= 10) return;
    setState(() => _number += value);
    if (_number.length == 10) {
      Future<void>.delayed(
        const Duration(milliseconds: 180),
        widget.onOtpRequested,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatted = _number.isEmpty
        ? '00000 00000'
        : '${_number.substring(0, _number.length > 5 ? 5 : _number.length)}${_number.length > 5 ? ' ${_number.substring(5)}' : ''}';
    final ready = _number.length == 10;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 34),
            const AppLogo(size: 76),
            const SizedBox(height: 24),
            Text(
              'Daily Katha లోకి స్వాగతం',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'మీ రోజువారీ కథ ప్రయాణాన్ని ప్రారంభించండి',
              style: TextStyle(
                color: AppColors.mutedBrown,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 40),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.deepSaffron.withValues(alpha: 0.45),
                    width: 2,
                  ),
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
                onPressed: ready ? widget.onOtpRequested : null,
                child: const Text('OTP పొందండి'),
              ),
            ),
            const SizedBox(height: 10),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_rounded, size: 17, color: AppColors.mutedBrown),
                SizedBox(width: 6),
                Text(
                  'మీ నంబర్ సురక్షితంగా ఉంటుంది',
                  style: TextStyle(color: AppColors.mutedBrown),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _Keypad(
              onDigit: _append,
              onBackspace: () {
                if (_number.isNotEmpty)
                  setState(
                    () => _number = _number.substring(0, _number.length - 1),
                  );
              },
            ),
            const SizedBox(height: 18),
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
  });

  final VoidCallback onVerified;
  final VoidCallback onChangeNumber;

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
      Future<void>.delayed(
        const Duration(milliseconds: 700),
        widget.onVerified,
      );
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
                'OTP నమోదు చేయండి',
                style: Theme.of(context).textTheme.displaySmall?.copyWith(
                  color: AppColors.deepSaffron,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'మీ మొబైల్ నంబర్‌కు పంపిన 4 అంకెల OTP ని నమోదు చేయండి',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.mutedBrown,
                  fontSize: 16,
                  height: 1.5,
                ),
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
                const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2.4),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'ధృవీకరిస్తున్నాము...',
                      style: TextStyle(
                        color: AppColors.deepSaffron,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                )
              else
                TextButton(
                  onPressed: widget.onChangeNumber,
                  child: const Text('మొబైల్ నంబర్ మార్చండి'),
                ),
              const Spacer(),
              _Keypad(
                onDigit: _append,
                onBackspace: () {
                  if (_otp.isNotEmpty && !_verifying)
                    setState(() => _otp = _otp.substring(0, _otp.length - 1));
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
  const OnboardingScreen({
    super.key,
    required this.selected,
    required this.onToggle,
    required this.onContinue,
  });

  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback onContinue;

  static const interests = [
    ('మహాభారతం', Icons.history_edu_rounded),
    ('రామాయణం', Icons.menu_book_rounded),
    ('శ్రీకృష్ణ కథలు', Icons.music_note_rounded),
    ('శివ కథలు', Icons.brightness_high_rounded),
    ('ఆలయ కథలు', Icons.account_balance_rounded),
    ('పండుగ కథలు', Icons.celebration_rounded),
    ('పిల్లల కథలు', Icons.child_care_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 30),
            const AppLogo(size: 70),
            const SizedBox(height: 22),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22),
              child: Column(
                children: [
                  Text(
                    'మీకు ఏ కథలు ఇష్టం?',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'మీకు నచ్చిన కథలను ఎంచుకోండి. మేము వాటిని మీ కోసం సిద్ధం చేస్తాము.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.mutedBrown,
                      height: 1.5,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 1.12,
                ),
                itemCount: interests.length,
                itemBuilder: (context, index) {
                  final (title, icon) = interests[index];
                  final isSelected = selected.contains(title);
                  return _InterestTile(
                    title: title,
                    icon: icon,
                    selected: isSelected,
                    onTap: () => onToggle(title),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 0, 22, 22),
              child: FilledButton.icon(
                onPressed: selected.isEmpty ? null : onContinue,
                icon: const Icon(Icons.arrow_forward_rounded),
                label: const Text('నా Daily Katha ప్రారంభించండి'),
              ),
            ),
          ],
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
    required this.points,
    required this.streak,
    required this.completedDays,
    required this.cardUnlocked,
    required this.onStartToday,
    required this.onOpenReader,
  });

  final int tabIndex;
  final ValueChanged<int> onTabChanged;
  final int points;
  final int streak;
  final Set<int> completedDays;
  final bool cardUnlocked;
  final VoidCallback onStartToday;
  final VoidCallback onOpenReader;

  @override
  Widget build(BuildContext context) {
    final pages = [
      HomeScreen(
        points: points,
        streak: streak,
        onStartToday: onStartToday,
        onOpenReader: onOpenReader,
      ),
      LibraryScreen(onOpenJourney: onStartToday),
      CardsScreen(cardUnlocked: cardUnlocked),
      ProfileScreen(
        points: points,
        streak: streak,
        completedDays: completedDays.length,
      ),
    ];
    return Scaffold(
      body: pages[tabIndex],
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
    required this.points,
    required this.streak,
    required this.onStartToday,
    required this.onOpenReader,
  });

  final int points;
  final int streak;
  final VoidCallback onStartToday;
  final VoidCallback onOpenReader;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        backgroundColor: Color(0xFFFFE7B3),
                        child: Icon(
                          Icons.account_circle_rounded,
                          color: AppColors.deepSaffron,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'నమస్కారం',
                              style: TextStyle(
                                color: AppColors.mutedBrown,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            Text(
                              'Daily Katha',
                              style: Theme.of(context).textTheme.titleLarge
                                  ?.copyWith(color: AppColors.deepSaffron),
                            ),
                          ],
                        ),
                      ),
                      _MetricPill(
                        icon: Icons.monetization_on_rounded,
                        label: '$points',
                        color: AppColors.gold,
                      ),
                      const SizedBox(width: 8),
                      _MetricPill(
                        icon: Icons.local_fire_department_rounded,
                        label: '$streak',
                        color: AppColors.saffron,
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                  Text(
                    'ఈరోజు కథ',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.deepSaffron,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _TodayHero(onStart: onOpenReader),
                  const SizedBox(height: 30),
                  _SectionTitle(title: 'Continue Journey', action: 'View all'),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 138,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _JourneyMiniCard(
                          title: 'రామాయణం',
                          subtitle: 'అరణ్యకాండ',
                          progress: .60,
                          color: AppColors.deepSaffron,
                        ),
                        _JourneyMiniCard(
                          title: 'శివ పురాణం',
                          subtitle: 'Episode 4',
                          progress: .25,
                          color: AppColors.maroon,
                        ),
                        _JourneyMiniCard(
                          title: 'ఆలయ కథలు',
                          subtitle: 'తిరుపతి',
                          progress: .42,
                          color: AppColors.success,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  _SectionTitle(title: 'Story Worlds', action: 'Explore'),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: const [
                      _WorldChip(
                        label: 'మహాభారతం',
                        icon: Icons.history_edu_rounded,
                      ),
                      _WorldChip(
                        label: 'రామాయణం',
                        icon: Icons.menu_book_rounded,
                      ),
                      _WorldChip(
                        label: 'భాగవతం',
                        icon: Icons.music_note_rounded,
                      ),
                      _WorldChip(
                        label: 'ఆలయ కథలు',
                        icon: Icons.account_balance_rounded,
                      ),
                      _WorldChip(
                        label: 'పండుగలు',
                        icon: Icons.celebration_rounded,
                      ),
                      _WorldChip(
                        label: 'పిల్లల కథలు',
                        icon: Icons.child_care_rounded,
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  _MoralCard(),
                  const SizedBox(height: 28),
                  _SectionTitle(title: 'Unlocked Cards', action: 'Cards'),
                  const SizedBox(height: 12),
                  Row(
                    children: const [
                      Expanded(child: _SmallSharePreview(title: 'ధర్మమే జయం')),
                      SizedBox(width: 12),
                      Expanded(
                        child: _SmallSharePreview(title: 'కర్మే మార్గం'),
                      ),
                    ],
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

class StoryJourneyScreen extends StatelessWidget {
  const StoryJourneyScreen({
    super.key,
    required this.completedDays,
    required this.onStart,
  });

  final Set<int> completedDays;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mahabharatam 100 Days Journey')),
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
                    Image.asset(
                      'assets/mahabharatam-cover.png',
                      fit: BoxFit.cover,
                    ),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Color(0xCC2B1A12)],
                        ),
                      ),
                    ),
                    const Positioned(
                      left: 18,
                      right: 18,
                      bottom: 18,
                      child: Text(
                        'మహాభారతం 100 రోజుల ప్రయాణం',
                        style: TextStyle(
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
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Overall Progress',
                            style: TextStyle(
                              color: AppColors.deepSaffron,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            'Day 5 of 100',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      LinearProgressIndicator(
                        value: .05,
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
            ...List.generate(7, (index) {
              final day = index + 1;
              final completed = completedDays.contains(day);
              final current = day == 5;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _DayTimelineTile(
                  day: day,
                  title: _dayTitles[index],
                  completed: completed,
                  current: current,
                  locked: day > 5,
                  onTap: current ? onStart : null,
                ),
              );
            }),
          ],
        ),
      ),
      bottomSheet: Padding(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
        child: FilledButton.icon(
          onPressed: onStart,
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('సందేశాన్ని కొనసాగించండి'),
        ),
      ),
    );
  }
}

class StoryReaderScreen extends StatefulWidget {
  const StoryReaderScreen({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  State<StoryReaderScreen> createState() => _StoryReaderScreenState();
}

class _StoryReaderScreenState extends State<StoryReaderScreen> {
  final PageController _controller = PageController();
  int _index = 0;
  bool _paused = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final slide = _slides[_index];
    final finalSlide = _index == _slides.length - 1;

    return Scaffold(
      backgroundColor: AppColors.brown,
      body: Center(
        child: AspectRatio(
          aspectRatio: 9 / 16,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 430),
            child: Stack(
              children: [
                PageView.builder(
                  controller: _controller,
                  itemCount: _slides.length,
                  onPageChanged: (value) => setState(() => _index = value),
                  itemBuilder: (_, index) =>
                      _StoryVisual(slide: _slides[index]),
                ),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xAA000000),
                        Colors.transparent,
                        Color(0xDD000000),
                      ],
                      stops: [0, .44, 1],
                    ),
                  ),
                  child: SizedBox.expand(),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: List.generate(_slides.length, (index) {
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: EdgeInsets.only(
                                  right: index == _slides.length - 1 ? 0 : 5,
                                ),
                                decoration: BoxDecoration(
                                  color: index <= _index
                                      ? Colors.white
                                      : Colors.white38,
                                  borderRadius: BorderRadius.circular(99),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            _RoundIconButton(
                              icon: Icons.close_rounded,
                              onTap: () => Navigator.of(context).pop(),
                            ),
                            const Spacer(),
                            _RoundIconButton(
                              icon: _paused
                                  ? Icons.play_arrow_rounded
                                  : Icons.pause_rounded,
                              onTap: () => setState(() => _paused = !_paused),
                            ),
                            const SizedBox(width: 10),
                            _RoundIconButton(
                              icon: Icons.bookmark_border_rounded,
                              onTap: () {},
                            ),
                            const SizedBox(width: 10),
                            _RoundIconButton(
                              icon: Icons.share_rounded,
                              onTap: () {},
                            ),
                          ],
                        ),
                        const Spacer(),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppColors.ivory.withValues(alpha: .96),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                slide.title,
                                style: Theme.of(
                                  context,
                                ).textTheme.headlineMedium,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                slide.body,
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              const SizedBox(height: 16),
                              FilledButton.icon(
                                onPressed: () {
                                  if (finalSlide) {
                                    widget.onComplete();
                                  } else {
                                    _controller.nextPage(
                                      duration: const Duration(
                                        milliseconds: 250,
                                      ),
                                      curve: Curves.easeOut,
                                    );
                                  }
                                },
                                icon: Icon(
                                  finalSlide
                                      ? Icons.quiz_rounded
                                      : Icons.arrow_forward_rounded,
                                ),
                                label: Text(
                                  finalSlide
                                      ? 'Quiz ప్రారంభించండి'
                                      : 'తర్వాతి స్లైడ్',
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class QuizFlowScreen extends StatefulWidget {
  const QuizFlowScreen({super.key, required this.onComplete});

  final void Function(int score, int total) onComplete;

  @override
  State<QuizFlowScreen> createState() => _QuizFlowScreenState();
}

class _QuizFlowScreenState extends State<QuizFlowScreen> {
  int _index = 0;
  int _score = 0;
  int? _selected;

  @override
  Widget build(BuildContext context) {
    final question = _questions[_index];
    final answered = _selected != null;
    final correct = _selected == question.correctIndex;

    return Scaffold(
      appBar: AppBar(title: const Text('ఈరోజు Quiz')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Text(
                'Question ${_index + 1} of ${_questions.length}',
                style: const TextStyle(
                  color: AppColors.mutedBrown,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              LinearProgressIndicator(
                value: (_index + 1) / _questions.length,
                minHeight: 8,
                borderRadius: BorderRadius.circular(999),
                color: AppColors.gold,
                backgroundColor: const Color(0xFFFFE7C7),
              ),
              const SizedBox(height: 28),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    question.text,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Expanded(
                child: ListView.separated(
                  itemCount: question.options.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, optionIndex) {
                    return _QuizOptionTile(
                      label: String.fromCharCode(65 + optionIndex),
                      text: question.options[optionIndex],
                      selected: _selected == optionIndex,
                      answered: answered,
                      correct: optionIndex == question.correctIndex,
                      onTap: () {
                        if (answered) return;
                        setState(() {
                          _selected = optionIndex;
                          if (optionIndex == question.correctIndex) _score += 1;
                        });
                      },
                    );
                  },
                ),
              ),
              if (answered)
                Text(
                  correct ? 'సరైన సమాధానం' : 'తప్పు సమాధానం',
                  style: TextStyle(
                    color: correct ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              const SizedBox(height: 12),
              FilledButton(
                onPressed: !answered
                    ? null
                    : () {
                        if (_index == _questions.length - 1) {
                          widget.onComplete(_score, _questions.length);
                        } else {
                          setState(() {
                            _index += 1;
                            _selected = null;
                          });
                        }
                      },
                child: Text(
                  _index == _questions.length - 1
                      ? 'Quiz పూర్తి చేయండి'
                      : 'తర్వాతి ప్రశ్న',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CompletionRewardScreen extends StatelessWidget {
  const CompletionRewardScreen({
    super.key,
    required this.score,
    required this.total,
    required this.points,
    required this.streak,
    required this.onUnlockCard,
    required this.onHome,
  });

  final int score;
  final int total;
  final int points;
  final int streak;
  final VoidCallback onUnlockCard;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final earned = 10 + (score == total ? 5 : 0);
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            const SizedBox(height: 30),
            const Icon(
              Icons.workspace_premium_rounded,
              size: 90,
              color: AppColors.saffron,
            ),
            const SizedBox(height: 18),
            Text(
              'Day 5 పూర్తి చేశారు',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: AppColors.deepSaffron),
            ),
            const SizedBox(height: 8),
            const Text(
              'అద్భుతం! మీరు విజయవంతంగా కథను పూర్తి చేశారు.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedBrown, fontSize: 16),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: _RewardTile(
                    icon: Icons.stars_rounded,
                    title: '+$earned Points',
                    label: 'సంపాదించారు',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RewardTile(
                    icon: Icons.local_fire_department_rounded,
                    title: '$streak Days',
                    label: 'Streak',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _RewardTile(
                    icon: Icons.quiz_rounded,
                    title: '$score / $total',
                    label: 'Quiz Score',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _RewardTile(
                    icon: Icons.savings_rounded,
                    title: '$points',
                    label: 'Total Points',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 26),
            const _UnlockedRewardPreview(),
            const SizedBox(height: 18),
            const _TomorrowTeaser(),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onUnlockCard,
              icon: const Icon(Icons.lock_open_rounded),
              label: const Text('Card Unlock చేయండి'),
            ),
            const SizedBox(height: 10),
            TextButton(onPressed: onHome, child: const Text('Go to Home')),
          ],
        ),
      ),
    );
  }
}

class ShareCardScreen extends StatelessWidget {
  const ShareCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Card Unlocked'),
        leading: IconButton(
          onPressed: () =>
              Navigator.of(context).popUntil((route) => route.isFirst),
          icon: const Icon(Icons.close_rounded),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(22),
          children: [
            Text(
              'Card Unlocked!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Share today’s wisdom with your family and friends.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedBrown),
            ),
            const SizedBox(height: 24),
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(26),
                  boxShadow: _softShadow,
                  image: const DecorationImage(
                    image: AssetImage('assets/mahabharatam-cover.png'),
                    fit: BoxFit.cover,
                  ),
                ),
                child: Container(
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(26),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x33000000), Color(0xAA000000)],
                    ),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BrandBadge(),
                      Spacer(),
                      Center(
                        child: Text(
                          'ధర్మమే జయం',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_rounded),
              label: const Text('Save to Gallery'),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _SocialButton(
                    label: 'WhatsApp',
                    icon: Icons.chat_rounded,
                    color: const Color(0xFF128C7E),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _SocialButton(
                    label: 'Insta Story',
                    icon: Icons.photo_camera_rounded,
                    color: const Color(0xFFBC1888),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.share_rounded),
              label: const Text('More Options'),
            ),
          ],
        ),
      ),
    );
  }
}

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({super.key, required this.onOpenJourney});

  final VoidCallback onOpenJourney;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text('Kathalu', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          const Text(
            'అన్ని story worlds ఒకే చోట',
            style: TextStyle(color: AppColors.mutedBrown, fontSize: 16),
          ),
          const SizedBox(height: 24),
          for (final section in _librarySections) ...[
            _SectionTitle(title: section.$1, action: ''),
            const SizedBox(height: 12),
            ...section.$2.map(
              (title) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _LibraryRow(title: title, onTap: onOpenJourney),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class CardsScreen extends StatelessWidget {
  const CardsScreen({super.key, required this.cardUnlocked});

  final bool cardUnlocked;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
        children: [
          Text('Cards', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 8),
          const Text(
            'మీరు unlock చేసిన devotional share cards',
            style: TextStyle(color: AppColors.mutedBrown),
          ),
          const SizedBox(height: 22),
          GridView.builder(
            itemCount: 6,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: .76,
            ),
            itemBuilder: (context, index) =>
                _SavedCardPreview(locked: index > 1 && !cardUnlocked),
          ),
        ],
      ),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({
    super.key,
    required this.points,
    required this.streak,
    required this.completedDays,
  });

  final int points;
  final int streak;
  final int completedDays;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 110),
        children: [
          Text(
            'మీ ప్రొఫైల్',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.displaySmall,
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
            'Srinivas',
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
            childAspectRatio: 1.12,
            children: [
              _ProfileStat(
                icon: Icons.star_rounded,
                value: '$points',
                label: 'Points',
              ),
              _ProfileStat(
                icon: Icons.local_fire_department_rounded,
                value: '$streak Days',
                label: 'Streak',
              ),
              _ProfileStat(
                icon: Icons.menu_book_rounded,
                value: '$completedDays',
                label: 'Completed Stories',
              ),
              const _ProfileStat(
                icon: Icons.track_changes_rounded,
                value: '85%',
                label: 'Accuracy',
              ),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Badges', action: ''),
          const SizedBox(height: 12),
          const Row(
            children: [
              _Badge(label: 'Early Bird', active: true),
              SizedBox(width: 14),
              _Badge(label: 'Scholar', active: false),
              SizedBox(width: 14),
              _Badge(label: 'Wise', active: false),
            ],
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Reminder Settings', action: ''),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(
                Icons.notifications_rounded,
                color: AppColors.deepSaffron,
              ),
              title: const Text('Daily Katha Time'),
              subtitle: const Text('06:30 AM'),
              trailing: Switch(value: true, onChanged: (_) {}),
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

class _InterestTile extends StatelessWidget {
  const _InterestTile({
    required this.title,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFFFE7C7) : Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? AppColors.saffron : AppColors.border,
            ),
            boxShadow: selected ? _softShadow : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Align(
                alignment: Alignment.topRight,
                child: Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  color: selected ? AppColors.deepSaffron : AppColors.border,
                  size: 20,
                ),
              ),
              const Spacer(),
              Icon(icon, color: AppColors.deepSaffron, size: 36),
              const SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}

class _TodayHero extends StatelessWidget {
  const _TodayHero({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onStart,
      child: AspectRatio(
        aspectRatio: .82,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            boxShadow: _softShadow,
            image: const DecorationImage(
              image: AssetImage('assets/mahabharatam-cover.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x33000000), Color(0xEE000000)],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: const [
                    _DarkPill(label: 'మహాభారతం'),
                    SizedBox(width: 8),
                    _DarkPill(
                      label: '5 నిమిషాలు',
                      icon: Icons.schedule_rounded,
                    ),
                  ],
                ),
                const Spacer(),
                const Text(
                  'కురుక్షేత్రం - Day 5',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'యుద్ధభూమిలో అర్జునుడి విషాదం, కృష్ణుడి గీతోపదేశం ప్రారంభం...',
                  style: TextStyle(
                    color: Colors.white70,
                    height: 1.45,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onStart,
                  icon: const Icon(Icons.play_circle_fill_rounded),
                  label: const Text('కథ ప్రారంభించండి'),
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
    required this.title,
    required this.subtitle,
    required this.progress,
    required this.color,
  });

  final String title;
  final String subtitle;
  final double progress;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 248,
      margin: const EdgeInsets.only(right: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border.withValues(alpha: .5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(Icons.menu_book_rounded, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),
          LinearProgressIndicator(
            value: progress,
            color: color,
            backgroundColor: const Color(0xFFFFE7C7),
            borderRadius: BorderRadius.circular(99),
          ),
        ],
      ),
    );
  }
}

class _MoralCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFEFD2),
        borderRadius: BorderRadius.circular(22),
        border: const Border(left: BorderSide(color: AppColors.gold, width: 5)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.format_quote_rounded, color: AppColors.deepSaffron),
              SizedBox(width: 8),
              Text(
                'నేటి సూక్తి',
                style: TextStyle(
                  color: AppColors.mutedBrown,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            '"కర్మణ్యేవాధికారస్తే మా ఫలేషు కదాచన"',
            style: TextStyle(
              fontSize: 20,
              height: 1.4,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'కర్మ చేయడంలోనే నీకు అధికారం ఉంది, ఫలితంపై కాదు.',
            style: TextStyle(color: AppColors.mutedBrown, height: 1.45),
          ),
        ],
      ),
    );
  }
}

class _StoryVisual extends StatelessWidget {
  const _StoryVisual({required this.slide});

  final _Slide slide;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset('assets/mahabharatam-cover.png', fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: slide.alignment,
              radius: .95,
              colors: [slide.color.withValues(alpha: .44), Colors.transparent],
            ),
          ),
        ),
      ],
    );
  }
}

class _DayTimelineTile extends StatelessWidget {
  const _DayTimelineTile({
    required this.day,
    required this.title,
    required this.completed,
    required this.current,
    required this.locked,
    this.onTap,
  });

  final int day;
  final String title;
  final bool completed;
  final bool current;
  final bool locked;
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
                : locked
                ? Icons.lock_rounded
                : Icons.play_arrow_rounded,
          ),
        ),
        title: Text(
          'Day $day',
          style: const TextStyle(
            color: AppColors.deepSaffron,
            fontWeight: FontWeight.w900,
          ),
        ),
        subtitle: Text(title),
        trailing: current ? const Chip(label: Text('Current')) : null,
      ),
    );
  }
}

class _QuizOptionTile extends StatelessWidget {
  const _QuizOptionTile({
    required this.label,
    required this.text,
    required this.selected,
    required this.answered,
    required this.correct,
    required this.onTap,
  });

  final String label;
  final String text;
  final bool selected;
  final bool answered;
  final bool correct;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final showCorrect = answered && correct;
    final showWrong = answered && selected && !correct;
    final color = showCorrect
        ? AppColors.success
        : showWrong
        ? AppColors.error
        : AppColors.brown;
    return Material(
      color: showCorrect
          ? const Color(0xFFEAF7EF)
          : showWrong
          ? const Color(0xFFFFEEEE)
          : Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: showCorrect || showWrong ? color : AppColors.border,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: const Color(0xFFFFE7B3),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.deepSaffron,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                showCorrect
                    ? Icons.check_circle_rounded
                    : showWrong
                    ? Icons.cancel_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: color,
              ),
            ],
          ),
        ),
      ),
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
              style: const TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.deepSaffron,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.mutedBrown,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnlockedRewardPreview extends StatelessWidget {
  const _UnlockedRewardPreview();

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: AspectRatio(
        aspectRatio: 16 / 10,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset('assets/mahabharatam-cover.png', fit: BoxFit.cover),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC000000)],
                ),
              ),
            ),
            const Positioned(
              left: 18,
              right: 18,
              bottom: 18,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'New Reward Unlocked',
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Daily Darshan Card',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
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

class _TomorrowTeaser extends StatelessWidget {
  const _TomorrowTeaser();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7B3),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.calendar_today_rounded, color: AppColors.deepSaffron),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'రేపు',
                  style: TextStyle(
                    color: AppColors.deepSaffron,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  'భీష్ముని గొప్ప ప్రతిజ్ఞ',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SmallSharePreview extends StatelessWidget {
  const _SmallSharePreview({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: .82,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          image: const DecorationImage(
            image: AssetImage('assets/mahabharatam-cover.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ),
    );
  }
}

class _LibraryRow extends StatelessWidget {
  const _LibraryRow({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            'assets/mahabharatam-cover.png',
            width: 58,
            height: 58,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: const Text('Daily story journey'),
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _SavedCardPreview extends StatelessWidget {
  const _SavedCardPreview({required this.locked});

  final bool locked;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        image: const DecorationImage(
          image: AssetImage('assets/mahabharatam-cover.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: locked
              ? Colors.black.withValues(alpha: .45)
              : Colors.transparent,
        ),
        child: locked
            ? const Icon(Icons.lock_rounded, color: Colors.white, size: 34)
            : const Text(
                'ధర్మమే జయం',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 20,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.saffron, size: 34),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
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
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.active});

  final String label;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 30,
          backgroundColor: active
              ? const Color(0xFFFFE7B3)
              : const Color(0xFFFFF1E6),
          child: Icon(
            Icons.workspace_premium_rounded,
            color: active ? AppColors.deepSaffron : AppColors.border,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: active ? AppColors.brown : AppColors.mutedBrown,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
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
      borderRadius: BorderRadius.circular(99),
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: .28),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7B3),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Row(
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
          const SizedBox(width: 4),
          Icon(icon, size: 18, color: color),
        ],
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

class _WorldChip extends StatelessWidget {
  const _WorldChip({required this.label, required this.icon});

  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, color: AppColors.deepSaffron, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
      backgroundColor: Colors.white,
      side: const BorderSide(color: AppColors.border),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
    );
  }
}

class _DarkPill extends StatelessWidget {
  const _DarkPill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: .38),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white24),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: Colors.white, size: 14),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _BrandBadge extends StatelessWidget {
  const _BrandBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: .22),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: Colors.white30),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.local_fire_department_rounded,
            color: AppColors.gold,
            size: 17,
          ),
          SizedBox(width: 5),
          Text(
            'DAILY KATHA',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  const _SocialButton({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: () {},
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(86),
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: .35)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(label),
        ],
      ),
    );
  }
}

class _ProgressLine extends StatelessWidget {
  const _ProgressLine();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      height: 5,
      decoration: BoxDecoration(
        color: const Color(0xFFFFE7B3),
        borderRadius: BorderRadius.circular(99),
      ),
      alignment: Alignment.centerLeft,
      child: FractionallySizedBox(
        widthFactor: .36,
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.deepSaffron,
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}

class _Slide {
  const _Slide(this.title, this.body, this.color, this.alignment);

  final String title;
  final String body;
  final Color color;
  final Alignment alignment;
}

class _Question {
  const _Question(this.text, this.options, this.correctIndex);

  final String text;
  final List<String> options;
  final int correctIndex;
}

const _slides = [
  _Slide(
    'ధర్మం మొదలైన క్షణం',
    'కురుక్షేత్ర యుద్ధభూమిలో అర్జునుడు తన మనసులో గందరగోళాన్ని అనుభవించాడు.',
    AppColors.gold,
    Alignment.topCenter,
  ),
  _Slide(
    'అర్జునుడి సందేహం',
    'తన బంధువులను చూసి అతని చేతులు వణికాయి. యుద్ధం సరైనదా అని ప్రశ్నించాడు.',
    AppColors.saffron,
    Alignment.centerLeft,
  ),
  _Slide(
    'కృష్ణుడి మాట',
    'కృష్ణుడు ధర్మం కోసం తీసుకునే నిర్ణయం కఠినమైనదైనా అవసరమని వివరించాడు.',
    AppColors.deepSaffron,
    Alignment.centerRight,
  ),
  _Slide(
    'జీవిత పాఠం',
    'భయం వచ్చినప్పుడు కూడా మన కర్తవ్యాన్ని స్పష్టంగా చూడటం నేర్చుకోవాలి.',
    AppColors.maroon,
    Alignment.bottomCenter,
  ),
];

const _questions = [
  _Question('అర్జునుడి రథానికి సారథి ఎవరు?', [
    'భీష్ముడు',
    'శ్రీకృష్ణుడు',
    'ద్రోణుడు',
    'కర్ణుడు',
  ], 1),
  _Question('కురుక్షేత్రంలో అర్జునుడు మొదట ఏమి అనుభవించాడు?', [
    'సంతోషం',
    'గందరగోళం',
    'కోపం',
    'నిద్ర',
  ], 1),
  _Question('ఈ కథలో ప్రధానమైన పాఠం ఏమిటి?', [
    'ధర్మం వైపు నిలవాలి',
    'యుద్ధం మాత్రమే ముఖ్యం',
    'మాట్లాడకూడదు',
    'ఎప్పుడూ కోపంగా ఉండాలి',
  ], 0),
];

const _dayTitles = [
  'The Great Story Begins',
  'Bhishma Pratigya',
  'Guru Drona',
  'The Game of Dice',
  'Kurukshetra Begins',
  'Arjuna Vishada Yogam',
  'Krishna’s Teaching',
];

const _librarySections = [
  ('Itihasam', ['Mahabharatam 100 Days Journey', 'Ramayanam 60 Days Journey']),
  ('Puranam', ['Sri Krishna Kathalu', 'Shiva Kathalu', 'Vishnu Avataralu']),
  ('Bhakti', ['Bhakta Prahlada', 'Annamayya', 'Ramadasu']),
  ('Temple Stories', ['Tirupati Balaji', 'Srisailam', 'Bhadrachalam']),
  ('Festival Specials', ['Sri Rama Navami', 'Krishna Janmashtami', 'Diwali']),
  ('Kids Katha', ['Panchatantra', 'Tenali Ramakrishna', 'Vikram-Betal']),
];

final _softShadow = [
  BoxShadow(
    color: AppColors.saffron.withValues(alpha: .12),
    blurRadius: 28,
    offset: const Offset(0, 12),
  ),
];
