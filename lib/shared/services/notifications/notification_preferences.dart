enum AdhanSoundType {
  none,
  short,
  full,
}

class NotificationPreferences {
  final Map<String, bool> adhanEnabled;
  final Map<String, int> prayerOffsets; // Minutes offset for each prayer
  final AdhanSoundType adhanSoundType;
  final bool morningAthkarReminderEnabled;
  final bool eveningAthkarReminderEnabled;
  final bool hourlyDhikrEnabled;
  final int hourlyDhikrIntervalMinutes;
  final bool floatingDhikrEnabled;

  const NotificationPreferences({
    required this.adhanEnabled,
    required this.prayerOffsets,
    required this.adhanSoundType,
    required this.morningAthkarReminderEnabled,
    required this.eveningAthkarReminderEnabled,
    required this.hourlyDhikrEnabled,
    required this.hourlyDhikrIntervalMinutes,
    required this.floatingDhikrEnabled,
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
      prayerOffsets: {
        'fajr': 0,
        'sunrise': 0,
        'dhuhr': 0,
        'asr': 0,
        'maghrib': 0,
        'isha': 0,
      },
      adhanSoundType: AdhanSoundType.full,
      morningAthkarReminderEnabled: true,
      eveningAthkarReminderEnabled: true,
      hourlyDhikrEnabled: true,
      hourlyDhikrIntervalMinutes: 10,
      floatingDhikrEnabled: false,
    );
  }

  NotificationPreferences copyWith({
    Map<String, bool>? adhanEnabled,
    Map<String, int>? prayerOffsets,
    AdhanSoundType? adhanSoundType,
    bool? morningAthkarReminderEnabled,
    bool? eveningAthkarReminderEnabled,
    bool? hourlyDhikrEnabled,
    int? hourlyDhikrIntervalMinutes,
    bool? floatingDhikrEnabled,
  }) {
    return NotificationPreferences(
      adhanEnabled: adhanEnabled ?? this.adhanEnabled,
      prayerOffsets: prayerOffsets ?? this.prayerOffsets,
      adhanSoundType: adhanSoundType ?? this.adhanSoundType,
      morningAthkarReminderEnabled: morningAthkarReminderEnabled ??
          this.morningAthkarReminderEnabled,
      eveningAthkarReminderEnabled: eveningAthkarReminderEnabled ??
          this.eveningAthkarReminderEnabled,
      hourlyDhikrEnabled: hourlyDhikrEnabled ?? this.hourlyDhikrEnabled,
      hourlyDhikrIntervalMinutes:
          hourlyDhikrIntervalMinutes ?? this.hourlyDhikrIntervalMinutes,
      floatingDhikrEnabled: floatingDhikrEnabled ?? this.floatingDhikrEnabled,
    );
  }

  bool isAdhanEnabled(String prayerKey) => adhanEnabled[prayerKey] ?? true;
  int getPrayerOffset(String prayerKey) => prayerOffsets[prayerKey] ?? 0;
}
