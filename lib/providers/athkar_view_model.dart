import 'dart:convert';
import 'package:flutter/material.dart';
import '../data/athkar_data.dart';
import '../models/dhikr_item.dart';
import '../services/athkar_tracking_service.dart';

import '../services/storage_service.dart';

enum AthkarType { morning, evening, sleep }

class AthkarViewModel extends ChangeNotifier {
  bool _isLoading = true;
  late AthkarDataState _data;

  bool get isLoading => _isLoading;
  AthkarDataState get data => _data;

  AthkarViewModel() {
    _loadDailyData();
  }

  Future<void> loadDailyData() async {
    await _loadDailyData();
  }

  Future<void> _loadDailyData() async {
    _isLoading = true;
    // notifyListeners();

    final prefs = StorageService.instance.prefs;
    final todayKey = AthkarTrackingService.formatDay(DateTime.now());

    final morning = _loadProgress(prefs.getString,
        type: AthkarType.morning, todayKey: todayKey);
    final evening = _loadProgress(prefs.getString,
        type: AthkarType.evening, todayKey: todayKey);
    final sleep = _loadProgress(prefs.getString,
        type: AthkarType.sleep, todayKey: todayKey);

    final morningDays =
        await AthkarTrackingService.loadCompletedDays(isMorning: true);
    final eveningDays =
        await AthkarTrackingService.loadCompletedDays(isMorning: false);
    final completedDays = morningDays.intersection(eveningDays);
    final todayComplete = completedDays.contains(todayKey);
    final streak = _calculateStreak(completedDays, todayComplete);
    final encouragement = _buildEncouragement(morning, evening);

    _data = AthkarDataState(
      morning: morning,
      evening: evening,
      sleep: sleep,
      streak: streak,
      todayComplete: todayComplete,
      encouragement: encouragement,
    );
    _isLoading = false;
    notifyListeners();
  }

  AthkarProgress _loadProgress(
    String? Function(String key) getString, {
    required AthkarType type,
    required String todayKey,
  }) {
    List<DhikrItem> items;
    String dateKey;
    String progressKey;

    switch (type) {
      case AthkarType.morning:
        items = buildMorningAthkar();
        dateKey = 'athkar_morning_date';
        progressKey = 'athkar_morning_progress';
        break;
      case AthkarType.evening:
        items = buildEveningAthkar();
        dateKey = 'athkar_evening_date';
        progressKey = 'athkar_evening_progress';
        break;
      case AthkarType.sleep:
        items = buildSleepAthkar();
        dateKey = 'athkar_sleep_date';
        progressKey = 'athkar_sleep_progress';
        break;
    }

    final total = items.fold<int>(0, (sum, item) => sum + item.count);

    if (getString(dateKey) != todayKey && type != AthkarType.sleep) {
      // Sleep athkar might be done at night (next day logic?) or same day.
      // For now, assume same day reset logic applies.
      return AthkarProgress(current: 0, total: total);
    }

    // For sleep, we might want to check if logic differs, but keeping standard for now.
    if (type == AthkarType.sleep && getString(dateKey) != todayKey) {
      return AthkarProgress(current: 0, total: total);
    }

    final raw = getString(progressKey);
    if (raw == null || raw.isEmpty) {
      return AthkarProgress(current: 0, total: total);
    }

    int current = 0;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        for (int i = 0; i < items.length && i < decoded.length; i++) {
          final value = decoded[i];
          if (value is int) {
            final capped = value.clamp(0, items[i].count);
            current += capped;
          }
        }
      }
    } catch (_) {
      return AthkarProgress(current: 0, total: total);
    }

    return AthkarProgress(current: current, total: total);
  }

  int _calculateStreak(Set<String> completedDays, bool todayComplete) {
    DateTime cursor = DateTime.now();
    if (!todayComplete) {
      cursor = cursor.subtract(const Duration(days: 1));
    }

    int streak = 0;
    while (completedDays.contains(AthkarTrackingService.formatDay(cursor))) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    return streak;
  }

  String _buildEncouragement(
    AthkarProgress morning,
    AthkarProgress evening,
  ) {
    final totalCurrent = morning.current + evening.current;
    if (morning.isComplete && evening.isComplete) {
      return '\u0645\u0627 \u0634\u0627\u0621 \u0627\u0644\u0644\u0647\u0021 \u0623\u062a\u0645\u0645\u062a \u0623\u0630\u0643\u0627\u0631 \u0627\u0644\u064a\u0648\u0645.';
    }
    if (morning.isComplete || evening.isComplete) {
      return '\u0623\u062d\u0633\u0646\u062a\u0021 \u062a\u0628\u0642\u0651\u0649 \u0627\u0644\u062c\u0632\u0621 \u0627\u0644\u0622\u062e\u0631 \u0644\u0625\u0643\u0645\u0627\u0644 \u0627\u0644\u064a\u0648\u0645.';
    }
    if (totalCurrent > 0) {
      return '\u0628\u062f\u0627\u064a\u0629 \u0637\u064a\u0628\u0629\u060c \u0648\u0627\u0635\u0644 \u0627\u0644\u0630\u0643\u0631 \u0639\u0644\u0649 \u0645\u0647\u0644.';
    }
    return '\u0627\u0628\u062f\u0623 \u0628\u0630\u0643\u0631 \u064a\u0633\u064a\u0631 \u064a\u0641\u062a\u062d \u0644\u0643 \u0628\u0631\u0643\u0629 \u064a\u0648\u0645\u0643.';
  }
}

class AthkarProgress {
  final int current;
  final int total;

  AthkarProgress({required this.current, required this.total});

  double get ratio => total == 0 ? 0 : current / total;
  bool get isComplete => total > 0 && current >= total;
}

class AthkarDataState {
  final AthkarProgress morning;
  final AthkarProgress evening;
  final AthkarProgress sleep;
  final int streak;
  final bool todayComplete;
  final String encouragement;

  AthkarDataState({
    required this.morning,
    required this.evening,
    required this.sleep,
    required this.streak,
    required this.todayComplete,
    required this.encouragement,
  });
}
