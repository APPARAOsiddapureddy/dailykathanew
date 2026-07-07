import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'language_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _spinnerController;

  @override
  void initState() {
    super.initState();
    _spinnerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();

    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LanguageScreen()),
        );
      }
    });
  }

  @override
  void dispose() {
    _spinnerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0.0, -0.56), // 50% 22%
            radius: 1.2,
            colors: [
              Color(0xFFE88A2A), // 0%
              Color(0xFFB84E19), // 52%
              Color(0xFF5E1A12), // 100%
            ],
            stops: [0.0, 0.52, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // Light rays
            Positioned.fill(
              child: Center(
                child: Transform.translate(
                  offset: Offset(0, -MediaQuery.of(context).size.height * 0.18),
                  child: CustomPaint(
                    size: const Size(360, 360),
                    painter: _RaysPainter(),
                  ),
                ),
              ),
            ),

            // Main content
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // OM icon container — frosted glass effect
                  Container(
                    width: 118,
                    height: 118,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(34),
                      color: const Color(0xFFFFF6E4).withOpacity(0.14),
                      border: Border.all(
                        color: const Color(0xFFFFF6E4).withOpacity(0.32),
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      'ॐ',
                      style: TextStyle(
                        fontSize: 66,
                        fontFamily: 'Noto Serif Telugu',
                        fontWeight: FontWeight.w400,
                        color: Color(0xFFFFF3DC),
                        height: 1.0,
                      ),
                    ),
                  ),

                  const SizedBox(height: 30),

                  // డైలీ కథ title
                  const Text(
                    'డైలీ కథ',
                    style: TextStyle(
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Noto Serif Telugu',
                      color: Color(0xFFFFF6E7),
                      letterSpacing: 0.4,
                    ),
                  ),

                  const SizedBox(height: 6),

                  // DAILY KATHA subtitle
                  const Text(
                    'DAILY  KATHA',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFFF6D9A6),
                      letterSpacing: 4.76, // 0.28em * 17px
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tagline
                  Text(
                    'ప్రతిరోజు ఒక కథ, ఒక పాఠం',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'Noto Sans Telugu',
                      color: const Color(0xFFFFF0DC).withOpacity(0.82),
                      height: 1.6,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            // Bottom section: spinner + branding
            Positioned(
              bottom: 44,
              left: 0,
              right: 0,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated spinner (custom painted arc)
                  SizedBox(
                    width: 34,
                    height: 34,
                    child: AnimatedBuilder(
                      animation: _spinnerController,
                      builder: (context, child) {
                        return CustomPaint(
                          painter: _SpinnerPainter(
                            progress: _spinnerController.value,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    'from AppsForBharat',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFFFFF0DC).withOpacity(0.6),
                      letterSpacing: 0.48,
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

/// Custom painter for the loading spinner.
/// Draws a circle with a brighter top arc that rotates.
class _SpinnerPainter extends CustomPainter {
  final double progress;
  _SpinnerPainter({required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 1.25;

    // Background circle
    final bgPaint = Paint()
      ..color = const Color(0xFFFFF0D6).withOpacity(0.35)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;
    canvas.drawCircle(center, radius, bgPaint);

    // Bright arc on top
    final arcPaint = Paint()
      ..color = const Color(0xFFFFF3DC)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startAngle = progress * 2 * math.pi - math.pi / 2;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      math.pi / 3, // 60 degree arc
      false,
      arcPaint,
    );
  }

  @override
  bool shouldRepaint(_SpinnerPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

/// Custom light rays painter — replicates the SVG "sun ray" lines
/// that radiate from the center.
class _RaysPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFDEBC0).withOpacity(0.28)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round;

    final scale = size.width / 100;

    // Ray definitions from the HTML SVG viewBox 0 0 100 100:
    final rays = [
      [50.0, 6.0, 50.0, 18.0],   // top center
      [72.0, 12.0, 66.0, 23.0],  // upper right
      [88.0, 28.0, 77.0, 34.0],  // right
      [94.0, 50.0, 82.0, 50.0],  // far right
      [28.0, 12.0, 34.0, 23.0],  // upper left
      [12.0, 28.0, 23.0, 34.0],  // left
      [6.0, 50.0, 18.0, 50.0],   // far left
    ];

    for (final ray in rays) {
      canvas.drawLine(
        Offset(ray[0] * scale, ray[1] * scale),
        Offset(ray[2] * scale, ray[3] * scale),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
