import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:religious_tasks_app/core/constants/app_constants.dart';
import 'package:religious_tasks_app/core/theme/theme_provider.dart';
import 'package:religious_tasks_app/features/athkar/models/athkar_time_helper.dart';
import 'package:religious_tasks_app/features/athkar/providers/athkar_view_model.dart';
import '../models/task_item.dart';
import '../providers/tasks_view_model.dart';
import '../widgets/daily_inspiration_card.dart';
import '../widgets/islamic_home_dashboard.dart';
import '../widgets/task_item_widget.dart';

import '../../athkar/screens/athkar_details_screen.dart';
import '../../athkar/screens/prophet_prayers_screen.dart';
import '../../athkar/screens/qiyam_layl_screen.dart';
import '../../athkar/screens/surah_kahf_screen.dart';
import '../../happiness_jar/screens/happiness_jar_screen.dart';
import '../../prayers/screens/prayer_details_screen.dart';
import '../../quran/screens/khatmah_screen.dart';
import '../../settings/screens/settings_screen.dart';
import '../../statistics/screens/statistics_screen.dart';
import '../../tasbeeh/screens/custom_tasbeeh_screen.dart';
import 'all_features_screen.dart';

class TasksScreen extends StatefulWidget {
  final ThemeProvider themeProvider;
  const TasksScreen({super.key, required this.themeProvider});

  @override
  State<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends State<TasksScreen>
    with WidgetsBindingObserver {
  static const double _maxContentWidth = 1040.0;

  bool _showRemainingSunnahOnly = false;
  int _currentTabIndex = 0;
  int _lanternReplayTick = 0;
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      SystemNavigator.setFrameworkHandlesBack(true);
      _checkFridaySurahKahfReminder();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lastBackPressTime = null;
      SystemNavigator.setFrameworkHandlesBack(true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          SystemNavigator.setFrameworkHandlesBack(true);
        }
      });
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _lastBackPressTime = null;
    }
  }

  Future<void> _checkFridaySurahKahfReminder() async {
    if (!mounted || DateTime.now().weekday != DateTime.friday) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedDate = prefs.getString(SurahKahfScreen.fridayDismissedDateKey);
      if (savedDate == SurahKahfScreen.todayDateKey()) return;
      if (!mounted) return;
      await _showFridaySurahKahfDialog(prefs);
    } catch (_) {}
  }

  Future<void> _showFridaySurahKahfDialog(SharedPreferences prefs) async {
    bool dontShowAgain = false;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accent = context.primaryColor;
    const gold = Color(0xFFD4AF37);

    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: Dialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(26),
                  side: BorderSide(
                    color: gold.withValues(alpha: isDark ? 0.45 : 0.6),
                    width: 1.2,
                  ),
                ),
                backgroundColor:
                    isDark ? const Color(0xFF131D2B) : Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [accent, context.primaryDarkColor],
                            begin: Alignment.topRight,
                            end: Alignment.bottomLeft,
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withValues(alpha: 0.28),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.menu_book_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: isDark ? 0.18 : 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: gold.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          "جمعة مباركة ✨",
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? const Color(0xFFFDE68A)
                                : const Color(0xFF92400E),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "لا تنسَ قراءة سورة الكهف اليوم",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.cairo(
                          fontSize: 17.5,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "«مَنْ قَرَأَ سُورَةَ الْكَهْفِ فِي يَوْمِ الْجُمُعَةِ أَضَاءَ لَهُ مِنَ النُّورِ مَا بَيْنَ الْجُمُعَتَيْنِ»",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.amiri(
                          fontSize: 16,
                          height: 1.65,
                          color: isDark
                              ? Colors.white70
                              : const Color(0xFF475569),
                        ),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setDialogState(() {
                            dontShowAgain = !dontShowAgain;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: isDark
                                ? Colors.white.withValues(alpha: 0.05)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: dontShowAgain
                                  ? accent.withValues(alpha: 0.6)
                                  : (isDark
                                      ? Colors.white.withValues(alpha: 0.1)
                                      : const Color(0xFFE2E8F0)),
                            ),
                          ),
                          child: Row(
                            children: [
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: dontShowAgain
                                      ? accent
                                      : Colors.transparent,
                                  border: Border.all(
                                    color: dontShowAgain
                                        ? accent
                                        : (isDark
                                            ? Colors.white54
                                            : const Color(0xFF94A3B8)),
                                    width: 1.8,
                                  ),
                                ),
                                child: dontShowAgain
                                    ? const Icon(
                                        Icons.check_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  "عدم إظهار هذا التذكير مجدداً هذه الجمعة",
                                  style: GoogleFonts.cairo(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : const Color(0xFF334155),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () async {
                                if (dontShowAgain) {
                                  await prefs.setString(
                                    SurahKahfScreen.fridayDismissedDateKey,
                                    SurahKahfScreen.todayDateKey(),
                                  );
                                }
                                if (ctx.mounted) {
                                  Navigator.pop(ctx);
                                }
                              },
                              style: OutlinedButton.styleFrom(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                side: BorderSide(
                                  color: isDark
                                      ? Colors.white24
                                      : const Color(0xFFCBD5E1),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: Text(
                                "إلغاء",
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.white70
                                      : const Color(0xFF475569),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            flex: 2,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.pop(ctx);
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const SurahKahfScreen(),
                                  ),
                                );
                              },
                              icon: const Icon(
                                Icons.auto_stories_rounded,
                                size: 18,
                              ),
                              label: Text(
                                "اقرأ الآن",
                                style: GoogleFonts.cairo(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: accent,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  double _horizontalInset(double availableWidth) {
    final basePad = availableWidth < 360 ? 12.0 : 16.0;
    if (availableWidth <= _maxContentWidth + (basePad * 2)) {
      return basePad;
    }
    return (availableWidth - _maxContentWidth) / 2;
  }

  void _syncAthkarTaskCompletion(
    TasksViewModel vm,
    String taskName,
    bool isComplete,
  ) {
    if (!isComplete) return;
    final idx = vm.tasks.indexWhere((t) => t.name == taskName);
    if (idx != -1 && !vm.tasks[idx].isCompleted) {
      vm.toggleTask(idx, completionValue: true);
    }
  }

  Future<void> _handleRefresh(TasksViewModel vm) async {
    HapticFeedback.selectionClick();
    final athkarVm = Provider.of<AthkarViewModel>(context, listen: false);
    await Future.wait([
      vm.refreshAll(),
      athkarVm.loadDailyData(),
    ]);
    if (!mounted) return;
    setState(() => _lanternReplayTick++);
    _syncAthkarTaskCompletion(
      vm,
      kAthkarMorning,
      athkarVm.data.morning.isComplete,
    );
    _syncAthkarTaskCompletion(
      vm,
      kAthkarEvening,
      athkarVm.data.evening.isComplete,
    );
    _syncAthkarTaskCompletion(
      vm,
      kAthkarSleep,
      athkarVm.data.sleep.isComplete,
    );

    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "تم تحديث كافة البيانات والمواقيت ✓",
          style: GoogleFonts.cairo(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: context.primaryColor,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _handleRootBackPress(bool isDark) {
    if (_currentTabIndex != 0) {
      HapticFeedback.selectionClick();
      _lastBackPressTime = null;
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      setState(() => _currentTabIndex = 0);
      return;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null ||
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      HapticFeedback.lightImpact();
      const gold = Color(0xFFD4AF37);
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'انقر رجوع مرة أخرى للخروج من التطبيق',
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              color: Colors.white,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          backgroundColor: isDark
              ? const Color(0xE6131D2B)
              : const Color(0xE60F3D3E),
          elevation: 0,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(44, 0, 44, 14),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: gold.withValues(alpha: 0.45),
              width: 1,
            ),
          ),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    _lastBackPressTime = null;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    SystemNavigator.pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final backgroundColor = theme.scaffoldBackgroundColor;
    final iconColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _handleRootBackPress(isDark);
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
        backgroundColor: context.appScaffoldBg,
        bottomNavigationBar: _buildBottomNavigationBar(context, isDark),
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: context.appBgGradient,
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
          child: Consumer<TasksViewModel>(
            builder: (context, vm, child) {
              final allSunnah = vm.otherTasks;
              final displayedSunnah = _showRemainingSunnahOnly
                  ? allSunnah.where((t) => !t.isCompleted).toList()
                  : allSunnah;

              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 280),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.03),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child: KeyedSubtree(
                  key: ValueKey(_currentTabIndex),
                  child: _buildCurrentTabContent(
                    context: context,
                    vm: vm,
                    isDark: isDark,
                    backgroundColor: backgroundColor,
                    iconColor: iconColor,
                    textScale: textScale,
                    allSunnah: allSunnah,
                    displayedSunnah: displayedSunnah,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    ),
    ),
    );
  }

  Widget _buildCurrentTabContent({
    required BuildContext context,
    required TasksViewModel vm,
    required bool isDark,
    required Color backgroundColor,
    required Color iconColor,
    required double textScale,
    required List<TaskItem> allSunnah,
    required List<TaskItem> displayedSunnah,
  }) {
    if (_currentTabIndex == 2) {
      return AllFeaturesScreen(
        vm: vm,
        embedded: true,
        themeProvider: widget.themeProvider,
      );
    }
    if (_currentTabIndex == 3) {
      return StatisticsScreen(
        morningStreak: vm.morningStreak,
        eveningStreak: vm.eveningStreak,
        sleepStreak: vm.sleepStreak,
        embedded: true,
        themeProvider: widget.themeProvider,
      );
    }

    return RefreshIndicator(
      onRefresh: () => _handleRefresh(vm),
      child: LayoutBuilder(
        builder: (context, viewportConstraints) {
          final screenWidth = viewportConstraints.maxWidth;
          final hPad = _horizontalInset(screenWidth);
          final isWide = screenWidth >= 720;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            slivers: [
              if (_currentTabIndex == 1)
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                      child: _buildWorshipDomeHeader(
                        context: context,
                        vm: vm,
                        isDark: isDark,
                      ),
                    ),
                  ),
                ),
              if (_currentTabIndex == 0) ...[
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 2, hPad, 0),
                      child: IslamicHomeDashboard(
                        vm: vm,
                        themeProvider: widget.themeProvider,
                        isDark: isDark,
                        onOpenServicesTab: () {
                          _lastBackPressTime = null;
                          ScaffoldMessenger.of(context).hideCurrentSnackBar();
                          setState(() => _currentTabIndex = 2);
                        },
                        onOpenPrayerDetails: (task) {
                          final idx = vm.tasks.indexOf(task);
                          if (idx != -1) {
                            _handleTaskTap(context, vm, idx, task);
                          }
                        },
                        onTogglePrayerCompletion: (task) {
                          final idx = vm.tasks.indexOf(task);
                          if (idx != -1) {
                            vm.toggleTask(idx);
                          }
                        },
                        bottomWidget: DailyInspirationCard(
                          vm: vm,
                          isDark: isDark,
                        ),
                        lanternReplayTick: _lanternReplayTick,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                      child: _buildSuggestionArea(
                        context: context,
                        vm: vm,
                        isDark: isDark,
                        textScale: textScale,
                      ),
                    ),
                  ),
                ),
                if (vm.prayerTasks.isNotEmpty)
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 12, hPad, 0),
                        child: _buildQuickPrayersBar(
                          context: context,
                          vm: vm,
                          isDark: isDark,
                        ),
                      ),
                    ),
                  ),
                if (allSunnah.isNotEmpty)
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 10, hPad, 0),
                        child: _buildFramedSectionContainer(
                          isDark: isDark,
                          isNarrow: screenWidth < 360,
                          header: _buildSunnahHeaderWidget(
                            allTasks: allSunnah,
                            isDark: isDark,
                          ),
                          child: displayedSunnah.isEmpty
                              ? _buildAllSunnahDoneBanner(isDark)
                              : _buildSunnahGridWidget(
                                  context: context,
                                  vm: vm,
                                  tasks: displayedSunnah,
                                  isDark: isDark,
                                  textScale: textScale,
                                ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                      child: _buildBottomInsightsArea(
                        context: context,
                        vm: vm,
                        isDark: isDark,
                        textScale: textScale,
                        isWide: isWide,
                      ),
                    ),
                  ),
                ),
                if (vm.earnedBadges.isNotEmpty)
                  SliverToBoxAdapter(
                    child: RepaintBoundary(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(hPad, 16, hPad, 0),
                        child: _buildFramedSectionContainer(
                          isDark: isDark,
                          isNarrow: screenWidth < 360,
                          header: _buildSectionHeaderRow(
                            title: "أوسمتك المستحقة",
                            icon: Icons.emoji_events_rounded,
                            trailingText: "${vm.earnedBadges.length}",
                            isDark: isDark,
                          ),
                          child: _buildBadgesSection(vm, isDark),
                        ),
                      ),
                    ),
                  ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 28)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context, bool isDark) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    const items = [
      (label: 'الرئيسية', icon: Icons.home_rounded),
      (label: 'العبادات', icon: Icons.task_alt_rounded),
      (label: 'الخدمات', icon: Icons.grid_view_rounded),
      (label: 'إحصائياتي', icon: Icons.bar_chart_rounded),
    ];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.appCardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        border: Border(
          top: BorderSide(
            color: gold.withValues(alpha: isDark ? 0.45 : 0.65),
            width: 1.2,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(items.length, (idx) {
              final item = items[idx];
              final selected = _currentTabIndex == idx;
              return Expanded(
                child: GestureDetector(
                  onTap: () {
                    if (_currentTabIndex == idx) return;
                    HapticFeedback.selectionClick();
                    _lastBackPressTime = null;
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    setState(() => _currentTabIndex = idx);
                  },
                  behavior: HitTestBehavior.opaque,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding:
                        const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
                    decoration: BoxDecoration(
                      gradient: selected
                          ? const LinearGradient(
                              colors: [goldLight, gold],
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                            )
                          : null,
                      color: selected ? null : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: selected
                            ? gold
                            : Colors.transparent,
                        width: 1.1,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedScale(
                          scale: selected ? 1.1 : 1.0,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOutBack,
                          child: Icon(
                            item.icon,
                            size: 22,
                            color: selected
                                ? const Color(0xFF041D16)
                                : (isDark
                                    ? Colors.white60
                                    : const Color(0xFF475569)),
                          ),
                        ),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            item.label,
                            maxLines: 1,
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: selected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: selected
                                  ? const Color(0xFF041D16)
                                  : (isDark
                                      ? Colors.white60
                                      : const Color(0xFF475569)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildWorshipDomeHeader({
    required BuildContext context,
    required TasksViewModel vm,
    required bool isDark,
  }) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final accent = context.primaryColor;
    final totalTasks = vm.tasks.length;
    final completedTasks = vm.tasks.where((t) => t.isCompleted).length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0A241D), Color(0xFF0F2D24)]
              : const [Color(0xFFFFFDF7), Color(0xFFF6EED9)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(32),
          bottom: Radius.circular(22),
        ),
        border: Border.all(
          color: gold.withValues(alpha: isDark ? 0.5 : 0.7),
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : gold).withValues(alpha: 0.14),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _WorshipArchLatticePainter(
                color: gold.withValues(alpha: isDark ? 0.12 : 0.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildWorshipCircleBtn(
                  icon: Icons.settings_outlined,
                  tooltip: 'الإعدادات',
                  isDark: isDark,
                  accent: accent,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsScreen()),
                  ),
                ),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'العبادات والمهام',
                        style: GoogleFonts.cairo(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? goldLight : context.primaryDarkColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: gold.withValues(alpha: isDark ? 0.16 : 0.14),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: gold.withValues(alpha: isDark ? 0.45 : 0.6),
                          ),
                        ),
                        child: Text(
                          'إنجاز اليوم: $completedTasks / $totalTasks',
                          style: GoogleFonts.cairo(
                            fontSize: 11.5,
                            fontWeight: FontWeight.bold,
                            color: isDark ? goldLight : const Color(0xFF78350F),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildWorshipCircleBtn(
                  icon: isDark
                      ? Icons.wb_sunny_rounded
                      : Icons.nights_stay_rounded,
                  tooltip: isDark ? 'الوضع الفاتح' : 'الوضع الداكن',
                  isDark: isDark,
                  accent: accent,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    widget.themeProvider.toggleTheme(!isDark);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorshipCircleBtn({
    required IconData icon,
    required String tooltip,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDark
                ? Colors.white.withValues(alpha: 0.07)
                : Colors.white.withValues(alpha: 0.9),
            border: Border.all(
              color: gold.withValues(alpha: isDark ? 0.45 : 0.6),
            ),
          ),
          child: Icon(
            icon,
            size: 20,
            color: isDark ? goldLight : accent,
          ),
        ),
      ),
    );
  }

  String _formatPrayerTime12h(DateTime? dt) {
    if (dt == null) return '--:--';
    final h12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    return '${h12.toString().padLeft(2, '0')}:$m';
  }

  ({IconData icon, DateTime? time}) _prayerMetaForTask(
    TaskItem task,
    TasksViewModel vm,
  ) {
    final times = vm.prayerTimes;
    if (task.name.contains(kPrayerFajr)) {
      return (icon: Icons.wb_twilight_rounded, time: times?.fajr);
    }
    if (task.name.contains(kPrayerDhuhr)) {
      return (icon: Icons.wb_sunny_rounded, time: times?.dhuhr);
    }
    if (task.name.contains(kPrayerAsr)) {
      return (icon: Icons.light_mode_rounded, time: times?.asr);
    }
    if (task.name.contains(kPrayerMaghrib)) {
      return (icon: Icons.nights_stay_outlined, time: times?.maghrib);
    }
    if (task.name.contains(kPrayerIsha)) {
      return (icon: Icons.bedtime_rounded, time: times?.isha);
    }
    return (icon: Icons.mosque_rounded, time: null);
  }

  Widget _buildQuickPrayersBar({
    required BuildContext context,
    required TasksViewModel vm,
    required bool isDark,
  }) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    const emeraldDone = Color(0xFF10B981);
    final totalCount = vm.prayerTasks.length;
    final completedCount = vm.prayerTasks.where((t) => t.isCompleted).length;
    final allDone = totalCount > 0 && completedCount == totalCount;
    final progress =
        totalCount == 0 ? 0.0 : (completedCount / totalCount).clamp(0.0, 1.0);
    final subtitleText = allDone
        ? 'أتممت الفروض الخمسة اليوم بحمد الله'
        : (vm.nextPrayerName.isNotEmpty
            ? 'الصلاة القادمة: ${vm.nextPrayerName}'
            : 'اضغط لتسجيل الصلاة • مطولاً للتفاصيل');

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.appCardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: (allDone ? emeraldDone : gold)
              .withValues(alpha: isDark ? 0.5 : 0.7),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : gold).withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: allDone
                        ? const [Color(0xFF10B981), Color(0xFF059669)]
                        : [
                            gold.withValues(alpha: isDark ? 0.28 : 0.22),
                            gold.withValues(alpha: isDark ? 0.10 : 0.08),
                          ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  border: Border.all(
                    color: (allDone ? emeraldDone : gold)
                        .withValues(alpha: 0.65),
                    width: 1.1,
                  ),
                ),
                child: Icon(
                  allDone ? Icons.verified_rounded : Icons.mosque_rounded,
                  size: 18,
                  color: allDone
                      ? Colors.white
                      : (isDark ? goldLight : const Color(0xFF78350F)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الصلوات الخمس',
                      style: GoogleFonts.cairo(
                        fontSize: 15.5,
                        fontWeight: FontWeight.bold,
                        height: 1.15,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleText,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.cairo(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: allDone
                            ? emeraldDone
                            : (isDark
                                ? goldLight.withValues(alpha: 0.85)
                                : const Color(0xFF78350F)),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
                decoration: BoxDecoration(
                  color: (allDone ? emeraldDone : gold)
                      .withValues(alpha: isDark ? 0.18 : 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: (allDone ? emeraldDone : gold)
                        .withValues(alpha: 0.55),
                  ),
                ),
                child: Directionality(
                  textDirection: TextDirection.ltr,
                  child: Text(
                    '$completedCount / $totalCount',
                    style: GoogleFonts.ibmPlexMono(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: allDone
                          ? emeraldDone
                          : (isDark ? goldLight : const Color(0xFF78350F)),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Container(
              height: 5.5,
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : gold.withValues(alpha: 0.16),
              child: LayoutBuilder(
                builder: (context, barConstraints) {
                  return Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: barConstraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          colors: allDone
                              ? const [Color(0xFF34D399), Color(0xFF059669)]
                              : const [goldLight, gold],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: List.generate(totalCount, (i) {
              final task = vm.prayerTasks[i];
              final done = task.isCompleted;
              final shortName = task.name.replaceFirst('صلاة ', '').trim();
              final globalIndex = vm.tasks.indexOf(task);
              final isNext = !done &&
                  vm.nextPrayerName.isNotEmpty &&
                  task.name.contains(vm.nextPrayerName);
              final meta = _prayerMetaForTask(task, vm);
              final timeLabel = _formatPrayerTime12h(meta.time);

              const cardRadius = BorderRadius.vertical(
                top: Radius.circular(26),
                bottom: Radius.circular(15),
              );

              final List<Color> bgColors;
              if (done) {
                bgColors = isDark
                    ? const [Color(0xFF065F46), Color(0xFF047857)]
                    : const [Color(0xFFD1FAE5), Color(0xFFA7F3D0)];
              } else if (isNext) {
                bgColors = isDark
                    ? const [Color(0xFF78350F), Color(0xFFB45309)]
                    : const [Color(0xFFFEF3C7), Color(0xFFFDE68A)];
              } else {
                bgColors = isDark
                    ? const [Color(0xFF102421), Color(0xFF0B171D)]
                    : const [Color(0xFFFFFFFF), Color(0xFFFDF8EC)];
              }

              final borderColor = done
                  ? emeraldDone
                  : (isNext
                      ? gold
                      : gold.withValues(alpha: isDark ? 0.35 : 0.55));

              final iconColor = done
                  ? (isDark ? Colors.white : const Color(0xFF065F46))
                  : (isNext
                      ? (isDark ? goldLight : const Color(0xFF78350F))
                      : (isDark ? goldLight : const Color(0xFF92400E)));

              final nameColor = done
                  ? (isDark ? Colors.white : const Color(0xFF064E3B))
                  : (isNext
                      ? (isDark ? Colors.white : const Color(0xFF451A03))
                      : (isDark ? Colors.white : const Color(0xFF1E293B)));

              final timeColor = done
                  ? (isDark
                      ? Colors.white.withValues(alpha: 0.88)
                      : const Color(0xFF047857))
                  : (isNext
                      ? (isDark ? goldLight : const Color(0xFF78350F))
                      : (isDark ? Colors.white60 : const Color(0xFF64748B)));

              return Expanded(
                child: Padding(
                  padding: EdgeInsetsDirectional.only(
                    end: i == totalCount - 1 ? 0 : 6,
                  ),
                  child: InkWell(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      if (globalIndex != -1) {
                        vm.toggleTask(globalIndex);
                      }
                    },
                    onLongPress: () {
                      if (globalIndex != -1) {
                        _handleTaskTap(context, vm, globalIndex, task);
                      }
                    },
                    borderRadius: cardRadius,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.fromLTRB(4, 9, 4, 8),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: bgColors,
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                        ),
                        borderRadius: cardRadius,
                        border: Border.all(
                          color: borderColor,
                          width: (done || isNext) ? 1.45 : 1.0,
                        ),
                        boxShadow: (done || isNext)
                            ? [
                                BoxShadow(
                                  color: (done ? emeraldDone : gold)
                                      .withValues(alpha: isDark ? 0.22 : 0.18),
                                  blurRadius: 8,
                                  offset: const Offset(0, 3),
                                ),
                              ]
                            : null,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 26,
                            height: 26,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: done
                                  ? (isDark
                                      ? Colors.white.withValues(alpha: 0.16)
                                      : Colors.white.withValues(alpha: 0.65))
                                  : (isNext
                                      ? (isDark
                                          ? Colors.black.withValues(alpha: 0.22)
                                          : Colors.white.withValues(alpha: 0.65))
                                      : gold.withValues(
                                          alpha: isDark ? 0.12 : 0.10)),
                            ),
                            child: Icon(
                              done ? Icons.check_circle_rounded : meta.icon,
                              size: 15.5,
                              color: iconColor,
                            ),
                          ),
                          const SizedBox(height: 5),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              shortName,
                              maxLines: 1,
                              style: GoogleFonts.cairo(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                height: 1.15,
                                color: nameColor,
                              ),
                            ),
                          ),
                          const SizedBox(height: 2),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Directionality(
                              textDirection: TextDirection.ltr,
                              child: Text(
                                timeLabel,
                                maxLines: 1,
                                style: GoogleFonts.ibmPlexMono(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: timeColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFramedSectionContainer({
    required bool isDark,
    required bool isNarrow,
    required Widget header,
    required Widget child,
  }) {
    const gold = Color(0xFFD4AF37);
    return Container(
      padding: EdgeInsets.all(isNarrow ? 12 : 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: context.appCardGradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gold.withValues(alpha: isDark ? 0.45 : 0.65),
          width: 1.25,
        ),
        boxShadow: [
          BoxShadow(
            color: (isDark ? Colors.black : gold).withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          header,
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildSunnahHeaderWidget({
    required List<TaskItem> allTasks,
    required bool isDark,
  }) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final accent = isDark ? goldLight : context.primaryColor;
    final completed = allTasks.where((t) => t.isCompleted).length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final textScale = MediaQuery.textScalerOf(context).scale(1.0);
        final stackFilter = constraints.maxWidth < 310 || textScale >= 1.2;

        final titleRow = Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: isDark ? 0.16 : 0.14),
                border: Border.all(
                  color: gold.withValues(alpha: 0.45),
                ),
              ),
              child: Icon(Icons.spa_rounded, size: 17, color: accent),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                "السنن والأذكار",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.cairo(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: isDark ? 0.18 : 0.12),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: gold.withValues(alpha: isDark ? 0.45 : 0.55),
                ),
              ),
              child: Text(
                "$completed/${allTasks.length}",
                style: GoogleFonts.ibmPlexMono(
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? goldLight : const Color(0xFF78350F),
                ),
              ),
            ),
          ],
        );

        final filterPill = Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF0A171C) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: gold.withValues(alpha: isDark ? 0.4 : 0.55),
              width: 1.2,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFilterPill(
                label: "الكل",
                selected: !_showRemainingSunnahOnly,
                isDark: isDark,
                accent: accent,
                onTap: () => setState(() => _showRemainingSunnahOnly = false),
              ),
              _buildFilterPill(
                label: "المتبقي",
                selected: _showRemainingSunnahOnly,
                isDark: isDark,
                accent: accent,
                onTap: () => setState(() => _showRemainingSunnahOnly = true),
              ),
            ],
          ),
        );

        if (stackFilter) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              titleRow,
              const SizedBox(height: 8),
              filterPill,
            ],
          );
        }

        return Row(
          children: [
            Expanded(child: titleRow),
            const SizedBox(width: 8),
            filterPill,
          ],
        );
      },
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required bool isDark,
    required Color accent,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? context.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: GoogleFonts.cairo(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: selected
                ? Colors.white
                : (isDark ? Colors.white70 : const Color(0xFF475569)),
          ),
        ),
      ),
    );
  }

  Widget _buildAllSunnahDoneBanner(bool isDark) {
    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF172231) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.45 : 0.38),
          width: 1.35,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.verified_rounded, color: accent, size: 32),
          const SizedBox(height: 8),
          Text(
            "ما شاء الله! أتممت جميع السنن والأذكار اليوم 🎉",
            textAlign: TextAlign.center,
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => setState(() => _showRemainingSunnahOnly = false),
            child: Text(
              "عرض جميع المهام",
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: accent,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomInsightsArea({
    required BuildContext context,
    required TasksViewModel vm,
    required bool isDark,
    required double textScale,
    required bool isWide,
  }) {
    return _buildGratitudeSection(context, vm, isDark, textScale);
  }

  Widget _buildSuggestionArea({
    required BuildContext context,
    required TasksViewModel vm,
    required bool isDark,
    required double textScale,
  }) {
    final activeEvent = vm.activeEvent;
    if (activeEvent == null) {
      return _buildContextAwareSuggestion(context, vm, isDark);
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 520 || textScale >= 1.2) {
          return Column(
            children: [
              _buildSmartEventBanner(activeEvent, isDark),
              const SizedBox(height: 10),
              _buildContextAwareSuggestion(context, vm, isDark),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 4,
              child: _buildSmartEventBanner(activeEvent, isDark),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 6,
              child: _buildContextAwareSuggestion(context, vm, isDark),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSunnahGridWidget({
    required BuildContext context,
    required TasksViewModel vm,
    required List<TaskItem> tasks,
    required bool isDark,
    required double textScale,
  }) {
    Widget buildCard(TaskItem task, int localIndex) {
      return TaskItemWidget(
        task: task,
        index: localIndex,
        isDark: isDark,
        now: vm.now,
        prayerTimes: vm.prayerTimes,
        prayerTimesTomorrow: vm.tomorrowPrayerTimes,
        compactGridCard: true,
        onTap: () {
          final globalIndex = vm.tasks.indexOf(task);
          if (globalIndex != -1) {
            _handleTaskTap(context, vm, globalIndex, task);
          }
        },
        onToggle: () {
          final globalIndex = vm.tasks.indexOf(task);
          if (globalIndex != -1) {
            vm.toggleTask(globalIndex);
          }
        },
        onIncrement: () {
          final globalIndex = vm.tasks.indexOf(task);
          if (globalIndex != -1) {
            vm.incrementCounter(globalIndex);
          }
        },
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns;
        if (constraints.maxWidth < 305 || textScale >= 1.25) {
          columns = 1;
        } else if (constraints.maxWidth >= 660) {
          columns = 3;
        } else {
          columns = 2;
        }

        if (columns == 1) {
          return Column(
            children: [
              for (int idx = 0; idx < tasks.length; idx++) ...[
                TaskItemWidget(
                  task: tasks[idx],
                  index: idx,
                  isDark: isDark,
                  now: vm.now,
                  prayerTimes: vm.prayerTimes,
                  prayerTimesTomorrow: vm.tomorrowPrayerTimes,
                  compactGridCard: false,
                  onTap: () {
                    final globalIndex = vm.tasks.indexOf(tasks[idx]);
                    if (globalIndex != -1) {
                      _handleTaskTap(context, vm, globalIndex, tasks[idx]);
                    }
                  },
                  onToggle: () {
                    final globalIndex = vm.tasks.indexOf(tasks[idx]);
                    if (globalIndex != -1) {
                      vm.toggleTask(globalIndex);
                    }
                  },
                  onIncrement: () {
                    final globalIndex = vm.tasks.indexOf(tasks[idx]);
                    if (globalIndex != -1) {
                      vm.incrementCounter(globalIndex);
                    }
                  },
                ),
                if (idx < tasks.length - 1) const SizedBox(height: 10),
              ],
            ],
          );
        }

        final rowCount = (tasks.length / columns).ceil();
        return Column(
          children: [
            for (int rowIndex = 0; rowIndex < rowCount; rowIndex++) ...[
              Builder(
                builder: (context) {
                  final start = rowIndex * columns;
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        for (int col = 0; col < columns; col++) ...[
                          Expanded(
                            child: (start + col) < tasks.length
                                ? buildCard(tasks[start + col], start + col)
                                : const SizedBox.shrink(),
                          ),
                          if (col < columns - 1) const SizedBox(width: 10),
                        ],
                      ],
                    ),
                  );
                },
              ),
              if (rowIndex < rowCount - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }

  Widget _buildBadgesSection(TasksViewModel vm, bool isDark) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: vm.earnedBadges.map((badgeId) {
        String title = "";
        IconData icon = Icons.star_rounded;
        Color color = Colors.amber;

        if (badgeId == 'dhikr_1000') {
          title = "الذاكر الـ 1000";
          icon = Icons.emoji_events_rounded;
        } else if (badgeId == 'streak_morning_7') {
          title = "سبعيني الصباح";
          icon = Icons.wb_sunny_rounded;
          color = Colors.orange;
        }

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF172231) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withValues(alpha: isDark ? 0.50 : 0.45),
              width: 1.3,
            ),
            boxShadow: isDark
                ? null
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.cairo(
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildGratitudeSection(
    BuildContext context,
    TasksViewModel vm,
    bool isDark,
    double textScale,
  ) {
    final blessingOfDay =
        vm.currentBlessing.isEmpty ? "نعمة الإسلام والهداية" : vm.currentBlessing;
    final accent = isDark ? const Color(0xFF2DD4BF) : context.primaryColor;
    const gold = Color(0xFFD97706);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0F292E), Color(0xFF162231)]
              : const [Color(0xFFECFDF5), Color(0xFFF0FDFA)],
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: accent.withValues(alpha: isDark ? 0.50 : 0.36),
          width: 1.45,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: isDark ? 0.14 : 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrowHeader =
              constraints.maxWidth < 330 || textScale >= 1.25;
          final sideBySideButtons =
              constraints.maxWidth >= 460 && textScale < 1.2;

          final countChip = Container(
            padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: isDark ? 0.22 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: gold.withValues(alpha: 0.58),
                width: 1.15,
              ),
            ),
            child: Text(
              "${vm.gratitudeCount} حمداً",
              style: GoogleFonts.cairo(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.amberAccent : const Color(0xFFB45309),
              ),
            ),
          );

          final praiseBtn = ElevatedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              vm.incrementGratitude();
            },
            icon: const Icon(Icons.favorite_rounded, size: 18),
            label: Text(
              "قل: الحمد لله 🤲",
              style: GoogleFonts.cairo(
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          final jarBtn = OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HappinessJarScreen(),
              ),
            ),
            icon: const Icon(Icons.card_giftcard_rounded, size: 18, color: gold),
            label: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                "افتح برطمان السعادة 💛",
                style: GoogleFonts.cairo(
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.amberAccent : const Color(0xFFB45309),
                ),
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
              side: BorderSide(
                color: gold.withValues(alpha: 0.72),
                width: 1.35,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          );

          return Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: isDark ? 0.2 : 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.volunteer_activism_rounded,
                      size: 22,
                      color: accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "واحة الشكر والامتنان",
                          style: GoogleFonts.cairo(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? Colors.white
                                : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "لَئِن شَكَرْتُمْ لَأَزِيدَنَّكُمْ",
                          style: GoogleFonts.amiri(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: accent,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isNarrowHeader) ...[
                    const SizedBox(width: 8),
                    countChip,
                  ],
                ],
              ),
              if (isNarrowHeader) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: countChip,
                ),
              ],
              const SizedBox(height: 12),
              Text(
                "يا رب لك الحمد كما ينبغي لجلال وجهك وعظيم سلطانك",
                textAlign: TextAlign.center,
                style: GoogleFonts.amiri(
                  fontSize: 17.5,
                  fontWeight: FontWeight.bold,
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.92)
                      : const Color(0xFF134E4A),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.26)
                      : Colors.white.withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: accent.withValues(alpha: isDark ? 0.34 : 0.28),
                    width: 1.2,
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "نعمة نتذكرها الآن:",
                            style: GoogleFonts.cairo(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white60
                                  : Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            "أشكرك يا ربي على $blessingOfDay",
                            style: GoogleFonts.cairo(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: "تغيير النعمة",
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        vm.cycleBlessing();
                      },
                      icon: Icon(Icons.refresh_rounded, color: accent),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (sideBySideButtons)
                Row(
                  children: [
                    Expanded(child: praiseBtn),
                    const SizedBox(width: 10),
                    Expanded(child: jarBtn),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    praiseBtn,
                    const SizedBox(height: 8),
                    jarBtn,
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSmartEventBanner(String event, bool isDark) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF0E211E), Color(0xFF0A171C)]
              : const [Color(0xFFFFFDF8), Color(0xFFF8F0DB)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: gold.withValues(alpha: isDark ? 0.5 : 0.7),
          width: 1.3,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.stars_rounded,
            color: isDark ? goldLight : const Color(0xFFD97706),
            size: 19,
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              event,
              textAlign: TextAlign.center,
              style: GoogleFonts.cairo(
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                fontWeight: FontWeight.bold,
                fontSize: 12.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContextAwareSuggestion(
      BuildContext context, TasksViewModel vm, bool isDark) {
    final suggestion = vm.activeContextSuggestion;
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final accent = isDark ? goldLight : context.primaryColor;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: gold.withValues(alpha: isDark ? 0.7 : 0.85),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: gold.withValues(alpha: isDark ? 0.16 : 0.24),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        image: DecorationImage(
          image: AssetImage(
            isDark
                ? 'assets/images/worship_hero_dark.jpg'
                : 'assets/images/worship_hero_light.jpg',
          ),
          fit: BoxFit.cover,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(24),
          onTap: () => _handleSuggestionTap(context, vm, suggestion),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22.5),
              gradient: LinearGradient(
                colors: isDark
                    ? [
                        const Color(0xFF041D16).withValues(alpha: 0.78),
                        const Color(0xFF041D16).withValues(alpha: 0.35),
                        Colors.transparent,
                      ]
                    : [
                        const Color(0xFFFFFDF7).withValues(alpha: 0.82),
                        const Color(0xFFFFFDF7).withValues(alpha: 0.42),
                        Colors.transparent,
                      ],
                stops: const [0.0, 0.55, 1.0],
                begin: Alignment.centerRight,
                end: Alignment.centerLeft,
              ),
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                final compact = constraints.maxWidth < 310 || textScale >= 1.25;

                final openBadge = Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
                  decoration: BoxDecoration(
                    color: isDark ? gold : context.primaryColor,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "افتح",
                        style: GoogleFonts.cairo(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark ? const Color(0xFF041D16) : Colors.white,
                        ),
                      ),
                      const SizedBox(width: 3),
                      Icon(
                        Icons.arrow_forward_ios_rounded,
                        size: 10,
                        color: isDark ? const Color(0xFF041D16) : Colors.white,
                      ),
                    ],
                  ),
                );

                final cycleButton = IconButton(
                  tooltip: "عرض اقتراح آخر",
                  visualDensity: VisualDensity.compact,
                  onPressed: vm.cycleContextSuggestion,
                  icon: Icon(
                    Icons.autorenew_rounded,
                    size: 19,
                    color: isDark ? goldLight : accent,
                  ),
                );

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 9,
                                  vertical: 2.5,
                                ),
                                decoration: BoxDecoration(
                                  color: gold.withValues(
                                      alpha: isDark ? 0.2 : 0.16),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: gold.withValues(
                                        alpha: isDark ? 0.5 : 0.65),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      suggestion.icon,
                                      size: 12,
                                      color: isDark
                                          ? goldLight
                                          : const Color(0xFF78350F),
                                    ),
                                    const SizedBox(width: 5),
                                    Flexible(
                                      child: Text(
                                        "مقترح لك الآن • ${suggestion.categoryLabel}",
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.cairo(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                          color: isDark
                                              ? goldLight
                                              : const Color(0xFF78350F),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 6),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: AlignmentDirectional.centerStart,
                                child: Text(
                                  suggestion.title,
                                  maxLines: 1,
                                  style: GoogleFonts.cairo(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                suggestion.subtitle,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.cairo(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.88)
                                      : const Color(0xFF334155),
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (!compact) ...[
                          const SizedBox(width: 8),
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              cycleButton,
                              openBadge,
                            ],
                          ),
                        ],
                      ],
                    ),
                    if (compact) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          cycleButton,
                          const SizedBox(width: 6),
                          openBadge,
                        ],
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _handleSuggestionTap(
    BuildContext context,
    TasksViewModel vm,
    ContextSuggestion suggestion,
  ) {
    switch (suggestion.action) {
      case ContextSuggestionAction.prayer:
        final prayerName = suggestion.prayerName ?? suggestion.title;
        final taskIndex = vm.tasks.indexWhere((t) =>
            t.name == prayerName ||
            t.name.contains(prayerName.replaceFirst('صلاة ', '')));
        final isCompleted =
            taskIndex != -1 ? vm.tasks[taskIndex].isCompleted : false;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PrayerDetailsScreen(
              prayerName: prayerName,
              prayerTime: suggestion.prayerTime,
              isCompleted: isCompleted,
              onToggleCompletion: () {
                if (taskIndex != -1) {
                  vm.toggleTask(taskIndex);
                }
              },
            ),
          ),
        );
      case ContextSuggestionAction.morningAthkar:
        _navigateToAthkar(context, vm, true);
      case ContextSuggestionAction.eveningAthkar:
        _navigateToAthkar(context, vm, false);
      case ContextSuggestionAction.sleepAthkar:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const AthkarDetailsScreen(
              title: kAthkarSleep,
              isMorning: false,
            ),
          ),
        ).then((_) async {
          if (!context.mounted) return;
          final athkarVM =
              Provider.of<AthkarViewModel>(context, listen: false);
          await athkarVM.loadDailyData();
          final idx = vm.tasks.indexWhere((t) => t.name == kAthkarSleep);
          if (idx != -1 && athkarVM.data.sleep.isComplete) {
            vm.toggleTask(idx, completionValue: true);
          }
        });
      case ContextSuggestionAction.qiyam:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QiyamLaylScreen()),
        );
      case ContextSuggestionAction.surahKahf:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SurahKahfScreen()),
        );
      case ContextSuggestionAction.khatmah:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const KhatmahScreen()),
        );
      case ContextSuggestionAction.tasbeeh:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const CustomTasbeehScreen()),
        );
      case ContextSuggestionAction.prophetPrayer:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const ProphetPrayersScreen()),
        ).then((_) async {
          if (!context.mounted) return;
          final prefs = await SharedPreferences.getInstance();
          final count = prefs.getInt('prophet_prayer_counter') ?? 0;
          final idx = vm.tasks.indexWhere((t) => t.name == kProphetPrayer);
          if (idx != -1) {
            vm.toggleTask(idx, completionValue: count >= 100);
          }
        });
      case ContextSuggestionAction.happinessJar:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HappinessJarScreen()),
        );
    }
  }

  void _navigateToAthkar(
      BuildContext context, TasksViewModel vm, bool isMorning) {
    final now = DateTime.now();
    final isActive = isMorning
        ? AthkarTimeHelper.isMorningWindow(now)
        : AthkarTimeHelper.isEveningWindow(now);

    if (isActive) {
      _openAthkarScreen(context, vm, isMorning);
    } else {
      AthkarTimeHelper.showInactiveTimeDialog(
        context: context,
        isMorning: isMorning,
        onProceedAnyway: () => _openAthkarScreen(context, vm, isMorning),
        onSwitchToActive: () => _openAthkarScreen(context, vm, !isMorning),
      );
    }
  }

  void _openAthkarScreen(
      BuildContext context, TasksViewModel vm, bool isMorning) {
    final title = isMorning ? kAthkarMorning : kAthkarEvening;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => AthkarDetailsScreen(
          title: title,
          isMorning: isMorning,
        ),
      ),
    ).then((_) async {
      if (!context.mounted) return;
      final athkarVM = Provider.of<AthkarViewModel>(context, listen: false);
      await athkarVM.loadDailyData();
      final isComplete = isMorning
          ? athkarVM.data.morning.isComplete
          : athkarVM.data.evening.isComplete;
      final index = vm.tasks.indexWhere((t) => t.name == title);
      if (index != -1) {
        vm.toggleTask(index, completionValue: isComplete);
      }
    });
  }

  Widget _buildSectionHeaderRow({
    required String title,
    required IconData icon,
    required bool isDark,
    String? trailingText,
  }) {
    const gold = Color(0xFFD4AF37);
    const goldLight = Color(0xFFFDE68A);
    final accent = isDark ? goldLight : context.primaryColor;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: gold.withValues(alpha: isDark ? 0.16 : 0.14),
            border: Border.all(
              color: gold.withValues(alpha: 0.45),
            ),
          ),
          child: Icon(icon, size: 17, color: accent),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.cairo(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ),
        if (trailingText != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: gold.withValues(alpha: isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: gold.withValues(alpha: isDark ? 0.45 : 0.55),
              ),
            ),
            child: Text(
              trailingText,
              style: GoogleFonts.ibmPlexMono(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? goldLight : const Color(0xFF78350F),
              ),
            ),
          ),
      ],
    );
  }

  void _handleTaskTap(
      BuildContext context, TasksViewModel vm, int index, dynamic task) {
    if (task.name == kPrayerFajr ||
        task.name == kPrayerDhuhr ||
        task.name == kPrayerAsr ||
        task.name == kPrayerMaghrib ||
        task.name == kPrayerIsha ||
        task.name.contains('الفجر') ||
        task.name.contains('الظهر') ||
        task.name.contains('العصر') ||
        task.name.contains('المغرب') ||
        task.name.contains('العشاء')) {
      DateTime? pTime;
      if (vm.prayerTimes != null) {
        if (task.name.contains(kPrayerFajr)) {
          pTime = vm.prayerTimes!.fajr;
        } else if (task.name.contains(kPrayerDhuhr)) {
          pTime = vm.prayerTimes!.dhuhr;
        } else if (task.name.contains(kPrayerAsr)) {
          pTime = vm.prayerTimes!.asr;
        } else if (task.name.contains(kPrayerMaghrib)) {
          pTime = vm.prayerTimes!.maghrib;
        } else if (task.name.contains(kPrayerIsha)) {
          pTime = vm.prayerTimes!.isha;
        }
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PrayerDetailsScreen(
            prayerName: task.name,
            prayerTime: pTime,
            isCompleted: task.isCompleted,
            onToggleCompletion: () => vm.toggleTask(index),
          ),
        ),
      );
    } else if (task.name == kQuranWird) {
      vm.toggleTask(index);
    } else if (task.name.contains(kAthkarLabel)) {
      final isMorning = task.name.contains(kAthkarMorning);
      final isSleep = task.name.contains(kAthkarSleep);
      final title = isSleep
          ? kAthkarSleep
          : (isMorning ? kAthkarMorning : kAthkarEvening);

      final now = DateTime.now();
      final isActive = isSleep ||
          (isMorning
              ? AthkarTimeHelper.isMorningWindow(now)
              : AthkarTimeHelper.isEveningWindow(now));

      if (isActive) {
        _openAthkarDetailsAndSync(context, vm, title, isMorning, isSleep);
      } else {
        AthkarTimeHelper.showInactiveTimeDialog(
          context: context,
          isMorning: isMorning,
          onProceedAnyway: () => _openAthkarDetailsAndSync(
              context, vm, title, isMorning, isSleep),
          onSwitchToActive: () => _openAthkarDetailsAndSync(context, vm,
              isMorning ? kAthkarEvening : kAthkarMorning, !isMorning, false),
        );
      }
    } else if (task.name.contains(kProphetPrayer)) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProphetPrayersScreen()),
      ).then((_) async {
        final prefs = await SharedPreferences.getInstance();
        final count = prefs.getInt('prophet_prayer_counter') ?? 0;
        vm.updateProphetPrayerCount(count);
      });
    } else if (task.name == kCustomWird) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CustomTasbeehScreen()),
      );
    } else if (task.name.contains(kPrayerQiyam) || task.name.contains('قيام')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const QiyamLaylScreen()),
      );
    } else {
      vm.toggleTask(index);
    }
  }

  void _openAthkarDetailsAndSync(BuildContext context, TasksViewModel vm,
      String title, bool isMorning, bool isSleep) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            AthkarDetailsScreen(title: title, isMorning: isMorning),
      ),
    ).then((_) async {
      if (!context.mounted) return;
      final athkarVM = Provider.of<AthkarViewModel>(context, listen: false);
      await athkarVM.loadDailyData();

      bool isComplete = false;
      if (isSleep) {
        isComplete = athkarVM.data.sleep.isComplete;
      } else if (isMorning) {
        isComplete = athkarVM.data.morning.isComplete;
      } else {
        isComplete = athkarVM.data.evening.isComplete;
      }

      final taskIndex = vm.tasks.indexWhere((t) => t.name == title);
      if (taskIndex != -1) {
        vm.toggleTask(taskIndex, completionValue: isComplete);
      }
    });
  }
}

class _WorshipArchLatticePainter extends CustomPainter {
  final Color color;
  const _WorshipArchLatticePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    const step = 28.0;
    for (double x = 0; x <= size.width + step; x += step) {
      for (double y = 0; y <= size.height + step; y += step) {
        final path = Path()
          ..moveTo(x, y - 9)
          ..lineTo(x + 9, y)
          ..lineTo(x, y + 9)
          ..lineTo(x - 9, y)
          ..close();
        canvas.drawPath(path, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _WorshipArchLatticePainter oldDelegate) =>
      oldDelegate.color != color;
}
