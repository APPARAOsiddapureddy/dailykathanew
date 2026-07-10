import 'package:flutter/material.dart';

import 'app/daily_katha_app.dart';
import 'core/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.instance.init();
  runApp(const DailyKathaApp());
}
