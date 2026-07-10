import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'app/daily_katha_app.dart';
import 'core/services/notification_service.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await NotificationService.instance.init();
  runApp(const DailyKathaApp());
}
