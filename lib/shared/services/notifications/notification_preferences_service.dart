import 'package:shared_preferences/shared_preferences.dart';

import 'notification_preferences.dart';

class NotificationPreferencesService {
  static const List<String> prayerKeys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];
  static const List<int> dhikrIntervalOptions = [10, 60, 90, 120];

  static const String adhanSoundTypeKey = 'adhan_sound_type_v1';
  static const String hourlyDhikrEnabledKey = 'hourly_dhikr_enabled_v1';
  static const String hourlyDhikrIntervalKey =
      'hourly_dhikr_interval_minutes_v1';
  static const String morningAthkarReminderEnabledKey =
      'morning_athkar_reminder_enabled_v1';
  static const String eveningAthkarReminderEnabledKey =
      'evening_athkar_reminder_enabled_v1';
  static const String floatingDhikrEnabledKey = 'floating_dhikr_enabled_v1';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = NotificationPreferences.defaults();
    final adhanEnabled = <String, bool>{};
    final storedInterval = prefs.getInt(hourlyDhikrIntervalKey);
    final soundTypeIndex = prefs.getInt(adhanSoundTypeKey) ?? 
        AdhanSoundType.full.index;
    final adhanSoundType = AdhanSoundType.values[soundTypeIndex.clamp(0, AdhanSoundType.values.length - 1)];

    for (final prayerKey in prayerKeys) {
      adhanEnabled[prayerKey] =
          prefs.getBool('adhan_enabled_$prayerKey') ?? true;
    }

    return defaults.copyWith(
      adhanEnabled: adhanEnabled,
      adhanSoundType: adhanSoundType,
      morningAthkarReminderEnabled:
          prefs.getBool(morningAthkarReminderEnabledKey) ??
              defaults.morningAthkarReminderEnabled,
      eveningAthkarReminderEnabled:
          prefs.getBool(eveningAthkarReminderEnabledKey) ??
              defaults.eveningAthkarReminderEnabled,
      hourlyDhikrEnabled:
          prefs.getBool(hourlyDhikrEnabledKey) ?? defaults.hourlyDhikrEnabled,
      hourlyDhikrIntervalMinutes:
          dhikrIntervalOptions.contains(storedInterval)
              ? storedInterval!
              : defaults.hourlyDhikrIntervalMinutes,
      floatingDhikrEnabled:
          prefs.getBool(floatingDhikrEnabledKey) ?? defaults.floatingDhikrEnabled,
    );
  }

  Future<void> setAdhanEnabled(String prayerKey, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_enabled_$prayerKey', value);
  }

  Future<void> setAdhanSoundType(AdhanSoundType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(adhanSoundTypeKey, type.index);
  }

  Future<void> setMorningAthkarReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(morningAthkarReminderEnabledKey, value);
  }

  Future<void> setEveningAthkarReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(eveningAthkarReminderEnabledKey, value);
  }

  Future<void> setHourlyDhikrEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(hourlyDhikrEnabledKey, value);
  }

  Future<void> setHourlyDhikrIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(hourlyDhikrIntervalKey, minutes);
  }

  Future<void> setFloatingDhikrEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(floatingDhikrEnabledKey, value);
  }
}
