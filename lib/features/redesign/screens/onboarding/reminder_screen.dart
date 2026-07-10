import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/services/notification_service.dart';
import '../../data/mock_data.dart';
import '../main/main_shell.dart';

class ReminderScreen extends StatefulWidget {
  const ReminderScreen({super.key});

  @override
  State<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  TimeOfDay _selectedTime = const TimeOfDay(hour: 7, minute: 0);

  void _finishOnboarding(BuildContext context) {
    Navigator.of(
      context,
    ).pushReplacement(MaterialPageRoute(builder: (_) => const MainShell()));
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (picked != null) setState(() => _selectedTime = picked);
  }

  Future<void> _allowReminders(BuildContext context) async {
    final state = context.read<AppState>();
    final granted = await NotificationService.instance.requestPermission();
    await state.setReminderTime(_selectedTime);
    await state.setNotificationsEnabled(granted);
    if (context.mounted) _finishOnboarding(context);
  }

  Future<void> _skipReminders(BuildContext context) async {
    await context.read<AppState>().setNotificationsEnabled(false);
    if (context.mounted) _finishOnboarding(context);
  }

  String _formatTime(TimeOfDay time, bool isTelugu) {
    final hour12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final isAm = time.period == DayPeriod.am;
    return isTelugu
        ? '${isAm ? 'ఉదయం' : 'సాయంత్రం'} $hour12:$minute'
        : '$hour12:$minute ${isAm ? 'AM' : 'PM'}';
  }

  @override
  Widget build(BuildContext context) {
    final isTelugu = context.watch<AppState>().language == AppLanguage.telugu;
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
              Text(
                isTelugu ? 'రోజువారీ గుర్తు' : 'Daily Reminder',
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Noto Serif Telugu',
                  color: Color(0xFF6B1F22),
                ),
              ),

              const SizedBox(height: 14),

              // ── Description ──
              Text(
                isTelugu
                    ? 'ప్రతిరోజు మీ కథను కొనసాగించడానికి మేము సున్నితంగా గుర్తు చేస్తాము — నెమ్మదిగా, గౌరవంగా.'
                    : 'We\'ll gently remind you to continue your story each day — slow, and with respect.',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  fontFamily: 'Noto Sans Telugu',
                  color: Color(0xFF7A6A55),
                  height: 1.65,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 22),

              // ── Time pill (tap to change) ──
              GestureDetector(
                onTap: _pickTime,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 10,
                  ),
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
                      const Icon(
                        Icons.access_time_rounded,
                        size: 16,
                        color: Color(0xFFB07A2A),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _formatTime(_selectedTime, isTelugu),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'Noto Sans Telugu',
                          color: Color(0xFF8A5A14),
                        ),
                      ),
                      const SizedBox(width: 6),
                      const Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: Color(0xFFB07A2A),
                      ),
                    ],
                  ),
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
                      colors: [Color(0xFFE67C22), Color(0xFFCE5D0E)],
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
                    onPressed: () => _allowReminders(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: Text(
                      isTelugu ? 'అనుమతించు' : 'Allow',
                      style: const TextStyle(
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
                onPressed: () => _skipReminders(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text(
                  isTelugu ? 'ఇప్పుడు కాదు' : 'Not now',
                  style: const TextStyle(
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
