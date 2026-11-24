import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:religious_tasks_app/features/athkar/data/athkar_data.dart';
import 'package:religious_tasks_app/features/athkar/models/dhikr_item.dart';
import 'storage_service.dart';

class AthkarTrackingService {
  static const String _morningDoneKey = 'athkar_morning_done_dates';
  static const String _eveningDoneKey = 'athkar_evening_done_dates';

  static String formatDay(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  static Future<void> markCompleted({
    required bool isMorning,
    DateTime? date,
  }) async {
    final key = isMorning ? _morningDoneKey : _eveningDoneKey;
    final dayKey = formatDay(date ?? DateTime.now());
    final dates = _readDateSet(key);
    if (dates.add(dayKey)) {
      await _writeDateSet(key, dates);
    }
  }

  static Future<Set<String>> loadCompletedDays({
    required bool isMorning,
  }) async {
    final key = isMorning ? _morningDoneKey : _eveningDoneKey;
    return _readDateSet(key);
  }

  static Set<String> _readDateSet(String key) {
    final raw = StorageService.instance.getString(key);
    if (raw == null || raw.isEmpty) return <String>{};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <String>{};
      return decoded.whereType<String>().toSet();
    } catch (_) {
      return <String>{};
    }
  }

  static Future<void> _writeDateSet(
    String key,
    Set<String> dates,
  ) async {
    final sorted = dates.toList()..sort();
    await StorageService.instance.setString(key, jsonEncode(sorted));
  }

  static const String _streaksKey = 'athkar_streaks_v1';
  static const String _tasksLastDatePrefix = 'saved_tasks_v2_last_date_';

  static Map<String, int> loadStreaks() {
    final raw = StorageService.instance.getString(_streaksKey);
    if (raw == null || raw.isEmpty) {
      return {'morning': 0, 'evening': 0, 'sleep': 0};
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return {
          'morning': decoded['morning'] is int ? decoded['morning'] as int : 0,
          'evening': decoded['evening'] is int ? decoded['evening'] as int : 0,
          'sleep': decoded['sleep'] is int ? decoded['sleep'] as int : 0,
        };
      }
    } catch (_) {}
    return {'morning': 0, 'evening': 0, 'sleep': 0};
  }

  static Future<void> syncStreakWithStorage(String type) async {
    final now = DateTime.now();
    final todayStr = formatDay(now);
    final yesterdayStr = formatDay(now.subtract(const Duration(days: 1)));
    final lastDateKey = '$_tasksLastDatePrefix$type';
    final lastDate = StorageService.instance.getString(lastDateKey);

    if (lastDate == todayStr) return;

    final streaks = loadStreaks();
    int currentStreak = streaks[type] ?? 0;
    if (lastDate == yesterdayStr) {
      currentStreak++;
    } else {
      currentStreak = 1;
    }

    streaks[type] = currentStreak;
    await StorageService.instance.setString(lastDateKey, todayStr);
    await StorageService.instance.setString(_streaksKey, jsonEncode(streaks));
  }

  static Map<String, int> loadTodayAthkarReadCounts() {
    final todayStr = formatDay(DateTime.now());
    return {
      'morning': _sumProgressForDate(
        'athkar_morning_date',
        'athkar_morning_progress',
        todayStr,
      ),
      'evening': _sumProgressForDate(
        'athkar_evening_date',
        'athkar_evening_progress',
        todayStr,
      ),
      'sleep': _sumProgressForDate(
        'athkar_sleep_date',
        'athkar_sleep_progress',
        todayStr,
      ),
    };
  }

  static int _sumProgressForDate(
    String dateKey,
    String progressKey,
    String todayStr,
  ) {
    final prefs = StorageService.instance.prefs;
    if (prefs.getString(dateKey) != todayStr) return 0;
    final raw = prefs.getString(progressKey);
    if (raw == null || raw.isEmpty) return 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return 0;
      int total = 0;
      for (final val in decoded) {
        if (val is int && val > 0) total += val;
      }
      return total;
    } catch (_) {
      return 0;
    }
  }

  static Map<String, ({int completed, int total})>
      loadTodayAthkarCompletionSummary() {
    final todayStr = formatDay(DateTime.now());
    return {
      'morning': _countCompletedForDate(
        'athkar_morning_date',
        'athkar_morning_progress',
        todayStr,
        buildMorningAthkar(),
      ),
      'evening': _countCompletedForDate(
        'athkar_evening_date',
        'athkar_evening_progress',
        todayStr,
        buildEveningAthkar(),
      ),
      'sleep': _countCompletedForDate(
        'athkar_sleep_date',
        'athkar_sleep_progress',
        todayStr,
        buildSleepAthkar(),
      ),
    };
  }

  static ({int completed, int total}) _countCompletedForDate(
    String dateKey,
    String progressKey,
    String todayStr,
    List<DhikrItem> items,
  ) {
    final total = items.length;
    final prefs = StorageService.instance.prefs;
    if (prefs.getString(dateKey) != todayStr) {
      return (completed: 0, total: total);
    }
    final raw = prefs.getString(progressKey);
    if (raw == null || raw.isEmpty) {
      return (completed: 0, total: total);
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return (completed: 0, total: total);
      int completed = 0;
      for (int i = 0; i < total && i < decoded.length; i++) {
        final val = decoded[i];
        if (val is int && val >= items[i].count) {
          completed++;
        }
      }
      return (completed: completed, total: total);
    } catch (_) {
      return (completed: 0, total: total);
    }
  }
}
