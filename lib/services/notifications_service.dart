import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:adhan/adhan.dart'; // For PrayerTimes

import '../constants/strings.dart';

class NotificationManager {
  static final NotificationManager _instance = NotificationManager._internal();
  factory NotificationManager() => _instance;
  NotificationManager._internal();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  static const String kPrayerChannelId = 'prayer_reminders';
  static const String kPrayerReminderSound = 'prayer_reminder';

  // Generic channel (kept for backward compatibility or fallbacks)
  static const String kAdhanChannelId = 'adhan_notifications';
  static const String kAdhanSound = 'adhan_call';

  static const String kDhikrChannelId = 'athkar_reminders';
  static const String kDhikrSound = 'dhikr_chime';

  // Incremented version to force channel recreation
  static const String kNotificationChannelVersionKey =
      'notification_channels_v4';

  static const List<String> kDhikrPhrases = [
    'سبحان الله',
    'الحمد لله',
    'الله أكبر',
    'لا إله إلا الله',
    'سبحان الله وبحمده',
    'سبحان الله العظيم',
    'أستغفر الله',
    'لا حول ولا قوة إلا بالله',
    'اللهم صل وسلم على نبينا محمد',
    'لا إله إلا أنت سبحانك إني كنت من الظالمين',
    'حسبي الله لا إله إلا هو عليه توكلت',
    'اللهم إنك عفو تحب العفو فاعف عني',
    'رضيت بالله رباً وبالإسلام ديناً وبمحمد نبياً',
    'يا حي يا قيوم برحمتك أستغيث',
  ];

  static const List<String> kDhikrTitles = [
    'رسالة لك 💌',
    'طهر لسانك ✨',
    'دقائق من وقتك ⏳',
    'زادك للآخرة 🌿',
    'همسة إيمانية 🌙',
    'ذكر و أجر 💎',
  ];

  Future<void> init() async {
    await _configureLocalTimeZone();

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
    );

    // Initialize the plugin
    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        // Handle notification tap if needed
      },
    );

    final androidPlugin =
        flutterLocalNotificationsPlugin.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.requestNotificationsPermission();

    final prefs = await SharedPreferences.getInstance();
    final shouldResetChannels =
        !(prefs.getBool(kNotificationChannelVersionKey) ?? false);

    if (shouldResetChannels) {
      debugPrint("Resetting notification channels to V3...");
      await androidPlugin?.deleteNotificationChannel(kPrayerChannelId);
      await androidPlugin?.deleteNotificationChannel(kAdhanChannelId);
      await androidPlugin?.deleteNotificationChannel(kDhikrChannelId);
      // Delete old per-prayer channels if they existed (unlikely but safe)
      await androidPlugin?.deleteNotificationChannel('adhan_channel_fajr');
      await androidPlugin?.deleteNotificationChannel('adhan_channel_dhuhr');
      await androidPlugin?.deleteNotificationChannel('adhan_channel_asr');
      await androidPlugin?.deleteNotificationChannel('adhan_channel_maghrib');
      await androidPlugin?.deleteNotificationChannel('adhan_channel_isha');

      await prefs.setBool(kNotificationChannelVersionKey, true);
    }

    // 1. General Reminder Channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kPrayerChannelId,
        AppStrings.notificationPrayerChannelName,
        description: AppStrings.notificationPrayerChannelDesc,
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound(kPrayerReminderSound),
        playSound: true,
      ),
    );

    // 2. Dhikr Channel
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        kDhikrChannelId,
        AppStrings.notificationDhikrChannelName,
        description: AppStrings.notificationDhikrChannelDesc,
        importance: Importance.defaultImportance,
        sound: RawResourceAndroidNotificationSound(kDhikrSound),
        playSound: true,
      ),
    );

    // 3. Specific Adhan Channels (One for each prayer to allow custom sounds)
    final prayers = ['fajr', 'dhuhr', 'asr', 'maghrib', 'isha'];
    for (var prayer in prayers) {
      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'adhan_channel_$prayer', // e.g. adhan_channel_fajr
          '${AppStrings.notificationAdhanChannelName} - $prayer',
          description: AppStrings.notificationAdhanChannelDesc,
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound('adhan_$prayer'),
          playSound: true,
        ),
      );
    }
    await scheduleMorningEveningAthkar();
    await scheduleDhikrNotifications();
  }

  Future<void> _configureLocalTimeZone() async {
    tz_data.initializeTimeZones();
    final dynamic timeZoneName = await FlutterTimezone.getLocalTimezone();
    try {
      tz.setLocalLocation(tz.getLocation(timeZoneName.toString()));
    } catch (e) {
      debugPrint('Failed to set location: $e');
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> scheduleMorningEveningAthkar() async {
    const idMorning = 3001;
    const idEvening = 3002;

    try {
      await flutterLocalNotificationsPlugin.cancel(idMorning);
      await flutterLocalNotificationsPlugin.cancel(idEvening);
    } catch (_) {}

    final now = tz.TZDateTime.now(tz.local);

    // Morning 5:00 AM
    var morningDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 5, 0);
    if (morningDate.isBefore(now)) {
      morningDate = morningDate.add(const Duration(days: 1));
    }

    // Evening 6:50 PM (18:50)
    var eveningDate =
        tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, 50);
    if (eveningDate.isBefore(now)) {
      eveningDate = eveningDate.add(const Duration(days: 1));
    }

    const details = NotificationDetails(
        android: AndroidNotificationDetails(
      kDhikrChannelId,
      AppStrings.notificationDhikrChannelName,
      channelDescription: AppStrings.notificationDhikrChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(kDhikrSound),
      playSound: true,
    ));

    await flutterLocalNotificationsPlugin.zonedSchedule(
      idMorning,
      "أذكار الصباح",
      "حان الآن موعد أذكار الصباح",
      morningDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );

    await flutterLocalNotificationsPlugin.zonedSchedule(
      idEvening,
      "أذكار المساء",
      "حان الآن موعد أذكار المساء",
      eveningDate,
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time, // Repeats daily
    );
  }

  Future<void> schedulePrayerNotifications({
    required PrayerTimes today,
    required PrayerTimes tomorrow,
  }) async {
    final now = tz.TZDateTime.now(tz.local);
    final items = [
      {
        'id': 101,
        'key': 'fajr',
        'name': AppStrings.fajr,
        'today': today.fajr,
        'tomorrow': tomorrow.fajr
      },
      {
        'id': 102,
        'key': 'dhuhr',
        'name': AppStrings.dhuhr,
        'today': today.dhuhr,
        'tomorrow': tomorrow.dhuhr
      },
      {
        'id': 103,
        'key': 'asr',
        'name': AppStrings.asr,
        'today': today.asr,
        'tomorrow': tomorrow.asr
      },
      {
        'id': 104,
        'key': 'maghrib',
        'name': AppStrings.maghrib,
        'today': today.maghrib,
        'tomorrow': tomorrow.maghrib
      },
      {
        'id': 105,
        'key': 'isha',
        'name': AppStrings.isha,
        'today': today.isha,
        'tomorrow': tomorrow.isha
      },
    ];

    for (final item in items) {
      final baseId = item['id'] as int;
      try {
        await flutterLocalNotificationsPlugin.cancel(baseId);
        await flutterLocalNotificationsPlugin.cancel(baseId + 100);
      } catch (e) {
        // ignore errors on cancel
      }
    }

    // Load preferences
    final prefs = await SharedPreferences.getInstance();

    const reminderDetails = NotificationDetails(
        android: AndroidNotificationDetails(
      kPrayerChannelId,
      AppStrings.notificationPrayerChannelName,
      channelDescription: AppStrings.notificationPrayerChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound(kPrayerReminderSound),
      playSound: true,
    ));

    for (final item in items) {
      final name = item['name'] as String;
      final key = item['key'] as String; // fajr, dhuhr...
      final todayTime = item['today'] as DateTime;
      final tomorrowTime = item['tomorrow'] as DateTime;

      // 1. Pre-notification (5 mins before)
      tz.TZDateTime scheduled = tz.TZDateTime.from(todayTime, tz.local)
          .subtract(const Duration(minutes: 5));
      if (scheduled.isBefore(now)) {
        scheduled = tz.TZDateTime.from(tomorrowTime, tz.local)
            .subtract(const Duration(minutes: 5));
      }
      if (scheduled.isAfter(now)) {
        final baseId = item['id'] as int;
        await flutterLocalNotificationsPlugin.zonedSchedule(
          baseId,
          "${AppStrings.remainingTimeTitle} $name",
          AppStrings.prepareForPrayer,
          scheduled,
          reminderDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      // 2. Adhan notification (Specific Sound per Prayer)
      final isAdhanEnabled = prefs.getBool('adhan_enabled_$key') ?? true;

      if (isAdhanEnabled) {
        // Create specific details for this prayer to use its specific channel
        final adhanDetails = NotificationDetails(
            android: AndroidNotificationDetails(
          'adhan_channel_$key', // Use specific channel
          '${AppStrings.notificationAdhanChannelName} - $key',
          channelDescription: AppStrings.notificationAdhanChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          sound: RawResourceAndroidNotificationSound(
              'adhan_$key'), // Specific sound
          playSound: true,
        ));

        tz.TZDateTime adhanTime = tz.TZDateTime.from(todayTime, tz.local);
        if (adhanTime.isBefore(now)) {
          adhanTime = tz.TZDateTime.from(tomorrowTime, tz.local);
        }
        if (adhanTime.isAfter(now)) {
          final baseId = item['id'] as int;
          await flutterLocalNotificationsPlugin.zonedSchedule(
            baseId + 100,
            AppStrings.timeForAdhan,
            "${AppStrings.nowPrayer} $name",
            adhanTime,
            adhanDetails,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      }
    }
  }

  Future<void> scheduleDhikrNotifications() async {
    const int kDhikrIntervalMinutes = 60;
    const int kDhikrScheduleHours = 48; // Schedule ahead for 48 hours

    // Cancel existing hourly notifications to prevent accumulation
    for (int i = 0; i < 100; i++) {
      try {
        await flutterLocalNotificationsPlugin.cancel(200 + i);
      } catch (_) {}
    }

    final now = tz.TZDateTime.now(tz.local);
    int idCounter = 200;

    // Remove unused details variable if we create it inline below
    // or use it if we want to reuse configuration.
    // For specific titles/messages we're creating new NotificationDetails anyway.

    for (int i = 1; i <= kDhikrScheduleHours; i++) {
      final scheduledTime =
          now.add(Duration(minutes: kDhikrIntervalMinutes * i));

      // Skip very late night hours (e.g., 12 AM to 4 AM) if desired?
      // For now, we will schedule all to ensure "Every hour" request is met.

      final phrase = kDhikrPhrases[(i + now.day) % kDhikrPhrases.length];
      final title = kDhikrTitles[(i + now.hour) % kDhikrTitles.length];

      await flutterLocalNotificationsPlugin.zonedSchedule(
        idCounter++,
        title,
        phrase,
        scheduledTime,
        NotificationDetails(
            android: AndroidNotificationDetails(
          kDhikrChannelId,
          AppStrings.notificationDhikrChannelName,
          channelDescription: AppStrings.notificationDhikrChannelDesc,
          importance: Importance.defaultImportance,
          sound: const RawResourceAndroidNotificationSound(kDhikrSound),
          playSound: true,
          styleInformation: BigTextStyleInformation(phrase),
        )),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  /// Plays a test notification immediately for the specific prayer to verify audio
  Future<void> testAdhanNotification(
      String prayerKey, String prayerName) async {
    final details = NotificationDetails(
        android: AndroidNotificationDetails(
      'adhan_channel_$prayerKey',
      '${AppStrings.notificationAdhanChannelName} - $prayerKey',
      channelDescription: AppStrings.notificationAdhanChannelDesc,
      importance: Importance.high,
      priority: Priority.high,
      sound: RawResourceAndroidNotificationSound('adhan_$prayerKey'),
      playSound: true,
    ));

    await flutterLocalNotificationsPlugin.show(
      888, // Special ID for testing
      "تجربة صوت الأذان",
      "حان الآن وقت صلاة $prayerName",
      details,
    );
  }
}
