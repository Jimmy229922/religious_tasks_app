import 'dart:async';
import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:intl/intl.dart' as intl;

import '../constants/app_constants.dart';
import '../constants/strings.dart';
import '../models/task_item.dart';
import '../services/location_service.dart';
import '../services/notifications_service.dart';
import '../services/storage_service.dart';

class TasksViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  final LocationService _locationService = LocationService();
  final NotificationManager _notificationManager = NotificationManager();

  static const String _dateKey = 'last_opened_date_v2';
  static const String _tasksKey = 'saved_tasks_v2';
  static const String _athkarStreaksKey = 'athkar_streaks_v1';
  static const String _quranSurahKey = 'quran_last_surah';
  static const String _quranAyahKey = 'quran_last_ayah';

  List<TaskItem> _tasks = [];
  List<TaskItem> get tasks => _tasks;

  // Streak & Quran Data
  int _morningStreak = 0;
  int _eveningStreak = 0;
  int _sleepStreak = 0;
  String _lastSurah = "الفاتحة";
  int _lastAyah = 1;

  int get morningStreak => _morningStreak;
  int get eveningStreak => _eveningStreak;
  int get sleepStreak => _sleepStreak;
  String get lastSurah => _lastSurah;
  int get lastAyah => _lastAyah;

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  String _locationName = AppStrings.locating;
  String get locationName => _locationName;

  PrayerTimes? _prayerTimes;
  PrayerTimes? get prayerTimes => _prayerTimes;

  PrayerTimes? _tomorrowPrayerTimes;
  PrayerTimes? get tomorrowPrayerTimes => _tomorrowPrayerTimes;

  // Clock timer state
  DateTime _now = DateTime.now();
  DateTime get now => _now;
  Timer? _clockTimer;

  // --- Dynamic Content State (Refreshed by user) ---
  String _currentInspiration = "";
  String _currentBlessing = "";
  String _currentEventBanner = "";

  String get currentInspiration => _currentInspiration;
  String get currentBlessing => _currentBlessing;
  String get currentEventBanner => _currentEventBanner;

  final List<String> _inspirationsList = [
    "أحب الأعمال إلى الله أدومها وإن قل",
    "الدعاء هو العبادة",
    "من صلى البردين دخل الجنة",
    "أقرب ما يكون العبد من ربه وهو ساجد",
    "الكلمة الطيبة صدقة",
    "تبسمك في وجه أخيك صدقة",
    "اتق الله حيثما كنت",
    "لا تغضب ولك الجنة",
    "خير الناس أنفعهم للناس",
    "إنما الأعمال بالنيات",
    "من كان في حاجة أخيه كان الله في حاجته",
    "خيركم من تعلم القرآن وعلمه",
    "الدين النصيحة",
    "المسلم من سلم المسلمون من لسانه ويده",
    "إماطة الأذى عن الطريق صدقة",
    "لا تحقرن من المعروف شيئاً",
    "من لزم الاستغفار جعل الله له من كل هم فرجا",
  ];

  final List<String> _blessingsList = [
    "نعمة البصر",
    "نعمة السمع",
    "نعمة الإسلام",
    "نعمة الصحة والعافية",
    "نعمة الأهل والأحباب",
    "نعمة الأمن والأمان",
    "نعمة العقل والتفكير",
    "نعمة النطق والبيان",
    "نعمة الهداية للطريق المستقيم",
    "نعمة الرزق والمأكل والمشرب",
    "نعمة الستر",
    "نعمة النوم والراحة",
  ];

  final List<String> _generalEventsList = [
    "كثرة الصلاة على النبي تكفيك همك",
    "تصدق ولو بشق تمرة",
    "بر الوالدين مفتاح الجنة",
    "حافظ على صلاة الضحى",
    "اقرأ وردك القرآني اليومي",
    "جدد نيتك في كل عمل",
    "اذكر الله يذكرك",
  ];

  TasksViewModel() {
    _initTasks();
    _initLocationAndPrayers();
    _loadQuranProgress();
    _startClock();
    _initRandomContent();
  }

  void _initRandomContent() {
    // Initial Load - Use Day of Year for Consistency on first load, or Random.
    // User requested refresh feature, implying they want randomness or updates.
    // Let's stick to Day logic for initial, but verify inputs.

    // We can just call refreshRandomContent to seed it initially,
    // but typically "daily" content implies stability unless updated manually.
    // However, for the "refresh" feature to be obvious, let's randomize or use day logic.

    final dayOfYear = int.parse(intl.DateFormat("D").format(DateTime.now()));

    _currentInspiration =
        _inspirationsList[dayOfYear % _inspirationsList.length];
    _currentBlessing = _blessingsList[dayOfYear % _blessingsList.length];

    // Event Banner: Check date first
    _currentEventBanner = _getDateSpecificEvent() ??
        _generalEventsList[dayOfYear % _generalEventsList.length];
  }

  void refreshRandomContent() {
    // Pick random new values
    final random = DateTime.now().millisecondsSinceEpoch;

    _currentInspiration = _inspirationsList[random % _inspirationsList.length];
    // Simple shift for others to ensure variety
    _currentBlessing = _blessingsList[(random + 5) % _blessingsList.length];

    // For Event Banner, we can toggle between date specific (if any) and random general hints
    // Or just random from generals + date specific?
    // Let's just pick a random from general list to give "fresh" advice.
    // Or maybe include the Date Specific one in the mix?

    final dateEvent = _getDateSpecificEvent();
    if (dateEvent != null && (random % 2 == 0)) {
      // 50% chance to show the date event again (if exists)
      _currentEventBanner = dateEvent;
    } else {
      _currentEventBanner =
          _generalEventsList[random % _generalEventsList.length];
    }

    notifyListeners();
  }

  String? _getDateSpecificEvent() {
    final weekday = _now.weekday;
    // Fasting Mondays
    if (weekday == DateTime.monday) return "صيام الاثنين (سنة)";
    if (weekday == DateTime.thursday) return "صيام الخميس (سنة)";

    // Friday
    if (weekday == DateTime.friday) {
      return "يوم الجمعة: سورة الكهف وساعة استجابة";
    }
    return null;
  }

  Future<void> refreshLocation() async {
    await _initLocationAndPrayers();
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newNow = DateTime.now();
      if (newNow.minute != _now.minute ||
          newNow.hour != _now.hour ||
          _now.day != newNow.day) {
        _now = newNow;
        notifyListeners();
      } else {
        // Just update internal time without rebuilding UI essentially
        _now = newNow;
      }
    });
  }

  Future<void> _initTasks() async {
    final lastDate = _storage.getString(_dateKey);
    final todayDate = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());

    _tasks = [
      TaskItem(name: kPrayerFajr, description: "", targetCount: 1),
      TaskItem(
          name: kAthkarMorning,
          description: AppStrings.afterFajr,
          targetCount: 1),
      TaskItem(name: kPrayerDhuhr, description: "", targetCount: 1),
      TaskItem(name: kPrayerAsr, description: "", targetCount: 1),
      TaskItem(name: kPrayerMaghrib, description: "", targetCount: 1),
      TaskItem(name: kPrayerIsha, description: "", targetCount: 1),
      TaskItem(
          name: kProphetPrayer,
          description: AppStrings.count200,
          targetCount: 200),
      TaskItem(
          name: kAthkarEvening,
          description: AppStrings.afterAsr,
          targetCount: 1),
      TaskItem(name: kAthkarSleep, description: "قبل النوم", targetCount: 1),
      TaskItem(
          name: kQuranWird, description: AppStrings.dailyWird, targetCount: 1),
    ];

    _loadStreaks();

    if (lastDate != todayDate) {
      await _resetTasksForNewDay(todayDate);
    } else {
      final savedTasksJson = _storage.getString(_tasksKey);
      if (savedTasksJson != null) {
        try {
          List<dynamic> decode = jsonDecode(savedTasksJson);
          _tasks = decode.map((item) => TaskItem.fromJson(item)).toList();
        } catch (_) {
          // fallback to default
        }
      }
    }
    _updateTaskDescriptions();
    notifyListeners();
  }

  Future<void> _resetTasksForNewDay(String today) async {
    // Check missing daily tasks to break streak if needed before resetting
    // But simplistic approach: we check streaks on completion, and if user missed yesterday, we reset.
    // Actually, on new day, if yesterday wasn't completed, streak might break.
    // For now, let's keep streak logic simple: We update streak when user completes task.
    // If we want to reset if missed, we need to check yesterday's status.
    // Let's rely on stored "last completed date" for streaks logic below.

    for (var task in _tasks) {
      task.isCompleted = false;
      task.currentCount = 0;
    }
    await _storage.setString(_dateKey, today);
    await _saveTasks();
  }

  // Streak Logic
  Future<void> _loadStreaks() async {
    final jsonStr = _storage.getString(_athkarStreaksKey);
    if (jsonStr != null) {
      final data = jsonDecode(jsonStr);
      _morningStreak = data['morning'] ?? 0;
      _eveningStreak = data['evening'] ?? 0;
      _sleepStreak = data['sleep'] ?? 0;
    }
  }

  Future<void> _updateStreak(String type) async {
    final now = DateTime.now();
    final todayStr = intl.DateFormat('yyyy-MM-dd').format(now);
    final yesterdayStr = intl.DateFormat('yyyy-MM-dd')
        .format(now.subtract(const Duration(days: 1)));

    final lastDateKey = "${_tasksKey}_last_date_$type";

    final lastDate = _storage.getString(lastDateKey);

    int newStreak = (type == 'morning')
        ? _morningStreak
        : (type == 'evening')
            ? _eveningStreak
            : _sleepStreak;

    if (lastDate == todayStr) {
      // already incremented today
    } else if (lastDate == yesterdayStr) {
      newStreak++;
    } else {
      // missed a day or more (or first time)
      newStreak = 1;
    }

    if (type == 'morning') {
      _morningStreak = newStreak;
    } else if (type == 'evening') {
      _eveningStreak = newStreak;
    } else {
      _sleepStreak = newStreak;
    }

    await _storage.setString(lastDateKey, todayStr);
    // Save composite
    final data = {
      'morning': _morningStreak,
      'evening': _eveningStreak,
      'sleep': _sleepStreak
    };
    await _storage.setString(_athkarStreaksKey, jsonEncode(data));
    notifyListeners();
  }

  Future<void> _saveTasks() async {
    List<Map<String, dynamic>> tasksJson =
        _tasks.map((e) => e.toJson()).toList();
    await _storage.setString(_tasksKey, jsonEncode(tasksJson));
  }

  Future<void> _initLocationAndPrayers() async {
    _isLoadingLocation = true;
    notifyListeners();

    final result = await _locationService.getCurrentPosition();

    if (result.message.isNotEmpty) {
      _locationName = result.message;
      _isLoadingLocation = false;
      notifyListeners();
      // If position is null but message is set (error), we stop here unless we want to try cached inside service
      if (result.position == null) return;
    }

    if (result.position != null) {
      await _calculatePrayers(result.position!);
    }
  }

  Future<void> _calculatePrayers(Position position) async {
    final coordinates = Coordinates(position.latitude, position.longitude);
    final params = CalculationMethod.egyptian.getParameters();
    params.madhab = Madhab.shafi;

    final todayTimes = PrayerTimes.today(coordinates, params);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowComponents =
        DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
    final tomorrowTimes = PrayerTimes(coordinates, tomorrowComponents, params);

    _prayerTimes = todayTimes;
    _tomorrowPrayerTimes = tomorrowTimes;
    _isLoadingLocation = false;

    _locationName = await _locationService.getLocationName(position);

    _updateTaskDescriptions();
    notifyListeners();

    // Schedule notifications
    await _notificationManager.schedulePrayerNotifications(
        today: todayTimes, tomorrow: tomorrowTimes);
  }

  void _updateTaskDescriptions() {
    if (_prayerTimes == null) return;
    final formatter = intl.DateFormat.jm('ar');

    for (var task in _tasks) {
      if (task.name.contains(kPrayerFajr)) {
        task.description = formatter.format(_prayerTimes!.fajr);
      } else if (task.name.contains(kPrayerDhuhr)) {
        task.description = formatter.format(_prayerTimes!.dhuhr);
      } else if (task.name.contains(kPrayerAsr)) {
        task.description = formatter.format(_prayerTimes!.asr);
      } else if (task.name.contains(kPrayerMaghrib)) {
        task.description = formatter.format(_prayerTimes!.maghrib);
      } else if (task.name.contains(kPrayerIsha)) {
        task.description = formatter.format(_prayerTimes!.isha);
      }
    }
  }

  // Task Actions
  void toggleTask(int index, {bool? completionValue}) {
    if (completionValue != null) {
      _tasks[index].isCompleted = completionValue;
      _tasks[index].currentCount =
          completionValue ? _tasks[index].targetCount : 0;

      // Check for streak update
      if (completionValue) {
        if (_tasks[index].name == kAthkarMorning) _updateStreak('morning');
        if (_tasks[index].name == kAthkarEvening) _updateStreak('evening');
        if (_tasks[index].name == kAthkarSleep) _updateStreak('sleep');
      }
    } else {
      _tasks[index].isCompleted = !_tasks[index].isCompleted;
      if (!_tasks[index].isCompleted && _tasks[index].targetCount > 1) {
        _tasks[index].currentCount = 0;
      } else if (_tasks[index].isCompleted && _tasks[index].targetCount > 1) {
        _tasks[index].currentCount = _tasks[index].targetCount;
      }

      // Check for streak update
      if (_tasks[index].isCompleted) {
        if (_tasks[index].name == kAthkarMorning) _updateStreak('morning');
        if (_tasks[index].name == kAthkarEvening) _updateStreak('evening');
        if (_tasks[index].name == kAthkarSleep) _updateStreak('sleep');
      }
    }
    _saveTasks();
    notifyListeners();
  }

  void incrementCounter(int index) {
    if (_tasks[index].currentCount < _tasks[index].targetCount) {
      _tasks[index].currentCount++;
      if (_tasks[index].currentCount == _tasks[index].targetCount) {
        _tasks[index].isCompleted = true;
        // Check for streak update
        if (_tasks[index].name == kAthkarMorning) _updateStreak('morning');
        if (_tasks[index].name == kAthkarEvening) _updateStreak('evening');
        if (_tasks[index].name == kAthkarSleep) _updateStreak('sleep');
      }
      _saveTasks();
      notifyListeners();
    }
  }

  // Helpers for UI
  int get totalCount => _tasks.length;
  int get completedCount => _tasks.where((t) => t.isCompleted).length;
  double get progress => totalCount == 0 ? 0.0 : completedCount / totalCount;

  List<TaskItem> get prayerTasks => _tasks
      .where((t) => [
            kPrayerFajr,
            kPrayerDhuhr,
            kPrayerAsr,
            kPrayerMaghrib,
            kPrayerIsha
          ].contains(t.name))
      .toList();

  List<TaskItem> get otherTasks => _tasks
      .where((t) => ![
            kPrayerFajr,
            kPrayerDhuhr,
            kPrayerAsr,
            kPrayerMaghrib,
            kPrayerIsha
          ].contains(t.name))
      .toList();

  // Aliases for backward compatibility or cleaner UI refactoring
  String get dailyInspiration => _currentInspiration;
  String? get activeEvent =>
      _currentEventBanner.isEmpty ? null : _currentEventBanner;

  // --- New Features Logic ---

  // 1. Smart Events (Fasting/Events) code replaced by _currentEventBanner state.

  // 2. Quran Progress
  void _loadQuranProgress() {
    _lastSurah = _storage.getString(_quranSurahKey) ?? "الفاتحة";
    // getInt might not be in your wrapper? If not, parse string.
    // Assuming wrapper based on context has getString, let's use getString for safety or check wrapper.
    // I'll assume standard SharedPreferences behavior but safer to store as int if wrapper supports it.
    // If your StorageService only has getString and setString:
    // _lastAyah = int.tryParse(_storage.getString(_quranAyahKey) ?? "1") ?? 1;
    // But usually it supports others. Let's try to see if I can simply store as Json or String to be safe.
    final a = _storage.getString(_quranAyahKey);
    _lastAyah = a != null ? int.parse(a) : 1;
  }

  Future<void> updateQuranProgress(String surah, int ayah) async {
    _lastSurah = surah;
    _lastAyah = ayah;
    await _storage.setString(_quranSurahKey, surah);
    await _storage.setString(_quranAyahKey, ayah.toString());
    notifyListeners();
  }

  // 3. Context Aware Athkar
  String get suggestedAthkar {
    final hour = _now.hour;
    // Morning Athkar: 5:00 AM to 11:00 AM
    if (hour >= 5 && hour < 11) {
      // Check if Morning Athkar is done, if not return it
      // Actually standard logic is fine for morning range.
      return kAthkarMorning;
    }
    // Fajr (Pre-Dawn): 3:00 AM to 5:00 AM
    if (hour >= 3 && hour < 5) {
      return kPrayerFajr;
    }
    // Evening Athkar: 3:00 PM (15:00) to 8:00 PM (20:00)
    // Extended to 20 to cover the 6:50 PM case comfortably
    if (hour >= 15 && hour < 20) return kAthkarEvening;

    // Sleep Athkar: 8:00 PM onwards or late night
    if (hour >= 20 || hour < 3) {
      // Check if Evening Athkar is done
      final eveningTask = _tasks.firstWhere(
        (t) => t.name == kAthkarEvening,
        orElse: () => TaskItem(
            name: kAthkarEvening,
            description: AppStrings.afterAsr,
            targetCount: 1),
      );

      if (!eveningTask.isCompleted) {
        return kAthkarEvening;
      }
      return kAthkarSleep; // "أذكار النوم" in Consts
    }

    return "استغفر الله";
  }

  // 4. Weather Mock
  Map<String, String> get weatherInfo {
    final month = _now.month;
    final hour = _now.hour;

    String temp = "25°";
    String advice = "جو معتدل";

    if (month >= 11 || month <= 2) {
      // Winter
      temp = "12°";
      advice = (hour < 8 || hour > 18)
          ? "الجو بارد، ارتدِ ملابس ثقيلة للصلاة"
          : "جو شتوي لطيف";
    } else if (month >= 6 && month <= 8) {
      // Summer
      temp = "38°";
      advice = "حار ومشمش، حافظ على رطوبتك";
    }

    return {"temp": temp, "advice": advice};
  }
}
