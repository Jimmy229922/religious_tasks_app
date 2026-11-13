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

  int get pagesPerDay => (604 / targetDays).ceil();
  int get pagesPerPrayer => (pagesPerDay / 5).ceil();

  String getTodayRequirement(int currentPage) {
    final nextTargetPage = min(604, currentPage + pagesPerDay);
    return "وردك اليوم: من الصفحة ${currentPage == 0 ? 1 : currentPage} إلى $nextTargetPage ($pagesPerDay صفحة • $pagesPerPrayer صفحات بعد كل صلاة)";
  }
}

class KhatmahPlannerService {
  static const String _daysKey = 'khatmah_target_days';
  static const String _startPageKey = 'khatmah_start_page';
  static const String _startDateKey = 'khatmah_start_date';

  static Future<void> savePlan(int targetDays, {int startPage = 1}) async {
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

    if (days == null) return null;
    return KhatmahPlan(
      targetDays: days,
      startPage: startPage,
      startDateMillis: startDate ?? DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<void> clearPlan() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_daysKey);
    await prefs.remove(_startPageKey);
    await prefs.remove(_startDateKey);
  }
}
