enum AdhanSoundType {
  none,
  short,
  full,
}

class NotificationPreferences {
  final Map<String, bool> adhanEnabled;
  final AdhanSoundType adhanSoundType;
  final bool morningAthkarReminderEnabled;
  final bool eveningAthkarReminderEnabled;
  final bool hourlyDhikrEnabled;
  final int hourlyDhikrIntervalMinutes;

  const NotificationPreferences({
    required this.adhanEnabled,
    required this.adhanSoundType,
    required this.morningAthkarReminderEnabled,
    required this.eveningAthkarReminderEnabled,
    required this.hourlyDhikrEnabled,
    required this.hourlyDhikrIntervalMinutes,
  });

  factory NotificationPreferences.defaults() {
    return const NotificationPreferences(
      adhanEnabled: {
        'fajr': true,
        'sunrise': true,
        'dhuhr': true,
        'asr': true,
        'maghrib': true,
        'isha': true,
      },
      adhanSoundType: AdhanSoundType.full,
      morningAthkarReminderEnabled: true,
      eveningAthkarReminderEnabled: true,
      hourlyDhikrEnabled: true,
      hourlyDhikrIntervalMinutes: 60,
    );
  }

  NotificationPreferences copyWith({
    Map<String, bool>? adhanEnabled,
    AdhanSoundType? adhanSoundType,
    bool? morningAthkarReminderEnabled,
    bool? eveningAthkarReminderEnabled,
    bool? hourlyDhikrEnabled,
    int? hourlyDhikrIntervalMinutes,
  }) {
    return NotificationPreferences(
      adhanEnabled: adhanEnabled ?? this.adhanEnabled,
      adhanSoundType: adhanSoundType ?? this.adhanSoundType,
      morningAthkarReminderEnabled: morningAthkarReminderEnabled ??
          this.morningAthkarReminderEnabled,
      eveningAthkarReminderEnabled: eveningAthkarReminderEnabled ??
          this.eveningAthkarReminderEnabled,
      hourlyDhikrEnabled: hourlyDhikrEnabled ?? this.hourlyDhikrEnabled,
      hourlyDhikrIntervalMinutes:
          hourlyDhikrIntervalMinutes ?? this.hourlyDhikrIntervalMinutes,
    );
  }

  bool isAdhanEnabled(String prayerKey) => adhanEnabled[prayerKey] ?? true;
}
