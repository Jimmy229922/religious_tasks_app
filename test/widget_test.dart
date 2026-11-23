import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/athkar/data/athkar_data.dart';
import 'package:religious_tasks_app/features/athkar/screens/duaa_safar_screen.dart';
import 'package:religious_tasks_app/features/athkar/screens/qiyam_layl_screen.dart';
import 'package:religious_tasks_app/features/happiness_jar/data/happiness_jar_data.dart';
import 'package:religious_tasks_app/features/happiness_jar/screens/happiness_jar_screen.dart';
import 'package:religious_tasks_app/features/names_of_allah/screens/names_of_allah_screen.dart';
import 'package:religious_tasks_app/features/prayers/screens/prayer_details_screen.dart';
import 'package:religious_tasks_app/features/qibla/screens/qibla_screen.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/features/radio/providers/radio_view_model.dart';
import 'package:religious_tasks_app/features/radio/screens/radio_screen.dart';
import 'package:religious_tasks_app/features/ruqyah/screens/ruqyah_screen.dart';
import 'package:religious_tasks_app/features/tasbeeh/screens/guided_tasbeeh_screen.dart';
import 'package:religious_tasks_app/features/tasks/providers/tasks_view_model.dart';
import 'package:religious_tasks_app/features/tasks/screens/tasks_screen.dart';
import 'package:religious_tasks_app/features/tasks/widgets/prayers_timeline_section.dart';
import 'package:religious_tasks_app/features/tasks/widgets/quick_access_section.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';
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

  test('ThemeProvider manages accent color, text scale, and OLED black',
      () async {
    final provider = ThemeProvider();

    expect(provider.accentColor, AppAccentColor.royalBlue);
    expect(provider.textScaleFactor, 1.0);
    expect(provider.useOledBlack, isTrue);

    await provider.setAccentColor(AppAccentColor.emerald);
    await provider.setTextScaleFactor(1.16);
    await provider.setUseOledBlack(false);

    expect(provider.accentColor, AppAccentColor.emerald);
    expect(provider.getDynamicSeedColor(12), AppAccentColor.emerald.color);
    expect(provider.textScaleFactor, 1.16);
    expect(provider.useOledBlack, isFalse);

    await provider.resetAppearanceDefaults();
    expect(provider.appThemeMode, AppThemeMode.system);
    expect(provider.accentColor, AppAccentColor.royalBlue);
    expect(provider.textScaleFactor, 1.0);
    expect(provider.useOledBlack, isTrue);
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
    expect(preferences.stopAdhanOnVolumeButton, isFalse);
    expect(preferences.stopSalawatOnVolumeButton, isFalse);
    expect(preferences.happinessJarEnabled, isTrue);
    expect(preferences.happinessJarHour, 17);
    expect(preferences.happinessJarMinute, 0);
    expect(preferences.isAdhanEnabled('fajr'), isTrue);
    expect(preferences.isAdhanEnabled('sunrise'), isFalse);
    expect(preferences.getPrayerOffset('fajr'), 0);
  });

  test('NotificationPreferencesService persists volume-stop and moazzen prefs',
      () async {
    final service = NotificationPreferencesService();

    await service.setSelectedMoazzenId('afasy');
    await service.setStopAdhanOnVolumeButton(true);
    await service.setStopSalawatOnVolumeButton(true);
    await service.setHappinessJarEnabled(false);
    await service.setHappinessJarTime(20, 30);

    final loaded = await service.load();
    expect(loaded.selectedMoazzenId, 'afasy');
    expect(loaded.stopAdhanOnVolumeButton, isTrue);
    expect(loaded.stopSalawatOnVolumeButton, isTrue);
    expect(loaded.happinessJarEnabled, isFalse);
    expect(loaded.happinessJarHour, 20);
    expect(loaded.happinessJarMinute, 30);
  });

  test('HappinessJarData provides rich messages and deterministic daily picks',
      () {
    expect(HappinessJarData.messages.length, greaterThanOrEqualTo(60));

    final day1 = HappinessJarData.getMessageForDate(DateTime(2026, 5, 1));
    final day1Repeat = HappinessJarData.getMessageForDate(DateTime(2026, 5, 1));
    final day2 = HappinessJarData.getMessageForDate(DateTime(2026, 5, 2));

    expect(day1.id, day1Repeat.id);
    expect(day2.id, isNot(day1.id));

    final randomHope = HappinessJarData.getRandomMessage(
      category: HappinessCategory.hope,
      excludeId: 'h1',
    );
    expect(randomHope.category, HappinessCategory.hope);
    expect(randomHope.id, isNot('h1'));

    for (final msg in HappinessJarData.messages) {
      final preview = msg.notificationPreview;
      expect(preview.isNotEmpty, isTrue);
      expect(HappinessMessage.visualLength(preview), lessThanOrEqualTo(38));
      expect(preview.contains('...'), isFalse);
    }
  });

  test('Sleep Athkar places Surah Al-Mulk last and QuranRepository isolates Surah 67',
      () async {
    final sleepAthkar = buildSleepAthkar();
    expect(sleepAthkar, isNotEmpty);
    expect(sleepAthkar.last.text, contains('الْمُلْكِ'));

    final pages = await QuranRepository.getSurahPages(67);
    expect(pages, [562, 563, 564]);

    final page564MulkOnly =
        await QuranRepository.getPageContent(564, onlySurahNumber: 67);
    expect(page564MulkOnly.sections, isNotEmpty);
    expect(
      page564MulkOnly.sections.every((s) => s.surahNumber == 67),
      isTrue,
    );
  });

  test('TasksViewModel updates gratitude counter and cycles blessings', () async {
    await StorageService.init();
    final vm = TasksViewModel();
    addTearDown(vm.dispose);

    final initialBlessing = vm.currentBlessing;
    expect(vm.gratitudeCount, 0);

    await vm.incrementGratitude();
    expect(vm.gratitudeCount, 1);

    vm.cycleBlessing();
    expect(vm.currentBlessing, isNot(initialBlessing));
  });

  test(
      'TasksViewModel.buildContextSuggestions surfaces prayer actions and rich suggestions',
      () async {
    await StorageService.init();
    final vm = TasksViewModel();
    addTearDown(vm.dispose);

    final coords = Coordinates(30.0444, 31.2357);
    final params = CalculationMethod.egyptian.getParameters();
    final date = DateComponents(2026, 11, 20); // Friday
    final times = PrayerTimes(coords, date, params);

    final asrSuggestions = vm.buildContextSuggestions(
      now: times.asr.add(const Duration(minutes: 10)),
      prayerTimes: times,
    );
    expect(asrSuggestions.first.action, ContextSuggestionAction.prayer);
    expect(asrSuggestions.first.prayerName, 'صلاة العصر');
    expect(
      asrSuggestions.any((s) => s.action == ContextSuggestionAction.surahKahf),
      isTrue,
    );
    expect(
      asrSuggestions
          .any((s) => s.action == ContextSuggestionAction.happinessJar),
      isTrue,
    );

    final maghribSuggestions = vm.buildContextSuggestions(
      now: times.maghrib.add(const Duration(minutes: 5)),
      prayerTimes: times,
    );
    expect(maghribSuggestions.first.action, ContextSuggestionAction.prayer);
    expect(maghribSuggestions.first.prayerName, 'صلاة المغرب');
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
    final rangeDay1 = plan.getTodayRange(now: DateTime(2026, 11, 1));
    expect(rangeDay1.firstPage, 1);
    expect(rangeDay1.lastPage, 21);
    expect(rangeDay1.isCompleted, isFalse);
  });

  test('QuranTextFormatter parses Arabic digits and extracts full verse text',
      () {
    expect(QuranTextFormatter.toEnglishDigits('٢٥٥'), '255');
    expect(QuranTextFormatter.parseVerseNumber('١٢'), 12);
    expect(QuranTextFormatter.parseVerseNumber('42'), 42);

    const sample =
        'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ ﴿٢﴾ الرَّحْمَٰنِ الرَّحِيمِ ﴿٣﴾';
    expect(
      QuranTextFormatter.extractFullVerseText(sample, '2'),
      'الْحَمْدُ لِلَّهِ رَبِّ الْعَالَمِينَ',
    );
    expect(
      QuranTextFormatter.extractFullVerseText(sample, '٣'),
      'الرَّحْمَٰنِ الرَّحِيمِ',
    );
  });

  test('QuranRepository resolves verse text, Madani page, and ayah count',
      () async {
    final verseText = await QuranRepository.getVerseText(1, 2);
    expect(verseText, isNotNull);
    expect(verseText, contains('رَبِّ'));

    final page = await QuranRepository.getPageForAyah(2, 255);
    expect(page, 42);

    expect(QuranRepository.getCompletedAyahsCount(1, 7), 7);
    expect(QuranRepository.getCompletedAyahsCount(2, 5), 12);
    expect(QuranRepository.getCompletedAyahsCount(114, 6), 6236);
  });

  test('QiblaMath normalizes angles and avoids 360 wrap-around jumps', () {
    expect(QiblaMath.normalizeAngle(-90), 270);
    expect(QiblaMath.normalizeAngle(-179), 181);
    expect(QiblaMath.normalizeAngle(360), 0);
    expect(QiblaMath.normalizeAngle(365), 5);

    // Crossing North (359 -> 1) should be +2 degrees, not -358
    expect(QiblaMath.shortestSignedDelta(359, 1), 2);
    expect(QiblaMath.shortestSignedDelta(1, 359), -2);

    // Turning from East (90) toward Cairo Qibla (~136) -> turn right (+46)
    final cairoQibla = Qibla(Coordinates(30.0444, 31.2357)).direction;
    expect(cairoQibla, inInclusiveRange(130.0, 142.0));
    final diffFromEast = QiblaMath.shortestSignedDelta(90, cairoQibla);
    expect(diffFromEast, greaterThan(40));
    expect(QiblaMath.isAligned(diffFromEast), isFalse);
    expect(QiblaMath.isAligned(2.5), isTrue);
    expect(QiblaMath.isAligned(-3.5), isTrue);
  });

  testWidgets('Key screens render cleanly in Light Mode with proper contrast',
      (WidgetTester tester) async {
    Widget wrapLight(Widget child) {
      return MaterialApp(
        themeMode: ThemeMode.light,
        theme: ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          scaffoldBackgroundColor: const Color(0xFFF6F7FB),
          cardTheme: const CardThemeData(
            color: Colors.white,
            surfaceTintColor: Colors.transparent,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.black87,
          ),
        ),
        home: child,
      );
    }

    await tester.pumpWidget(wrapLight(const QiyamLaylScreen()));
    await tester.pump();
    final qiyamAppBar = tester.widget<AppBar>(find.byType(AppBar));
    expect(qiyamAppBar.foregroundColor, Colors.white);

    await tester.pumpWidget(wrapLight(const RuqyahScreen()));
    await tester.pump();
    expect(find.text('الرقية الشرعية المكتوبة 📖'), findsOneWidget);

    await tester.pumpWidget(wrapLight(const DuaaSafarScreen()));
    await tester.pump();
    expect(find.text('دعاء السفر'), findsOneWidget);

    await tester.pumpWidget(wrapLight(const GuidedTasbeehScreen()));
    await tester.pump();
    expect(find.text('حلقة ذكر'), findsOneWidget);

    await tester.pumpWidget(wrapLight(const NamesOfAllahScreen()));
    await tester.pump();
    expect(find.text('أسماء الله الحسنى الـ 99'), findsOneWidget);

    await tester.pumpWidget(wrapLight(const PrayerDetailsScreen(
      prayerName: 'الفجر',
    )));
    await tester.pump();
    expect(find.text('أذكار بعد الصلاة'), findsOneWidget);

    await tester.pumpWidget(wrapLight(const HappinessJarScreen()));
    await tester.pump();
    expect(find.text('برطمان السعادة 💛'), findsOneWidget);
    expect(find.text('اسحب رسالة سعادة جديدة ✨'), findsOneWidget);
    expect(find.textContaining('رسالة مبهجة'), findsNothing);
    expect(find.textContaining('إشعار يومي'), findsNothing);

    await tester.tap(find.text('اسحب رسالة سعادة جديدة ✨'));
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('تُفتح لك رسالة سعادة الآن...'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 1050));
    await tester.pump(const Duration(milliseconds: 450));
    expect(find.text('تُفتح لك رسالة سعادة الآن...'), findsNothing);
    expect(find.text('اسحب رسالة سعادة جديدة ✨'), findsOneWidget);

    await tester.pumpWidget(
      wrapLight(
        ChangeNotifierProvider(
          create: (_) => RadioViewModel(),
          child: const RadioScreen(),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('راديو القرآن الكريم'), findsOneWidget);
    expect(find.text('بث مباشر على مدار الساعة'), findsOneWidget);

    await StorageService.init();
    final tasksVm = TasksViewModel();
    try {
      await tester.pumpWidget(
        wrapLight(
          Scaffold(
            body: QuickAccessSection(vm: tasksVm, isDark: false),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('القرآن الكريم'), findsOneWidget);
      expect(find.text('برطمان السعادة'), findsOneWidget);
      expect(find.text('التسبيح'), findsNothing);
    } finally {
      tasksVm.dispose();
    }
  });

  testWidgets(
      'Redesigned TasksScreen handles compact, standard, and tablet widths with large text scale without overflow',
      (WidgetTester tester) async {
    await StorageService.init();
    final themeProvider = ThemeProvider();
    final tasksVm = TasksViewModel();

    final originalOnError = FlutterError.onError;
    final recordedErrors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      recordedErrors.add(details);
    };

    try {
      Future<void> pumpViewport({
        required Size size,
        required double textScale,
        required Brightness brightness,
      }) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(
          ChangeNotifierProvider<TasksViewModel>.value(
            value: tasksVm,
            child: MaterialApp(
              key: ValueKey('$size-$textScale-$brightness'),
              locale: const Locale('ar'),
              supportedLocales: const [Locale('ar')],
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
              theme: ThemeData(
                useMaterial3: true,
                brightness: brightness,
                scaffoldBackgroundColor: brightness == Brightness.dark
                    ? const Color(0xFF0B131E)
                    : const Color(0xFFF6F7FB),
              ),
              builder: (context, child) {
                final mq = MediaQuery.of(context);
                return MediaQuery(
                  data: mq.copyWith(textScaler: TextScaler.linear(textScale)),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              home: TasksScreen(themeProvider: themeProvider),
            ),
          ),
        );
        await tester.pump();
        expect(recordedErrors, isEmpty,
            reason: recordedErrors.map((e) => e.exceptionAsString()).join('\n'));
      }

      // 1. Compact phone + large text scale (1.3x) in Light Mode
      await pumpViewport(
        size: const Size(320, 720),
        textScale: 1.3,
        brightness: Brightness.light,
      );
      expect(find.textContaining('إنجازك اليومي'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('الوصول السريع'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('الوصول السريع'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('واحة الشكر'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('واحة الشكر'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('افتح برطمان السعادة 💛'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('افتح برطمان السعادة 💛'), findsOneWidget);
      expect(recordedErrors, isEmpty,
          reason: recordedErrors.map((e) => e.exceptionAsString()).join('\n'));

      // 2. Standard phone in Dark Mode + Sunnah filter pill
      await pumpViewport(
        size: const Size(390, 844),
        textScale: 1.0,
        brightness: Brightness.dark,
      );
      expect(find.textContaining('إنجازك اليومي'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('السنن والأذكار'),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('السنن والأذكار'), findsOneWidget);
      expect(find.text('المتبقي'), findsOneWidget);
      await tester.tap(find.text('المتبقي'));
      await tester.pump();
      expect(recordedErrors, isEmpty,
          reason: recordedErrors.map((e) => e.exceptionAsString()).join('\n'));

      // 3. Tablet width + 1.16x text scale in Light Mode
      await pumpViewport(
        size: const Size(840, 1024),
        textScale: 1.16,
        brightness: Brightness.light,
      );
      expect(find.text('الصلوات المفروضة'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('افتح برطمان السعادة 💛'),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('افتح برطمان السعادة 💛'), findsOneWidget);
      expect(recordedErrors, isEmpty,
          reason: recordedErrors.map((e) => e.exceptionAsString()).join('\n'));
    } finally {
      FlutterError.onError = originalOnError;
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
      tasksVm.dispose();
    }
  });

  testWidgets(
      'PrayersTimelineSection handles narrow, standard, and wide widths with large text scale without overflow',
      (WidgetTester tester) async {
    await StorageService.init();
    final tasksVm = _FakePrayersTasksViewModel();
    if (tasksVm.prayerTasks.isNotEmpty) {
      tasksVm.prayerTasks.first.isCompleted = true;
    }

    final originalOnError = FlutterError.onError;
    final recordedErrors = <FlutterErrorDetails>[];
    FlutterError.onError = (details) {
      recordedErrors.add(details);
    };

    try {
      for (final spec in [
        (width: 320.0, scale: 1.35, dark: false),
        (width: 390.0, scale: 1.16, dark: true),
        (width: 720.0, scale: 1.15, dark: false),
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            key: ValueKey('prayers-${spec.width}-${spec.scale}-${spec.dark}'),
            locale: const Locale('ar'),
            supportedLocales: const [Locale('ar')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              brightness: spec.dark ? Brightness.dark : Brightness.light,
            ),
            builder: (context, child) {
              final mq = MediaQuery.of(context);
              return MediaQuery(
                data: mq.copyWith(textScaler: TextScaler.linear(spec.scale)),
                child: child ?? const SizedBox.shrink(),
              );
            },
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: spec.width,
                    child: PrayersTimelineSection(
                      vm: tasksVm,
                      prayerTasks: tasksVm.prayerTasks,
                      isDark: spec.dark,
                      onOpenDetails: (_) {},
                      onToggleCompletion: (_) {},
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text('الفجر'), findsOneWidget);
        expect(find.text('التالية'), findsOneWidget);
        expect(find.text('تمت'), findsOneWidget);
        expect(find.text('أتممتها'), findsWidgets);
      }
    } finally {
      FlutterError.onError = originalOnError;
      tasksVm.dispose();
    }
    expect(recordedErrors, isEmpty,
        reason: recordedErrors.map((e) => e.exceptionAsString()).join('\n'));
  });
}

class _FakePrayersTasksViewModel extends TasksViewModel {
  final PrayerTimes _fakePrayerTimes = PrayerTimes.today(
    Coordinates(30.0444, 31.2357),
    CalculationMethod.egyptian.getParameters(),
  );

  @override
  PrayerTimes? get prayerTimes => _fakePrayerTimes;

  @override
  String get nextPrayerName => 'العصر';
}
