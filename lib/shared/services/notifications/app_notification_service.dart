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

  Future<void> stopAdhanAudio() async {
    try {
      await _nativeAdhanChannel.invokeMethod('cancel', {'requestCode': 9999});
    } catch (e) {
      debugPrint("Error stopping adhan audio: $e");
    }
  }

  static const String prayerChannelId = 'prayer_reminders';
  static const String prayerReminderSound = 'prayer_reminder';
  static const String adhanChannelId = 'adhan_notifications';
  static const String dhikrChannelId = 'athkar_reminders_v3';
  static const String dhikrSound = 'dhikr_chime';
  static const String salawatChannelId = 'salawat_notifications_v1';
  static const String salawatSound = 'salawat_sound';
  static const String notificationChannelVersionKey =
      'notification_channels_v18';

  static const int _dhikrNotificationStartId = 4000;
  static const int _salawatNotificationStartId = 6000;
  static const int _dhikrScheduleWindowMinutes = 48 * 60;
  static const int _morningAthkarNotificationId = 3001;
  static const int _eveningAthkarNotificationId = 3002;
  static const int _dhikrAlarmId = 5000;
  static const String dhikrCycleStartTimeKey = 'dhikr_cycle_start_time';
  static const String salawatCycleStartTimeKey = 'salawat_cycle_start_time';
  static const String customDhikrKey = 'user_custom_dhikrs_v1';

  static const List<String> _dhikrPhrases = [
    'سُبْحَانَ اللَّهِ',
    'الْحَمْدُ لِلَّهِ',
    'اللَّهُ أَكْبَرُ',
    'لَا إِلَٰهَ إِلَّا اللَّهُ',
    'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ',
    'سُبْحَانَ اللَّهِ الْعَظِيمِ',
    'أَسْتَغْفِرُ اللَّهَ',
    'لَا حَوْلَ وَلَا قُوَّةَ إِلَّا بِاللَّهِ',
    'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ',
    'لَا إِلَٰهَ إِلَّا أَنْتَ سُبْحَانَكَ إِنِّي كُنْتُ مِنَ الظَّالِمِينَ',
    'حَسْبِيَ اللَّهُ لَا إِلَهَ إِلَّا هُوَ عَلَيْهِ تَوَكَّلْتُ',
    'اللَّهُمَّ إِنَّكَ عَفُوٌّ تُحِبُّ الْعَفْوَ فَاعْفُ عَنِّي',
    'رَضِيتُ بِاللَّهِ رَبًّا وَبِالْإِسْلَامِ دِينًا وَبِمُحَمَّدٍ نَبِيًّا',
    'يَا حَيُّ يَا قَيُّومُ بِرَحْمَتِكَ أَسْتَغِيثُ',
    'اللَّهُمَّ بَارِكْ لِي فِي وَقْتِي وَعَمَلِي',
    'رَبِّ اغْفِرْ لِي وَلِوَالِدَيَّ وَلِلْمُؤْمِنِينَ وَالْمُؤْمِنَاتِ',
    'اللَّهُمَّ إِنِّي أَسْأَلُكَ الْهُدَى وَالتُّقَى وَالْعَفَافَ وَالْغِنَى',
    'الْحَمْدُ لِلَّهِ عَلَى كُلِّ حَالٍ',
    'اللَّهُمَّ ارْزُقْنِي حُبَّكَ وَحُبَّ مَنْ يَنْفَعُنِي حُبُّهُ عِنْدَكَ',
    'اللَّهُمَّ أَعِنِّي عَلَى ذِكْرِكَ وَشُكْرِكَ وَحُسْنِ عِبَادَتِكَ',
    'سُبْحَانَ اللَّهِ عَدَدَ مَا خَلَقَ، سُبْحَانَ اللَّهِ مِلْءَ مَا خَلَقَ',
    'أَسْتَغْفِرُ اللَّهَ الْعَظِيمَ وَأَتُوبُ إِلَيْهِ',
    'اللَّهُمَّ اجْعَلْنَا مِنَ الذَّاكِرِينَ اللَّهَ كَثِيرًا وَالذَّاكِرَاتِ',
  ];

  static const List<String> _dhikrTitles = [
    'رِسَالَةٌ لَكَ',
    'طَهِّرْ لِسَانَكَ',
    'دَقَائِقُ مِنْ وَقْتِكَ',
    'زَادُكَ لِلْآخِرَةِ',
    'هَمْسَةٌ إِيمَانِيَّةٌ',
    'ذِكْرٌ وَأَجْرٌ',
  ];

  Future<void> init() async {
    await _ensureInitialized();
    await syncRecurringSchedules();
    await reschedulePrayerNotificationsFromSavedLocation();
  }

  Future<void> syncRecurringSchedules() async {
    await _ensureInitialized();
    final preferences = await _preferencesService.load();
    await scheduleMorningEveningAthkar(settings: preferences);
    await scheduleDhikrNotifications(settings: preferences, forceReschedule: true);
    await scheduleSalawatNotifications(settings: preferences, forceReschedule: true);
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
        'أَذْكَارُ الصَّبَاحِ',
        'حَانَ الْآنَ مَوْعِدُ أَذْكَارِ الصَّبَاحِ',
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
        'أَذْكَارُ الْمَسَاءِ',
        'حَانَ الْآنَ مَوْعِدُ أَذْكَارِ الْمَسَاءِ',
        eveningDate,
        details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  Future<void> reschedulePrayerNotificationsFromSavedLocation() async {
    try {
      await _ensureInitialized();
      final prefs = await SharedPreferences.getInstance();
      final latStr = prefs.getString('last_latitude');
      final lngStr = prefs.getString('last_longitude');

      if (latStr == null || lngStr == null) {
        debugPrint("Skipping prayer reschedule: No saved location");
        return;
      }

      final lat = double.tryParse(latStr);
      final lng = double.tryParse(lngStr);

      if (lat == null || lng == null) return;

      final coordinates = Coordinates(lat, lng);
      
      // Use saved calculation method or default to Egyptian
      final savedMethod = prefs.getString('calculation_method');
      CalculationMethod method = CalculationMethod.egyptian;
      if (savedMethod != null) {
        try {
          method = CalculationMethod.values.firstWhere((e) => e.name == savedMethod);
        } catch (_) {}
      }
      
      final params = method.getParameters();
      params.madhab = Madhab.shafi;
      
      // Load offsets
      final notificationPrefs = await _preferencesService.load();
      params.adjustments.fajr = notificationPrefs.getPrayerOffset('fajr');
      params.adjustments.sunrise = notificationPrefs.getPrayerOffset('sunrise');
      params.adjustments.dhuhr = notificationPrefs.getPrayerOffset('dhuhr');
      params.adjustments.asr = notificationPrefs.getPrayerOffset('asr');
      params.adjustments.maghrib = notificationPrefs.getPrayerOffset('maghrib');
      params.adjustments.isha = notificationPrefs.getPrayerOffset('isha');

      final todayTimes = PrayerTimes.today(coordinates, params);
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final tomorrowTimes = PrayerTimes(
        coordinates,
        DateComponents(tomorrow.year, tomorrow.month, tomorrow.day),
        params,
      );
      final afterTomorrow = DateTime.now().add(const Duration(days: 2));
      final afterTomorrowTimes = PrayerTimes(
        coordinates,
        DateComponents(afterTomorrow.year, afterTomorrow.month, afterTomorrow.day),
        params,
      );

      await schedulePrayerNotifications(
        today: todayTimes,
        tomorrow: tomorrowTimes,
        afterTomorrow: afterTomorrowTimes,
      );
      debugPrint("✅ Background prayer reschedule completed");
    } catch (e) {
      debugPrint("Failed to reschedule prayers in background: $e");
    }
  }

  Future<void> schedulePrayerNotifications({
    required PrayerTimes today,
    required PrayerTimes tomorrow,
    PrayerTimes? afterTomorrow,
  }) async {
    await _ensureInitialized();

    final preferences = await _preferencesService.load();
    final now = tz.TZDateTime.now(tz.local);
    
    // We will schedule for today, tomorrow, and optionally afterTomorrow
    final days = [
      {'times': today, 'suffix': 0},
      {'times': tomorrow, 'suffix': 1000},
    ];
    if (afterTomorrow != null) {
      days.add({'times': afterTomorrow, 'suffix': 2000});
    }

    final prayerKeys = ['fajr', 'sunrise', 'dhuhr', 'asr', 'maghrib', 'isha'];
    final prayerNames = [AppStrings.fajr, AppStrings.sunrise, AppStrings.dhuhr, AppStrings.asr, AppStrings.maghrib, AppStrings.isha];
    final baseIds = [101, 106, 102, 103, 104, 105];

    // Clear old notifications for the range we are about to set
    for (var day in days) {
      final suffix = day['suffix'] as int;
      for (var id in baseIds) {
        await _plugin.cancel(id + suffix); // Reminder ID
        await _plugin.cancel(id + 100 + suffix); // Adhan ID
        await _cancelNativeAdhan(id + 100 + suffix);
      }
    }

    const reminderDetails = NotificationDetails(
      android: AndroidNotificationDetails(
        prayerChannelId,
        AppStrings.notificationPrayerChannelName,
        channelDescription: AppStrings.notificationPrayerChannelDesc,
        importance: Importance.max,
        priority: Priority.max,
        sound: RawResourceAndroidNotificationSound(prayerReminderSound),
        playSound: true,
      ),
    );

    for (var day in days) {
      final times = day['times'] as PrayerTimes;
      final suffix = day['suffix'] as int;

      for (int i = 0; i < prayerKeys.length; i++) {
        final key = prayerKeys[i];
        final name = prayerNames[i];
        final baseId = baseIds[i];
        final prayerTime = times.timeForPrayer(Prayer.values.firstWhere((e) => e.name == key, orElse: () => Prayer.none));
        
        if (prayerTime == null) continue;
        
        final tzPrayerTime = tz.TZDateTime.from(prayerTime, tz.local);
        if (tzPrayerTime.isBefore(now)) continue;

        // 1. Reminder (5 min before) - Only if it's not Sunrise
        if (key != 'sunrise') {
          final reminderTime = tzPrayerTime.subtract(const Duration(minutes: 5));
          if (reminderTime.isAfter(now)) {
            await _safeZonedSchedule(
              baseId + suffix,
              '${AppStrings.remainingTimeTitle} $name',
              AppStrings.prepareForPrayer,
              reminderTime,
              reminderDetails,
              androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
            );
          }
        }

        // 2. Adhan Notification
        if (!preferences.isAdhanEnabled(key)) continue;

        await _scheduleNativeAdhan(
          baseId + 100 + suffix,
          key,
          name,
          tzPrayerTime.millisecondsSinceEpoch,
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
          ? 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ'
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
      String phrase = now.weekday == DateTime.friday ? 'اللَّهُمَّ صَلِّ وَسَلِّمْ عَلَى نَبِيِّنَا مُحَمَّدٍ' : allPhrases[now.minute % allPhrases.length];

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

  Future<void> scheduleSalawatNotifications({
    NotificationPreferences? settings,
    bool forceReschedule = false,
  }) async {
    await _ensureInitialized();
    final preferences = settings ?? await _preferencesService.load();
    final sharedPrefs = await SharedPreferences.getInstance();

    final savedInterval = sharedPrefs.getInt('saved_salawat_interval');
    final savedStartTime = sharedPrefs.getInt(salawatCycleStartTimeKey);

    bool intervalChanged = savedInterval != preferences.salawatIntervalMinutes;
    bool shouldInitCycle = savedStartTime == null || intervalChanged || forceReschedule;

    if (!preferences.salawatReminderEnabled) {
      await _cancelAllSalawatNotifications();
      return;
    }

    if (shouldInitCycle) {
      final now = tz.TZDateTime.now(tz.local);
      await sharedPrefs.setInt(salawatCycleStartTimeKey, now.millisecondsSinceEpoch);
      await sharedPrefs.setInt('saved_salawat_interval', preferences.salawatIntervalMinutes);
      await _cancelAllSalawatNotifications();
    }

    final now = tz.TZDateTime.now(tz.local);
    final intervalMinutes = preferences.salawatIntervalMinutes;

    final cycleStartMillis =
        sharedPrefs.getInt(salawatCycleStartTimeKey) ?? now.millisecondsSinceEpoch;
    final cycleStart =
        tz.TZDateTime.fromMillisecondsSinceEpoch(tz.local, cycleStartMillis);
    final intervalSeconds = intervalMinutes * 60;
    final secondsSinceStart = now.difference(cycleStart).inSeconds;
    final elapsedCycles =
        secondsSinceStart < 0 ? 0 : (secondsSinceStart ~/ intervalSeconds);
    final lastGridPoint =
        cycleStart.add(Duration(seconds: elapsedCycles * intervalSeconds));

    int reqCount = (_dhikrScheduleWindowMinutes / intervalMinutes).ceil();
    final scheduleCount = reqCount > 64 ? 64 : reqCount;

    for (var i = 1; i <= scheduleCount; i++) {
      final scheduledTime =
          lastGridPoint.add(Duration(minutes: intervalMinutes * i));
      if (scheduledTime.isBefore(now.add(const Duration(seconds: 5)))) continue;

      await _scheduleNativeAdhan(
        _salawatNotificationStartId + i - 1,
        'salawat',
        'الصلاة على النبي',
        scheduledTime.millisecondsSinceEpoch,
        99,
        'default',
      );
    }
  }

  Future<void> _cancelAllSalawatNotifications() async {
    try {
      for (int i = 0; i < 100; i++) {
        await _plugin.cancel(_salawatNotificationStartId + i);
        await _cancelNativeAdhan(_salawatNotificationStartId + i);
      }
    } catch (e) {
      debugPrint('Error canceling salawat notifications: $e');
    }
  }

  Future<void> testSalawatNotification() async {
    try {
      await _ensureInitialized();
      await _nativeAdhanChannel.invokeMethod<void>('playSalawatNow');
    } catch (e, stack) {
      debugPrint('Error in testSalawatNotification: $e\n$stack');
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
    await androidPlugin?.deleteNotificationChannel(salawatChannelId);
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

    try {
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          salawatChannelId,
          'تنبيهات الصلاة على النبي',
          description: 'تنبيهات وصوت الصلاة على النبي ﷺ',
          importance: Importance.max,
          sound: RawResourceAndroidNotificationSound(salawatSound),
          playSound: true,
        ),
      );
    } catch (e) {
      if (!_isInvalidSoundError(e)) rethrow;
      await androidPlugin?.createNotificationChannel(
        const AndroidNotificationChannel(
          salawatChannelId,
          'تنبيهات الصلاة على النبي',
          description: 'تنبيهات وصوت الصلاة على النبي ﷺ',
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
