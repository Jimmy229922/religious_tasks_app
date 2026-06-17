import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/religious_app.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/athkar/providers/athkar_view_model.dart';
import 'features/tasbeeh/providers/tasbeeh_view_model.dart';
import 'features/tasks/providers/tasks_view_model.dart';
import 'features/radio/providers/radio_view_model.dart';
import 'shared/widgets/dhikr_overlay.dart';
import 'shared/services/audio/radio_service.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: DhikrOverlay(),
    ),
  );
}

void main() async {
  debugPrint("🟢 Application Main Function Started");
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  await AndroidAlarmManager.initialize();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await initializeDateFormatting('ar', null);
  HijriCalendar.setLocal('ar');
  // NotificationManager().init() removed to prevent startup crash.
  // Moved to SplashScreen/Main App usage.
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint("StorageService init failed: $e");
  }

  // Initialize notifications in the background (don't block first frame).
  AppNotificationService().init().catchError((e) {
    debugPrint("Notification init failed: $e");
  });

  await RadioService().init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AthkarViewModel()),
        ChangeNotifierProvider(create: (_) => TasksViewModel()),
        ChangeNotifierProvider(create: (_) => TasbeehViewModel()),
        ChangeNotifierProvider(create: (_) => RadioViewModel()),
      ],
      child: const ReligiousApp(),
    ),
  );
}
