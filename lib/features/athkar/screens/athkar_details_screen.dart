import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/athkar_data.dart';
import '../models/dhikr_item.dart';
import 'package:religious_tasks_app/core/services/athkar_tracking_service.dart';
import 'package:religious_tasks_app/core/services/storage_service.dart';
import 'package:religious_tasks_app/core/services/audio_service.dart';
import 'package:religious_tasks_app/core/services/ad_service.dart';
import '../widgets/dhikr_card.dart';
import '../widgets/details/athkar_header.dart';
import '../widgets/details/athkar_controls.dart';
import '../widgets/details/athkar_empty_state.dart';
import '../widgets/details/athkar_focus_navigator.dart';

class AthkarDetailsScreen extends StatefulWidget {
  final String title;
  final bool isMorning;

  const AthkarDetailsScreen({
    super.key,
    required this.title,
    required this.isMorning,
  });

  @override
  State<AthkarDetailsScreen> createState() => _AthkarDetailsScreenState();
}

class _AthkarDetailsScreenState extends State<AthkarDetailsScreen> {
  static const Duration _removeDuration = Duration(milliseconds: 500);
  static const String _fontScaleKey = 'athkar_font_scale';
  static const double _minFontScale = 0.85;
  static const double _maxFontScale = 1.45;

  final ScrollController _scrollController = ScrollController();
  List<DhikrItem> _allAthkar = [];
  List<DhikrItem> _visibleAthkar = [];
  final Set<DhikrItem> _removingItems = {};
  bool _isLoading = true;
  bool _showCompleted = false;
  bool _focusMode = false;
  bool _isNightMode = false;
  bool _themeInitialized = false;
  int _focusIndex = 0;
  double _fontScale = 1.0;
  late final String _progressKey;
  late final String _dateKey;

  final AudioService _audioService = AudioService();
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _audioService.init();

    if (widget.title == "أذكار النوم") {
      _progressKey = 'athkar_sleep_progress';
      _dateKey = 'athkar_sleep_date';
    } else {
      _progressKey = widget.isMorning
          ? 'athkar_morning_progress'
          : 'athkar_evening_progress';
      _dateKey =
          widget.isMorning ? 'athkar_morning_date' : 'athkar_evening_date';
    }

    _loadProgress();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_themeInitialized) {
      _isNightMode = Theme.of(context).brightness == Brightness.dark;
      _themeInitialized = true;
    }
  }

  @override
  void dispose() {
    _audioService.stop();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _speak(DhikrItem item, int index) async {
    if (_playingIndex == index) {
      await _audioService.stop();
      setState(() => _playingIndex = null);
      return;
    }

    await _audioService.stop();
    setState(() => _playingIndex = index);

    await _audioService.speak(item.text, onCompletion: () {
      if (mounted) setState(() => _playingIndex = null);
    });
  }

  String _todayKey() {
    final now = DateTime.now();
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    return '${now.year}-$month-$day';
  }

  Future<void> _loadProgress() async {
    final prefs = StorageService.instance.prefs;
    final today = _todayKey();
    final savedDate = prefs.getString(_dateKey);
    final savedScale = prefs.getDouble(_fontScaleKey);

    List<DhikrItem> list;
    if (widget.title == "أذكار النوم") {
      list = buildSleepAthkar();
    } else {
      list = widget.isMorning ? buildMorningAthkar() : buildEveningAthkar();
    }

    if (savedDate == today) {
      final saved = prefs.getString(_progressKey);
      if (saved != null) {
        final List<dynamic> counts = jsonDecode(saved);
        for (int i = 0; i < list.length && i < counts.length; i++) {
          final value = counts[i];
          if (value is int) {
            final capped =
                value < 0 ? 0 : (value > list[i].count ? list[i].count : value);
            list[i].current = capped;
          }
        }
      }
    } else {
      await prefs.setString(_dateKey, today);
      await prefs.remove(_progressKey);
    }

    final fontScale = _clampFontScale(savedScale ?? _fontScale);
    final visible = _filterVisible(list);

    if (!mounted) return;
    setState(() {
      _allAthkar = list;
      _visibleAthkar = visible;
      _fontScale = fontScale;
      _focusIndex = _clampFocusIndex(_focusIndex, visible.length);
      _isLoading = false;
    });
  }

  Future<void> _saveProgress() async {
    final prefs = StorageService.instance.prefs;
    final counts =
        _allAthkar.map((item) => item.current).toList(growable: false);
    await prefs.setString(_progressKey, jsonEncode(counts));
  }

  double _clampFontScale(double value) {
    return value.clamp(_minFontScale, _maxFontScale).toDouble();
  }

  int _clampFocusIndex(int value, int length) {
    if (length <= 0) return 0;
    if (value < 0) return 0;
    if (value >= length) return length - 1;
    return value;
  }

  List<DhikrItem> _filterVisible(List<DhikrItem> source) {
    if (_showCompleted) {
      return List<DhikrItem>.from(source);
    }
    return source.where((item) => item.current < item.count).toList();
  }

  Future<void> _saveFontScale() async {
    final prefs = StorageService.instance.prefs;
    await prefs.setDouble(_fontScaleKey, _fontScale);
  }

  void _setFontScale(double value) {
    final clamped = _clampFontScale(value);
    if (clamped == _fontScale) return;
    setState(() {
      _fontScale = clamped;
    });
    _saveFontScale();
  }

  void _stepFont(double delta) {
    _setFontScale(_fontScale + delta);
  }

  void _toggleShowCompleted(bool value) {
    if (_showCompleted == value) return;
    setState(() {
      _showCompleted = value;
      _removingItems.clear();
      _visibleAthkar = _filterVisible(_allAthkar);
      _focusIndex = _clampFocusIndex(_focusIndex, _visibleAthkar.length);
    });
    _maybeScrollToTop(force: true);
  }

  void _toggleFocusMode(bool value) {
    if (_focusMode == value) return;
    setState(() {
      _focusMode = value;
      _focusIndex = _clampFocusIndex(_focusIndex, _visibleAthkar.length);
    });
    if (value) {
      _maybeScrollToTop(force: true);
    }
  }

  void _goFocusNext() {
    if (_focusIndex + 1 >= _visibleAthkar.length) return;
    setState(() {
      _focusIndex++;
    });
  }

  void _goFocusPrev() {
    if (_focusIndex <= 0) return;
    setState(() {
      _focusIndex--;
    });
  }

  void _maybeScrollToTop({bool force = false}) {
    if (!_scrollController.hasClients) return;
    if (!force && _scrollController.offset > 120) return;
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _increment(int index) {
    if (index < 0 || index >= _visibleAthkar.length) return;
    final item = _visibleAthkar[index];
    if (item.current >= item.count) return;

    HapticFeedback.lightImpact();

    // Prevent double tapping causing double scheduling
    if (_removingItems.contains(item)) return;

    setState(() {
      item.current++;
    });
    _saveProgress();

    if (item.current >= item.count) {
      HapticFeedback.mediumImpact();
      if (!_showCompleted) {
        _scheduleRemovalSequence(item);
      }
    }
  }

  void _scheduleRemovalSequence(DhikrItem item) async {
    // For Focus Mode, we want seamless transition A -> B.
    // relying on AnimatedSwitcher to handle the swap.
    if (_focusMode) {
      // Short delay just to see the "final count" for a split second
      await Future.delayed(const Duration(milliseconds: 100));
      if (!mounted) return;
      setState(() {
        _visibleAthkar.remove(item);
        // Ensure index is valid
        _focusIndex = _clampFocusIndex(_focusIndex, _visibleAthkar.length);
      });
      return;
    }

    // List Mode: We use the "Removing" state to collapse the item gracefully.
    if (!mounted) return;

    setState(() {
      _removingItems.add(item);
    });

    await Future.delayed(_removeDuration);
    if (!mounted) return;

    setState(() {
      _visibleAthkar.remove(item);
      _removingItems.remove(item);
      _focusIndex = _clampFocusIndex(_focusIndex, _visibleAthkar.length);
    });
    _maybeScrollToTop();
  }

  bool get _allDone =>
      _allAthkar.isNotEmpty &&
      _allAthkar.every((item) => item.current >= item.count);

  int get _totalTarget => _allAthkar.fold(0, (sum, item) => sum + item.count);

  int get _totalCurrent =>
      _allAthkar.fold(0, (sum, item) => sum + item.current);

  double get _overallProgress {
    final total = _totalTarget;
    if (total == 0) return 0;
    return _totalCurrent / total;
  }

  String get _fallbackReward => widget.isMorning
      ? 'ذكر عظيم من أذكار الصباح'
      : 'ذكر عظيم من أذكار المساء';

  Future<void> _exitScreen() async {
    if (_allDone) {
      await AthkarTrackingService.markCompleted(isMorning: widget.isMorning);

      // Show Interstitial Ad for Morning/Evening Athkar completion
      if (widget.title.contains("الصباح") || widget.title.contains("المساء")) {
        await AdService.instance.showInterstitialAd();
      }
    }
    if (!mounted) return;
    Navigator.of(context).pop(_allDone);
  }

  void _toggleTheme() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  Widget _buildAnimatedItem(BuildContext context, DhikrItem item, int index) {
    final isRemoving = _removingItems.contains(item);
    return AnimatedSwitcher(
      key: ObjectKey(item),
      duration: _removeDuration,
      switchInCurve: Curves.easeOutBack,
      switchOutCurve: Curves.easeInBack,
      transitionBuilder: (child, animation) {
        return SizeTransition(
          sizeFactor: animation,
          axisAlignment: -1,
          child: FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
        );
      },
      child: isRemoving
          ? const SizedBox.shrink(key: ValueKey('removed'))
          : KeyedSubtree(
              key: ObjectKey(item),
              child: DhikrCard(
                item: item,
                index: index,
                totalCount: _visibleAthkar.length,
                isFocus: false,
                isMorning: widget.isMorning,
                trueBlackMode: _isNightMode,
                isPlaying: _playingIndex == index,
                fontScale: _fontScale,
                fallbackReward: _fallbackReward,
                onIncrement: _increment,
                onSpeak: (idx) => _speak(item, idx),
              ),
            ),
    );
  }

  Widget _buildFocusSection(BuildContext context) {
    if (_visibleAthkar.isEmpty) {
      return AthkarEmptyState(
        isMorning: widget.isMorning,
        isNightMode: _isNightMode,
        showCompleted: _showCompleted,
        onShowCompleted: () => _toggleShowCompleted(true),
      );
    }

    final item = _visibleAthkar[_focusIndex];
    final isRemoving = _removingItems.contains(item);

    return Column(
      children: [
        AnimatedSwitcher(
          duration: _removeDuration,
          switchInCurve: Curves.easeOutBack,
          switchOutCurve: Curves.easeInBack,
          transitionBuilder: (child, animation) {
            return FadeTransition(
              opacity: animation,
              child: SizeTransition(
                sizeFactor: animation,
                axisAlignment: -1,
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(animation),
                  child: child,
                ),
              ),
            );
          },
          child: isRemoving
              ? SizedBox.shrink(key: ValueKey('removed_${item.hashCode}'))
              : KeyedSubtree(
                  key: ObjectKey(item),
                  child: DhikrCard(
                    item: item,
                    index: _focusIndex,
                    totalCount: _visibleAthkar.length,
                    isFocus: true,
                    isMorning: widget.isMorning,
                    trueBlackMode: _isNightMode,
                    isPlaying: _playingIndex == _focusIndex,
                    fontScale: _fontScale,
                    fallbackReward: _fallbackReward,
                    onIncrement: _increment,
                    onSpeak: (idx) => _speak(item, idx),
                  ),
                ),
        ),
        const SizedBox(height: 12),
        AthkarFocusNavigator(
          isMorning: widget.isMorning,
          isNightMode: _isNightMode,
          currentIndex: _focusIndex,
          totalCount: _visibleAthkar.length,
          onPrev: _focusIndex > 0 ? _goFocusPrev : null,
          onNext: _focusIndex + 1 < _visibleAthkar.length ? _goFocusNext : null,
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context) {
    final children = <Widget>[
      AthkarHeader(
        title: widget.title,
        isMorning: widget.isMorning,
        totalTarget: _totalTarget,
        totalCurrent: _totalCurrent,
        progress: _overallProgress,
        allDone: _allDone,
      ),
      AthkarControls(
        isMorning: widget.isMorning,
        isNightMode: _isNightMode,
        showCompleted: _showCompleted,
        focusMode: _focusMode,
        fontScale: _fontScale,
        minFontScale: _minFontScale,
        maxFontScale: _maxFontScale,
        onToggleShowCompleted: _toggleShowCompleted,
        onToggleFocusMode: () => _toggleFocusMode(!_focusMode),
        onFontScaleChanged: _setFontScale,
        onStepFont: _stepFont,
      ),
    ];

    if (_focusMode) {
      children.add(_buildFocusSection(context));
    } else if (_visibleAthkar.isEmpty) {
      children.add(AthkarEmptyState(
        isMorning: widget.isMorning,
        isNightMode: _isNightMode,
        showCompleted: _showCompleted,
        onShowCompleted: () => _toggleShowCompleted(true),
      ));
    } else {
      for (int i = 0; i < _visibleAthkar.length; i++) {
        children.add(_buildAnimatedItem(context, _visibleAthkar[i], i));
      }
    }

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(12),
      children: children,
    );
  }

  void _resetProgress() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("إعادة البدء"),
        content: const Text("هل تريد تصفير العدادات والبدء من جديد؟"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            onPressed: () {
              setState(() {
                for (var item in _allAthkar) {
                  item.current = 0;
                }
                _removingItems.clear();
                _visibleAthkar = _filterVisible(_allAthkar);
                _focusIndex = 0;
              });
              _saveProgress();
              Navigator.pop(ctx);
            },
            child: const Text("تأكيد"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: _isNightMode
          ? ThemeData.dark().copyWith(
              scaffoldBackgroundColor: Colors.black,
              appBarTheme: const AppBarTheme(backgroundColor: Colors.black),
            )
          : ThemeData.light().copyWith(
              scaffoldBackgroundColor: const Color(0xFFFAFAFA),
            ),
      child: Builder(builder: (context) {
        final isDark = _isNightMode;

        final appBarColor = isDark
            ? Colors.black
            : (widget.isMorning
                ? const Color(0xFF2E7D32)
                : const Color(0xFF3949AB));

        final background = isDark
            ? null
            : LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: widget.isMorning
                    ? const [
                        Color(0xFFF9FCF6),
                        Color(0xFFEAF4EC),
                        Color(0xFFF3F6FF)
                      ]
                    : const [
                        Color(0xFFF4F6FF),
                        Color(0xFFE9EDFF),
                        Color(0xFFF9FAFF)
                      ],
              );

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (didPop) return;
            _exitScreen();
          },
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              backgroundColor: isDark ? Colors.black : null,
              appBar: AppBar(
                title: Text(widget.title),
                backgroundColor: appBarColor,
                foregroundColor: Colors.white,
                elevation: 0,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: _exitScreen,
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.restart_alt),
                    tooltip: "إعادة البدء",
                    onPressed: _resetProgress,
                  ),
                  IconButton(
                    icon: Icon(isDark
                        ? Icons.wb_sunny_outlined
                        : Icons.nights_stay_outlined),
                    tooltip: "تبديل الوضع",
                    onPressed: _toggleTheme,
                  ),
                ],
              ),
              body: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Container(
                      decoration:
                          isDark ? null : BoxDecoration(gradient: background),
                      child: _buildContent(context),
                    ),
            ),
          ),
        );
      }),
    );
  }
}
