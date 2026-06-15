import 'package:adhan/adhan.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/strings.dart';
import 'notification_preferences.dart';
import 'notification_preferences_service.dart';

class AppNotificationService {
  static final AppNotificationService _instance =
      AppNotificationService._internal();

  factory AppNotificationService() => _instance;

  AppNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final NotificationPreferencesService _preferencesService =
      NotificationPreferencesService();
  static const MethodChannel _nativeAdhanChannel =
      MethodChannel('religious_tasks_app/native_adhan');

  bool _isInitialized = false;

  static const String prayerChannelId = 'prayer_reminders';
  static const String prayerReminderSound = 'prayer_reminder';
  static const String adhanChannelId = 'adhan_notifications';
  static const String dhikrChannelId = 'athkar_reminders';
  static const String dhikrSound = 'dhikr_chime';
  static const String notificationChannelVersionKey =
      'notification_channels_v7';

  static const int _dhikrNotificationStartId = 4000;
  static const int _dhikrScheduleWindowMinutes = 48 * 60;
  static const int _maxDhikrScheduleCount = _dhikrScheduleWindowMinutes ~/ 10;
  static const int _morningAthkarNotificationId = 3001;
  static const int _eveningAthkarNotificationId = 3002;

  static const List<String> _dhikrPhrases = [
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
    'رضيت بالله ربًا وبالإسلام دينًا وبمحمد نبيًا',
    'يا حي يا قيوم برحمتك أستغيث',
    'اللهم بارك لي في وقتي وعملي',
    'ربي اغفر لي ولوالدي وللمؤمنين والمؤمنات',
    'اللهم إني أسألك الهدى والتقى والعفاف والغنى',
    'الحمد لله على كل حال',
    'اللهم ارزقني حبك وحب من ينفعني حبه عندك',
    'اللهم أعني على ذكرك وشكرك وحسن عبادتك',
    'سبحان الله عدد ما خلق، سبحان الله ملء ما خلق',
    'استغفر الله العظيم وأتوب إليه',
    'اللهم اجعلنا من الذاكرين الله كثيرًا والذاكرات',
  ];

  static const List<String> _dhikrTitles = [
    'رسالة لك',
    'طهّر لسانك',
    'دقائق من وقتك',
    'زادك للآخرة',
    'همسة إيمانية',
    'ذكر وأجر',
  ];

  Future<void> init() async {
    await _ensureInitialized();
    await syncRecurringSchedules();
  }

  Future<void> syncRecurringSchedules() async {
    await _ensureInitialized();
    final preferences = await _preferencesService.load();
    await scheduleMorningEveningAthkar(settings: preferences);
    await scheduleDhikrNotifications(settings: preferences);
  }

  Future<void> scheduleMorningEveningAthkar({
    NotificationPreferences? settings,
  }) async {
    await _ensureInitialized();
    final preferences = settings ?? await _preferencesService.load();
    final now = tz.TZDateTime.now(tz.local);

    await _plugin.cancel(_morningAthkarNotificationId);
    await _plugin.cancel(_eveningAthkarNotificationId);

    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        dhikrChannelId,
        AppStrings.notificationDhikrChannelName,
        channelDescription: AppStrings.notificationDhikrChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(dhikrSound),
        playSound: true,
      ),
    );

    if (preferences.morningAthkarReminderEnabled) {
      var morningDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 5);
      if (morningDate.isBefore(now)) {
        morningDate = morningDate.add(const Duration(days: 1));
      }

      await _safeZonedSchedule(
        _morningAthkarNotificationId,
        'أذكار الصباح',
        'حان الآن موعد أذكار الصباح',
        morningDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }

    if (preferences.eveningAthkarReminderEnabled) {
      var eveningDate =
          tz.TZDateTime(tz.local, now.year, now.month, now.day, 18, 50);
      if (eveningDate.isBefore(now)) {
        eveningDate = eveningDate.add(const Duration(days: 1));
      }

      await _safeZonedSchedule(
        _eveningAthkarNotificationId,
        'أذكار المساء',
        'حان الآن موعد أذكار المساء',
        eveningDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> schedulePrayerNotifications({
    required PrayerTimes today,
    required PrayerTimes tomorrow,
  }) async {
    await _ensureInitialized();

    final preferences = await _preferencesService.load();
    final now = tz.TZDateTime.now(tz.local);
    final items = [
      {
        'id': 101,
        'key': 'fajr',
        'name': AppStrings.fajr,
        'today': today.fajr,
        'tomorrow': tomorrow.fajr,
      },
      {
        'id': 106,
        'key': 'sunrise',
        'name': AppStrings.sunrise,
        'today': today.sunrise,
        'tomorrow': tomorrow.sunrise,
      },
      {
        'id': 102,
        'key': 'dhuhr',
        'name': AppStrings.dhuhr,
        'today': today.dhuhr,
        'tomorrow': tomorrow.dhuhr,
      },
      {
        'id': 103,
        'key': 'asr',
        'name': AppStrings.asr,
        'today': today.asr,
        'tomorrow': tomorrow.asr,
      },
      {
        'id': 104,
        'key': 'maghrib',
        'name': AppStrings.maghrib,
        'today': today.maghrib,
        'tomorrow': tomorrow.maghrib,
      },
      {
        'id': 105,
        'key': 'isha',
        'name': AppStrings.isha,
        'today': today.isha,
        'tomorrow': tomorrow.isha,
      },
    ];

    for (final item in items) {
      final baseId = item['id'] as int;
      await _plugin.cancel(baseId);
      await _plugin.cancel(baseId + 100);
      await _cancelNativeAdhan(baseId + 100);
    }

    const reminderDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        prayerChannelId,
        AppStrings.notificationPrayerChannelName,
        channelDescription: AppStrings.notificationPrayerChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        sound: RawResourceAndroidNotificationSound(prayerReminderSound),
        playSound: true,
      ),
    );

    for (final item in items) {
      final name = item['name'] as String;
      final key = item['key'] as String;
      final todayTime = item['today'] as DateTime;
      final tomorrowTime = item['tomorrow'] as DateTime;
      final baseId = item['id'] as int;

      var reminderTime = tz.TZDateTime.from(todayTime, tz.local)
          .subtract(const Duration(minutes: 5));
      if (reminderTime.isBefore(now)) {
        reminderTime = tz.TZDateTime.from(tomorrowTime, tz.local)
            .subtract(const Duration(minutes: 5));
      }

      if (reminderTime.isAfter(now)) {
        await _safeZonedSchedule(
          baseId,
          '${AppStrings.remainingTimeTitle} $name',
          AppStrings.prepareForPrayer,
          reminderTime,
          reminderDetails,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }

      if (!preferences.isAdhanEnabled(key)) {
        continue;
      }

      var adhanTime = tz.TZDateTime.from(todayTime, tz.local);
      if (adhanTime.isBefore(now)) {
        adhanTime = tz.TZDateTime.from(tomorrowTime, tz.local);
      }

      if (adhanTime.isAfter(now)) {
        await _scheduleNativeAdhan(
          baseId + 100,
          key,
          name,
          adhanTime.millisecondsSinceEpoch,
        );
      }
    }
  }

  Future<void> scheduleDhikrNotifications({
    NotificationPreferences? settings,
  }) async {
    await _ensureInitialized();
    final preferences = settings ?? await _preferencesService.load();

    try {
      final pendingNotifications = await _plugin.pendingNotificationRequests();
      int cancelCount = 0;

      for (final request in pendingNotifications) {
        final id = request.id;
        bool shouldCancel = false;

        if (id >= 200 && id < 488 && (id < 201 || id > 206)) {
          shouldCancel = true;
        } else if (id >= _dhikrNotificationStartId &&
            id < _dhikrNotificationStartId + _maxDhikrScheduleCount) {
          shouldCancel = true;
        }

        if (shouldCancel) {
          await _plugin.cancel(id);
          cancelCount++;
          // Yield to UI thread every few cancellations to prevent jank
          if (cancelCount % 3 == 0) {
            await Future.delayed(const Duration(milliseconds: 10));
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to cancel old dhikr notifications: $e');
    }

    if (!preferences.hourlyDhikrEnabled) {
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    final intervalMinutes = preferences.hourlyDhikrIntervalMinutes;

    // Calculate how many to schedule, but cap it at 64 to avoid Android limit exceptions
    // Some devices limit the app to 50 or 500 total alarms. 64 is safe and covers ~10 hours even for 10min intervals.
    int reqCount = (_dhikrScheduleWindowMinutes / intervalMinutes).ceil();
    final scheduleCount = reqCount > 64 ? 64 : reqCount;

    for (var i = 1; i <= scheduleCount; i++) {
      final scheduledTime = now.add(Duration(minutes: intervalMinutes * i));
      final phrase = _dhikrPhrases[(i + now.day) % _dhikrPhrases.length];
      final title = _dhikrTitles[(i + now.hour) % _dhikrTitles.length];

      await _safeZonedSchedule(
        _dhikrNotificationStartId + i - 1,
        title,
        phrase,
        scheduledTime,
        NotificationDetails(
          android: AndroidNotificationDetails(
            dhikrChannelId,
            AppStrings.notificationDhikrChannelName,
            channelDescription: AppStrings.notificationDhikrChannelDesc,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            sound: const RawResourceAndroidNotificationSound(dhikrSound),
            playSound: true,
            styleInformation: BigTextStyleInformation(phrase),
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );

      // Yield to UI thread occasionally to prevent scrolling jank
      if (i % 3 == 0) {
        await Future.delayed(const Duration(milliseconds: 10));
      }
    }
  }

  Future<void> testAdhanNotification(
      String prayerKey, String prayerName) async {
    await _ensureInitialized();
    final preferences = await _preferencesService.load();

    if (preferences.adhanSoundType == AdhanSoundType.full) {
      await _playNativeAdhanNow(prayerKey, prayerName);
      return;
    }

    var soundName = 'adhan_$prayerKey';
    if (prayerKey == 'sunrise') {
      soundName = prayerReminderSound;
    }

    final useSound = preferences.adhanSoundType == AdhanSoundType.short;

    final details = NotificationDetails(
      android: AndroidNotificationDetails(
        'adhan_channel_$prayerKey',
        '${AppStrings.notificationAdhanChannelName} - $prayerKey',
        channelDescription: AppStrings.notificationAdhanChannelDesc,
        importance: Importance.high,
        priority: Priority.high,
        sound: useSound ? RawResourceAndroidNotificationSound(soundName) : null,
        playSound: useSound,
      ),
    );

    await _plugin.show(
      888,
      'تجربة صوت الأذان',
      'حان الآن وقت صلاة $prayerName',
      details,
    );
  }

  Future<void> testDhikrNotification() async {
    await _ensureInitialized();

    final phrase = _dhikrPhrases[DateTime.now().minute % _dhikrPhrases.length];
    final title = _dhikrTitles[DateTime.now().hour % _dhikrTitles.length];

    await _plugin.show(
      889,
      title,
      phrase,
      NotificationDetails(
        android: AndroidNotificationDetails(
          dhikrChannelId,
          AppStrings.notificationDhikrChannelName,
          channelDescription: AppStrings.notificationDhikrChannelDesc,
          importance: Importance.high,
          priority: Priority.high,
          sound: const RawResourceAndroidNotificationSound(dhikrSound),
          playSound: true,
          styleInformation: BigTextStyleInformation(phrase),
        ),
      ),
    );
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) {
      return;
    }

    await _configureLocalTimeZone();

    const initializationSettings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    await _plugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (_) {},
    );

    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    await androidPlugin?.requestNotificationsPermission();

    await _resetChannelsIfNeeded(androidPlugin);
    await _createChannels(androidPlugin);

    _isInitialized = true;
  }

  Future<void> _resetChannelsIfNeeded(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    final shouldResetChannels =
        !(sharedPrefs.getBool(notificationChannelVersionKey) ?? false);

    if (!shouldResetChannels) {
      return;
    }

    await androidPlugin?.deleteNotificationChannel(prayerChannelId);
    await androidPlugin?.deleteNotificationChannel(adhanChannelId);
    await androidPlugin?.deleteNotificationChannel(dhikrChannelId);

    for (final prayerKey in NotificationPreferencesService.prayerKeys) {
      await androidPlugin
          ?.deleteNotificationChannel('adhan_channel_$prayerKey');
    }

    await _plugin.cancelAll();
    await sharedPrefs.setBool(notificationChannelVersionKey, true);
  }

  Future<void> _createChannels(
    AndroidFlutterLocalNotificationsPlugin? androidPlugin,
  ) async {
    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        prayerChannelId,
        AppStrings.notificationPrayerChannelName,
        description: AppStrings.notificationPrayerChannelDesc,
        importance: Importance.high,
        sound: RawResourceAndroidNotificationSound(prayerReminderSound),
        playSound: true,
      ),
    );

    await androidPlugin?.createNotificationChannel(
      const AndroidNotificationChannel(
        dhikrChannelId,
        AppStrings.notificationDhikrChannelName,
        description: AppStrings.notificationDhikrChannelDesc,
        importance: Importance.defaultImportance,
        sound: RawResourceAndroidNotificationSound(dhikrSound),
        playSound: true,
      ),
    );

    for (final prayerKey in NotificationPreferencesService.prayerKeys) {
      var soundName = 'adhan_$prayerKey';
      if (prayerKey == 'sunrise') {
        soundName = prayerReminderSound;
      }

      await androidPlugin?.createNotificationChannel(
        AndroidNotificationChannel(
          'adhan_channel_$prayerKey',
          '${AppStrings.notificationAdhanChannelName} - $prayerKey',
          description: AppStrings.notificationAdhanChannelDesc,
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound(soundName),
          playSound: true,
        ),
      );
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      tz_data.initializeTimeZones();
      final rawTimeZone = await FlutterTimezone.getLocalTimezone();
      var timeZoneName = rawTimeZone.toString();

      if (timeZoneName.startsWith('TimezoneInfo(')) {
        final parts = timeZoneName.split(',');
        if (parts.isNotEmpty) {
          timeZoneName = parts[0].replaceAll('TimezoneInfo(', '').trim();
        }
      }

      try {
        tz.setLocalLocation(tz.getLocation(timeZoneName));
      } catch (_) {
        if (timeZoneName.contains('Cairo') || timeZoneName.contains('Egypt')) {
          tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
        } else {
          tz.setLocalLocation(tz.getLocation('UTC'));
        }
      }
    } catch (error) {
      debugPrint('Failed to set location: $error');
      try {
        tz.setLocalLocation(tz.getLocation('UTC'));
      } catch (_) {}
    }
  }

  Future<void> _safeZonedSchedule(
    int id,
    String? title,
    String? body,
    tz.TZDateTime scheduledDate,
    NotificationDetails notificationDetails, {
    required AndroidScheduleMode androidScheduleMode,
    DateTimeComponents? matchDateTimeComponents,
  }) async {
    try {
      await _plugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        notificationDetails,
        androidScheduleMode: androidScheduleMode,
        matchDateTimeComponents: matchDateTimeComponents,
      );
    } catch (e) {
      if (androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        // Fallback to inexact if exact alarms are denied by Android 14+
        try {
          await _plugin.zonedSchedule(
            id,
            title,
            body,
            scheduledDate,
            notificationDetails,
            androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
            matchDateTimeComponents: matchDateTimeComponents,
          );
        } catch (e2) {
          debugPrint('Failed to schedule inexact fallback for $id: $e2');
        }
      } else {
        debugPrint('Failed to schedule exact notification $id: $e');
      }
    }
  }

  Future<void> _scheduleNativeAdhan(
    int requestCode,
    String prayerKey,
    String prayerName,
    int timeMillis,
  ) async {
    try {
      await _nativeAdhanChannel.invokeMethod<void>('schedule', {
        'requestCode': requestCode,
        'prayerKey': prayerKey,
        'prayerName': prayerName,
        'timeMillis': timeMillis,
      });
    } catch (e) {
      debugPrint('Failed to schedule native adhan $requestCode: $e');
    }
  }

  Future<void> _cancelNativeAdhan(int requestCode) async {
    try {
      await _nativeAdhanChannel.invokeMethod<void>('cancel', {
        'requestCode': requestCode,
      });
    } catch (e) {
      debugPrint('Failed to cancel native adhan $requestCode: $e');
    }
  }

  Future<void> _playNativeAdhanNow(String prayerKey, String prayerName) async {
    try {
      await _nativeAdhanChannel.invokeMethod<void>('playNow', {
        'prayerKey': prayerKey,
        'prayerName': prayerName,
      });
    } catch (e) {
      debugPrint('Failed to play native adhan now: $e');
    }
  }
}
