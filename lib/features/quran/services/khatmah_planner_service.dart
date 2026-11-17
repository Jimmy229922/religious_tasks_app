import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';

class KhatmahPlan {
  final int targetDays;
  final int startPage;
  final int startDateMillis;

  const KhatmahPlan({
    required this.targetDays,
    required this.startPage,
    required this.startDateMillis,
  });

  int get pagesPerDay => ((605 - startPage) / targetDays).ceil();
  int get pagesPerPrayer => (pagesPerDay / 5).ceil();

  String getTodayRequirement({DateTime? now}) {
    final startDate = DateTime.fromMillisecondsSinceEpoch(startDateMillis);
    final today = now ?? DateTime.now();
    final startDay = DateTime(startDate.year, startDate.month, startDate.day);
    final currentDay = DateTime(today.year, today.month, today.day);
    final elapsedDays = max(0, currentDay.difference(startDay).inDays);
    final firstPage = startPage + (elapsedDays * pagesPerDay);
    if (firstPage > 604) {
      return "اكتملت مدة خطة الختمة. يمكنك بدء خطة جديدة.";
    }
    final lastPage = min(604, firstPage + pagesPerDay - 1);
    final pageCount = lastPage - firstPage + 1;
    return "وردك اليوم: من الصفحة $firstPage إلى $lastPage ($pageCount صفحة • نحو $pagesPerPrayer صفحات بعد كل صلاة)";
  }
}

class KhatmahPlannerService {
  static const String _daysKey = 'khatmah_target_days';
  static const String _startPageKey = 'khatmah_start_page';
  static const String _startDateKey = 'khatmah_start_date';

  static Future<void> savePlan(int targetDays, {int startPage = 1}) async {
    if (targetDays < 5 || targetDays > 60) {
      throw ArgumentError.value(targetDays, 'targetDays');
    }
    if (startPage < 1 || startPage > 604) {
      throw ArgumentError.value(startPage, 'startPage');
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_daysKey, targetDays);
    await prefs.setInt(_startPageKey, startPage);
    await prefs.setInt(_startDateKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<KhatmahPlan?> loadPlan() async {
    final prefs = await SharedPreferences.getInstance();
    final days = prefs.getInt(_daysKey);
    final startPage = prefs.getInt(_startPageKey) ?? 1;
    final startDate = prefs.getInt(_startDateKey);

    if (days == null ||
        days < 5 ||
        days > 60 ||
        startPage < 1 ||
        startPage > 604 ||
        startDate == null ||
        startDate <= 0) {
      return null;
    }
    return KhatmahPlan(
      targetDays: days,
      startPage: startPage,
      startDateMillis: startDate,
    );
  }

  static Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_daysKey);
    await prefs.remove(_startPageKey);
    await prefs.remove(_startDateKey);
  }
}
