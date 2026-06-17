import 'dart:convert';
import 'package:adhan/adhan.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart' as overlay;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../../core/constants/strings.dart';
import '../audio/radio_service.dart';
import 'notification_preferences.dart';
import 'notification_preferences_service.dart';
import 'dhikr_background_refresher.dart';

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
  Future<void>? _initFuture;

  static const String prayerChannelId = 'prayer_reminders';
  static const String prayerReminderSound = 'prayer_reminder';
  static const String adhanChannelId = 'adhan_notifications';
  static const String dhikrChannelId = 'athkar_reminders_v3';
  static const String dhikrSound = 'dhikr_chime';
  static const String notificationChannelVersionKey =
      'notification_channels_v12';

  static const int _dhikrNotificationStartId = 4000;
  static const int _dhikrScheduleWindowMinutes = 48 * 60;
  static const int _morningAthkarNotificationId = 3001;
  static const int _eveningAthkarNotificationId = 3002;
  static const int _dhikrAlarmId = 5000;
  static const String dhikrCycleStartTimeKey = 'dhikr_cycle_start_time';
  static const String customDhikrKey = 'user_custom_dhikrs_v1';

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

    final details = _buildDhikrNotificationDetails();

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
      {'id': 101, 'key': 'fajr', 'name': AppStrings.fajr, 'today': today.fajr, 'tomorrow': tomorrow.fajr},
      {'id': 106, 'key': 'sunrise', 'name': AppStrings.sunrise, 'today': today.sunrise, 'tomorrow': tomorrow.sunrise},
      {'id': 102, 'key': 'dhuhr', 'name': AppStrings.dhuhr, 'today': today.dhuhr, 'tomorrow': tomorrow.dhuhr},
      {'id': 103, 'key': 'asr', 'name': AppStrings.asr, 'today': today.asr, 'tomorrow': tomorrow.asr},
      {'id': 104, 'key': 'maghrib', 'name': AppStrings.maghrib, 'today': today.maghrib, 'tomorrow': tomorrow.maghrib},
      {'id': 105, 'key': 'isha', 'name': AppStrings.isha, 'today': today.isha, 'tomorrow': tomorrow.isha},
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

      // 1. Reminder (5 min before)
      var reminderTime = tz.TZDateTime.from(todayTime, tz.local).subtract(const Duration(minutes: 5));
      if (reminderTime.isBefore(now)) {
        reminderTime = tz.TZDateTime.from(tomorrowTime, tz.local).subtract(const Duration(minutes: 5));
      }

      if (reminderTime.isAfter(now)) {
        await _safeZonedSchedule(baseId, '${AppStrings.remainingTimeTitle} $name', AppStrings.prepareForPrayer, reminderTime, reminderDetails, androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle);
      }

      // 2. Adhan Notification (at time)
      if (!preferences.isAdhanEnabled(key)) continue;

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
          preferences.adhanSoundType.index,
          preferences.selectedMoazzenId,
        );
      }
    }
  }

  Future<void> scheduleDhikrNotifications({
    NotificationPreferences? settings,
    bool forceReschedule = false,
  }) async {
    await _ensureInitialized();
    final preferences = settings ?? await _preferencesService.load();
    final sharedPrefs = await SharedPreferences.getInstance();
    
    final savedInterval = sharedPrefs.getInt('saved_dhikr_interval');
    final savedStartTime = sharedPrefs.getInt(dhikrCycleStartTimeKey);

    bool intervalChanged = savedInterval != preferences.hourlyDhikrIntervalMinutes;
    bool shouldInitCycle = savedStartTime == null || intervalChanged || forceReschedule;

    if (!preferences.hourlyDhikrEnabled) {
      await AndroidAlarmManager.cancel(_dhikrAlarmId);
      await AndroidAlarmManager.cancel(DhikrBackgroundRefresher.refreshAlarmId);
      await closeDhikrOverlay();
      await _cancelAllDhikrNotifications();
      return;
    }

    if (shouldInitCycle) {
      final now = tz.TZDateTime.now(tz.local);
      await sharedPrefs.setInt(dhikrCycleStartTimeKey, now.millisecondsSinceEpoch);
      await sharedPrefs.setInt('saved_dhikr_interval', preferences.hourlyDhikrIntervalMinutes);
      
      await AndroidAlarmManager.cancel(_dhikrAlarmId);
      await _cancelAllDhikrNotifications();

      await AndroidAlarmManager.periodic(
        const Duration(hours: 4),
        DhikrBackgroundRefresher.refreshAlarmId,
        DhikrBackgroundRefresher.refreshCallback,
        exact: false,
        wakeup: false,
        rescheduleOnReboot: true,
      );
    }

    await AndroidAlarmManager.cancel(_dhikrAlarmId);
    await closeDhikrOverlay();

    // Always schedule standard notifications if enabled
    final now = tz.TZDateTime.now(tz.local);
    final intervalMinutes = preferences.hourlyDhikrIntervalMinutes;

    final cycleStartMillis =
        sharedPrefs.getInt(dhikrCycleStartTimeKey) ?? now.millisecondsSinceEpoch;
    final cycleStart =
        tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, cycleStartMillis);
    final intervalSeconds = intervalMinutes * 60;
    final secondsSinceStart = now.difference(cycleStart).inSeconds;
    final elapsedCycles =
        secondsSinceStart < 0 ? 0 : (secondsSinceStart ~/ intervalSeconds);
    final lastGridPoint =
        cycleStart.add(Duration(seconds: elapsedCycles * intervalSeconds));

    final customDhikrsJson = sharedPrefs.getString(customDhikrKey);
    final List<String> userDhikrs = customDhikrsJson != null
        ? List<String>.from(jsonDecode(customDhikrsJson))
        : [];
    final allPhrases = [..._dhikrPhrases, ...userDhikrs];

    int reqCount = (_dhikrScheduleWindowMinutes / intervalMinutes).ceil();
    final scheduleCount = reqCount > 64 ? 64 : reqCount;

    for (var i = 1; i <= scheduleCount; i++) {
      final scheduledTime =
          lastGridPoint.add(Duration(minutes: intervalMinutes * i));
      if (scheduledTime.isBefore(now.add(const Duration(seconds: 5)))) continue;

      String phrase = scheduledTime.weekday == DateTime.friday
          ? 'اللهم صل وسلم على نبينا محمد'
          : allPhrases[(i + scheduledTime.day) % allPhrases.length];
      final title = _dhikrTitles[(i + scheduledTime.hour) % _dhikrTitles.length];

      await _safeZonedSchedule(
        _dhikrNotificationStartId + i - 1,
        title,
        phrase,
        scheduledTime,
        _buildDhikrNotificationDetails(phrase: phrase),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    }
  }

  Future<void> _cancelAllDhikrNotifications() async {
    try {
      // Loop through potential IDs instead of querying which can be flaky
      for (int i = 0; i < 100; i++) {
        await _plugin.cancel(_dhikrNotificationStartId + i);
      }
    } catch (e) {
      debugPrint('Error canceling dhikr notifications: $e');
    }
  }

  @pragma('vm:entry-point')
  static Future<void> dhikrAlarmCallback() async {
    try {
      final sharedPrefs = await SharedPreferences.getInstance();
      final customDhikrsJson = sharedPrefs.getString(customDhikrKey);
      final List<String> userDhikrs = customDhikrsJson != null ? List<String>.from(jsonDecode(customDhikrsJson)) : [];
      final allPhrases = [..._dhikrPhrases, ...userDhikrs];
      
      final now = DateTime.now();
      String phrase = now.weekday == DateTime.friday ? 'اللهم صل وسلم على نبينا محمد' : allPhrases[now.minute % allPhrases.length];

      await _showFloatingDhikrText(phrase);
    } catch (e) {
      debugPrint("Dhikr alarm callback failed: $e");
    }
  }

  Future<bool> ensureFloatingDhikrPermission() async {
    try {
      if (await overlay.FlutterOverlayWindow.isPermissionGranted()) return true;
      await overlay.FlutterOverlayWindow.requestPermission();
      return await overlay.FlutterOverlayWindow.isPermissionGranted();
    } catch (e) {
      return false;
    }
  }

  Future<void> closeDhikrOverlay() async {
    if (await overlay.FlutterOverlayWindow.isActive()) {
      await overlay.FlutterOverlayWindow.closeOverlay();
    }
  }

  static Future<void> _showFloatingDhikrText(String text) async {
    if (!(await overlay.FlutterOverlayWindow.isPermissionGranted())) return;

    if (await overlay.FlutterOverlayWindow.isActive()) {
      await overlay.FlutterOverlayWindow.shareData(text);
      return;
    }

    await overlay.FlutterOverlayWindow.showOverlay(
      enableDrag: true,
      overlayTitle: "الذكر اليومي",
      overlayContent: text,
      flag: overlay.OverlayFlag.defaultFlag,
      alignment: overlay.OverlayAlignment.topRight,
      visibility: overlay.NotificationVisibility.visibilityPublic,
      positionGravity: overlay.PositionGravity.right,
      height: 200,
      width: 800,
    );

    // Give some time for overlay to initialize before sharing data
    await Future.delayed(const Duration(milliseconds: 600));
    await overlay.FlutterOverlayWindow.shareData(text);
  }

  Future<void> testAdhanNotification(String prayerKey, String prayerName) async {
    await _ensureInitialized();
    final preferences = await _preferencesService.load();
    await _playNativeAdhanNow(prayerKey, prayerName, preferences.adhanSoundType.index, preferences.selectedMoazzenId);
  }

  Future<void> testDhikrNotification() async {
    try {
      await _ensureInitialized();
      final phrase = _dhikrPhrases[DateTime.now().minute % _dhikrPhrases.length];

      try {
        await _plugin.show(
          889,
          _dhikrTitles[DateTime.now().hour % _dhikrTitles.length],
          phrase,
          _buildDhikrNotificationDetails(
            phrase: phrase,
            fullScreenIntent: false,
          ),
        );
      } catch (e) {
        if (!_isInvalidSoundError(e)) rethrow;
        // Fallback without custom sound if the sound resource is problematic
        await _plugin.show(
          889,
          _dhikrTitles[DateTime.now().hour % _dhikrTitles.length],
          phrase,
          _buildDhikrNotificationDetails(
            phrase: phrase,
            useCustomSound: false,
            fullScreenIntent: false,
          ),
        );
      }
    } catch (e, stack) {
      debugPrint('Error in testDhikrNotification: $e\n$stack');
      rethrow;
    }
  }

  Future<void> _ensureInitialized() async {
    if (_isInitialized) return;
    if (_initFuture != null) return _initFuture;
    _initFuture = _doInitialize();
    await _initFuture;
    _isInitialized = true;
    _initFuture = null;
  }

  Future<void> _doInitialize() async {
    await _configureLocalTimeZone();
    const initializationSettings = InitializationSettings(android: AndroidInitializationSettings('@mipmap/ic_launcher'));
    await _plugin.initialize(initializationSettings);
    
    final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    await _resetChannelsIfNeeded(androidPlugin);
    await _createChannels(androidPlugin);
  }

  Future<void> _resetChannelsIfNeeded(AndroidFlutterLocalNotificationsPlugin? androidPlugin) async {
    final sharedPrefs = await SharedPreferences.getInstance();
    if (sharedPrefs.getBool(notificationChannelVersionKey) ?? false) return;

    await androidPlugin?.deleteNotificationChannel(prayerChannelId);
    await androidPlugin?.deleteNotificationChannel(adhanChannelId);
    await androidPlugin?.deleteNotificationChannel(dhikrChannelId);
    await _plugin.cancelAll();
    await sharedPrefs.setBool(notificationChannelVersionKey, true);
  }

  Future<void> _createChannels(AndroidFlutterLocalNotificationsPlugin? androidPlugin) async {
    try {
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          prayerChannelId,
          AppStrings.notificationPrayerChannelName,
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound(prayerReminderSound),
          playSound: true,
        ),
      );
    } catch (e) {
      if (!_isInvalidSoundError(e)) rethrow;
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          prayerChannelId,
          AppStrings.notificationPrayerChannelName,
          importance: Importance.max,
          playSound: true,
        ),
      );
    }

    try {
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          dhikrChannelId,
          AppStrings.notificationDhikrChannelName,
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound(dhikrSound),
          playSound: true,
        ),
      );
    } catch (e) {
      if (!_isInvalidSoundError(e)) rethrow;
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          dhikrChannelId,
          AppStrings.notificationDhikrChannelName,
          importance: Importance.max,
          playSound: true,
        ),
      );
    }
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      tz_data.initializeTimeZones();
      final dynamic res = await FlutterTimezone.getLocalTimezone();
      // استخراج الاسم سواء كان الرد نصاً أو كائناً
      final String timeZoneName = res is String ? res : res.name.toString();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      try {
        tz.setLocalLocation(tz.getLocation('Africa/Cairo'));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('UTC'));
      }
    }
  }

  Future<void> _safeZonedSchedule(int id, String? title, String? body, tz.TZDateTime scheduledDate, NotificationDetails details, {required AndroidScheduleMode androidScheduleMode, DateTimeComponents? matchDateTimeComponents}) async {
    try {
      await _plugin.zonedSchedule(id, title, body, scheduledDate, details, androidScheduleMode: androidScheduleMode, matchDateTimeComponents: matchDateTimeComponents);
    } catch (e) {
      if (_isInvalidSoundError(e)) {
        final fallbackDetails = body == null
            ? _buildDhikrNotificationDetails(useCustomSound: false)
            : _buildDhikrNotificationDetails(
                phrase: body,
                useCustomSound: false,
              );
        await _plugin.zonedSchedule(id, title, body, scheduledDate, fallbackDetails, androidScheduleMode: androidScheduleMode, matchDateTimeComponents: matchDateTimeComponents);
        return;
      }
      if (androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        await _plugin.zonedSchedule(id, title, body, scheduledDate, details, androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle, matchDateTimeComponents: matchDateTimeComponents);
      }
    }
  }

  NotificationDetails _buildDhikrNotificationDetails({
    String? phrase,
    bool useCustomSound = true,
    bool? fullScreenIntent,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        dhikrChannelId,
        AppStrings.notificationDhikrChannelName,
        channelDescription: AppStrings.notificationDhikrChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        sound: useCustomSound
            ? const RawResourceAndroidNotificationSound(dhikrSound)
            : null,
        playSound: true,
        styleInformation:
            phrase != null ? BigTextStyleInformation(phrase) : null,
        visibility: NotificationVisibility.public,
        fullScreenIntent: fullScreenIntent ?? false,
      ),
    );
  }

  bool _isInvalidSoundError(Object error) {
    return error is PlatformException && error.code == 'invalid_sound';
  }

  Future<void> _scheduleNativeAdhan(int requestCode, String prayerKey, String prayerName, int timeMillis, int soundType, String moazzenId) async {
    // Pause Radio if it's playing before Adhan
    if (RadioService().player.playing) {
      await RadioService().pause();
      // Schedule a resume after typical adhan duration (approx 4 minutes)
      Future.delayed(const Duration(minutes: 4), () {
        RadioService().resume();
      });
    }
    await _nativeAdhanChannel.invokeMethod<void>('schedule', {
      'requestCode': requestCode,
      'prayerKey': prayerKey,
      'prayerName': prayerName,
      'timeMillis': timeMillis,
      'soundType': soundType,
      'moazzenId': moazzenId,
    });
  }

  Future<void> _cancelNativeAdhan(int requestCode) async {
    await _nativeAdhanChannel.invokeMethod<void>('cancel', {'requestCode': requestCode});
  }

  Future<void> _playNativeAdhanNow(String prayerKey, String prayerName, int soundType, String moazzenId) async {
    if (RadioService().player.playing) {
      await RadioService().pause();
    }
    await _nativeAdhanChannel.invokeMethod<void>('playNow', {
      'prayerKey': prayerKey,
      'prayerName': prayerName,
      'soundType': soundType,
      'moazzenId': moazzenId,
    });
  }
}
