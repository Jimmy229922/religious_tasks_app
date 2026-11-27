import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:adhan/adhan.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hijri/hijri_calendar.dart' as hijri;
import 'package:home_widget/home_widget.dart';
import 'package:intl/intl.dart' as intl;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import 'package:religious_tasks_app/core/constants/strings.dart';
import '../models/task_item.dart';
import 'package:religious_tasks_app/core/services/location_service.dart';
import 'package:religious_tasks_app/core/widgets/quran_text_formatter.dart';
import 'package:religious_tasks_app/features/quran/data/quran_page_mapping.dart';
import 'package:religious_tasks_app/features/quran/data/quran_repository.dart';
import 'package:religious_tasks_app/shared/services/notifications/app_notification_service.dart';
import 'package:religious_tasks_app/shared/services/notifications/notification_preferences_service.dart';
import 'package:religious_tasks_app/core/services/storage_service.dart';

enum ContextSuggestionAction {
  prayer,
  morningAthkar,
  eveningAthkar,
  sleepAthkar,
  qiyam,
  surahKahf,
  khatmah,
  tasbeeh,
  prophetPrayer,
  happinessJar,
}

class ContextSuggestion {
  final String title;
  final String subtitle;
  final String categoryLabel;
  final IconData icon;
  final Color accentColor;
  final ContextSuggestionAction action;
  final String? prayerName;
  final DateTime? prayerTime;

  const ContextSuggestion({
    required this.title,
    required this.subtitle,
    required this.categoryLabel,
    required this.icon,
    required this.accentColor,
    required this.action,
    this.prayerName,
    this.prayerTime,
  });
}

class TasksViewModel extends ChangeNotifier {
  final StorageService _storage = StorageService.instance;
  final LocationService _locationService = LocationService();
  final AppNotificationService _notificationService = AppNotificationService();

  static const String _dateKey = 'last_opened_date_v2';
  static const String _tasksKey = 'saved_tasks_v2';
  static const String _athkarStreaksKey = 'athkar_streaks_v1';
  static const String _badgesKey = 'earned_badges_v1';
  static const String _totalDhikrCountKey = 'total_dhikr_count_v1';
  static const String _gratitudeCountKey = 'gratitude_count_v1';
  static const String _quranSurahKey = 'quran_last_surah';
  static const String _quranAyahKey = 'quran_last_ayah';
  static const String _quranSurahNumKey = 'quran_last_surah_number';
  static const String _quranPageKey = 'quran_last_page';
  static const String _quranVerseTextKey = 'quran_last_verse_text';
  static const String _latKey = 'last_latitude';
  static const String _lngKey = 'last_longitude';
  static const String _locNameKey = 'last_location_name';
  static const String _prayerWidgetName = 'PrayerWidgetProvider';

  List<TaskItem> _tasks = [];
  List<TaskItem> get tasks => _tasks;

  // Streak & Quran Data
  int _morningStreak = 0;
  int _eveningStreak = 0;
  int _sleepStreak = 0;
  String _lastSurah = "الفاتحة";
  int _lastAyah = 1;
  int _lastSurahNumber = 1;
  int _lastPage = 1;
  String _lastVerseText = "";
  bool _hasQuranBookmark = false;
  List<String> _earnedBadges = [];
  int _totalDhikrCount = 0;
  int _gratitudeCount = 0;

  int get morningStreak => _morningStreak;
  int get eveningStreak => _eveningStreak;
  int get sleepStreak => _sleepStreak;
  String get lastSurah => _lastSurah;
  int get lastAyah => _lastAyah;
  int get lastSurahNumber => _lastSurahNumber;
  int get lastPage => _lastPage;
  String get lastVerseText => _lastVerseText;
  bool get hasQuranBookmark => _hasQuranBookmark;
  List<String> get earnedBadges => _earnedBadges;
  int get totalDhikrCount => _totalDhikrCount;
  int get gratitudeCount => _gratitudeCount;

  bool _isLoadingLocation = false;
  bool get isLoadingLocation => _isLoadingLocation;

  String _locationName = AppStrings.locating;
  String get locationName => _locationName;

  PrayerTimes? _prayerTimes;
  PrayerTimes? get prayerTimes => _prayerTimes;

  PrayerTimes? _tomorrowPrayerTimes;
  PrayerTimes? get tomorrowPrayerTimes => _tomorrowPrayerTimes;

  DateTime? get nextPrayerTime {
    if (_prayerTimes == null) return null;
    final next = _prayerTimes!.nextPrayer();
    // If next is none, it might be after Isha, so next is Fajr tomorrow?
    // adhan package usually handles this if initialized correctly, or returns none if today's prayers are done.
    if (next == Prayer.none) {
      return _tomorrowPrayerTimes?.fajr;
    }
    return _prayerTimes!.timeForPrayer(next);
  }

  String get nextPrayerName {
    if (_prayerTimes == null) return "";
    final next = _prayerTimes!.nextPrayer();
    if (next == Prayer.none) return "الفجر"; // Assuming tomorrow Fajr
    return _getPrayerNameArabic(next);
  }

  String _getPrayerNameArabic(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return "الفجر";
      case Prayer.sunrise:
        return "الشروق";
      case Prayer.dhuhr:
        return "الظهر";
      case Prayer.asr:
        return "العصر";
      case Prayer.maghrib:
        return "المغرب";
      case Prayer.isha:
        return "العشاء";
      default:
        return "";
    }
  }

  // Clock timer state
  DateTime _now = DateTime.now();
  String _activeDate = intl.DateFormat('yyyy-MM-dd').format(DateTime.now());
  DateTime get now => _now;
  Timer? _clockTimer;
  DateTime? _lastLocationRefresh;

  // --- Dynamic Content State (Refreshed by user) ---
  String _currentInspiration = "";
  String _currentInspirationSource =
      ""; // e.g. "البقرة: 152" or empty for general wisdom
  bool _isInspirationQuran = false;

  String _currentBlessing = "";
  String _currentEventBanner = "";

  String get currentInspiration => _currentInspiration;
  String get currentInspirationSource => _currentInspirationSource;
  bool get isInspirationQuran => _isInspirationQuran;

  String get currentBlessing => _currentBlessing;
  String get currentEventBanner => _currentEventBanner;

  final List<String> _inspirationsList = [
    "أحب الأعمال إلى الله أدومها وإن قل",
    "الدعاء هو العبادة",
    "من صلى البردين دخل الجنة",
    "أقرب ما يكون العبد من ربه وهو ساجد",
    "الكلمة الطيبة صدقة",
    "تبسمك في وجه أخيك صدقة",
    "اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها",
    "لا تغضب ولك الجنة",
    "خير الناس أنفعهم للناس",
    "إنما الأعمال بالنيات وإنما لكل امرئ ما نوى",
    "من كان في حاجة أخيه كان الله في حاجته",
    "خيركم من تعلم القرآن وعلمه",
    "الدين النصيحة",
    "المسلم من سلم المسلمون من لسانه ويده",
    "إماطة الأذى عن الطريق صدقة",
    "لا تحقرن من المعروف شيئاً ولو أن تلقى أخاك بوجه طلق",
    "من لزم الاستغفار جعل الله له من كل هم فرجاً ومن كل ضيق مخرجاً",
    "من صلى عليّ صلاةً صلى الله عليه بها عشراً",
    "كلمتان خفيفتان على اللسان ثقيلتان في الميزان: سبحان الله وبحمده، سبحان الله العظيم",
    "الطهور شطر الإيمان، والحمد لله تملأ الميزان",
    "أحب الكلام إلى الله أربع: سبحان الله، والحمد لله، ولا إله إلا الله، والله أكبر",
    "احفظ الله يحفظك، احفظ الله تجده تجاهك",
    "إذا سألت فاسأل الله، وإذا استعنت فاستعن بالله",
    "عجباً لأمر المؤمن، إن أمره كله خير",
    "من قرأ حرفاً من كتاب الله فله به حسنة، والحسنة بعشر أمثالها",
    "يسّروا ولا تعسّروا، وبشّروا ولا تنفّروا",
    "ارحموا من في الأرض يرحمكم من في السماء",
    "إن الله رفيق يحب الرفق في الأمر كله",
    "أدّ الأمانة إلى من ائتمنك، ولا تخن من خانك",
    "البر حسن الخلق",
    "تفاءلوا بالخير تجدوه",
    "ما نقصت صدقة من مال، وما زاد الله عبداً بعفو إلا عزاً",
    "لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه",
    "من أصبح منكم آمناً في سربه، معافى في جسده، عنده قوت يومه، فكأنما حيزت له الدنيا",
    "قل آمنت بالله ثم استقم",
  ];

  final List<Map<String, String>> _quranVersesList = [
    {
      "text": "فَاذْكُرُونِي أَذْكُرْكُمْ وَاشْكُرُوا لِي وَلَا تَكْفُرُونِ",
      "source": "سورة البقرة • ١٥٢"
    },
    {"text": "إِنَّ اللَّهَ مَعَ الصَّابِرِينَ", "source": "سورة البقرة • ١٥٣"},
    {
      "text":
          "وَإِذَا سَأَلَكَ عِبَادِي عَنِّي فَإِنِّي قَرِيبٌ ۖ أُجِيبُ دَعْوَةَ الدَّاعِ إِذَا دَعَانِ",
      "source": "سورة البقرة • ١٨٦"
    },
    {
      "text": "أَلَا بِذِكْرِ اللَّهِ تَطْمَئِنُّ الْقُلُوبُ",
      "source": "سورة الرعد • ٢٨"
    },
    {
      "text":
          "وَمَنْ يَتَّقِ اللَّهَ يَجْعَلْ لَهُ مَخْرَجًا ۝٢ وَيَرْزُقْهُ مِنْ حَيْثُ لَا يَحْتَسِبُ ۝٣",
      "source": "سورة الطلاق • ٢-٣"
    },
    {"text": "وَرَحْمَتِي وَسِعَتْ كُلَّ شَيْءٍ", "source": "سورة الأعراف • ١٥٦"},
    {
      "text": "لَا يُكَلِّفُ اللَّهُ نَفْسًا إِلَّا وُسْعَهَا",
      "source": "سورة البقرة • ٢٨٦"
    },
    {
      "text": "قُلْ لَنْ يُصِيبَنَا إِلَّا مَا كَتَبَ اللَّهُ لَنَا",
      "source": "سورة التوبة • ٥١"
    },
    {
      "text": "وَعَسَىٰ أَنْ تَكْرَهُوا شَيْئًا وَهُوَ خَيْرٌ لَكُمْ",
      "source": "سورة البقرة • ٢١٦"
    },
    {"text": "وَكَفَىٰ بِاللَّهِ وَكِيلًا", "source": "سورة النساء • ٨١"},
    {
      "text": "رَبِّ اشْرَحْ لِي صَدْرِي ۝٢٥ وَيَسِّرْ لِي أَمْرِي ۝٢٦",
      "source": "سورة طه • ٢٥-٢٦"
    },
    {
      "text": "فَإِنَّ مَعَ الْعُسْرِ يُسْرًا ۝٥ إِنَّ مَعَ الْعُسْرِ يُسْرًا ۝٦",
      "source": "سورة الشرح • ٥-٦"
    },
    {
      "text": "وَلَسَوْفَ يُعْطِيكَ رَبُّكَ فَتَرْضَىٰ",
      "source": "سورة الضحى • ٥"
    },
    {
      "text": "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
      "source": "سورة إبراهيم • ٧"
    },
    {
      "text": "لَا تَحْزَنْ إِنَّ اللَّهَ مَعَنَا",
      "source": "سورة التوبة • ٤٠"
    },
    {
      "text": "وَمَن يَتَوَكَّلْ عَلَى اللَّهِ فَهُوَ حَسْبُهُ",
      "source": "سورة الطلاق • ٣"
    },
    {
      "text": "لَعَلَّ اللَّهَ يُحْدِثُ بَعْدَ ذَٰلِكَ أَمْرًا",
      "source": "سورة الطلاق • ١"
    },
    {
      "text": "فَاصْبِرْ إِنَّ وَعْدَ اللَّهِ حَقٌّ",
      "source": "سورة الروم • ٦٠"
    },
    {
      "text": "وَأُفَوِّضُ أَمْرِي إِلَى اللَّهِ ۚ إِنَّ اللَّهَ بَصِيرٌ بِالْعِبَادِ",
      "source": "سورة غافر • ٤٤"
    },
    {
      "text": "ادْعُونِي أَسْتَجِبْ لَكُمْ",
      "source": "سورة غافر • ٦٠"
    },
    {
      "text": "إِنَّ رَبِّي لَسَمِيعُ الدُّعَاءِ",
      "source": "سورة إبراهيم • ٣٩"
    },
    {
      "text": "وَهُوَ مَعَكُمْ أَيْنَ مَا كُنتُمْ",
      "source": "سورة الحديد • ٤"
    },
    {
      "text": "إِنَّ اللَّهَ لَطِيفٌ خَبِيرٌ",
      "source": "سورة لقمان • ١٦"
    },
    {
      "text": "رَبَّنَا آتِنَا فِي الدُّنْيَا حَسَنَةً وَفِي الْآخِرَةِ حَسَنَةً وَقِنَا عَذَابَ النَّارِ",
      "source": "سورة البقرة • ٢٠١"
    },
    {
      "text": "حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ",
      "source": "سورة آل عمران • ١٧٣"
    },
  ];

  final List<String> _blessingsList = [
    "نعمة الإسلام والهداية",
    "نعمة البصر وتأمل بديع خلقك",
    "نعمة السمع وتلاوة كتابك",
    "نعمة الصحة والعافية في البدن",
    "نعمة الأهل والأحباب والصحبة الصالحة",
    "نعمة الأمن والأمان في الأوطان والبيوت",
    "نعمة العقل والفهم والتدبّر",
    "نعمة النطق والبيان واللسان الذاكر",
    "نعمة الستر واللطف الخفي",
    "نعمة الرزق الطيب والمأكل والمشرب",
    "نعمة النوم الهادئ والراحة بعد التعب",
    "نعمة القرآن الكريم وتيسير تلاوته",
    "نعمة الصلاة ومناجاتك في كل وقت",
    "نعمة الدعاء وقربك من عبادك",
    "نعمة التوبة وقبول الأوبة",
    "نعمة الهواء النقي والشمس والماء",
    "نعمة الصبر والسكينة عند الشدائد",
    "نعمة العمل والسعي والبركة في الوقت",
    "نعمة بر الوالدين ورضاهما",
    "نعمة الأخوّة الصادقة وجبر الخواطر",
    "نعمة القناعة والرضا بما قسمت",
    "نعمة الخشوع والطمأنينة في القلب",
    "نعمة السلامة من البلاء والمحن",
    "نعمة الفرج بعد الضيق واليسر بعد العسر",
    "نعمة القدرة على الحركة والمشي",
    "نعمة القلب السليم النقي من الحقد",
    "نعمة العلم والمعرفة والتعلّم",
    "نعمة الصدقة ومساعدة المحتاجين",
    "نعمة استشعار معيّتك في كل لحظة",
    "نعمة تجدد الأمل وبشائر الصباح",
    "نعمة الليل للسكينة والتهجد",
    "نعمة الاستغفار ومحوه للذنوب",
    "نعمة الصلاة على الحبيب محمد ﷺ",
    "نعمة الضحك والابتسامة وإدخال السرور",
    "نعمك الظاهرة والباطنة ما علمنا منها وما لم نعلم",
  ];

  final List<String> _generalEventsList = [
    "كثرة الصلاة على النبي ﷺ تكفيك همك",
    "تصدق ولو بشق تمرة",
    "بر الوالدين مفتاح الجنة",
    "حافظ على صلاة الضحى",
    "اقرأ وردك القرآني اليومي",
    "جدد نيتك في كل عمل",
    "اذكر الله يذكرك",
    "استغفر الله العظيم وأتوب إليه",
  ];

  final Random _random = Random();

  TasksViewModel() {
    _initTasks();
    _initLocationAndPrayers();
    _loadQuranProgress();
    _loadBadges();
    _loadTotalDhikr();
    _loadGratitudeCount();
    _startClock();
    _initRandomContent();
  }

  void _loadBadges() {
    final badgesJson = _storage.getString(_badgesKey);
    if (badgesJson != null) {
      try {
        final decoded = jsonDecode(badgesJson);
        if (decoded is List && decoded.every((item) => item is String)) {
          _earnedBadges = List<String>.from(decoded);
        }
      } catch (_) {
        _earnedBadges = [];
      }
    }
  }

  void _loadTotalDhikr() {
    final count = _storage.getString(_totalDhikrCountKey);
    _totalDhikrCount = count == null ? 0 : (int.tryParse(count) ?? 0);
  }

  void _loadGratitudeCount() {
    final count = _storage.getString(_gratitudeCountKey);
    _gratitudeCount = count == null ? 0 : (int.tryParse(count) ?? 0);
  }

  Future<void> incrementGratitude() async {
    _gratitudeCount++;
    await _storage.setString(_gratitudeCountKey, _gratitudeCount.toString());
    await addToTotalDhikr(1);
  }

  void cycleBlessing() {
    if (_blessingsList.length <= 1) return;
    final candidates = _blessingsList
        .where((b) => b != _currentBlessing)
        .toList(growable: false);
    _currentBlessing = candidates[_random.nextInt(candidates.length)];
    notifyListeners();
  }

  Future<void> _checkMilestones() async {
    bool changed = false;

    // Milestone: 1000 Dhikr
    if (_totalDhikrCount >= 1000 && !_earnedBadges.contains('dhikr_1000')) {
      _earnedBadges.add('dhikr_1000');
      changed = true;
    }

    // Milestone: 7 day streak (Morning)
    if (_morningStreak >= 7 && !_earnedBadges.contains('streak_morning_7')) {
      _earnedBadges.add('streak_morning_7');
      changed = true;
    }

    if (changed) {
      await _storage.setString(_badgesKey, jsonEncode(_earnedBadges));
      notifyListeners();
    }
  }

  Future<void> addToTotalDhikr(int amount) async {
    _totalDhikrCount += amount;
    await _storage.setString(_totalDhikrCountKey, _totalDhikrCount.toString());
    await _checkMilestones();
    notifyListeners();
  }

  void _initRandomContent() {
    final dayOfYear = int.parse(intl.DateFormat("D").format(DateTime.now()));

    // Toggle between Quran and Wisdom based on day parity for variation
    if (dayOfYear % 2 == 1) {
      final index = dayOfYear % _quranVersesList.length;
      _currentInspiration = _quranVersesList[index]["text"]!;
      _currentInspirationSource = _quranVersesList[index]["source"]!;
      _isInspirationQuran = true;
    } else {
      _currentInspiration =
          _inspirationsList[dayOfYear % _inspirationsList.length];
      _currentInspirationSource = "";
      _isInspirationQuran = false;
    }

    _currentBlessing = _blessingsList[dayOfYear % _blessingsList.length];

    // Event Banner: Check date first
    _currentEventBanner = _getDateSpecificEvent() ??
        _generalEventsList[dayOfYear % _generalEventsList.length];
  }

  void refreshRandomContent() {
    final useQuran = _random.nextBool();

    if (useQuran) {
      final candidates = _quranVersesList
          .where((v) => v["text"] != _currentInspiration)
          .toList(growable: false);
      final picked = candidates.isNotEmpty
          ? candidates[_random.nextInt(candidates.length)]
          : _quranVersesList[_random.nextInt(_quranVersesList.length)];
      _currentInspiration = picked["text"]!;
      _currentInspirationSource = picked["source"]!;
      _isInspirationQuran = true;
    } else {
      final candidates = _inspirationsList
          .where((item) => item != _currentInspiration)
          .toList(growable: false);
      _currentInspiration = candidates.isNotEmpty
          ? candidates[_random.nextInt(candidates.length)]
          : _inspirationsList[_random.nextInt(_inspirationsList.length)];
      _currentInspirationSource = "";
      _isInspirationQuran = false;
    }

    final blessingCandidates = _blessingsList
        .where((b) => b != _currentBlessing)
        .toList(growable: false);
    _currentBlessing = blessingCandidates.isNotEmpty
        ? blessingCandidates[_random.nextInt(blessingCandidates.length)]
        : _blessingsList[_random.nextInt(_blessingsList.length)];

    final dateEvent = _getDateSpecificEvent();
    if (dateEvent != null) {
      _currentEventBanner = dateEvent;
    } else {
      final eventCandidates = _generalEventsList
          .where((e) => e != _currentEventBanner)
          .toList(growable: false);
      _currentEventBanner = eventCandidates.isNotEmpty
          ? eventCandidates[_random.nextInt(eventCandidates.length)]
          : _generalEventsList[_random.nextInt(_generalEventsList.length)];
    }

    notifyListeners();
  }

  Future<void> refreshAll() async {
    final currentNow = DateTime.now();
    _now = currentNow;
    final today = intl.DateFormat('yyyy-MM-dd').format(currentNow);
    if (today != _activeDate) {
      _activeDate = today;
      await _initTasks();
    } else {
      await _loadStreaks();
      _loadBadges();
      _loadTotalDhikr();
      _loadGratitudeCount();
      try {
        final prefs = await SharedPreferences.getInstance();
        final prophetCount = prefs.getInt('prophet_prayer_counter') ?? 0;
        final prophetIndex =
            _tasks.indexWhere((t) => t.name.contains(kProphetPrayer));
        if (prophetIndex != -1) {
          _tasks[prophetIndex].currentCount = prophetCount;
          _tasks[prophetIndex].isCompleted =
              prophetCount >= _tasks[prophetIndex].targetCount;
        }
      } catch (_) {}
    }

    _loadQuranProgress();
    refreshRandomContent();
    await refreshLocation(userInitiated: false);
    await _updateOtherWidgets();
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

  Future<void> refreshLocation({bool userInitiated = false}) async {
    await _initLocationAndPrayers(requestPermission: userInitiated);
  }

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _clockTimer?.cancel();
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  void _startClock() {
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final newNow = DateTime.now();
      // Only notify listeners if the minute has changed (drastic optimization)
      if (newNow.minute != _now.minute) {
        _now = newNow;
        final newDate = intl.DateFormat('yyyy-MM-dd').format(newNow);
        if (newDate != _activeDate) {
          _activeDate = newDate;
          unawaited(_handleDateChange());
        }
        _updatePrayerWidget();

        // Auto-refresh location every hour only if coordinates are not yet loaded
        if (_prayerTimes == null &&
            (_lastLocationRefresh == null ||
                newNow.difference(_lastLocationRefresh!).inHours >= 1)) {
          refreshLocation(userInitiated: false);
        }

        notifyListeners();
      } else {
        _now = newNow;
      }
    });
  }

  Future<void> _handleDateChange() async {
    await _initTasks();
    await _initLocationAndPrayers();
    _initRandomContent();
    notifyListeners();
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
          name: kPrayerQiyam,
          description: "ركعتين في جوف الليل",
          targetCount: 1),
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
      final prefs = await SharedPreferences.getInstance();
      final prophetCount = prefs.getInt('prophet_prayer_counter') ?? 0;
      final prophetIndex =
          _tasks.indexWhere((t) => t.name.contains(kProphetPrayer));
      if (prophetIndex != -1) {
        _tasks[prophetIndex].currentCount = prophetCount;
        if (prophetCount >= _tasks[prophetIndex].targetCount) {
          _tasks[prophetIndex].isCompleted = true;
        }
      }
    }
    _updateTaskDescriptions();
    notifyListeners();
  }

  Future<void> _resetTasksForNewDay(String today) async {
    for (var task in _tasks) {
      task.isCompleted = false;
      task.currentCount = 0;
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('prophet_prayer_counter', 0);
    await _storage.setString(_dateKey, today);
    await _saveTasks();
  }

  // Streak Logic
  Future<void> _loadStreaks() async {
    final jsonStr = _storage.getString(_athkarStreaksKey);
    if (jsonStr != null) {
      try {
        final decoded = jsonDecode(jsonStr);
        if (decoded is Map) {
          _morningStreak = decoded['morning'] is int ? decoded['morning'] : 0;
          _eveningStreak = decoded['evening'] is int ? decoded['evening'] : 0;
          _sleepStreak = decoded['sleep'] is int ? decoded['sleep'] : 0;
        }
      } catch (_) {
        _morningStreak = 0;
        _eveningStreak = 0;
        _sleepStreak = 0;
      }
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

  Future<void> _initLocationAndPrayers({bool requestPermission = false}) async {
    // 1. Try to load cached location first for instant UI
    final savedLat = _storage.getString(_latKey);
    final savedLng = _storage.getString(_lngKey);
    _locationName = _storage.getString(_locNameKey) ?? AppStrings.locating;

    final parsedLat = savedLat == null ? null : double.tryParse(savedLat);
    final parsedLng = savedLng == null ? null : double.tryParse(savedLng);
    final hasCachedCoords = parsedLat != null && parsedLng != null;
    if (hasCachedCoords) {
      final pos = Position(
        latitude: parsedLat,
        longitude: parsedLng,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
      await _calculatePrayers(
        pos,
        useSavedMetadataOnly: true,
        scheduleNotifications: false,
      );
      debugPrint("📍 Using cached location for instant startup");
    }

    _isLoadingLocation = true;
    notifyListeners();

    final result = await _locationService.getCurrentPosition(
      requestPermission: requestPermission,
      openSettingsIfDisabled: requestPermission,
    );
    _lastLocationRefresh = DateTime.now();

    if (result.position != null) {
      final newPos = result.position!;
      final movedSignificantly = !hasCachedCoords ||
          (newPos.latitude - parsedLat).abs() > 0.01 ||
          (newPos.longitude - parsedLng).abs() > 0.01;
      await _storage.setString(_latKey, newPos.latitude.toString());
      await _storage.setString(_lngKey, newPos.longitude.toString());

      final hasSavedMethod =
          (_storage.getString('calculation_method') ?? '').isNotEmpty;
      final hasSavedLocName = (_storage.getString(_locNameKey) ?? '').isNotEmpty;

      await _calculatePrayers(
        newPos,
        useSavedMetadataOnly:
            !movedSignificantly && hasSavedMethod && hasSavedLocName,
        scheduleNotifications: true,
      );
    } else if (!hasCachedCoords) {
      _locationName = result.message.isNotEmpty
          ? result.message
          : AppStrings.unknownLocation;
    } else {
      if (_prayerTimes != null && _tomorrowPrayerTimes != null) {
        final afterTomorrow = DateTime.now().add(const Duration(days: 2));
        final params = await _resolveSavedPrayerParams();
        final afterTomorrowTimes = PrayerTimes(
          Coordinates(parsedLat, parsedLng),
          DateComponents(
            afterTomorrow.year,
            afterTomorrow.month,
            afterTomorrow.day,
          ),
          params,
        );
        unawaited(
          _notificationService.schedulePrayerNotifications(
            today: _prayerTimes!,
            tomorrow: _tomorrowPrayerTimes!,
            afterTomorrow: afterTomorrowTimes,
          ),
        );
      }
    }

    _isLoadingLocation = false;
    notifyListeners();
  }

  Future<void> applyPrayerOffsetsAndReschedule() async {
    final coords = _prayerTimes?.coordinates;
    Position? position;
    if (coords != null) {
      position = Position(
        latitude: coords.latitude,
        longitude: coords.longitude,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    } else {
      final savedLat = double.tryParse(_storage.getString(_latKey) ?? '');
      final savedLng = double.tryParse(_storage.getString(_lngKey) ?? '');
      if (savedLat != null && savedLng != null) {
        position = Position(
          latitude: savedLat,
          longitude: savedLng,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        );
      }
    }

    if (position == null) {
      await refreshLocation();
      return;
    }

    await _calculatePrayers(
      position,
      useSavedMetadataOnly: true,
      scheduleNotifications: true,
    );
  }

  Future<CalculationParameters> _resolveSavedPrayerParams() async {
    final savedMethod = _storage.getString('calculation_method');
    CalculationMethod method = CalculationMethod.egyptian;
    if (savedMethod != null && savedMethod.isNotEmpty) {
      method = CalculationMethod.values.firstWhere(
        (e) => e.name == savedMethod,
        orElse: () => CalculationMethod.egyptian,
      );
    }
    final params = method.getParameters();
    params.madhab = Madhab.shafi;
    try {
      final notificationPrefs = await NotificationPreferencesService().load();
      params.adjustments.fajr = notificationPrefs.getPrayerOffset('fajr');
      params.adjustments.sunrise = notificationPrefs.getPrayerOffset('sunrise');
      params.adjustments.dhuhr = notificationPrefs.getPrayerOffset('dhuhr');
      params.adjustments.asr = notificationPrefs.getPrayerOffset('asr');
      params.adjustments.maghrib = notificationPrefs.getPrayerOffset('maghrib');
      params.adjustments.isha = notificationPrefs.getPrayerOffset('isha');
    } catch (_) {}
    return params;
  }

  Future<void> _calculatePrayers(
    Position position, {
    bool useSavedMetadataOnly = false,
    bool scheduleNotifications = true,
  }) async {
    final coordinates = Coordinates(position.latitude, position.longitude);

    CalculationMethod method = CalculationMethod.egyptian;
    final savedMethodName = _storage.getString('calculation_method');
    if (savedMethodName != null && savedMethodName.isNotEmpty) {
      method = CalculationMethod.values.firstWhere(
        (e) => e.name == savedMethodName,
        orElse: () => CalculationMethod.egyptian,
      );
    }

    if (!useSavedMetadataOnly) {
      try {
        final countryCode = await _locationService.getCountryCode(position);
        if (countryCode != null) {
          switch (countryCode.toUpperCase()) {
            case 'SA':
              method = CalculationMethod.umm_al_qura;
              break;
            case 'AE':
            case 'QA':
            case 'KW':
            case 'OM':
            case 'BH':
              method = CalculationMethod.dubai;
              break;
            case 'MA':
            case 'DZ':
            case 'TN':
              method = CalculationMethod.muslim_world_league;
              break;
            case 'JO':
            case 'LB':
            case 'SY':
            case 'PS':
              method = CalculationMethod.karachi;
              break;
            case 'EG':
              method = CalculationMethod.egyptian;
              break;
            default:
              method = CalculationMethod.muslim_world_league;
          }
        }
      } catch (e) {
        debugPrint("Failed to detect country method: $e");
      }
      await _storage.setString('calculation_method', method.name);
    }

    final params = method.getParameters();
    params.madhab = Madhab.shafi;

    try {
      final notificationPrefs = await NotificationPreferencesService().load();
      params.adjustments.fajr = notificationPrefs.getPrayerOffset('fajr');
      params.adjustments.sunrise = notificationPrefs.getPrayerOffset('sunrise');
      params.adjustments.dhuhr = notificationPrefs.getPrayerOffset('dhuhr');
      params.adjustments.asr = notificationPrefs.getPrayerOffset('asr');
      params.adjustments.maghrib = notificationPrefs.getPrayerOffset('maghrib');
      params.adjustments.isha = notificationPrefs.getPrayerOffset('isha');
    } catch (e) {
      debugPrint("Failed to load prayer offsets: $e");
    }

    final todayTimes = PrayerTimes.today(coordinates, params);
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    final tomorrowComponents =
        DateComponents(tomorrow.year, tomorrow.month, tomorrow.day);
    final tomorrowTimes = PrayerTimes(coordinates, tomorrowComponents, params);

    final afterTomorrow = DateTime.now().add(const Duration(days: 2));
    final afterTomorrowTimes = PrayerTimes(
      coordinates,
      DateComponents(
        afterTomorrow.year,
        afterTomorrow.month,
        afterTomorrow.day,
      ),
      params,
    );

    _prayerTimes = todayTimes;
    _tomorrowPrayerTimes = tomorrowTimes;
    _isLoadingLocation = false;
    _updateTaskDescriptions();
    notifyListeners();

    if (!useSavedMetadataOnly) {
      try {
        final resolvedName = await _locationService
            .getLocationName(position)
            .timeout(const Duration(seconds: 5));
        if (resolvedName.trim().isNotEmpty && _locationName != resolvedName) {
          _locationName = resolvedName;
          await _storage.setString(_locNameKey, resolvedName);
          notifyListeners();
        }
      } catch (_) {}
    }

    if (scheduleNotifications) {
      await _notificationService.schedulePrayerNotifications(
        today: todayTimes,
        tomorrow: tomorrowTimes,
        afterTomorrow: afterTomorrowTimes,
      );
      await _updatePrayerWidget();
    }
  }

  Future<void> _updatePrayerWidget() async {
    if (_prayerTimes == null) return;

    try {
      final next = _prayerTimes!.nextPrayer();
      final nextPrayer = next == Prayer.none ? Prayer.fajr : next;
      final nextTime = next == Prayer.none
          ? _tomorrowPrayerTimes?.fajr
          : _prayerTimes!.timeForPrayer(nextPrayer);

      if (nextTime == null) return;

      final duration = nextTime.difference(DateTime.now());
      final safeDuration = duration.isNegative ? Duration.zero : duration;
      final hours = safeDuration.inHours;
      final minutes = safeDuration.inMinutes % 60;
      final remaining =
          hours > 0 ? '$hours\u0633 $minutes\u062f' : '$minutes\u062f';

      await HomeWidget.saveWidgetData<int>(
          'next_prayer_timestamp', nextTime.millisecondsSinceEpoch);
      await HomeWidget.saveWidgetData<String>(
          'prayer_name', _getPrayerNameForWidget(nextPrayer));
      await HomeWidget.saveWidgetData<String>(
          'prayer_time', intl.DateFormat.jm('ar').format(nextTime));
      await HomeWidget.saveWidgetData<String>('remaining_time', remaining);

      // Additional interactive data
      final nowHijri = hijri.HijriCalendar.now();
      await HomeWidget.saveWidgetData<String>('hijri_date',
          "${nowHijri.hDay} ${nowHijri.longMonthName} ${nowHijri.hYear}");
      await HomeWidget.saveWidgetData<String>('location_name', _locationName);

      // Send all prayer times to widget
      final formatter = intl.DateFormat.jm('ar');
      await HomeWidget.saveWidgetData<String>(
          'fajr_time', formatter.format(_prayerTimes!.fajr));
      await HomeWidget.saveWidgetData<String>(
          'dhuhr_time', formatter.format(_prayerTimes!.dhuhr));
      await HomeWidget.saveWidgetData<String>(
          'asr_time', formatter.format(_prayerTimes!.asr));
      await HomeWidget.saveWidgetData<String>(
          'maghrib_time', formatter.format(_prayerTimes!.maghrib));
      await HomeWidget.saveWidgetData<String>(
          'isha_time', formatter.format(_prayerTimes!.isha));
      await HomeWidget.saveWidgetData<String>(
          'next_prayer_id', nextPrayer.name);

      await HomeWidget.updateWidget(androidName: _prayerWidgetName);

      // Update Other Widgets
      await _updateOtherWidgets();
    } catch (e) {
      debugPrint("Prayer widget update failed: $e");
    }
  }

  Future<void> _updateOtherWidgets() async {
    try {
      // 1. Dhikr Widget
      await HomeWidget.saveWidgetData<int>('completed_tasks', completedCount);
      await HomeWidget.saveWidgetData<int>('total_tasks', totalCount);
      await HomeWidget.updateWidget(androidName: 'DhikrWidgetProvider');

      // 2. Verse Widget
      await HomeWidget.saveWidgetData<String>(
          'verse_text', _currentInspiration);
      await HomeWidget.saveWidgetData<String>(
          'verse_source',
          _currentInspirationSource.isEmpty
              ? "حكمة اليوم"
              : _currentInspirationSource);
      await HomeWidget.updateWidget(androidName: 'VerseWidgetProvider');

      // 3. Quran Widget
      await HomeWidget.saveWidgetData<String>('last_surah', _lastSurah);
      await HomeWidget.saveWidgetData<String>(
          'last_ayah', _lastAyah.toString());
      await HomeWidget.updateWidget(androidName: 'QuranWidgetProvider');
    } catch (e) {
      debugPrint("Other widgets update failed: $e");
    }
  }

  String _getPrayerNameForWidget(Prayer p) {
    switch (p) {
      case Prayer.fajr:
        return '\u0627\u0644\u0641\u062c\u0631';
      case Prayer.sunrise:
        return '\u0627\u0644\u0634\u0631\u0648\u0642';
      case Prayer.dhuhr:
        return '\u0627\u0644\u0638\u0647\u0631';
      case Prayer.asr:
        return '\u0627\u0644\u0639\u0635\u0631';
      case Prayer.maghrib:
        return '\u0627\u0644\u0645\u063a\u0631\u0628';
      case Prayer.isha:
        return '\u0627\u0644\u0639\u0634\u0627\u0621';
      default:
        return '';
    }
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
    _updateOtherWidgets();
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
      _updateOtherWidgets();
      notifyListeners();
    }
  }

  void updateProphetPrayerCount(int count) {
    final index = _tasks.indexWhere((t) => t.name.contains(kProphetPrayer));
    if (index != -1) {
      _tasks[index].currentCount = count;
      _tasks[index].isCompleted = (count >= _tasks[index].targetCount);
      _saveTasks();
      _updateOtherWidgets();
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
    final prefs = _storage.prefs;
    final bookmarkSurah = prefs.getString('quran_global_bookmark_surah_name');
    final bookmarkVerse = prefs.getString('quran_global_bookmark_verse');
    final bookmarkSurahNum = prefs.getInt('quran_global_bookmark_surah_number');
    final bookmarkPage = prefs.getInt('quran_global_bookmark_page');
    final bookmarkFullText = prefs.getString('quran_global_bookmark_full_text');

    if (bookmarkSurah != null && bookmarkVerse != null) {
      final parsedAyah = QuranTextFormatter.parseVerseNumber(bookmarkVerse);
      _lastSurah = bookmarkSurah;
      _lastAyah = parsedAyah ?? 1;
      _lastSurahNumber =
          bookmarkSurahNum ?? QuranRepository.findSurahByName(bookmarkSurah).number;
      _lastPage = bookmarkPage ??
          (QuranPageMapping.surahStartPage[_lastSurahNumber] ?? 1);
      _lastVerseText = bookmarkFullText ??
          (prefs.getString('quran_global_bookmark_snippet') ?? '');
      _hasQuranBookmark = true;
      return;
    }

    _lastSurah = _storage.getString(_quranSurahKey) ?? "الفاتحة";
    final a = _storage.getString(_quranAyahKey);
    _lastAyah = a == null ? 1 : (int.tryParse(a) ?? 1);
    final resolvedSurah = QuranRepository.findSurahByName(_lastSurah);
    _lastSurahNumber = prefs.getInt(_quranSurahNumKey) ?? resolvedSurah.number;
    _lastPage = prefs.getInt(_quranPageKey) ??
        (QuranPageMapping.surahStartPage[_lastSurahNumber] ?? 1);
    _lastVerseText = _storage.getString(_quranVerseTextKey) ?? "";
    _hasQuranBookmark = false;
  }

  void syncQuranBookmarkFromPrefs() {
    _loadQuranProgress();
    notifyListeners();
  }

  Future<void> updateQuranProgress(
    String surah,
    int ayah, {
    int? surahNumber,
    int? page,
    String? verseText,
    bool hasBookmark = true,
  }) async {
    final resolvedSurah = surahNumber != null
        ? null
        : QuranRepository.findSurahByName(surah);
    final effectiveSurahNum = surahNumber ?? resolvedSurah!.number;
    final effectivePage =
        (page ?? QuranPageMapping.surahStartPage[effectiveSurahNum] ?? 1)
            .clamp(1, 604);

    _lastSurah = surah;
    _lastAyah = ayah;
    _lastSurahNumber = effectiveSurahNum;
    _lastPage = effectivePage;
    if (verseText != null) {
      _lastVerseText = verseText;
    }
    _hasQuranBookmark = hasBookmark;

    await _storage.setString(_quranSurahKey, surah);
    await _storage.setString(_quranAyahKey, ayah.toString());
    await _storage.prefs.setInt(_quranSurahNumKey, effectiveSurahNum);
    await _storage.prefs.setInt(_quranPageKey, effectivePage);
    if (verseText != null) {
      await _storage.setString(_quranVerseTextKey, verseText);
    }

    _updateOtherWidgets();
    notifyListeners();
  }

  Future<void> clearQuranBookmark() async {
    _hasQuranBookmark = false;
    notifyListeners();
  }

  int _suggestionOffset = 0;

  bool _isTaskDone(String taskName) =>
      _tasks.any((t) => t.name == taskName && t.isCompleted);

  List<ContextSuggestion> get contextSuggestions => buildContextSuggestions(
        now: _now,
        prayerTimes: _prayerTimes,
      );

  ContextSuggestion get activeContextSuggestion {
    final list = contextSuggestions;
    return list[_suggestionOffset % list.length];
  }

  void cycleContextSuggestion() {
    final list = contextSuggestions;
    if (list.isEmpty) return;
    _suggestionOffset = (_suggestionOffset + 1) % list.length;
    notifyListeners();
  }

  String get suggestedAthkar => activeContextSuggestion.title;

  List<ContextSuggestion> buildContextSuggestions({
    required DateTime now,
    required PrayerTimes? prayerTimes,
  }) {
    final suggestions = <ContextSuggestion>[];

    ContextSuggestion prayerSuggestion(String name, DateTime? time,
        String subtitle, IconData icon, Color color) {
      return ContextSuggestion(
        title: name,
        subtitle: subtitle,
        categoryLabel: 'مواقيت الصلاة',
        icon: icon,
        accentColor: color,
        action: ContextSuggestionAction.prayer,
        prayerName: name,
        prayerTime: time,
      );
    }

    // 1. Current Prayer Window (Highest Priority if not completed)
    if (prayerTimes != null) {
      final current = prayerTimes.currentPrayerByDateTime(now);
      final next = prayerTimes.nextPrayerByDateTime(now);

      if (current == Prayer.fajr && !_isTaskDone(kPrayerFajr)) {
        suggestions.add(prayerSuggestion(
          kPrayerFajr,
          prayerTimes.fajr,
          'أدِّ صلاة الفجر واقرأ أذكار ما بعد الصلاة وتفاصيلها 🌅',
          Icons.wb_twilight_rounded,
          const Color(0xFF0284C7),
        ));
      } else if (current == Prayer.dhuhr && !_isTaskDone(kPrayerDhuhr)) {
        suggestions.add(prayerSuggestion(
          kPrayerDhuhr,
          prayerTimes.dhuhr,
          'حافظ على صلاة الظهر في وقتها وتفقد أذكار بعد الصلاة ☀️',
          Icons.wb_sunny_rounded,
          const Color(0xFFD97706),
        ));
      } else if (current == Prayer.asr && !_isTaskDone(kPrayerAsr)) {
        suggestions.add(prayerSuggestion(
          kPrayerAsr,
          prayerTimes.asr,
          'الصلاة الوسطى — بادر بصلاة العصر وأذكار ما بعد الصلاة 🌤️',
          Icons.light_mode_rounded,
          const Color(0xFFEA580C),
        ));
      } else if (current == Prayer.maghrib && !_isTaskDone(kPrayerMaghrib)) {
        suggestions.add(prayerSuggestion(
          kPrayerMaghrib,
          prayerTimes.maghrib,
          'حان وقت صلاة المغرب — اضغط لعرض الأذكار والأحكام 🌇',
          Icons.nights_stay_outlined,
          const Color(0xFFDB2777),
        ));
      } else if (current == Prayer.isha && !_isTaskDone(kPrayerIsha)) {
        suggestions.add(prayerSuggestion(
          kPrayerIsha,
          prayerTimes.isha,
          'اختم يومك بصلاة العشاء وأذكار بعد الصلاة المباركة 🌙',
          Icons.bedtime_rounded,
          const Color(0xFF4F46E5),
        ));
      }

      // Pre-Fajr -> Qiyam Al-Layl
      if (next == Prayer.fajr && now.hour < 5) {
        suggestions.add(const ContextSuggestion(
          title: kPrayerQiyam,
          subtitle: 'أجواء السحر ومناجاة الله في جوف الليل ✨',
          categoryLabel: 'نافلة مباركة',
          icon: Icons.nights_stay_rounded,
          accentColor: Color(0xFF4338CA),
          action: ContextSuggestionAction.qiyam,
        ));
      }
    } else {
      final hour = now.hour;
      if (hour >= 4 && hour < 6 && !_isTaskDone(kPrayerFajr)) {
        suggestions.add(prayerSuggestion(
          kPrayerFajr,
          null,
          'أدِّ صلاة الفجر واطلع على أذكار ما بعد الصلاة 🌅',
          Icons.wb_twilight_rounded,
          const Color(0xFF0284C7),
        ));
      } else if (hour >= 12 && hour < 15 && !_isTaskDone(kPrayerDhuhr)) {
        suggestions.add(prayerSuggestion(
          kPrayerDhuhr,
          null,
          'حافظ على صلاة الظهر وتفقد أذكار بعد الصلاة ☀️',
          Icons.wb_sunny_rounded,
          const Color(0xFFD97706),
        ));
      } else if (hour >= 15 && hour < 18 && !_isTaskDone(kPrayerAsr)) {
        suggestions.add(prayerSuggestion(
          kPrayerAsr,
          null,
          'حافظ على صلاة العصر وأذكار ما بعد الصلاة 🌤️',
          Icons.light_mode_rounded,
          const Color(0xFFEA580C),
        ));
      } else if (hour >= 18 && hour < 19 && !_isTaskDone(kPrayerMaghrib)) {
        suggestions.add(prayerSuggestion(
          kPrayerMaghrib,
          null,
          'أدِّ صلاة المغرب وتفقد أذكار بعد الصلاة 🌇',
          Icons.nights_stay_outlined,
          const Color(0xFFDB2777),
        ));
      } else if (hour >= 19 && hour < 23 && !_isTaskDone(kPrayerIsha)) {
        suggestions.add(prayerSuggestion(
          kPrayerIsha,
          null,
          'أدِّ صلاة العشاء وأذكار بعد الصلاة 🌙',
          Icons.bedtime_rounded,
          const Color(0xFF4F46E5),
        ));
      } else if (hour >= 0 && hour < 4) {
        suggestions.add(const ContextSuggestion(
          title: kPrayerQiyam,
          subtitle: 'أجواء السحر ومناجاة الله في جوف الليل ✨',
          categoryLabel: 'نافلة مباركة',
          icon: Icons.nights_stay_rounded,
          accentColor: Color(0xFF4338CA),
          action: ContextSuggestionAction.qiyam,
        ));
      }
    }

    // 2. Time-appropriate Athkar (prioritize incomplete)
    final hour = now.hour;
    final inMorningWindow = (prayerTimes != null &&
            (prayerTimes.currentPrayerByDateTime(now) == Prayer.sunrise ||
                prayerTimes.currentPrayerByDateTime(now) == Prayer.fajr)) ||
        (hour >= 5 && hour < 12);
    if (inMorningWindow && !_isTaskDone(kAthkarMorning)) {
      suggestions.add(const ContextSuggestion(
        title: kAthkarMorning,
        subtitle: 'حصّن يومك بأذكار الصباح واجعله في حفظ الله ☀️',
        categoryLabel: 'تحصين اليوم',
        icon: Icons.wb_sunny_rounded,
        accentColor: Color(0xFFD97706),
        action: ContextSuggestionAction.morningAthkar,
      ));
    }

    final inEveningWindow = (prayerTimes != null &&
            (prayerTimes.currentPrayerByDateTime(now) == Prayer.asr ||
                prayerTimes.currentPrayerByDateTime(now) == Prayer.maghrib)) ||
        (hour >= 15 && hour < 21);
    if (inEveningWindow && !_isTaskDone(kAthkarEvening)) {
      suggestions.add(const ContextSuggestion(
        title: kAthkarEvening,
        subtitle: 'اقرأ أذكار المساء لطمأنينة قلبك وحفظك ليلاً 🌆',
        categoryLabel: 'تحصين المساء',
        icon: Icons.brightness_4_rounded,
        accentColor: Color(0xFF7C3AED),
        action: ContextSuggestionAction.eveningAthkar,
      ));
    }

    if ((hour >= 20 || hour < 4) && !_isTaskDone(kAthkarSleep)) {
      suggestions.add(const ContextSuggestion(
        title: kAthkarSleep,
        subtitle: 'اختم ليلتك بأذكار النوم لتبيت في أمان الله 🛌',
        categoryLabel: 'قبل النوم',
        icon: Icons.bedtime_outlined,
        accentColor: Color(0xFF4F46E5),
        action: ContextSuggestionAction.sleepAthkar,
      ));
    }

    // 3. Friday Special Suggestions
    if (now.weekday == DateTime.friday) {
      suggestions.add(const ContextSuggestion(
        title: 'سورة الكهف',
        subtitle: 'نورٌ ما بين الجمعتين — تلاوة سورة الكهف المباركة 📖',
        categoryLabel: 'سنن الجمعة',
        icon: Icons.auto_stories_rounded,
        accentColor: Color(0xFF15803D),
        action: ContextSuggestionAction.surahKahf,
      ));
      if (!_isTaskDone(kProphetPrayer)) {
        suggestions.add(const ContextSuggestion(
          title: '$kProphetPrayer ﷺ',
          subtitle: 'أكثر من الصلاة على النبي ﷺ في يوم الجمعة المبارك 💛',
          categoryLabel: 'سنن الجمعة',
          icon: Icons.favorite_rounded,
          accentColor: Color(0xFFE11D48),
          action: ContextSuggestionAction.prophetPrayer,
        ));
      }
    }

    // 4. Daily Quran Wird / Khatmah
    if (!_isTaskDone(kQuranWird)) {
      suggestions.add(const ContextSuggestion(
        title: 'متابعة ورد القرآن والختمة',
        subtitle: 'افتح متابع الختمة وتقدم في وردك اليومي من كتاب الله 📖',
        categoryLabel: 'كتاب الله',
        icon: Icons.menu_book_rounded,
        accentColor: Color(0xFF0F766E),
        action: ContextSuggestionAction.khatmah,
      ));
    }

    // 5. Happiness Jar (Uplifting Daily Message)
    suggestions.add(const ContextSuggestion(
      title: 'برطمان السعادة 💛',
      subtitle: 'اسحب رسالة مبهجة تزرع الأمل والسرور في قلبك اليوم ✨',
      categoryLabel: 'جرعة تفاؤل',
      icon: Icons.card_giftcard_rounded,
      accentColor: Color(0xFFD97706),
      action: ContextSuggestionAction.happinessJar,
    ));

    // 6. Prophet Prayer (non-Friday if incomplete)
    if (now.weekday != DateTime.friday && !_isTaskDone(kProphetPrayer)) {
      suggestions.add(const ContextSuggestion(
        title: '$kProphetPrayer ﷺ',
        subtitle: 'من صلى عليّ صلاةً صلى الله عليه بها عشراً 🌿',
        categoryLabel: 'ذكر مبارك',
        icon: Icons.favorite_rounded,
        accentColor: Color(0xFFDB2777),
        action: ContextSuggestionAction.prophetPrayer,
      ));
    }

    // 7. Tasbeeh / Istighfar
    suggestions.add(const ContextSuggestion(
      title: 'استغفر الله • المسبحة الذكية',
      subtitle: 'رطّب لسانك بالاستغفار والتسبيح في دقائق معدودة 📿',
      categoryLabel: 'تسبيح وذكر',
      icon: Icons.fingerprint_rounded,
      accentColor: Color(0xFF0F766E),
      action: ContextSuggestionAction.tasbeeh,
    ));

    return suggestions;
  }

  // --- Dynamic Background Logic ---
  LinearGradient get currentBackgroundGradient {
    final hour = _now.hour;

    // Fajr / Early Morning (4 - 6) - Purple to Orange (Sunrise)
    if (hour >= 4 && hour < 6) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2C3E50), Color(0xFFFD746C)],
      );
    }
    // Morning / Day (6 - 16) - Bright Blue
    else if (hour >= 6 && hour < 16) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF2980B9), Color(0xFF6DD5FA), Color(0xFFFFFFFF)],
      );
    }
    // Sunset / Maghrib (16 - 19) - Orange to Deep Purple
    else if (hour >= 16 && hour < 19) {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFff7e5f), Color(0xFFfeb47b)], // Sunset theme
      );
    }
    // Night (19 - 4) - Deep Blue/Black
    else {
      return const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFF141E30), Color(0xFF243B55)],
      );
    }
  }

  // --- Rings Progress Logic ---
  // Returns value between 0.0 and 1.0
  double get prayersProgress {
    final prayerTasks = _tasks.where((t) =>
        t.name == kPrayerFajr ||
        t.name == kPrayerDhuhr ||
        t.name == kPrayerAsr ||
        t.name == kPrayerMaghrib ||
        t.name == kPrayerIsha);
    if (prayerTasks.isEmpty) return 0.0;
    final completed = prayerTasks.where((t) => t.isCompleted).length;
    return completed / prayerTasks.length;
  }

  double get athkarProgress {
    final athkarTasks = _tasks.where((t) =>
        t.name == kAthkarMorning ||
        t.name == kAthkarEvening ||
        t.name == kAthkarSleep ||
        t.name == kProphetPrayer); // Including Prophet's prayer
    if (athkarTasks.isEmpty) return 0.0;
    final completed = athkarTasks.where((t) => t.isCompleted).length;
    return completed / athkarTasks.length;
  }

  double get quranProgress {
    final quranTask =
        _tasks.firstWhere((t) => t.name == kQuranWird, orElse: () => _tasks[0]);
    // Also include 'Sunnah' prayers as bonus here if you want
    // For now simple single task check
    return quranTask.isCompleted ? 1.0 : 0.0;
  }

  // Quick Action Handler
  void performQuickAction(String actionName) {
    // Just increment a virtual "Good Deeds" counter or Streak for visual feedback
    // In real app, save to DB
    _morningStreak++; // Using streak as points for now
    notifyListeners();
  }
}
