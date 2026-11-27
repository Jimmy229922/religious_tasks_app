import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:flutter_displaymode/flutter_displaymode.dart';

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
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await Future.wait<void>([
    () async {
      try {
        await Supabase.initialize(
          url: 'https://kqjqqaqucsbwvlaourqy.supabase.co',
          publishableKey: 'sb_publishable_xALekfH8optKoUUZkokBFQ_s0rzdW11',
          realtimeClientOptions: const RealtimeClientOptions(
            eventsPerSecond: 2,
          ),
        );
      } catch (e) {
        debugPrint("Supabase init failed: $e");
      }
    }(),
    () async {
      try {
        await AndroidAlarmManager.initialize();
      } catch (e) {
        debugPrint("AlarmManager init failed: $e");
      }
    }(),
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
    initializeDateFormatting('ar', null),
    () async {
      try {
        await StorageService.init();
      } catch (e) {
        debugPrint("StorageService init failed: $e");
      }
    }(),
    () async {
      try {
        await RadioService.ensureBackgroundConfigured();
      } catch (e) {
        debugPrint("Radio background config failed: $e");
      }
    }(),
  ]);

  HijriCalendar.setLocal('ar');

  FlutterDisplayMode.setHighRefreshRate().catchError((e) {
    debugPrint("High refresh rate init failed: $e");
  });

  final onboardingCompleted = StorageService.isInitialized &&
      (StorageService.instance.prefs.getBool('onboarding_completed') ?? false);
  if (onboardingCompleted) {
    Future<void>.delayed(const Duration(seconds: 4), () {
      AppNotificationService().init().catchError((e) {
        debugPrint("Notification init failed: $e");
      });
    });
  }

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
