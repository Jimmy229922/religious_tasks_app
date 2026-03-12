import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';

import 'app/religious_app.dart';
import 'core/services/ad_service.dart';
import 'core/services/notifications_service.dart';
import 'core/services/storage_service.dart';
import 'core/theme/theme_provider.dart';
import 'features/athkar/providers/athkar_view_model.dart';
import 'features/tasbeeh/providers/tasbeeh_view_model.dart';
import 'features/tasks/providers/tasks_view_model.dart';

void main() async {
  debugPrint("🟢 Application Main Function Started");
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await initializeDateFormatting('ar', null);
  HijriCalendar.setLocal('ar');
  try {
    await StorageService.init();
  } catch (e) {
    debugPrint("StorageService init failed: $e");
  }

  bool showPermissionsOnboarding = false;
  try {
    showPermissionsOnboarding = await _shouldShowPermissionsOnboarding();
  } catch (e) {
    debugPrint("Startup routing failed: $e");
  }

  if (!showPermissionsOnboarding) {
    NotificationManager().init().catchError((Object error) {
      debugPrint("Notification init failed: $error");
    });
  }

  // Initialize Ads
  AdService.instance.init();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AthkarViewModel()),
        ChangeNotifierProvider(create: (_) => TasksViewModel()),
        ChangeNotifierProvider(create: (_) => TasbeehViewModel()),
      ],
      child: ReligiousApp(
        showPermissionsOnboarding: showPermissionsOnboarding,
      ),
    ),
  );
}

Future<bool> _shouldShowPermissionsOnboarding() async {
  final prefs = StorageService.instance.prefs;
  final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;

  if (onboardingCompleted) {
    return false;
  }

  final notificationsGranted = await Permission.notification.status;
  final locationGranted = await Permission.locationWhenInUse.status;

  if (!notificationsGranted.isGranted || !locationGranted.isGranted) {
    return true;
  }

  if (Platform.isAndroid) {
    final alarmGranted = await Permission.scheduleExactAlarm.status;
    if (!alarmGranted.isGranted) {
      return true;
    }
  }

  await prefs.setBool('onboarding_completed', true);
  return false;
}
