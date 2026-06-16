import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';

void main() {
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

  test('NotificationPreferences defaults match expected notification setup', () {
    final preferences = NotificationPreferences.defaults();

    expect(preferences.adhanSoundType, AdhanSoundType.full);
    expect(preferences.hourlyDhikrEnabled, isTrue);
    expect(preferences.hourlyDhikrIntervalMinutes, 10);
    expect(preferences.morningAthkarReminderEnabled, isTrue);
    expect(preferences.eveningAthkarReminderEnabled, isTrue);
    expect(preferences.floatingDhikrEnabled, isFalse);
    expect(preferences.isAdhanEnabled('fajr'), isTrue);
    expect(preferences.getPrayerOffset('fajr'), 0);
  });
}
