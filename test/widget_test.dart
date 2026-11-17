import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';
import 'package:religious_tasks_app/shared/services/updates/app_update_service.dart';
import 'package:religious_tasks_app/features/quran/services/khatmah_planner_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('ThemeProvider uses system mode by default', () {
    final provider = ThemeProvider();

    expect(provider.appThemeMode, AppThemeMode.system);
    expect(provider.themeMode, ThemeMode.system);
  });

  test('ThemeProvider changes theme mode correctly', () {
    final provider = ThemeProvider();

    provider.setThemeMode(AppThemeMode.dark);
    expect(provider.appThemeMode, AppThemeMode.dark);
    expect(provider.themeMode, ThemeMode.dark);

    provider.setThemeMode(AppThemeMode.light);
    expect(provider.appThemeMode, AppThemeMode.light);
    expect(provider.themeMode, ThemeMode.light);
  });

  test('NotificationPreferences defaults match expected notification setup',
      () {
    final preferences = NotificationPreferences.defaults();

    expect(preferences.adhanSoundType, AdhanSoundType.full);
    expect(preferences.hourlyDhikrEnabled, isTrue);
    expect(preferences.hourlyDhikrIntervalMinutes, 10);
    expect(preferences.morningAthkarReminderEnabled, isTrue);
    expect(preferences.eveningAthkarReminderEnabled, isTrue);
    expect(preferences.floatingDhikrEnabled, isFalse);
    expect(preferences.salawatReminderEnabled, isTrue);
    expect(preferences.salawatIntervalMinutes, 15);
    expect(preferences.isAdhanEnabled('fajr'), isTrue);
    expect(preferences.isAdhanEnabled('sunrise'), isFalse);
    expect(preferences.getPrayerOffset('fajr'), 0);
  });

  test('AppUpdateService compares semantic version parts safely', () {
    expect(AppUpdateService.isVersionGreater('3.8.7', '3.8.6'), isTrue);
    expect(AppUpdateService.isVersionGreater('3.10.0', '3.9.9'), isTrue);
    expect(AppUpdateService.isVersionGreater('3.8', '3.8.0'), isFalse);
    expect(AppUpdateService.isVersionGreater('3.8.6', '3.8.6'), isFalse);
    expect(AppUpdateService.isVersionGreater('3.8.5', '3.8.6'), isFalse);
  });

  test('AppUpdateService uses build number only for the same version', () {
    expect(
      AppUpdateService.isUpdateAvailable(
        latestVersion: '3.7.0',
        latestBuildNumber: 100,
        currentVersion: '3.8.6',
        currentBuildNumber: 37,
      ),
      isFalse,
    );
    expect(
      AppUpdateService.isUpdateAvailable(
        latestVersion: '3.8.6',
        latestBuildNumber: 38,
        currentVersion: '3.8.6',
        currentBuildNumber: 37,
      ),
      isTrue,
    );
    expect(
      AppUpdateService.isUpdateAvailable(
        latestVersion: '3.8.7',
        latestBuildNumber: 1,
        currentVersion: '3.8.6',
        currentBuildNumber: 37,
      ),
      isTrue,
    );
  });

  test('KhatmahPlan calculates page ranges from its start date and page', () {
    final plan = KhatmahPlan(
      targetDays: 30,
      startPage: 1,
      startDateMillis: DateTime(2026, 11, 1).millisecondsSinceEpoch,
    );

    expect(plan.pagesPerDay, 21);
    expect(
      plan.getTodayRequirement(now: DateTime(2026, 11, 1)),
      contains('من الصفحة 1 إلى 21'),
    );
    expect(
      plan.getTodayRequirement(now: DateTime(2026, 11, 2)),
      contains('من الصفحة 22 إلى 42'),
    );
  });
}
