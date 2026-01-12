import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'app/religious_app.dart';
import 'services/notifications_service.dart';
import 'services/storage_service.dart';
import 'providers/theme_provider.dart';
import 'providers/athkar_view_model.dart';
import 'providers/tasks_view_model.dart';

void main() async {
  debugPrint("🟢 Application Main Function Started");
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
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
  NotificationManager().init().catchError((e) {
    debugPrint("Notification init failed: $e");
  });

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AthkarViewModel()),
        ChangeNotifierProvider(create: (_) => TasksViewModel()),
      ],
      child: const ReligiousApp(),
    ),
  );
}
