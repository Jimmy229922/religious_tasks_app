import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../data/athkar_data.dart';
import '../models/dhikr_item.dart';
import '../services/athkar_tracking_service.dart';
import '../services/storage_service.dart';
import '../services/audio_service.dart';
import '../widgets/dhikr_card.dart';

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
    _progressKey = widget.isMorning
        ? 'athkar_morning_progress'
        : 'athkar_evening_progress';
    _dateKey = widget.isMorning ? 'athkar_morning_date' : 'athkar_evening_date';
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

    final list = widget.isMorning ? buildMorningAthkar() : buildEveningAthkar();

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
      ? '\u0630\u0643\u0631 \u0639\u0638\u064a\u0645 \u0645\u0646 \u0623\u0630\u0643\u0627\u0631 \u0627\u0644\u0635\u0628\u0627\u062d'
      : '\u0630\u0643\u0631 \u0639\u0638\u064a\u0645 \u0645\u0646 \u0623\u0630\u0643\u0627\u0631 \u0627\u0644\u0645\u0633\u0627\u0621';

  Future<void> _exitScreen() async {
    if (_allDone) {
      await AthkarTrackingService.markCompleted(isMorning: widget.isMorning);
    }
    if (!mounted) return;
    Navigator.of(context).pop(_allDone);
  }

  Widget _buildHeader(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentStart = widget.isMorning
        ? (isDark ? const Color(0xFF1B5E20) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF1A237E) : const Color(0xFF3949AB));
    final accentEnd = widget.isMorning
        ? (isDark ? const Color(0xFF2E7D32) : const Color(0xFF81C784))
        : (isDark ? const Color(0xFF303F9F) : const Color(0xFF7986CB));
    final total = _totalTarget;
    final current = _totalCurrent;
    final progress = _overallProgress;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [accentStart, accentEnd],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.18),
            blurRadius: 16,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  widget.isMorning ? Icons.wb_sunny_rounded : Icons.nights_stay,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  widget.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_allDone)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    '\u0645\u0643\u062a\u0645\u0644\u0629',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '\u0627\u0644\u062a\u0642\u062f\u0645: $current \u0645\u0646 $total',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  void _toggleTheme() {
    setState(() {
      _isNightMode = !_isNightMode;
    });
  }

  Widget _buildControls(BuildContext context) {
    final isDark = _isNightMode;
    final surface = isDark ? Colors.black : Colors.white;
    final border = isDark ? Colors.white24 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final accent = widget.isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));
    final chipBackground =
        isDark ? const Color(0xFF141414) : const Color(0xFFF2F4F2);
    final percent = (_fontScale * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text(
                    '\u063a\u064a\u0631 \u0627\u0644\u0645\u0643\u062a\u0645\u0644\u0629'),
                selected: !_showCompleted,
                onSelected: (_) => _toggleShowCompleted(false),
                selectedColor: accent.withValues(alpha: isDark ? 0.25 : 0.18),
                backgroundColor: chipBackground,
                labelStyle: TextStyle(
                  color: !_showCompleted ? accent : textMuted,
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: !_showCompleted ? accent : border,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text('\u0627\u0644\u0643\u0644'),
                selected: _showCompleted,
                onSelected: (_) => _toggleShowCompleted(true),
                selectedColor: accent.withValues(alpha: isDark ? 0.25 : 0.18),
                backgroundColor: chipBackground,
                labelStyle: TextStyle(
                  color: _showCompleted ? accent : textMuted,
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: _showCompleted ? accent : border,
                  ),
                ),
              ),
              ChoiceChip(
                label: const Text(
                    '\u0648\u0636\u0639 \u0627\u0644\u062a\u0631\u0643\u064a\u0632'),
                selected: _focusMode,
                onSelected: _toggleFocusMode,
                selectedColor: accent.withValues(alpha: isDark ? 0.25 : 0.18),
                backgroundColor: chipBackground,
                labelStyle: TextStyle(
                  color: _focusMode ? accent : textMuted,
                  fontWeight: FontWeight.w600,
                ),
                shape: StadiumBorder(
                  side: BorderSide(
                    color: _focusMode ? accent : border,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.text_fields, color: accent),
              const SizedBox(width: 8),
              Text(
                '\u062d\u062c\u0645 \u0627\u0644\u062e\u0637',
                style: TextStyle(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Text(
                '$percent%',
                style: TextStyle(color: textMuted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildFontButton(
                icon: Icons.remove,
                onTap: () => _stepFont(-0.05),
                accent: accent,
                surface: chipBackground,
                border: border,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    activeTrackColor: accent,
                    inactiveTrackColor: accent.withValues(alpha: 0.25),
                    thumbColor: accent,
                    overlayColor: accent.withValues(alpha: 0.12),
                  ),
                  child: Slider(
                    value: _fontScale,
                    min: _minFontScale,
                    max: _maxFontScale,
                    divisions: 12,
                    onChanged: _setFontScale,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _buildFontButton(
                icon: Icons.add,
                onTap: () => _stepFont(0.05),
                accent: accent,
                surface: chipBackground,
                border: border,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFontButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color accent,
    required Color surface,
    required Color border,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: surface,
          shape: BoxShape.circle,
          border: Border.all(color: border),
        ),
        child: Icon(icon, color: accent, size: 18),
      ),
    );
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
      return _buildEmptyState(context);
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
        _buildFocusNavigator(context),
      ],
    );
  }

  Widget _buildFocusNavigator(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = widget.isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));
    final border = isDark ? Colors.white12 : Colors.black12;
    final canPrev = _focusIndex > 0;
    final canNext = _focusIndex + 1 < _visibleAthkar.length;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canPrev ? _goFocusPrev : null,
            icon: const Icon(Icons.chevron_right),
            label: const Text('\u0627\u0644\u0633\u0627\u0628\u0642'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: isDark ? 0.18 : 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            '${_focusIndex + 1} / ${_visibleAthkar.length}',
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: canNext ? _goFocusNext : null,
            icon: const Icon(Icons.chevron_left),
            label: const Text('\u0627\u0644\u062a\u0627\u0644\u064a'),
            style: OutlinedButton.styleFrom(
              foregroundColor: accent,
              side: BorderSide(color: border),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF12181C) : Colors.white;
    final border = isDark ? Colors.white12 : Colors.black12;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textMuted = isDark ? Colors.white70 : Colors.black54;
    final accent = widget.isMorning
        ? (isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32))
        : (isDark ? const Color(0xFF9FA8DA) : const Color(0xFF3949AB));

    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: border),
      ),
      child: Column(
        children: [
          Icon(Icons.celebration, color: accent, size: 30),
          const SizedBox(height: 8),
          Text(
            '\u0645\u0645\u062a\u0627\u0632! \u0623\u062a\u0645\u0645\u062a \u0643\u0644 \u0623\u0644\u0630\u0643\u0627\u0631.',
            style: TextStyle(
              color: textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            '\u064a\u0645\u0643\u0646\u0643 \u0645\u0631\u0627\u062c\u0639\u0629 \u0623\u0644\u0630\u0643\u0627\u0631 \u0623\u0648 \u0625\u0638\u0647\u0627\u0631 \u0627\u0644\u0645\u0643\u062a\u0645\u0644\u0629 \u0644\u0627\u062d\u0642\u0627.',
            style: TextStyle(color: textMuted, fontSize: 13),
            textAlign: TextAlign.center,
          ),
          if (!_showCompleted) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _toggleShowCompleted(true),
              icon: const Icon(Icons.visibility_outlined),
              label: const Text(
                  '\u0639\u0631\u0636 \u0623\u0644\u0630\u0643\u0627\u0631 \u0627\u0644\u0645\u0643\u062a\u0645\u0644\u0629'),
              style: OutlinedButton.styleFrom(
                foregroundColor: accent,
                side: BorderSide(color: border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final children = <Widget>[
      _buildHeader(context),
      _buildControls(context),
    ];

    if (_focusMode) {
      children.add(_buildFocusSection(context));
    } else if (_visibleAthkar.isEmpty) {
      children.add(_buildEmptyState(context));
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
