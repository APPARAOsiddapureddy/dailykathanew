import 'package:flutter/material.dart';

import '../main/main_shell.dart';

class ReminderScreen extends StatelessWidget {
  const ReminderScreen({super.key});

  void _finishOnboarding(BuildContext context) {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF4E8),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 0),
          child: Column(
            children: [
              const SizedBox(height: 44),

              // ── Bell icon container ──
              Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(38),
                  gradient: const RadialGradient(
                    center: Alignment(0.0, -0.6), // at 50% 20%
                    radius: 1.2,
                    colors: [
                      Color(0xFFFCE3B4), // 0%
                      Color(0xFFE7A93B), // 70%
                      Color(0xFFC77E1E), // 100%
                    ],
                    stops: [0.0, 0.70, 1.0],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFC88C1E).withValues(alpha: 0.28),
                      blurRadius: 30,
                      offset: const Offset(0, 14),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 60,
                  color: Color(0xFF6B2A11),
                ),
              ),

              const SizedBox(height: 34),

              // ── Title ──
              const Text(
                'రోజువారీ గుర్తు',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Noto Serif Telugu',
                  color: Color(0xFF6B1F22),
                ),
              ),

              const SizedBox(height: 14),

              // ── Description ──
              const Text(
                'ప్రతిరోజు మీ కథను కొనసాగించడానికి మేము సున్నితంగా గుర్తు చేస్తాము — నెమ్మదిగా, గౌరవంగా.',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Noto Sans Telugu',
                  color: Color(0xFF7A6A55),
                  height: 1.65,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 22),

              // ── Time pill ──
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFBEAD2),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(
                    color: const Color(0xFFEAD3A8),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Clock icon
                    const Icon(
                      Icons.access_time_rounded,
                      size: 16,
                      color: Color(0xFFB07A2A),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'ఉదయం 7:00',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Noto Sans Telugu',
                        color: Color(0xFF8A5A14),
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer pushes buttons to bottom
              const Spacer(),

              // ── Allow button ──
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFFE67C22),
                        Color(0xFFCE5D0E),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFC85A12).withValues(alpha: 0.3),
                        blurRadius: 22,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: () => _finishOnboarding(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: const Text(
                      'అనుమతించు',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        fontFamily: 'Noto Sans Telugu',
                        color: Color(0xFFFFF7E9),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 6),

              // ── Not now button ──
              TextButton(
                onPressed: () => _finishOnboarding(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'ఇప్పుడు కాదు',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Noto Sans Telugu',
                    color: Color(0xFF9A876E),
                  ),
                ),
              ),

              const SizedBox(height: 26),
            ],
          ),
        ),
      ),
    );
  }
}
