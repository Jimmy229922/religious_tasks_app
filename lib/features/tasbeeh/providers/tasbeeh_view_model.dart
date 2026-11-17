import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/services/global_challenge_service.dart';

class TasbeehViewModel extends ChangeNotifier {
  static const String _prefsKey = 'custom_tasbeeh_athkar';
  static const String _totalCountKey = 'total_tasbeeh_count_v1';
  static const String _pendingGlobalCountKey =
      'pending_global_tasbeeh_count_v1';
  static const String customOption = '__custom__';

  final GlobalChallengeService _globalService = GlobalChallengeService();
  int _globalCount = 0;
  final int _maxTarget = 1000000;
  int _localSessionCount = 0;
  bool _globalSyncFailed = false;
  bool _isSyncing = false;
  Timer? _syncTimer;
  StreamSubscription<Map<String, dynamic>>? _challengeSubscription;
  StreamSubscription<dynamic>? _authSubscription;
  bool _isDisposed = false;

  final List<int> _milestones = [
    1000,
    5000,
    10000,
    50000,
    100000,
    500000,
    1000000
  ];

  int get globalCount => _globalCount;
  int get maxTarget => _maxTarget;
  bool get globalSyncFailed => _globalSyncFailed;
  bool get hasPendingGlobalSync => _localSessionCount > 0;
  bool get globalContributionRequiresAccount =>
      !_globalService.hasAuthenticatedSession;

  int get currentMilestone {
    for (int milestone in _milestones) {
      if (_globalCount < milestone) return milestone;
    }
    return _maxTarget;
  }

  int get lastAchievedMilestone {
    int last = 0;
    for (int milestone in _milestones) {
      if (_globalCount >= milestone) {
        last = milestone;
      } else {
        break;
      }
    }
    return last;
  }

  List<int> get achievedMilestones {
    return _milestones.where((m) => _globalCount >= m).toList();
  }

  double get globalProgress {
    if (_globalCount >= _maxTarget) return 1.0;
    return (_globalCount / currentMilestone).clamp(0.0, 1.0);
  }

  bool get isChallengeCompleted => _globalCount >= _maxTarget;

  static const List<String> _defaultAthkar = [
    'اللهم صلِّ وسلم وبارك على نبينا محمد',
  ];

  int _counter = 0;
  int _totalCounter = 0;
  String _selectedDhikr = _defaultAthkar.first;
  bool _isCustomInput = false;
  List<String> _customAthkar = [];
  final TextEditingController customController = TextEditingController();

  int get counter => _counter;
  int get totalCounter => _totalCounter;
  String get selectedDhikr => _selectedDhikr;
  bool get isCustomInput => _isCustomInput;
  List<String> get allAthkar => [..._defaultAthkar, ..._customAthkar];

  TasbeehViewModel() {
    _loadCustomAthkar();
    _loadTotalCount();
    _initGlobalSync();
  }

  void _initGlobalSync() {
    _globalService.subscribeToChallenge();
    _challengeSubscription = _globalService.challengeStream.listen((data) {
      _globalCount = data['count'] ?? 0;
      notifyListeners();
    });
    _authSubscription = _globalService.authStateChanges.listen((_) {
      if (_localSessionCount > 0 && _globalService.hasAuthenticatedSession) {
        _startSyncTimer(Duration.zero);
      }
    });
  }

  Future<void> _loadTotalCount() async {
    final prefs = StorageService.instance.prefs;
    _totalCounter = prefs.getInt(_totalCountKey) ?? 0;
    _localSessionCount = prefs.getInt(_pendingGlobalCountKey) ?? 0;
    if (_localSessionCount > 0) {
      _startSyncTimer();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _challengeSubscription?.cancel();
    _authSubscription?.cancel();
    customController.dispose();
    _isDisposed = true;
    super.dispose();
  }

  Future<void> _loadCustomAthkar() async {
    final prefs = StorageService.instance.prefs;
    _customAthkar = prefs.getStringList(_prefsKey) ?? [];
    notifyListeners();
  }

  Future<void> _saveCustomAthkar() async {
    final prefs = StorageService.instance.prefs;
    await prefs.setStringList(_prefsKey, _customAthkar);
  }

  void increment() {
    if (isChallengeCompleted) return;

    _counter++;
    _totalCounter++;
    _localSessionCount++;
    HapticFeedback.lightImpact();
    unawaited(
      StorageService.instance.prefs.setInt(_totalCountKey, _totalCounter),
    );
    unawaited(_persistPendingGlobalCount());

    // Batch sync to avoid hitting Supabase on EVERY click (throttling)
    _startSyncTimer();

    notifyListeners();
  }

  void _startSyncTimer([
    Duration delay = const Duration(seconds: 2),
  ]) {
    _syncTimer?.cancel();
    _syncTimer = Timer(delay, () {
      unawaited(_syncToSupabase());
    });
  }

  Future<void> _syncToSupabase() async {
    if (_isSyncing || _localSessionCount <= 0) return;
    if (!_globalService.hasAuthenticatedSession) {
      _globalSyncFailed = true;
      notifyListeners();
      return;
    }

    _isSyncing = true;
    var successfulBatches = 0;
    try {
      while (_localSessionCount > 0 && successfulBatches < 3) {
        final amountToSync = _localSessionCount.clamp(1, 100);
        final success =
            await _globalService.incrementGlobalCounter(amountToSync);
        if (!success) {
          _globalSyncFailed = true;
          _startSyncTimer(const Duration(minutes: 1));
          break;
        }

        _localSessionCount -= amountToSync;
        successfulBatches++;
        _globalSyncFailed = false;
        await _persistPendingGlobalCount();
      }

      if (_localSessionCount > 0 && !_globalSyncFailed) {
        _startSyncTimer(const Duration(minutes: 1));
      }
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  Future<void> _persistPendingGlobalCount() async {
    final prefs = StorageService.instance.prefs;
    if (_localSessionCount <= 0) {
      await prefs.remove(_pendingGlobalCountKey);
    } else {
      await prefs.setInt(_pendingGlobalCountKey, _localSessionCount);
    }
  }

  void reset() {
    _counter = 0;
    HapticFeedback.mediumImpact();
    notifyListeners();
  }

  void selectDhikr(String? value) {
    if (value == null) return;
    if (value == customOption) {
      _isCustomInput = true;
      _selectedDhikr = customController.text.trim();
    } else {
      _isCustomInput = false;
      _selectedDhikr = value;
    }
    _counter = 0;
    notifyListeners();
  }

  void updateCustomText(String value) {
    if (_isCustomInput) {
      _selectedDhikr = value;
      notifyListeners();
    }
  }

  String? addCustomDhikr() {
    final text = customController.text.trim();
    if (text.isEmpty) {
      return 'اكتب الذكر أولاً';
    }

    final exists =
        _defaultAthkar.contains(text) || _customAthkar.contains(text);

    if (!exists) {
      _customAthkar.add(text);
      _saveCustomAthkar();
    }

    _selectedDhikr = text;
    _isCustomInput = false;
    _counter = 0;
    customController.clear();
    notifyListeners();

    return 'تمت إضافة الذكر';
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }
}
