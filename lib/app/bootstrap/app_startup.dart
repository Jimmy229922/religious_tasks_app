import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/services/storage_service.dart';
import '../../shared/services/notifications/app_notification_service.dart';

class AppStartupResult {
  final bool showPermissionsOnboarding;

  const AppStartupResult({
    required this.showPermissionsOnboarding,
  });
}

class AppStartup {
  static Future<AppStartupResult> initialize() async {
    debugPrint('Application startup began');

    await _configureFramework();
    await _initializeStorage();

    final showPermissionsOnboarding = await _resolveOnboardingState();
    _initializeNotificationsIfNeeded(
      showPermissionsOnboarding: showPermissionsOnboarding,
    );

    return AppStartupResult(
      showPermissionsOnboarding: showPermissionsOnboarding,
    );
  }

  static Future<void> _configureFramework() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    await initializeDateFormatting('ar', null);
    HijriCalendar.setLocal('ar');
  }

  static Future<void> _initializeStorage() async {
    try {
      await StorageService.init();
    } catch (error) {
      debugPrint('StorageService init failed: $error');
    }
  }

  static Future<bool> _resolveOnboardingState() async {
    try {
      return await _shouldShowPermissionsOnboarding();
    } catch (error) {
      debugPrint('Startup routing failed: $error');
      return false;
    }
  }

  static void _initializeNotificationsIfNeeded({
    required bool showPermissionsOnboarding,
  }) {
    if (showPermissionsOnboarding) {
      return;
    }

    AppNotificationService().init().catchError((Object error) {
      debugPrint('Notification init failed: $error');
    });
  }

  static Future<bool> _shouldShowPermissionsOnboarding() async {
    final prefs = StorageService.instance.prefs;
    final onboardingCompleted = prefs.getBool('onboarding_completed') ?? false;
    final notificationsGranted = await Permission.notification.status;
    final locationGranted = await Permission.locationWhenInUse.status;
    var hasRequiredPermissions =
        notificationsGranted.isGranted && locationGranted.isGranted;

    if (Platform.isAndroid) {
      final alarmGranted = await Permission.scheduleExactAlarm.status;
      hasRequiredPermissions = hasRequiredPermissions && alarmGranted.isGranted;
    }

    if (!hasRequiredPermissions) {
      if (onboardingCompleted) {
        await prefs.setBool('onboarding_completed', false);
      }
      return true;
    }

    if (!onboardingCompleted) {
      await prefs.setBool('onboarding_completed', true);
    }

    return false;
  }
}
