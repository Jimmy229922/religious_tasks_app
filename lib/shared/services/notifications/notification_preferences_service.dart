import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_preferences.dart';

class NotificationPreferencesService {
  static const MethodChannel _nativeAdhanChannel =
      MethodChannel('religious_tasks_app/native_adhan');

  static const List<String> prayerKeys = [
    'fajr',
    'sunrise',
    'dhuhr',
    'asr',
    'maghrib',
    'isha',
  ];
  static const List<int> dhikrIntervalOptions = [5, 10, 15, 60, 90, 120];
  static const List<int> salawatIntervalOptions = [15, 30, 45, 60, 90, 120];
  static const List<int> preAdhanReminderOptions = [5, 10, 15];

  static const String adhanSoundTypeKey = 'adhan_sound_type_v1';
  static const String hourlyDhikrEnabledKey = 'hourly_dhikr_enabled_v1';
  static const String hourlyDhikrIntervalKey =
      'hourly_dhikr_interval_minutes_v1';
  static const String morningAthkarReminderEnabledKey =
      'morning_athkar_reminder_enabled_v1';
  static const String eveningAthkarReminderEnabledKey =
      'evening_athkar_reminder_enabled_v1';
  static const String floatingDhikrEnabledKey = 'floating_dhikr_enabled_v1';
  static const String selectedMoazzenIdKey = 'selected_moazzen_id_v1';
  static const String salawatReminderEnabledKey = 'salawat_reminder_enabled_v1';
  static const String salawatIntervalKey = 'salawat_interval_minutes_v1';
  static const String stopAdhanOnVolumeButtonKey =
      'stop_adhan_on_volume_btn_v1';
  static const String stopSalawatOnVolumeButtonKey =
      'stop_salawat_on_volume_btn_v1';
  static const String happinessJarEnabledKey = 'happiness_jar_enabled_v1';
  static const String happinessJarHourKey = 'happiness_jar_hour_v1';
  static const String happinessJarMinuteKey = 'happiness_jar_minute_v1';
  static const String preAdhanReminderMinutesKey =
      'pre_adhan_reminder_minutes_v1';

  Future<NotificationPreferences> load() async {
    final prefs = await SharedPreferences.getInstance();
    final defaults = NotificationPreferences.defaults();
    final adhanEnabled = <String, bool>{};
    final prayerOffsets = <String, int>{};
    final storedInterval = prefs.getInt(hourlyDhikrIntervalKey);
    final storedSalawatInterval = prefs.getInt(salawatIntervalKey);
    final soundTypeIndex =
        prefs.getInt(adhanSoundTypeKey) ?? AdhanSoundType.full.index;
    final adhanSoundType = AdhanSoundType
        .values[soundTypeIndex.clamp(0, AdhanSoundType.values.length - 1)];

    for (final prayerKey in prayerKeys) {
      adhanEnabled[prayerKey] = prayerKey == 'sunrise'
          ? false
          : (prefs.getBool('adhan_enabled_$prayerKey') ?? true);
      prayerOffsets[prayerKey] =
          (prefs.getInt('prayer_offset_$prayerKey') ?? 0).clamp(-60, 60);
    }

    final stopAdhanOnVolume =
        prefs.getBool(stopAdhanOnVolumeButtonKey) ??
            defaults.stopAdhanOnVolumeButton;
    final stopSalawatOnVolume =
        prefs.getBool(stopSalawatOnVolumeButtonKey) ??
            defaults.stopSalawatOnVolumeButton;

    // Ensure Android native service preferences stay synced
    _syncVolumeStopSettingsToNative(
      stopAdhan: stopAdhanOnVolume,
      stopSalawat: stopSalawatOnVolume,
    );

    return defaults.copyWith(
      adhanEnabled: adhanEnabled,
      prayerOffsets: prayerOffsets,
      adhanSoundType: adhanSoundType,
      morningAthkarReminderEnabled:
          prefs.getBool(morningAthkarReminderEnabledKey) ??
              defaults.morningAthkarReminderEnabled,
      eveningAthkarReminderEnabled:
          prefs.getBool(eveningAthkarReminderEnabledKey) ??
              defaults.eveningAthkarReminderEnabled,
      hourlyDhikrEnabled:
          prefs.getBool(hourlyDhikrEnabledKey) ?? defaults.hourlyDhikrEnabled,
      hourlyDhikrIntervalMinutes: dhikrIntervalOptions.contains(storedInterval)
          ? storedInterval!
          : defaults.hourlyDhikrIntervalMinutes,
      floatingDhikrEnabled: prefs.getBool(floatingDhikrEnabledKey) ??
          defaults.floatingDhikrEnabled,
      selectedMoazzenId:
          prefs.getString(selectedMoazzenIdKey) ?? defaults.selectedMoazzenId,
      salawatReminderEnabled: prefs.getBool(salawatReminderEnabledKey) ??
          defaults.salawatReminderEnabled,
      salawatIntervalMinutes:
          salawatIntervalOptions.contains(storedSalawatInterval)
              ? storedSalawatInterval!
              : defaults.salawatIntervalMinutes,
      stopAdhanOnVolumeButton: stopAdhanOnVolume,
      stopSalawatOnVolumeButton: stopSalawatOnVolume,
      happinessJarEnabled:
          prefs.getBool(happinessJarEnabledKey) ?? defaults.happinessJarEnabled,
      happinessJarHour:
          (prefs.getInt(happinessJarHourKey) ?? defaults.happinessJarHour)
              .clamp(0, 23),
      happinessJarMinute:
          (prefs.getInt(happinessJarMinuteKey) ?? defaults.happinessJarMinute)
              .clamp(0, 59),
      preAdhanReminderMinutes: preAdhanReminderOptions
              .contains(prefs.getInt(preAdhanReminderMinutesKey))
          ? prefs.getInt(preAdhanReminderMinutesKey)!
          : defaults.preAdhanReminderMinutes,
    );
  }

  Future<void> setPreAdhanReminderMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    final safeMinutes =
        preAdhanReminderOptions.contains(minutes) ? minutes : 5;
    await prefs.setInt(preAdhanReminderMinutesKey, safeMinutes);
  }

  Future<void> setAdhanEnabled(String prayerKey, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_enabled_$prayerKey', value);
  }

  Future<void> setPrayerOffset(String prayerKey, int value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prayer_offset_$prayerKey', value.clamp(-60, 60));
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

  Future<void> setSelectedMoazzenId(String moazzenId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(selectedMoazzenIdKey, moazzenId);
  }

  Future<void> setSalawatReminderEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(salawatReminderEnabledKey, value);
  }

  Future<void> setSalawatIntervalMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(salawatIntervalKey, minutes);
  }

  Future<void> setStopAdhanOnVolumeButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(stopAdhanOnVolumeButtonKey, value);
    await _syncVolumeStopSettingsToNative(stopAdhan: value);
  }

  Future<void> setStopSalawatOnVolumeButton(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(stopSalawatOnVolumeButtonKey, value);
    await _syncVolumeStopSettingsToNative(stopSalawat: value);
  }

  Future<void> setHappinessJarEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(happinessJarEnabledKey, value);
  }

  Future<void> setHappinessJarTime(int hour, int minute) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(happinessJarHourKey, hour.clamp(0, 23));
    await prefs.setInt(happinessJarMinuteKey, minute.clamp(0, 59));
  }

  Future<void> _syncVolumeStopSettingsToNative({
    bool? stopAdhan,
    bool? stopSalawat,
  }) async {
    try {
      await _nativeAdhanChannel.invokeMethod<void>(
        'setVolumeStopSettings',
        {
          if (stopAdhan != null) 'stopAdhanOnVolume': stopAdhan,
          if (stopSalawat != null) 'stopSalawatOnVolume': stopSalawat,
        },
      );
    } catch (_) {
      // Safe no-op on non-Android platforms or in unit tests
    }
  }
}
