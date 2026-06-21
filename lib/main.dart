import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';

import 'app/religious_app.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/athkar/providers/athkar_view_model.dart';
import 'features/tasbeeh/providers/tasbeeh_view_model.dart';
import 'features/tasks/providers/tasks_view_model.dart';
import 'features/radio/providers/radio_view_model.dart';
import 'shared/widgets/dhikr_overlay.dart';
import 'shared/widgets/radio_overlay.dart';
import 'shared/services/audio/radio_service.dart';
import 'shared/services/updates/update_view_model.dart';

@pragma("vm:entry-point")
void overlayMain() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: StreamBuilder(
        stream: FlutterOverlayWindow.overlayListener,
        builder: (context, snapshot) {
          final data = snapshot.data;
          if (data == "RADIO_MODE") {
            return const RadioOverlay();
          }
          return const DhikrOverlay();
        },
      ),
    ),
  );
}

void main() async {
  debugPrint("🟢 Application Main Function Started");
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Supabase
  try {
    await Supabase.initialize(
      url: 'https://qxllkedwilhpmrcrfeya.supabase.co',
      publishableKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InF4bGxrZWR3aWxocG1yY3JmZXlhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODE4MjIyMzgsImV4cCI6MjA5NzM5ODIzOH0.Fr5QKruw69aHjj4NMJc8uWa4naZgInVfo2yZQF7hld8',
      realtimeClientOptions: const RealtimeClientOptions(
        eventsPerSecond: 2,
      ),
    );
  } catch (e) {
    debugPrint("Supabase init failed: $e");
  }

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
        ChangeNotifierProvider(create: (_) => UpdateViewModel()),
      ],
      child: const ReligiousApp(),
    ),
  );
}
