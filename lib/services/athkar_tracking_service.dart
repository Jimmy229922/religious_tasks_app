import 'dart:convert';
import 'package:intl/intl.dart';
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
}
